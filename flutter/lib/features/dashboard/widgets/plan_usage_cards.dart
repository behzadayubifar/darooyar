import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/providers/subscription_providers.dart';
import '../../subscription/screens/subscription_screen.dart';
import 'usage_card.dart';
import 'features_list.dart';
import '../../../core/theme/app_theme.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class PlanUsageCards extends ConsumerWidget {
  final SubscriptionPlan plan;

  const PlanUsageCards({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get active subscriptions to check real usage data
    final activeSubscriptionsAsync = ref.watch(activeSubscriptionsProvider);

    return activeSubscriptionsAsync.when(
      data: (subscriptions) {
        // Default values
        int remainingDays = 0;
        double daysPercentage = 0.0;
        int remainingUses = 0;
        double usesPercentage = 0.0;

        // If we have active subscriptions, use the real data
        if (subscriptions.isNotEmpty) {
          final subscription =
              subscriptions.first; // استفاده از اولین اشتراک فعال

          // Calculate days remaining
          if (plan.hasTimeLimit && subscription.expiryDate != null) {
            final now = DateTime.now();
            final totalDuration = subscription.expiryDate!
                .difference(subscription.purchaseDate)
                .inDays;
            remainingDays = subscription.expiryDate!.difference(now).inDays;

            if (totalDuration > 0) {
              daysPercentage = remainingDays / totalDuration;
              // Ensure percentage is between 0 and 1
              daysPercentage = daysPercentage.clamp(0.0, 1.0);
            }
          }

          // Calculate uses remaining
          if (subscription.remainingUses != null) {
            remainingUses = subscription.remainingUses!;

            if (plan.prescriptionCount > 0) {
              usesPercentage = remainingUses / plan.prescriptionCount;
              // Ensure percentage is between 0 and 1
              usesPercentage = usesPercentage.clamp(0.0, 1.0);
            }
          }
        }

        return Column(
          children: [
            // Usage cards
            if (plan.hasTimeLimit)
              UsageCard(
                title: 'زمان باقیمانده',
                value: '$remainingDays روز',
                percentage: daysPercentage,
                icon: Icons.calendar_today,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),

            if (plan.prescriptionCount > 0)
              UsageCard(
                title: 'نسخه‌های باقیمانده',
                value: '$remainingUses نسخه',
                percentage: usesPercentage,
                icon: Icons.description,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),

            // Features list
            FeaturesList(plan: plan),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('خطا در بارگذاری اطلاعات اشتراک: $error'),
      ),
    );
  }
}
