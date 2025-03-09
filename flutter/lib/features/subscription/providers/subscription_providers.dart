import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../models/plan.dart';
import '../services/subscription_service.dart';

// Provider for subscription service
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Provider for the list of available plans
final plansProvider = FutureProvider<List<Plan>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  return authState.when(
    data: (user) async {
      if (user == null) {
        return [];
      }
      final token = await ref.read(authServiceProvider).getToken();
      if (token == null) {
        return [];
      }
      return subscriptionService.getPlans(token);
    },
    loading: () async => [],
    error: (error, stackTrace) => [],
  );
});

// Provider for user subscriptions
final userSubscriptionsProvider =
    FutureProvider<List<UserSubscription>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  return authState.when(
    data: (user) async {
      if (user == null) {
        return [];
      }
      final token = await ref.read(authServiceProvider).getToken();
      if (token == null) {
        return [];
      }
      return subscriptionService.getUserSubscriptions(token);
    },
    loading: () async => [],
    error: (error, stackTrace) => [],
  );
});

// Provider for active user subscriptions
final activeSubscriptionsProvider =
    FutureProvider<List<UserSubscription>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  return authState.when(
    data: (user) async {
      if (user == null) {
        return [];
      }
      final token = await ref.read(authServiceProvider).getToken();
      if (token == null) {
        return [];
      }
      return subscriptionService.getActiveUserSubscriptions(token);
    },
    loading: () async => [],
    error: (error, stackTrace) => [],
  );
});

// Provider for credit transactions
final creditTransactionsProvider =
    FutureProvider.family<List<CreditTransaction>, PagingParams>(
        (ref, params) async {
  final authState = ref.watch(authStateProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  return authState.when(
    data: (user) async {
      if (user == null) {
        return [];
      }
      final token = await ref.read(authServiceProvider).getToken();
      if (token == null) {
        return [];
      }
      return subscriptionService.getCreditTransactions(
        token,
        limit: params.limit,
        offset: params.offset,
      );
    },
    loading: () async => [],
    error: (error, stackTrace) => [],
  );
});

// Purchase plan
final purchasePlanProvider =
    FutureProvider.family<UserSubscription, String>((ref, planId) async {
  final authState = ref.watch(authStateProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  return authState.when(
    data: (user) async {
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final token = await ref.read(authServiceProvider).getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      final subscription =
          await subscriptionService.purchasePlan(token, planId);

      // Refresh subscriptions and credit after purchase
      ref.invalidate(userSubscriptionsProvider);
      ref.invalidate(activeSubscriptionsProvider);
      ref.read(authStateProvider.notifier).refreshUser();

      return subscription;
    },
    loading: () => throw Exception('Authentication state is loading'),
    error: (error, stackTrace) =>
        throw Exception('Authentication error: $error'),
  );
});

// Use subscription
class UseSubscriptionParams {
  final String subscriptionId;
  final int count;

  UseSubscriptionParams(this.subscriptionId, this.count);
}

final useSubscriptionProvider =
    FutureProvider.family<void, UseSubscriptionParams>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  return authState.when(
    data: (user) async {
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final token = await ref.read(authServiceProvider).getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      await subscriptionService.useSubscription(
          token, params.subscriptionId, params.count);

      // Refresh subscriptions after usage
      ref.invalidate(activeSubscriptionsProvider);
      ref.invalidate(userSubscriptionsProvider);
    },
    loading: () => throw Exception('Authentication state is loading'),
    error: (error, stackTrace) =>
        throw Exception('Authentication error: $error'),
  );
});

// Paging parameters for transactions
class PagingParams {
  final int limit;
  final int offset;

  PagingParams({this.limit = 20, this.offset = 0});
}
