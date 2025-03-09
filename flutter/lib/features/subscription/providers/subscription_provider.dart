import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';

// Proveedor para el servicio de suscripción
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Proveedor para el plan de suscripción actual
final currentPlanProvider = FutureProvider<SubscriptionPlan?>((ref) async {
  final authState = ref.watch(authStateProvider);

  // Si el usuario no está autenticado, no puede tener un plan
  if (!authState.hasValue || authState.value == null) {
    return null;
  }

  final authService = ref.read(authServiceProvider);
  final subscriptionService = ref.read(subscriptionServiceProvider);

  try {
    // Obtener el token de autenticación
    final token = await authService.getToken();
    if (token == null) {
      AppLogger.w(
          'No authentication token available for fetching subscription plan');
      return null;
    }

    // Obtener el plan actual
    return await subscriptionService.getCurrentPlan(token);
  } catch (e) {
    AppLogger.e('Error fetching current subscription plan: $e');
    return null;
  }
});

// Proveedor para el estado de compra
final purchaseStateProvider =
    StateNotifierProvider<PurchaseStateNotifier, AsyncValue<void>>((ref) {
  return PurchaseStateNotifier(ref);
});

class PurchaseStateNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  PurchaseStateNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> purchasePlan(String planId) async {
    state = const AsyncValue.loading();

    try {
      // Obtener servicio de autenticación
      final authService = _ref.read(authServiceProvider);

      // Obtener token
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('لطفا ابتدا وارد شوید');
      }

      // Check if user already has an active plan
      final currentPlan = await _ref.read(currentPlanProvider.future);
      if (currentPlan != null) {
        throw Exception(
            'شما در حال حاضر یک اشتراک فعال دارید. لطفا تا زمان انقضای آن صبر کنید.');
      }

      // Obtener servicio de suscripción
      final subscriptionService = _ref.read(subscriptionServiceProvider);

      // Purchase the plan using the real API
      await subscriptionService.purchasePlan(token, planId);

      // Actualizar el estado si fue exitoso
      state = const AsyncValue.data(null);

      // Refrescar el plan actual
      _ref.refresh(currentPlanProvider);

      // Refrescar la información del usuario para actualizar el crédito
      _ref.read(authStateProvider.notifier).refreshUser();

      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      AppLogger.e('Purchase plan error: $e');
      rethrow;
    }
  }
}
