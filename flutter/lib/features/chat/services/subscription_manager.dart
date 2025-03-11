import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../../core/utils/logger.dart';

/// Service for managing subscription-related functionality in the chat
class SubscriptionManager {
  final Ref _ref;

  SubscriptionManager(this._ref);

  /// Check if the user has an active subscription
  bool hasActiveSubscription() {
    final subscriptionState = _ref.read(subscriptionProvider);
    return subscriptionState.hasActiveSubscription;
  }

  /// Check if the user has reached their message limit
  bool hasReachedMessageLimit() {
    final subscriptionState = _ref.read(subscriptionProvider);
    final plan = subscriptionState.currentPlan;

    if (plan == null) {
      return true; // No plan means no messages allowed
    }

    if (plan.prescriptionCount == -1) {
      return false; // Unlimited messages
    }

    return subscriptionState.usedMessages >= plan.prescriptionCount;
  }

  /// Get the current subscription plan
  SubscriptionPlan? getCurrentPlan() {
    final subscriptionState = _ref.read(subscriptionProvider);
    return subscriptionState.currentPlan;
  }

  /// Get the number of messages remaining
  int getRemainingMessages() {
    final subscriptionState = _ref.read(subscriptionProvider);
    final plan = subscriptionState.currentPlan;

    if (plan == null) {
      return 0;
    }

    if (plan.prescriptionCount == -1) {
      return -1; // Unlimited messages
    }

    return plan.prescriptionCount - subscriptionState.usedMessages;
  }

  /// Increment the used message count
  Future<void> incrementUsedMessages() async {
    try {
      await _ref.read(subscriptionProvider.notifier).incrementUsedMessages();
    } catch (e) {
      AppLogger.e('Error incrementing used messages: $e');
    }
  }
}
