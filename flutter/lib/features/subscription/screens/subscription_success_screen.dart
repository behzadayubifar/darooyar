import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../models/plan.dart';
import '../../../core/utils/number_formatter.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/subscription_providers.dart';
import '../providers/subscription_provider.dart';

class SubscriptionSuccessScreen extends ConsumerWidget {
  final Plan plan;
  final VoidCallback onContinue;

  const SubscriptionSuccessScreen({
    Key? key,
    required this.plan,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success animation
              Lottie.asset(
                'assets/animations/success.json',
                width: 200,
                height: 200,
                repeat: false,
              ),

              const SizedBox(height: 32),

              // Congratulations text
              Text(
                'تبریک! 🎉',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),

              const SizedBox(height: 16),

              Text(
                'اشتراک شما با موفقیت فعال شد',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Plan details card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'جزئیات اشتراک',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        context,
                        'نام پلن:',
                        plan.title,
                      ),
                      _buildDetailRow(
                        context,
                        'قیمت:',
                        '${NumberFormatter.formatPriceInThousands(plan.price)} تومان',
                      ),
                      if (plan.durationDays != null)
                        _buildDetailRow(
                          context,
                          'مدت زمان:',
                          plan.durationDays == 30
                              ? '۱ ماه'
                              : plan.durationDays == 365
                                  ? '۱ سال'
                                  : '${plan.durationDays} روز',
                        ),
                      if (plan.maxUses != null)
                        _buildDetailRow(
                          context,
                          'تعداد استفاده:',
                          '${plan.maxUses} بار',
                        ),
                      _buildDetailRow(
                        context,
                        'نوع پلن:',
                        _getPlanTypeText(plan.planType),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Refresh all necessary providers before continuing
                    ref.invalidate(userSubscriptionsProvider);
                    ref.invalidate(activeSubscriptionsProvider);
                    ref.invalidate(currentPlanProvider);
                    ref.read(authStateProvider.notifier).refreshUser();

                    // Call the original onContinue callback
                    onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ادامه',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _getPlanTypeText(String planType) {
    switch (planType) {
      case 'time_based':
        return 'زمان‌محور';
      case 'usage_based':
        return 'استفاده‌محور';
      case 'both':
        return 'ترکیبی';
      default:
        return planType;
    }
  }
}
