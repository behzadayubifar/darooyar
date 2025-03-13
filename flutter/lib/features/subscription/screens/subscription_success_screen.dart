import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../models/plan.dart';
import '../../../core/utils/number_formatter.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/subscription_providers.dart';
import '../providers/subscription_provider.dart';

class SubscriptionSuccessScreen extends ConsumerStatefulWidget {
  final Plan plan;
  final VoidCallback onContinue;

  const SubscriptionSuccessScreen({
    Key? key,
    required this.plan,
    required this.onContinue,
  }) : super(key: key);

  @override
  ConsumerState<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState
    extends ConsumerState<SubscriptionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [Colors.blueGrey.shade900, Colors.black]
                  : [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + 0.1 * _animationController.value,
                    child: child,
                  );
                },
                child: Lottie.asset(
                  'assets/animations/success.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
              ),

              const SizedBox(height: 24),

              // Congratulations text with animation
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.elasticOut,
                )),
                child: Text(
                  'تبریک! 🎉',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ),

              const SizedBox(height: 16),

              FadeTransition(
                opacity: _animationController,
                child: Text(
                  'اشتراک شما با موفقیت فعال شد',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // Plan details card
              Card(
                elevation: 8,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
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
                        widget.plan.title,
                      ),
                      _buildDetailRow(
                        context,
                        'قیمت:',
                        '${NumberFormatter.formatPriceInThousands(widget.plan.price)} تومان',
                      ),
                      if (widget.plan.durationDays != null)
                        _buildDetailRow(
                          context,
                          'مدت زمان:',
                          widget.plan.durationDays == 30
                              ? '۱ ماه'
                              : widget.plan.durationDays == 365
                                  ? '۱ سال'
                                  : '${widget.plan.durationDays} روز',
                        ),
                      if (widget.plan.maxUses != null)
                        _buildDetailRow(
                          context,
                          'تعداد استفاده:',
                          '${widget.plan.maxUses} بار',
                        ),
                      _buildDetailRow(
                        context,
                        'نوع پلن:',
                        _getPlanTypeText(widget.plan.planType),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Continue button with improved visibility in dark mode
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
                    widget.onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                    foregroundColor: isDarkMode
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'ادامه',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
