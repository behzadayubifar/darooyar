import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/plan.dart';
import '../providers/subscription_providers.dart';
import '../../../core/utils/number_formatter.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    AppLogger.d('SubscriptionScreen initialized');
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    AppLogger.d('SubscriptionScreen disposed');
    super.dispose();
  }

  Future<void> _purchasePlan(BuildContext context, Plan plan) async {
    final authState = ref.read(authStateProvider);

    if (!authState.hasValue || authState.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا ابتدا وارد شوید')),
      );
      return;
    }

    // Store context in a local variable to avoid using it across async gaps
    final currentContext = context;

    final user = authState.value!;

    if (user.credit < plan.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اعتبار شما برای خرید این پلن کافی نیست')),
      );
      return;
    }

    try {
      // Use the subscription service to purchase the plan
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final token = await ref.read(authServiceProvider).getToken();

      if (token == null) {
        throw Exception('لطفا ابتدا وارد شوید');
      }

      await subscriptionService.purchasePlan(token, plan.id);

      if (mounted) {
        setState(() {
          _showSuccess = true;
        });

        // Show success animation for a few seconds and then return to normal state
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSuccess = false;
            });
          }
        });

        // Refresh user data to update credit
        ref.read(authStateProvider.notifier).refreshUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final currentUserCredit = currentUser?.credit ?? 0.0;

    // If we're in success state, show a success animation
    if (_showSuccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('خرید اشتراک'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/success.json',
                width: 200,
                height: 200,
                repeat: false,
              ),
              const SizedBox(height: 24),
              const Text(
                'خرید شما با موفقیت انجام شد!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'از خرید شما متشکریم',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showSuccess = false;
                  });
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('بازگشت به پلن‌ها'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('خرید اشتراک'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Current credit information
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'اعتبار فعلی شما:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                _formatPriceInThousands(currentUserCredit),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPriceUnit(currentUserCredit),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to credit recharge screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('این قابلیت به زودی اضافه خواهد شد')),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'افزایش',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Plans content
          Expanded(
            child: plansAsync.when(
              data: (plans) {
                if (plans.isEmpty) {
                  return const Center(
                    child: Text('هیچ پلنی یافت نشد'),
                  );
                }

                return Column(
                  children: [
                    // Page indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          plans.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? _getPlanColor(
                                      plans[index].planType, context)
                                  : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // PageView for plans
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: plans.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return _buildPlanCard(
                            context,
                            plans[index],
                            false,
                            currentUserCredit,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text('خطا در بارگذاری پلن‌ها: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context, Plan plan, bool isLoading, double userCredit) {
    final bool canAfford = userCredit >= plan.price;

    // Get color and icon based on plan type
    final Color planColor = _getPlanColor(plan.planType, context);
    final IconData planIcon = _getPlanIcon(plan.planType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          // Plan header with gradient background and elevation animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  planColor.withOpacity(0.9),
                  planColor.withOpacity(0.7),
                  planColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: planColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Subtle elevation animation
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -5 * value),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    height: 70,
                    width: 70,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        planIcon,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Plan title
                Text(
                  plan.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Plan price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        _formatPriceInThousands(plan.price),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _getPriceUnit(plan.price),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Plan details
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan description
                  Text(
                    plan.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Plan features
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Duration
                          _buildFeatureItem(
                            context,
                            Icons.access_time,
                            plan.formattedDuration,
                          ),
                          const SizedBox(height: 12),

                          // Usage
                          _buildFeatureItem(
                            context,
                            Icons.format_list_numbered,
                            plan.formattedUses,
                          ),
                          const SizedBox(height: 12),

                          // Plan type
                          _buildFeatureItem(
                            context,
                            Icons.category,
                            plan.isTimeBased && plan.isUsageBased
                                ? 'محدودیت زمانی و تعداد استفاده'
                                : plan.isTimeBased
                                    ? 'محدودیت زمانی'
                                    : 'محدودیت تعداد استفاده',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Purchase button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading || !canAfford
                          ? null
                          : () => _purchasePlan(context, plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: planColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              canAfford ? 'خرید اشتراک' : 'اعتبار ناکافی',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Color _getPlanColor(String planType, BuildContext context) {
    switch (planType) {
      case 'time_based':
        return Colors.blue;
      case 'usage_based':
        return Colors.orange;
      case 'both':
        return Colors.indigo;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getPlanIcon(String planType) {
    switch (planType) {
      case 'time_based':
        return Icons.access_time;
      case 'usage_based':
        return Icons.format_list_numbered;
      case 'both':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.medical_services_outlined;
    }
  }

  // Helper method to format price by removing zeros appropriately
  String _formatPriceInThousands(double price) {
    // For prices >= 1,000,000,000, show as billion
    if (price >= 1000000000) {
      double priceInBillions = price / 1000000000;
      // Format with 2 decimal places if needed, otherwise show as integer
      String formatted = priceInBillions % 1 == 0
          ? priceInBillions.toInt().toString()
          : priceInBillions
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'\.?0*$'), '');
      return NumberFormatter.formatWithCommas(formatted);
    }
    // For prices >= 1,000,000, show as million
    else if (price >= 1000000) {
      double priceInMillions = price / 1000000;
      // Format with 2 decimal places if needed, otherwise show as integer
      String formatted = priceInMillions % 1 == 0
          ? priceInMillions.toInt().toString()
          : priceInMillions
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'\.?0*$'), '');
      return NumberFormatter.formatWithCommas(formatted);
    }
    // For smaller prices, show as thousand
    else {
      double priceInThousands = price / 1000;
      // Format with 2 decimal places if needed, otherwise show as integer
      String formatted = priceInThousands % 1 == 0
          ? priceInThousands.toInt().toString()
          : priceInThousands
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'\.?0*$'), '');
      return NumberFormatter.formatWithCommas(formatted);
    }
  }

  // Helper method to get the appropriate price unit based on the price value
  String _getPriceUnit(double price) {
    if (price >= 1000000000) {
      return 'میلیارد تومن';
    } else if (price >= 1000000) {
      return 'میلیون تومن';
    } else {
      return 'هزار تومن';
    }
  }
}
