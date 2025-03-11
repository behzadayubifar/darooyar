import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';

// Proveedor para el servicio de suscripción
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Subscription state provider
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref);
});

// Subscription state class
class SubscriptionState {
  final SubscriptionPlan? currentPlan;
  final bool hasActiveSubscription;
  final int usedMessages;

  SubscriptionState({
    this.currentPlan,
    this.hasActiveSubscription = false,
    this.usedMessages = 0,
  });

  SubscriptionState copyWith({
    SubscriptionPlan? currentPlan,
    bool? hasActiveSubscription,
    int? usedMessages,
  }) {
    return SubscriptionState(
      currentPlan: currentPlan ?? this.currentPlan,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
      usedMessages: usedMessages ?? this.usedMessages,
    );
  }
}

// Subscription notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final Ref _ref;

  SubscriptionNotifier(this._ref) : super(SubscriptionState()) {
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    try {
      final plan = await _ref.read(currentPlanProvider.future);
      state = state.copyWith(
        currentPlan: plan,
        hasActiveSubscription: plan != null,
      );
    } catch (e) {
      AppLogger.e('Error loading current plan: $e');
    }
  }

  Future<void> incrementUsedMessages() async {
    state = state.copyWith(usedMessages: state.usedMessages + 1);

    // If we have a subscription ID, record the usage
    if (state.currentPlan != null) {
      try {
        final authService = _ref.read(authServiceProvider);
        final token = await authService.getToken();

        if (token != null) {
          final subscriptionService = _ref.read(subscriptionServiceProvider);
          // Implement the actual API call to record usage
          // This is a placeholder - you'll need to implement the actual API call
        }
      } catch (e) {
        AppLogger.e('Error recording message usage: $e');
      }
    }
  }

  Future<void> refreshSubscription() async {
    await _loadCurrentPlan();
  }
}

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

      // Refresh the subscription provider
      _ref.read(subscriptionProvider.notifier).refreshSubscription();

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
