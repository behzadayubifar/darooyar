import 'package:flutter/material.dart';
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
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/number_formatter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  int _currentTabIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final currentPlanAsync = ref.watch(currentPlanProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatListScreen(),
              ),
            ).then((_) {
              setState(() {
                _currentIndex = 0;
              });
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
                  // Show a message instead of navigating to subscription screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('این قابلیت به زودی اضافه خواهد شد'),
                      duration: Duration(seconds: 2),
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
                Expanded(
                  child: Text(
                    'اشتراک فعال: ${plan.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: const Text('تغییر'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildUsageCard(
                    title: 'زمان',
                    icon: Icons.access_time,
                    color: Colors.blue,
                    percent: plan.hasTimeLimit ? timeUsed : 0,
                    value: plan.hasTimeLimit ? '$remainingDays روز' : 'نامحدود',
                    showProgress: plan.hasTimeLimit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUsageCard(
                    title: 'نسخه‌ها',
                    icon: Icons.description,
                    color: Colors.green,
                    percent: prescriptionsUsed,
                    value: '$remainingUses از ${plan.prescriptionCount}',
                    showProgress: true,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  flex: 2,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 12),
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
            const Text(
              'ویژگی‌های اشتراک شما',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
          const Text(
            'دسترسی سریع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(),
                    ),
                  );
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
                icon: Icons.settings,
                label: 'تنظیمات',
                color: Colors.teal,
                onTap: () {
                  final user = ref.read(authStateProvider).valueOrNull;
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
              color: Colors.grey[800],
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
                      percent: 0.7,
                      center: const Text(
                        "70%",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14.0),
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
                      percent: 0.4,
                      center: const Text(
                        "40%",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14.0),
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
                      LinearPercentIndicator(
                        lineHeight: 14.0,
                        percent: 0.6,
                        center: const Text(
                          "60%",
                          style: TextStyle(fontSize: 12.0, color: Colors.white),
                        ),
                        leading: const Text("شنبه"),
                        trailing: const Text("۶ گفتگو"),
                        progressColor: Colors.blue,
                        barRadius: const Radius.circular(7),
                      ),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        lineHeight: 14.0,
                        percent: 0.3,
                        center: const Text(
                          "30%",
                          style: TextStyle(fontSize: 12.0, color: Colors.white),
                        ),
                        leading: const Text("یکشنبه"),
                        trailing: const Text("۳ گفتگو"),
                        progressColor: Colors.blue,
                        barRadius: const Radius.circular(7),
                      ),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        lineHeight: 14.0,
                        percent: 0.9,
                        center: const Text(
                          "90%",
                          style: TextStyle(fontSize: 12.0, color: Colors.white),
                        ),
                        leading: const Text("دوشنبه"),
                        trailing: const Text("۹ گفتگو"),
                        progressColor: Colors.blue,
                        barRadius: const Radius.circular(7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatListScreen(),
              ),
            );
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ایجاد گفتگوی جدید'),
        content: TextField(
          controller: chatNameController,
          decoration: const InputDecoration(
            labelText: 'نام گفتگو',
            hintText: 'نام گفتگوی جدید را وارد کنید',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              final chatName = chatNameController.text.trim();
              if (chatName.isEmpty) {
                return;
              }

              Navigator.pop(context);

              // Create and navigate to new chat
              final chatService = ref.read(chatServiceProvider);
              try {
                final newChat = await chatService.createChat(chatName);
                if (newChat != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chat: newChat),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطا در ایجاد گفتگو: $e'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('ایجاد'),
          ),
        ],
      ),
    );
  }
}
