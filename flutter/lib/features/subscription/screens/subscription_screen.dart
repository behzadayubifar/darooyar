import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/plan.dart';
import '../providers/subscription_providers.dart';
import '../providers/subscription_provider.dart' as provider;
import '../../../core/utils/number_formatter.dart';
import '../screens/subscription_success_screen.dart';

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

      final subscription =
          await subscriptionService.purchasePlan(token, plan.id);

      if (mounted) {
        // Navigate to success screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SubscriptionSuccessScreen(
              plan: plan,
              onContinue: () {
                // Pop the success screen and the subscription screen
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                // Refresh user data to update credit and subscription info
                ref.read(authStateProvider.notifier).refreshUser();
              },
            ),
          ),
        );
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
    // دریافت اعتبار کاربر از authStateProvider
    final authState = ref.watch(authStateProvider);
    final currentUserCredit = authState.valueOrNull?.credit ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('خرید اشتراک'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // پس‌زمینه زیبا با گرادیان و الگوی نقطه‌ای
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: DotPatternPainter(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ),
              ),
            ),
          ),

          Column(
            children: [
              // نمایش اعتبار کاربر
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'اعتبار شما:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${NumberFormatter.formatPriceInThousands(currentUserCredit)} تومان',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // لیست پلن‌ها
              Expanded(
                child: ref.watch(plansProvider).when(
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
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    height: 8,
                                    width: _currentPage == index ? 24 : 8,
                                    decoration: BoxDecoration(
                                      color: _currentPage == index
                                          ? _getPlanColor(plans[index].planType,
                                              context, plans[index])
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
                                physics: const BouncingScrollPhysics(),
                                padEnds: true,
                                pageSnapping: true,
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
        ],
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context, Plan plan, bool isLoading, double userCredit) {
    final bool canAfford = userCredit >= plan.price;

    // Check if user has an active subscription
    final currentPlanAsync = ref.watch(provider.currentPlanProvider);
    final bool hasActivePlan = currentPlanAsync.maybeWhen(
      data: (plan) => plan != null,
      orElse: () => false,
    );

    // Get color and icon based on plan type
    final Color planColor = _getPlanColor(plan.planType, context, plan);
    final IconData planIcon = _getPlanIcon(plan.planType, plan);

    // تعریف رنگ‌های ثانویه برای گرادیان‌های زیباتر
    final Color secondaryColor = plan.planType == 'both'
        ? const Color(0xFF66BB6A) // سبز روشن‌تر برای پلن پایه
        : (plan.price >= 300000
            ? const Color(0xFFBA68C8) // بنفش روشن‌تر برای پلن پیشرفته
            : const Color(0xFF42A5F5)); // آبی روشن‌تر برای پلن متوسط

    // تعیین نام پلن برای نمایش عناصر مناسب
    final String planName = _getPlanName(plan);

    // استفاده از RepaintBoundary برای بهبود عملکرد رندرینگ
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            // Plan header with enhanced gradient background and elevation animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    planColor.withOpacity(0.8),
                    secondaryColor.withOpacity(0.9),
                    planColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: planColor.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // پترن پس‌زمینه متناسب با نوع پلن
                  Positioned.fill(
                    child: _buildPlanPattern(planName),
                  ),
                  Column(
                    children: [
                      // Enhanced elevation animation - با استفاده از key برای جلوگیری از خطا هنگام جابجایی
                      TweenAnimationBuilder<double>(
                        key: ValueKey('icon_animation_${plan.id}'),
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, -6 * value),
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // افکت درخشش پشت آیکون
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              // آیکون اصلی
                              Icon(
                                planIcon,
                                size: 45,
                                color: Colors.white,
                              ),
                              // نشانگر ویژگی خاص پلن
                              if (plan.title == 'سفکسیم' ||
                                  (plan.planType == 'usage_based' &&
                                      plan.price >= 300000)) // پلن پیشرفته
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Plan title with animation
                      TweenAnimationBuilder<double>(
                        key: ValueKey('title_animation_${plan.id}'),
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(15 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              plan.title,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            // نشانگر پلن پیشرفته
                            if (plan.title == 'سفکسیم' ||
                                (plan.planType == 'usage_based' &&
                                    plan.price >= 300000))
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ویژه',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Plan price with animation
                      TweenAnimationBuilder<double>(
                        key: ValueKey('price_animation_${plan.id}'),
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(-15 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                _formatPriceInThousands(plan.price),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
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
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Plan details with enhanced design
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(28)),
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
                    // Plan description with animation - با استفاده از key برای جلوگیری از خطا هنگام جابجایی
                    TweenAnimationBuilder<double>(
                      key: ValueKey('desc_animation_${plan.id}'),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value.clamp(
                              0.0, 1.0), // اطمینان از محدوده صحیح opacity
                          child: child,
                        );
                      },
                      child: Text(
                        plan.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Plan features with staggered animation - استفاده از LimitedBox برای جلوگیری از overflow
                    Expanded(
                      child: LimitedBox(
                        maxHeight:
                            300, // محدود کردن ارتفاع برای جلوگیری از overflow
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Duration
                              _buildFeatureItemAnimated(
                                context,
                                Icons.access_time,
                                plan.formattedDuration,
                                planColor,
                                0,
                                plan.id,
                              ),
                              const SizedBox(height: 16),

                              // Uses
                              _buildFeatureItemAnimated(
                                context,
                                Icons.format_list_numbered,
                                plan.formattedUses,
                                planColor,
                                1,
                                plan.id,
                              ),
                              const SizedBox(height: 16),

                              // Plan type
                              _buildFeatureItemAnimated(
                                context,
                                Icons.category,
                                plan.isTimeBased && plan.isUsageBased
                                    ? 'محدودیت زمانی و تعداد استفاده'
                                    : plan.isTimeBased
                                        ? 'محدودیت زمانی'
                                        : 'محدودیت تعداد استفاده',
                                planColor,
                                2,
                                plan.id,
                              ),

                              // ویژگی‌های اضافی برای پلن‌های خاص
                              if (plan.title == 'سفکسیم' ||
                                  (plan.planType == 'usage_based' &&
                                      plan.price >= 300000)) ...[
                                const SizedBox(height: 16),
                                _buildFeatureItemAnimated(
                                  context,
                                  Icons.star,
                                  'دسترسی به تمام امکانات ویژه',
                                  planColor,
                                  3,
                                  plan.id,
                                ),
                              ],

                              if (plan.title == 'سفوروکسیم' ||
                                  plan.title == 'سفکسیم' ||
                                  (plan.planType == 'usage_based' &&
                                      plan.price >= 135000)) ...[
                                const SizedBox(height: 16),
                                _buildFeatureItemAnimated(
                                  context,
                                  Icons.history,
                                  'نگهداری تاریخچه نسخه‌ها',
                                  planColor,
                                  4,
                                  plan.id,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Purchase button with enhanced design
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canAfford && !isLoading && !hasActivePlan
                            ? () => _purchasePlan(context, plan)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: planColor,
                          foregroundColor: Colors.white,
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
                            : hasActivePlan
                                ? const Text('شما اشتراک فعال دارید')
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
      ),
    );
  }

  // ساخت پترن پس‌زمینه متناسب با نوع پلن
  Widget _buildPlanPattern(String planName) {
    switch (planName) {
      case 'سفالکسین': // پلن پایه
        return CustomPaint(
          painter: CirclePatternPainter(
            color: Colors.white.withOpacity(0.1),
          ),
        );
      case 'سفوروکسیم': // پلن متوسط
        return CustomPaint(
          painter: WavePatternPainter(
            color: Colors.white.withOpacity(0.1),
          ),
        );
      case 'سفکسیم': // پلن پیشرفته
        return CustomPaint(
          painter: DiamondPatternPainter(
            color: Colors.white.withOpacity(0.1),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // تشخیص نام پلن بر اساس ویژگی‌های آن
  String _getPlanName(Plan plan) {
    // استفاده مستقیم از عنوان پلن اگر با نام‌های مورد نظر ما مطابقت داشته باشد
    if (plan.title == 'سفالکسین' ||
        plan.title == 'سفوروکسیم' ||
        plan.title == 'سفکسیم') {
      return plan.title;
    }

    // در غیر این صورت بر اساس ویژگی‌ها تشخیص می‌دهیم
    if (plan.planType == 'both') {
      return 'سفالکسین'; // پلن پایه
    } else if (plan.price >= 300000) {
      return 'سفکسیم'; // پلن پیشرفته
    } else {
      return 'سفوروکسیم'; // پلن متوسط
    }
  }

  // ساخت آیتم ویژگی با انیمیشن
  Widget _buildFeatureItemAnimated(
    BuildContext context,
    IconData icon,
    String text,
    Color planColor,
    int index,
    String planId,
  ) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('feature_${index}_${planId}'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: planColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: planColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: planColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlanColor(String planType, BuildContext context,
      [Plan? specificPlan]) {
    // رنگ‌بندی بر اساس روانشناسی رنگ‌ها
    // سفالکسین (پلن پایه): رنگ سبز - نشانه رشد، تازگی و مقرون به صرفه بودن
    // سفوروکسیم (پلن متوسط): رنگ آبی - نشانه اعتماد، امنیت و ثبات
    // سفکسیم (پلن پیشرفته): رنگ بنفش - نشانه لوکس بودن، خلاقیت و ارزش بالا

    // اگر پلن مشخصی ارسال شده باشد، از آن استفاده می‌کنیم
    if (specificPlan != null) {
      // پلن پایه (سفالکسین)
      if (specificPlan.planType == 'both') {
        return const Color(0xFF4CAF50); // سبز زنده برای پلن پایه
      }

      // پلن پیشرفته (سفکسیم)
      if (specificPlan.planType == 'usage_based' &&
          specificPlan.price >= 300000) {
        return const Color(0xFF9C27B0); // بنفش برای پلن پیشرفته
      }

      // پلن متوسط (سفوروکسیم)
      if (specificPlan.planType == 'usage_based') {
        return const Color(0xFF1976D2); // آبی برای پلن متوسط
      }
    }

    // بررسی نوع پلن و قیمت آن برای تعیین رنگ مناسب
    final plansData = ref.read(plansProvider);

    if (plansData.hasValue && plansData.value != null) {
      final plans = plansData.value!;

      // پلن پایه (سفالکسین)
      if (planType == 'both') {
        return const Color(0xFF4CAF50); // سبز زنده برای پلن پایه
      }

      // پلن‌های استفاده‌محور (سفوروکسیم و سفکسیم)
      if (planType == 'usage_based' && plans.length > 1) {
        // پیدا کردن پلن فعلی
        final currentPlan = plans.firstWhere(
          (p) => p.planType == planType,
          orElse: () => plans.first,
        );

        // پلن پیشرفته (سفکسیم) - گران‌ترین پلن
        if (currentPlan.price >= 300000) {
          return const Color(0xFF9C27B0); // بنفش برای پلن پیشرفته
        }

        // پلن متوسط (سفوروکسیم)
        return const Color(0xFF1976D2); // آبی برای پلن متوسط
      }
    }

    // رنگ‌های پیش‌فرض بر اساس نوع پلن
    switch (planType) {
      case 'time_based':
        return const Color(0xFF4CAF50); // سبز
      case 'usage_based':
        return const Color(0xFF1976D2); // آبی
      case 'both':
        return const Color(0xFF4CAF50); // سبز
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getPlanIcon(String planType, [Plan? specificPlan]) {
    // آیکون‌های متناسب با هر پلن

    // اگر پلن مشخصی ارسال شده باشد، از آن استفاده می‌کنیم
    if (specificPlan != null) {
      // پلن پایه (سفالکسین)
      if (specificPlan.planType == 'both') {
        return Icons.medication_rounded; // آیکون دارو برای پلن پایه (سفالکسین)
      }

      // پلن پیشرفته (سفکسیم)
      if (specificPlan.planType == 'usage_based' &&
          specificPlan.price >= 300000) {
        return Icons.workspace_premium; // آیکون پریمیوم برای پلن پیشرفته
      }

      // پلن متوسط (سفوروکسیم)
      if (specificPlan.planType == 'usage_based') {
        return Icons.health_and_safety; // آیکون سلامت برای پلن متوسط
      }
    }

    final plansData = ref.read(plansProvider);

    if (plansData.hasValue && plansData.value != null) {
      final plans = plansData.value!;

      // پلن پایه (سفالکسین)
      if (planType == 'both') {
        return Icons.medication_rounded; // آیکون دارو برای پلن پایه (سفالکسین)
      }

      // پلن‌های استفاده‌محور (سفوروکسیم و سفکسیم)
      if (planType == 'usage_based' && plans.length > 1) {
        // پیدا کردن پلن فعلی
        final currentPlan = plans.firstWhere(
          (p) => p.planType == planType,
          orElse: () => plans.first,
        );

        // پلن پیشرفته (سفکسیم) - گران‌ترین پلن
        if (currentPlan.price >= 300000) {
          return Icons.workspace_premium; // آیکون پریمیوم برای پلن پیشرفته
        }

        // پلن متوسط (سفوروکسیم)
        return Icons.health_and_safety; // آیکون سلامت برای پلن متوسط
      }
    }

    // آیکون‌های پیش‌فرض بر اساس نوع پلن
    switch (planType) {
      case 'time_based':
        return Icons.medication_rounded; // آیکون دارو
      case 'usage_based':
        return Icons.health_and_safety; // آیکون سلامت
      case 'both':
        return Icons.medication_rounded; // آیکون دارو
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

// کلاس برای ایجاد الگوی نقطه‌ای در پس‌زمینه
class DotPatternPainter extends CustomPainter {
  final Color color;

  DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    final spacing = 20.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// پترن دایره‌ای برای پلن پایه
class CirclePatternPainter extends CustomPainter {
  final Color color;

  CirclePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double maxRadius = size.width * 0.4;
    final center = Offset(size.width * 0.5, size.height * 0.5);

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * i / 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// پترن موجی برای پلن متوسط
class WavePatternPainter extends CustomPainter {
  final Color color;

  WavePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final waveHeight = height * 0.1;
    final waveWidth = width * 0.2;

    for (int i = 0; i < 3; i++) {
      final startY = height * 0.3 + (i * height * 0.2);
      path.moveTo(0, startY);

      for (double x = 0; x < width; x += waveWidth) {
        path.quadraticBezierTo(
          x + (waveWidth / 2),
          startY + waveHeight,
          x + waveWidth,
          startY,
        );
      }

      canvas.drawPath(path, paint);
      path.reset();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// پترن الماسی برای پلن پیشرفته
class DiamondPatternPainter extends CustomPainter {
  final Color color;

  DiamondPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double diamondSize = size.width * 0.15;
    final double spacing = diamondSize * 1.5;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final path = Path();
        path.moveTo(x, y + diamondSize / 2);
        path.lineTo(x + diamondSize / 2, y);
        path.lineTo(x + diamondSize, y + diamondSize / 2);
        path.lineTo(x + diamondSize / 2, y + diamondSize);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
