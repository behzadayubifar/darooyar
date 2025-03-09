import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/subscription_plan.dart';
import '../providers/subscription_provider.dart';
import '../../../core/utils/number_formatter.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    AppLogger.d('SubscriptionScreen initialized');
    _tabController =
        TabController(length: SubscriptionPlan.allPlans.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    AppLogger.d('SubscriptionScreen disposed');
    super.dispose();
  }

  Future<void> _purchasePlan(
      BuildContext context, SubscriptionPlan plan) async {
    final authState = ref.read(authStateProvider);

    if (!authState.hasValue || authState.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا ابتدا وارد شوید')),
      );
      return;
    }

    final user = authState.value!;

    if (user.credit < plan.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اعتبار شما برای خرید این پلن کافی نیست')),
      );
      return;
    }

    try {
      final success =
          await ref.read(purchaseStateProvider.notifier).purchasePlan(plan.id);

      if (success && mounted) {
        setState(() {
          _showSuccess = true;
        });

        // Mostrar animación de éxito durante unos segundos y luego volver al estado normal
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSuccess = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseStateProvider);
    final isLoading = purchaseState is AsyncLoading<void>;
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final currentUserCredit = currentUser?.credit ?? 0.0;

    // Si estamos en estado de éxito, mostrar una animación de éxito
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
          // Información sobre el crédito actual
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
                        child: Text(
                          NumberFormatter.formatPriceInThousands(
                              currentUserCredit.toStringAsFixed(0)),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navegar a la pantalla de recarga de crédito
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

          // Tabs para los planes
          TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            indicatorColor: _getPlanColor(
                SubscriptionPlan.allPlans[_tabController.index].id, context),
            labelColor: _getPlanColor(
                SubscriptionPlan.allPlans[_tabController.index].id, context),
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            tabs: SubscriptionPlan.allPlans
                .map((plan) => Tab(
                      child: Text(
                        plan.name,
                      ),
                    ))
                .toList(),
          ),

          // Contenido de los planes
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: SubscriptionPlan.allPlans.map((plan) {
                return _buildPlanCard(
                    context, plan, isLoading, currentUserCredit);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan,
      bool isLoading, double userCredit) {
    final bool canAfford = userCredit >= plan.price;

    // Obtener el color y el icono basándose en el ID del plan
    final Color planColor = _getPlanColor(plan.id, context);
    final IconData planIcon = _getPlanIcon(plan.id);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Encabezado del plan con fondo de gradiente y animación de elevación
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
                // Animación sutil de elevación
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
                // Título del plan y badge de "más popular" si es el plan cefixime
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (plan.id == 'cefixime')
                      Positioned(
                        top: -15,
                        left: -70,
                        child: Transform.rotate(
                          angle: -0.2, // Ángulo de rotación en radianes
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.shade700.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'محبوب‌ترین',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    NumberFormatter.formatPriceInThousands(
                        plan.price.toStringAsFixed(0)),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Características del plan - فضای بیشتر برای ویژگی‌های کامل
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicador de desplazamiento
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Nuevo diseño mejorado para características
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            planColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: planColor.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: planColor.withOpacity(0.07),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabecera con contador de características
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: planColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 14),
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.list_alt_rounded,
                                          color: planColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'ویژگی‌های این پلن',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: planColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${plan.features.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: planColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  planColor.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),

                          // Sección de características clave
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                Icon(Icons.stars_rounded,
                                    color: planColor, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'نکات کلیدی:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildKeyPoint(context, plan.getTimeInfo(),
                              Icons.timer_outlined, planColor),
                          _buildKeyPoint(context, plan.getRetentionInfo(),
                              Icons.history, planColor),
                          _buildKeyPoint(context, plan.getPrescriptionInfo(),
                              Icons.description_outlined, planColor),

                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  planColor.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),

                          // Lista de características
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                itemCount: plan.features.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _buildFeatureItem(
                                      context, plan.features[index], planColor,
                                      index: index);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botón de compra
          SizedBox(
            width: double.infinity,
            height: 56,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: canAfford && !isLoading
                    ? [
                        BoxShadow(
                          color: planColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: canAfford && !isLoading
                    ? () => _purchasePlan(context, plan)
                    : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  backgroundColor: planColor,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            canAfford ? 'خرید اشتراک' : 'اعتبار ناکافی',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (canAfford) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.shopping_cart_outlined, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nuevo método para crear distintivos de características clave
  Widget _buildKeyFeatureBadge(
      BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nuevo método para construir cada item de característica de manera más compacta y atractiva
  Widget _buildFeatureItem(
      BuildContext context, String feature, Color planColor,
      {int? index}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: planColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: planColor.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: planColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono de verificación con estilo mejorado
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: planColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.check,
                  color: planColor,
                  size: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  softWrap: true,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanColor(String planId, BuildContext context) {
    switch (planId) {
      case 'cephalexin':
        // سبز مایل به فیروزه‌ای - برای پلن پایه و اقتصادی
        // سبز نشان‌دهنده تازگی، آرامش و شروع است، مناسب برای مرحله آشنایی
        return Color(0xFF26A69A);
      case 'cefuroxime':
        // آبی - برای پلن متوسط
        // آبی حس اعتماد، امنیت و ثبات را القا می‌کند
        return Color(0xFF5C6BC0);
      case 'cefixime':
        // بنفش متمایل به طلایی - برای پلن پیشرفته
        // بنفش و طلایی حس لوکس بودن، قدرت و پرستیژ را منتقل می‌کند
        return Color(0xFF7E57C2);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getPlanIcon(String planId) {
    switch (planId) {
      case 'cephalexin':
        return Icons.medication_outlined;
      case 'cefuroxime':
        return Icons.medical_services_outlined;
      case 'cefixime':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.medication_outlined;
    }
  }

  Widget _buildKeyPoint(
      BuildContext context, String info, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                info,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
