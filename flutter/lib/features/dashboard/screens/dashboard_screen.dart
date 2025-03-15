import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_size.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../chat/models/chat.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/providers/chat_providers.dart';
import '../../settings/screens/settings_screen.dart';
import '../../subscription/models/plan.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../subscription/providers/subscription_providers.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../subscription/screens/credit_payment_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/number_formatter.dart';
import 'dart:math' as Math;
import '../../../utils/myket_utils.dart';
import '../../../services/myket_rating_service.dart';
import '../../../main.dart'; // Import main.dart for myketRatingServiceProvider

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _currentIndex = 0;
  int _currentTabIndex = 0;
  final PageController _pageController = PageController();

  // Add variables to track refresh state
  DateTime _lastRefreshTime = DateTime.now();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        // Sync page controller with tab controller
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // Refresh subscription data when the dashboard is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSubscriptionData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    // Remove observer when disposing
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshSubscriptionData();
    }
  }

  // Add a method to handle focus changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if this screen is currently focused
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      // Only refresh if we haven't refreshed recently
      final now = DateTime.now();
      if (now.difference(_lastRefreshTime).inSeconds > 10) {
        _refreshSubscriptionData();
      }
    }
  }

  // Method to refresh subscription data
  void _refreshSubscriptionData() {
    // Check if we're already refreshing or if it's too soon since last refresh
    final now = DateTime.now();
    if (_isRefreshing || now.difference(_lastRefreshTime).inSeconds < 10) {
      return; // Skip this refresh
    }

    // Set refreshing flag and update last refresh time
    _isRefreshing = true;
    _lastRefreshTime = now;

    // Invalidate providers to force refresh
    ref.invalidate(activeSubscriptionsProvider);
    ref.invalidate(userSubscriptionsProvider);
    ref.invalidate(currentPlanProvider);

    // Also refresh user data
    ref.read(authStateProvider.notifier).refreshUser();

    // Reset refreshing flag after a delay
    Future.delayed(const Duration(seconds: 2), () {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final currentPlanAsync = ref.watch(currentPlanProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmationDialog();
        }
        return;
      },
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                elevation: 0,
                automaticallyImplyLeading: false, // Remove back button
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'سلام ${user?.firstName ?? 'کاربر'} 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(bottom: 16, right: 16),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(user: user),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ];
          },
          body: RefreshIndicator(
            onRefresh: () async {
              ref.refresh(currentPlanProvider);
              ref.read(authStateProvider.notifier).refreshUser();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Credit Card
                  _buildCreditCard(user),

                  // Plan Usage Section
                  _buildPlanUsageSection(currentPlanAsync),

                  // Quick Actions
                  _buildQuickActions(context),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: AppTheme.primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: const [
                            Tab(
                                text: 'پیشنهادات',
                                icon: Icon(Icons.lightbulb_outline)),
                            Tab(text: 'آمار', icon: Icon(Icons.bar_chart)),
                            Tab(text: 'راهنما', icon: Icon(Icons.help_outline)),
                          ],
                        ),
                        // Use PageView instead of IndexedStack to enable swiping
                        SizedBox(
                          // Set a reasonable height that works for all content
                          // This is needed because PageView needs a fixed height
                          height: 350,
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              // Sync tab controller with page controller
                              setState(() {
                                _currentTabIndex = index;
                                _tabController.animateTo(index);
                              });
                            },
                            children: [
                              SingleChildScrollView(
                                child: _buildSuggestionsTab(),
                              ),
                              SingleChildScrollView(
                                child: _buildStatsTab(),
                              ),
                              SingleChildScrollView(
                                child: _buildHelpTab(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == _currentIndex) return;

            if (index == 0) {
              // Stay on dashboard
              setState(() {
                _currentIndex = 0;
              });
            } else if (index == 1) {
              // Navigate to chat history
              // Invalidate the provider before navigation to ensure fresh data
              ref.invalidate(chatListProvider);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatListScreen(),
                ),
              ).then((_) {
                setState(() {
                  _currentIndex = 0;
                });
                // Refresh data when returning from chat list
                _refreshSubscriptionData();
              });
            } else if (index == 2) {
              // Start new chat
              _showNewChatDialog(context);
              setState(() {
                _currentIndex = 0;
              });
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'داشبورد',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'تاریخچه',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'گفتگوی جدید',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(User? user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryColor,
            Color(0xFF7986CB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'اعتبار شما',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SvgPicture.asset(
                'assets/images/credit_card_chip.svg',
                height: 30,
                width: 30,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatPrice(user?.credit ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _getPriceUnit(user?.credit ?? 0),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to credit payment screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreditPaymentScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'افزایش اعتبار',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanUsageSection(
      AsyncValue<SubscriptionPlan?> currentPlanAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: currentPlanAsync.when(
        data: (plan) {
          if (plan == null) {
            return _buildNoPlanCard();
          }
          return _buildPlanUsageCards(plan);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('خطا در بارگیری اطلاعات: $error'),
        ),
      ),
    );
  }

  Widget _buildNoPlanCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Lottie.asset(
              'assets/animations/no_subscription.json',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.subscriptions_outlined,
                  size: 80,
                  color: AppTheme.primaryColor,
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'شما هنوز اشتراکی ندارید',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'برای استفاده از امکانات کامل برنامه، یک اشتراک تهیه کنید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'خرید اشتراک',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanUsageCards(SubscriptionPlan plan) {
    // Get active subscriptions to check real usage data
    final activeSubscriptionsAsync = ref.watch(activeSubscriptionsProvider);

    return activeSubscriptionsAsync.when(
      data: (subscriptions) {
        // Calculate real usage data from the active subscription
        // Default values in case we can't get real data
        double timeUsed = 0.0;
        double prescriptionsUsed = 0.0;
        int remainingDays = plan.timeLimitDays;
        int remainingUses = plan.prescriptionCount;

        // If we have active subscriptions, use the real data
        if (subscriptions.isNotEmpty) {
          final subscription =
              subscriptions.first; // Use the first active subscription

          // Calculate time used if the plan has time limit
          if (plan.hasTimeLimit && subscription.expiryDate != null) {
            final now = DateTime.now();
            final totalDuration = subscription.expiryDate!
                .difference(subscription.purchaseDate)
                .inDays;
            final remainingDuration =
                subscription.expiryDate!.difference(now).inDays;

            // Make sure we don't divide by zero
            if (totalDuration > 0) {
              timeUsed = 1.0 - (remainingDuration / totalDuration);
              timeUsed =
                  timeUsed.clamp(0.0, 1.0); // Ensure it's between 0 and 1
              remainingDays = remainingDuration;
            }
          }

          // Calculate prescriptions used
          if (subscription.remainingUses != null) {
            remainingUses = subscription.remainingUses!;
            // Calculate the percentage used
            if (plan.prescriptionCount > 0) {
              prescriptionsUsed =
                  1.0 - (remainingUses / plan.prescriptionCount);
              prescriptionsUsed = prescriptionsUsed.clamp(
                  0.0, 1.0); // Ensure it's between 0 and 1
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF7986CB)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'اشتراک فعال: ${plan.name}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildUsageCard(
                    title: 'زمان باقیمانده',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                    percent: plan.hasTimeLimit ? timeUsed : 0,
                    value: plan.hasTimeLimit ? '$remainingDays روز' : 'نامحدود',
                    showProgress: plan.hasTimeLimit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildUsageCard(
                    title: 'نسخه‌های باقیمانده',
                    icon: Icons.description,
                    color: Colors.green,
                    percent: prescriptionsUsed,
                    value: plan.prescriptionCount > 0
                        ? '$remainingUses از ${plan.prescriptionCount}'
                        : 'نامحدود',
                    showProgress: plan.prescriptionCount > 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFeaturesList(plan),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('خطا در بارگیری اطلاعات: $error'),
      ),
    );
  }

  Widget _buildUsageCard({
    required String title,
    required IconData icon,
    required Color color,
    required double percent,
    required String value,
    required bool showProgress,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title at the top with full width
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Value with right alignment
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (showProgress) ...[
              const SizedBox(height: 6),
              LinearPercentIndicator(
                lineHeight: 8,
                percent: 1 - percent, // Remaining percentage
                backgroundColor: Colors.grey[300],
                progressColor: color,
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(SubscriptionPlan plan) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.green.withOpacity(0.3), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ویژگی‌های اشتراک شما',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flash_on,
                  color: Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'دسترسی سریع',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                icon: Icons.add_circle_outline,
                label: 'گفتگوی جدید',
                color: Colors.blue,
                onTap: () {
                  _showNewChatDialog(context);
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.history,
                label: 'تاریخچه',
                color: Colors.purple,
                onTap: () {
                  // Invalidate the provider before navigation to ensure fresh data
                  ref.invalidate(chatListProvider);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(),
                    ),
                  ).then((_) {
                    // Refresh data when returning from chat list
                    _refreshSubscriptionData();
                  });
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.card_giftcard,
                label: 'اشتراک‌ها',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.star,
                label: 'نظر و امتیاز',
                color: Colors.amber,
                onTap: () {
                  MyketUtils.openRatingPage();
                  // Mark as rated in the service
                  ref.read(myketRatingServiceProvider).markAsRated();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: isDarkMode
                  ? Border.all(color: color.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? colorScheme.onSurface : Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSuggestionItem(
            icon: Icons.star,
            title: 'ارتقا به اشتراک پیشرفته',
            description:
                'با ارتقا به اشتراک پیشرفته، از امکانات بیشتری بهره‌مند شوید',
          ),
          _buildSuggestionItem(
            icon: Icons.history_edu,
            title: 'ثبت نسخه‌های بیشتر',
            description:
                'با ثبت نسخه‌های بیشتر، سابقه درمانی کامل‌تری داشته باشید',
          ),
          _buildSuggestionItem(
            icon: Icons.medical_services_outlined,
            title: 'مشاوره با پزشک',
            description:
                'برای دریافت مشاوره تخصصی، با پزشکان متخصص ارتباط برقرار کنید',
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Handle tap based on the suggestion type
          if (title.contains('اشتراک')) {
            // Navigate to subscription screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionScreen(),
              ),
            );
          } else if (title.contains('نسخه')) {
            // Show a message about prescriptions
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('برای ثبت نسخه‌های بیشتر، اشتراک خود را ارتقا دهید'),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (title.contains('مشاوره')) {
            // Show a message about consultation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('این قابلیت به زودی اضافه خواهد شد'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primaryColor),
          title: Text(title),
          subtitle: Text(
            description,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final currentPlanAsync = ref.watch(currentPlanProvider);
    // Get user chats for statistics
    final chatsAsync = ref.watch(chatListProvider);
    // Get user subscriptions for usage data
    final subscriptionsAsync = ref.watch(activeSubscriptionsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: currentPlanAsync.when(
        data: (plan) {
          if (plan == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  'برای مشاهده آمار استفاده، ابتدا یک اشتراک تهیه کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }

          // Calculate statistics based on actual data
          return chatsAsync.when(
            data: (chats) {
              // Calculate chat statistics
              final int totalChats = chats.length;
              final int maxChatsPerMonth = 100; // Assuming a reasonable maximum
              final double chatPercent = totalChats / maxChatsPerMonth;
              final double chatPercentCapped = chatPercent.clamp(0.0, 1.0);

              // Calculate prescription statistics
              return subscriptionsAsync.when(
                data: (subscriptions) {
                  // Get the active subscription
                  final activeSubscription =
                      subscriptions.isNotEmpty ? subscriptions.first : null;

                  // Calculate prescription usage
                  int maxPrescriptions =
                      plan.prescriptionCount > 0 ? plan.prescriptionCount : 100;
                  int usedPrescriptions = 0;
                  int remainingPrescriptions = maxPrescriptions;

                  if (activeSubscription != null &&
                      activeSubscription.remainingUses != null) {
                    remainingPrescriptions = activeSubscription.remainingUses!;
                    usedPrescriptions =
                        maxPrescriptions - remainingPrescriptions;
                  }

                  final double prescriptionPercent = maxPrescriptions > 0
                      ? usedPrescriptions / maxPrescriptions
                      : 0.0;
                  final double prescriptionPercentCapped =
                      prescriptionPercent.clamp(0.0, 1.0);

                  // Calculate weekly chat statistics
                  final Map<String, int> weekdayChats =
                      _calculateWeekdayChats(chats);
                  // Ensure maxWeekdayChats is never zero to avoid division by zero
                  final int maxWeekdayChats = Math.max(
                      1,
                      weekdayChats.values.isEmpty
                          ? 1
                          : weekdayChats.values
                              .reduce((a, b) => a > b ? a : b));

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CircularPercentIndicator(
                              radius: 50.0,
                              lineWidth: 8.0,
                              percent: chatPercentCapped,
                              center: Text(
                                "${(chatPercentCapped * 100).toInt()}%",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0),
                              ),
                              footer: const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text("گفتگوهای این ماه"),
                              ),
                              progressColor: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: CircularPercentIndicator(
                              radius: 50.0,
                              lineWidth: 8.0,
                              percent: prescriptionPercentCapped,
                              center: Text(
                                "${(prescriptionPercentCapped * 100).toInt()}%",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0),
                              ),
                              footer: const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text("نسخه‌های ثبت شده"),
                              ),
                              progressColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'آمار استفاده هفتگی',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildWeekdayProgressBar(
                                  weekdayChats, 'شنبه', maxWeekdayChats),
                              const SizedBox(height: 8),
                              _buildWeekdayProgressBar(
                                  weekdayChats, 'یکشنبه', maxWeekdayChats),
                              const SizedBox(height: 8),
                              _buildWeekdayProgressBar(
                                  weekdayChats, 'دوشنبه', maxWeekdayChats),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => const Center(
                  child: Text('خطا در بارگیری اطلاعات اشتراک'),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const Center(
              child: Text('خطا در بارگیری اطلاعات گفتگوها'),
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (_, __) => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Text('خطا در بارگیری اطلاعات'),
          ),
        ),
      ),
    );
  }

  // Helper method to calculate chats per weekday
  Map<String, int> _calculateWeekdayChats(List<Chat> chats) {
    // Initialize with default values of 0 for all days
    final Map<String, int> weekdayChats = {
      'شنبه': 0,
      'یکشنبه': 0,
      'دوشنبه': 0,
      'سه‌شنبه': 0,
      'چهارشنبه': 0,
      'پنج‌شنبه': 0,
      'جمعه': 0,
    };

    // If no chats, return the initialized map with zeros
    if (chats.isEmpty) {
      return weekdayChats;
    }

    // Get chats from the last week
    final DateTime now = DateTime.now();
    final DateTime oneWeekAgo = now.subtract(const Duration(days: 7));

    for (final chat in chats) {
      if (chat.updatedAt != null && chat.updatedAt.isAfter(oneWeekAgo)) {
        // Convert weekday to Persian
        final String weekday = _getWeekdayName(chat.updatedAt.weekday);
        weekdayChats[weekday] = (weekdayChats[weekday] ?? 0) + 1;
      }
    }

    return weekdayChats;
  }

  // Helper method to convert weekday number to Persian name
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'شنبه';
      case DateTime.sunday:
        return 'یکشنبه';
      case DateTime.monday:
        return 'دوشنبه';
      case DateTime.tuesday:
        return 'سه‌شنبه';
      case DateTime.wednesday:
        return 'چهارشنبه';
      case DateTime.thursday:
        return 'پنج‌شنبه';
      case DateTime.friday:
        return 'جمعه';
      default:
        return 'شنبه';
    }
  }

  // Helper method to build weekday progress bars safely
  Widget _buildWeekdayProgressBar(
      Map<String, int> weekdayChats, String day, int maxValue) {
    // Ensure we have a valid value and avoid division by zero
    final int value = weekdayChats[day] ?? 0;
    final double percent = maxValue > 0 ? value / maxValue : 0.0;
    final int percentInt = (percent * 100).toInt();

    return LinearPercentIndicator(
      lineHeight: 14.0,
      percent: percent,
      center: Text(
        "$percentInt%",
        style: const TextStyle(fontSize: 12.0, color: Colors.white),
      ),
      leading: Text(day),
      trailing: Text("$value گفتگو"),
      progressColor: Colors.blue,
      barRadius: const Radius.circular(7),
    );
  }

  Widget _buildHelpTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHelpItem(
            icon: Icons.chat_bubble_outline,
            title: 'شروع گفتگو',
            description:
                'برای شروع گفتگوی جدید، روی دکمه + در پایین صفحه کلیک کنید',
          ),
          _buildHelpItem(
            icon: Icons.history,
            title: 'مشاهده تاریخچه',
            description:
                'برای مشاهده گفتگوهای قبلی، به بخش تاریخچه مراجعه کنید',
          ),
          _buildHelpItem(
            icon: Icons.card_giftcard,
            title: 'خرید اشتراک',
            description: 'برای ارتقای اشتراک خود، به بخش اشتراک‌ها مراجعه کنید',
          ),
          _buildHelpItem(
            icon: Icons.folder,
            title: 'مدیریت پوشه‌ها',
            description:
                'برای سازماندهی گفتگوها، آنها را در پوشه‌های مختلف دسته‌بندی کنید',
          ),
          _buildHelpItem(
            icon: Icons.share,
            title: 'اشتراک‌گذاری گفتگوها',
            description: 'گفتگوهای خود را با دیگران به اشتراک بگذارید',
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Handle tap based on the help item type
          if (title.contains('شروع گفتگو')) {
            // Navigate to new chat screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chat: Chat(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: 'گفتگوی جدید',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    messages: [],
                    folderId: null,
                  ),
                ),
              ),
            );
          } else if (title.contains('مشاهده تاریخچه')) {
            // Navigate to chat history
            // Invalidate the provider before navigation to ensure fresh data
            ref.invalidate(chatListProvider);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatListScreen(),
              ),
            ).then((_) {
              // Refresh data when returning from chat list
              if (mounted) {
                _refreshSubscriptionData();
              }
            });
          } else if (title.contains('خرید اشتراک')) {
            // Navigate to subscription screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionScreen(),
              ),
            );
          } else if (title.contains('مدیریت پوشه')) {
            // Show a message about folder management
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('برای مدیریت پوشه‌ها، به بخش تاریخچه مراجعه کنید'),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (title.contains('اشتراک‌گذاری')) {
            // Show a message about sharing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('این قابلیت به زودی اضافه خواهد شد'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primaryColor),
          title: Text(title),
          subtitle: Text(
            description,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  // Helper method to format price by removing zeros appropriately
  String _formatPrice(double price) {
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

  // Show dialog to create a new chat
  void _showNewChatDialog(BuildContext context) async {
    // Check if user has an active plan
    final currentPlan = await ref.read(currentPlanProvider.future);
    if (currentPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ایجاد گفتگوی جدید نیاز به اشتراک فعال دارید'),
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to subscription screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SubscriptionScreen(),
        ),
      );
      return;
    }

    // Show dialog to enter chat name
    final TextEditingController chatNameController =
        TextEditingController(text: 'گفتگوی جدید');

    // Pre-select the default text
    chatNameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: chatNameController.text.length,
    );

    // Variable to track loading state
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (dialogContext) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('ایجاد گفتگوی جدید'),
          content: TextField(
            controller: chatNameController,
            decoration: const InputDecoration(
              labelText: 'نام گفتگو',
              hintText: 'نام گفتگوی جدید را وارد کنید',
            ),
            autofocus: true,
            enabled: !isLoading, // Disable text field during loading
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null // Disable button during loading
                  : () {
                      Navigator.pop(dialogContext);
                    },
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null // Disable button during loading
                  : () async {
                      final chatName = chatNameController.text.trim();
                      if (chatName.isEmpty) {
                        return;
                      }

                      // Set loading state
                      setState(() {
                        isLoading = true;
                      });

                      // Create new chat
                      final chatService = ref.read(chatServiceProvider);
                      try {
                        final newChat = await chatService.createChat(chatName);

                        // Close dialog first
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }

                        if (newChat != null && context.mounted) {
                          // Navigate to the chat screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(chat: newChat),
                            ),
                          );
                        } else if (context.mounted) {
                          // Show error if chat creation failed
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'خطا در ایجاد گفتگو. لطفا دوباره تلاش کنید.'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        // Reset loading state
                        if (dialogContext.mounted) {
                          setState(() {
                            isLoading = false;
                          });

                          // Show error in the dialog context
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('خطا در ایجاد گفتگو: $e'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } else if (context.mounted) {
                          // Show error in the parent context if dialog is closed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطا در ایجاد گفتگو: $e'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('ایجاد'),
            ),
          ],
        );
      }),
    );
  }

  // Show exit confirmation dialog
  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'خروج از برنامه',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'آیا از خروج از برنامه مطمئن هستید؟',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Add rating button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                MyketUtils.openRatingPage();
                // Mark as rated in the service
                ref.read(myketRatingServiceProvider).markAsRated();
              },
              icon: const Icon(Icons.star, color: Colors.amber),
              label: const Text('نظر و امتیاز دهید'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text(
              'خیر',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Exit the app
              SystemNavigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'بله',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
