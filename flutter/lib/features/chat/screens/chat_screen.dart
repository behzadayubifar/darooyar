import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async'; // Add this import for Timer
import 'dart:convert'; // Add this import for json encoding/decoding
import 'dart:io'; // Add this import for File
import 'package:http/http.dart' as http; // Add this import for HTTP requests
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../prescription/presentation/widgets/expandable_panel.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/message_providers.dart';
import 'dart:math';
import '../widgets/chat_image_widget.dart';
import '../widgets/message_bubble.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../auth/providers/auth_providers.dart';
import 'image_viewer_screen.dart';
import '../../../utils/myket_utils.dart';
import '../../../main.dart'; // Import main.dart for myketRatingServiceProvider

// Use the CollapseAllPanelsNotification from expandable_panel.dart

class ChatScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatScreen({Key? key, required this.chat}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

// Add TickerProviderStateMixin to support animation controllers
class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  String? _lastProcessedMessageId; // Track the last message ID we processed
  DateTime?
      _lastSubscriptionRefresh; // Track when we last refreshed the subscription
  int _remainingPrescriptions =
      0; // متغیر محلی برای نگهداری تعداد نسخه‌های باقیمانده
  DateTime?
      _lastDirectApiUpdate; // Track the last time we got a direct API update
  bool _ignoreProviderUpdates =
      false; // Flag to ignore provider updates temporarily
  bool _isPrescriptionProcessing = false; // متغیر برای کنترل وضعیت پردازش نسخه
  bool _isRefreshing = false; // Track when refresh is in progress

  // New variables for prescription submission flow
  bool _prescriptionModeActive = false;
  String _selectedPrescriptionType = '';
  // Add a new variable to control the input field visibility
  bool _showInputField = false;
  // Animation controller for input field expansion
  late AnimationController _inputExpandController;
  late Animation<double> _inputWidthAnimation;

  // متغیر جدید برای نگهداری مسیر تصویر انتخاب شده
  String? _selectedImagePath;
  // متغیر برای نشان دادن وضعیت انتخاب تصویر
  bool _hasSelectedImage = false;

  // Prescription submission types
  final List<Map<String, dynamic>> _prescriptionTypes = [
    {
      'id': 'text',
      'title': 'نسخه متنی',
      'icon': Icons.text_fields,
      'color': Colors.blue,
      'description': 'ارسال نسخه به صورت متنی',
      'placeholder': 'نسخه: '
    },
    {
      'id': 'image',
      'title': 'انتخاب از گالری',
      'icon': Icons.photo_library,
      'color': Colors.green,
      'description': 'ارسال تصویر نسخه از گالری',
      'placeholder': ''
    },
    {
      'id': 'camera',
      'title': 'عکس با دوربین',
      'icon': Icons.camera_alt,
      'color': Colors.purple,
      'description': 'گرفتن عکس از نسخه با دوربین',
      'placeholder': ''
    },
  ];

  // Define a list of colors and icons for the panels
  final List<Map<String, dynamic>> sectionStyles = [
    {'color': Colors.blue.shade700, 'icon': Icons.info_outline},
    {'color': Colors.red.shade700, 'icon': Icons.warning_outlined},
    {'color': Colors.orange.shade700, 'icon': Icons.healing_outlined},
    {'color': Colors.green.shade700, 'icon': Icons.access_time_outlined},
    {'color': Colors.purple.shade700, 'icon': Icons.restaurant_outlined},
    {
      'color': Colors.indigo.shade700,
      'icon': Icons.format_list_numbered_outlined
    },
    {'color': Colors.cyan.shade700, 'icon': Icons.health_and_safety_outlined},
    {'color': Colors.teal.shade700, 'icon': Icons.check_circle_outline},
    {'color': Colors.amber.shade700, 'icon': Icons.lightbulb_outline},
    {'color': Colors.pink.shade700, 'icon': Icons.favorite_outline},
    {'color': Colors.deepPurple.shade700, 'icon': Icons.psychology_outlined},
    {'color': Colors.brown.shade700, 'icon': Icons.science_outlined},
  ];

  // Define specific styles for known section types
  final Map<String, Map<String, dynamic>> specificStyles = {
    'تشخیص احتمالی': {
      'color': Colors.blue.shade700,
      'icon': Icons.info_outline
    },
    '۱. تشخیص احتمالی': {
      'color': Colors.blue.shade700,
      'icon': Icons.info_outline
    },
    '1. تشخیص احتمالی': {
      'color': Colors.blue.shade700,
      'icon': Icons.info_outline
    },
    '1. پیشگیری یا درمان کمبود': {
      'color': Colors.green.shade700,
      'icon': Icons.healing_outlined
    },
    'پیشگیری یا درمان کمبود': {
      'color': Colors.green.shade700,
      'icon': Icons.healing_outlined
    },
    'تشخیص': {'color': Colors.blue.shade700, 'icon': Icons.info_outline},
    'تداخلات': {'color': Colors.red.shade700, 'icon': Icons.warning_outlined},
    'تداخلات مهم': {
      'color': Colors.red.shade700,
      'icon': Icons.warning_outlined
    },
    'تداخلات دارویی': {
      'color': Colors.red.shade700,
      'icon': Icons.warning_outlined
    },
    '۲. تداخلات مهم': {
      'color': Colors.red.shade700,
      'icon': Icons.warning_outlined
    },
    '2. تداخلات مهم': {
      'color': Colors.red.shade700,
      'icon': Icons.warning_outlined
    },
    'عوارض': {'color': Colors.orange.shade700, 'icon': Icons.healing_outlined},
    'عوارض مهم': {
      'color': Colors.orange.shade700,
      'icon': Icons.healing_outlined
    },
    'عوارض شایع': {
      'color': Colors.orange.shade700,
      'icon': Icons.healing_outlined
    },
    'عوارض جانبی': {
      'color': Colors.orange.shade700,
      'icon': Icons.healing_outlined
    },
    '۳. عوارض مهم': {
      'color': Colors.orange.shade700,
      'icon': Icons.healing_outlined
    },
    'زمان مصرف': {
      'color': Colors.green.shade700,
      'icon': Icons.access_time_outlined
    },
    '۴. زمان مصرف': {
      'color': Colors.green.shade700,
      'icon': Icons.access_time_outlined
    },
    'نحوه مصرف': {
      'color': Colors.purple.shade700,
      'icon': Icons.restaurant_outlined
    },
    '۵. نحوه مصرف': {
      'color': Colors.purple.shade700,
      'icon': Icons.restaurant_outlined
    },
    'تعداد مصرف': {
      'color': Colors.indigo.shade700,
      'icon': Icons.format_list_numbered_outlined
    },
    'دوز مصرف': {
      'color': Colors.indigo.shade700,
      'icon': Icons.format_list_numbered_outlined
    },
    '۶. تعداد مصرف': {
      'color': Colors.indigo.shade700,
      'icon': Icons.format_list_numbered_outlined
    },
    'مدیریت عارضه': {
      'color': Colors.cyan.shade700,
      'icon': Icons.health_and_safety_outlined
    },
    '۷. مدیریت عارضه': {
      'color': Colors.cyan.shade700,
      'icon': Icons.health_and_safety_outlined
    },
    'خلاصه': {'color': Colors.teal.shade700, 'icon': Icons.summarize_outlined},
    'نکات مهم': {
      'color': Colors.amber.shade700,
      'icon': Icons.lightbulb_outline
    },
    'توصیه‌ها': {
      'color': Colors.amber.shade700,
      'icon': Icons.lightbulb_outline
    },
    'توصیه های مهم': {
      'color': Colors.amber.shade700,
      'icon': Icons.lightbulb_outline
    },
    'نتیجه گیری': {
      'color': Colors.pink.shade700,
      'icon': Icons.check_circle_outline
    },
    'نتیجه‌گیری': {
      'color': Colors.pink.shade700,
      'icon': Icons.check_circle_outline
    },
    'پاسخ داروخانه': {
      'color': Colors.deepPurple.shade700,
      'icon': Icons.local_pharmacy_outlined
    },
    'لیست داروها': {
      'color': Colors.deepPurple.shade700,
      'icon': Icons.medication_outlined
    },
    'داروهای نسخه': {
      'color': Colors.deepPurple.shade700,
      'icon': Icons.medication_outlined
    },
    'داروهای تجویز شده': {
      'color': Colors.deepPurple.shade700,
      'icon': Icons.medication_outlined
    },
    'داروها': {
      'color': Colors.deepPurple.shade700,
      'icon': Icons.medication_outlined
    },
    'کنترل فشار خون': {
      'color': Colors.red.shade700,
      'icon': Icons.favorite_outline
    },
    'فشار خون': {'color': Colors.red.shade700, 'icon': Icons.favorite_outline},
    'کنترل قند خون': {
      'color': Colors.blue.shade700,
      'icon': Icons.water_drop_outlined
    },
    'قند خون': {
      'color': Colors.blue.shade700,
      'icon': Icons.water_drop_outlined
    },
    'رژیم غذایی': {
      'color': Colors.green.shade700,
      'icon': Icons.restaurant_menu
    },
    'تغذیه': {'color': Colors.green.shade700, 'icon': Icons.restaurant_menu},
    'ورزش': {'color': Colors.orange.shade700, 'icon': Icons.directions_run},
    'فعالیت بدنی': {
      'color': Colors.orange.shade700,
      'icon': Icons.directions_run
    },
    'مراقبت‌های لازم': {
      'color': Colors.teal.shade700,
      'icon': Icons.shield_outlined
    },
    'مراقبت های لازم': {
      'color': Colors.teal.shade700,
      'icon': Icons.shield_outlined
    },
    'علائم هشدار': {
      'color': Colors.red.shade700,
      'icon': Icons.warning_amber_outlined
    },
    'علائم خطر': {
      'color': Colors.red.shade700,
      'icon': Icons.warning_amber_outlined
    },
    'پیگیری': {
      'color': Colors.indigo.shade700,
      'icon': Icons.event_available_outlined
    },
    'زمان مراجعه بعدی': {
      'color': Colors.indigo.shade700,
      'icon': Icons.event_available_outlined
    },
    'آزمایشات': {
      'color': Colors.purple.shade700,
      'icon': Icons.science_outlined
    },
    'آزمایش‌ها': {
      'color': Colors.purple.shade700,
      'icon': Icons.science_outlined
    },
    'تست‌های تشخیصی': {
      'color': Colors.purple.shade700,
      'icon': Icons.science_outlined
    },
    'عوامل خطر': {
      'color': Colors.deepOrange.shade700,
      'icon': Icons.dangerous_outlined
    },
    'مصرف با غذا': {
      'color': Colors.amber.shade700,
      'icon': Icons.restaurant_outlined
    },
    'مصرف_با_غذا': {
      'color': Colors.amber.shade700,
      'icon': Icons.restaurant_outlined
    },
  };

  // Add a new state variable to track if any panel is expanded
  bool _isAnyPanelExpanded = false;

  // Add a set to track expanded panel IDs
  final Set<String> _expandedPanelIds = {};

  // Add a state variable for tracking if the subscription banner is collapsed
  bool _isSubscriptionBannerCollapsed = true;

  @override
  void initState() {
    super.initState();

    // اطمینان از اینکه وضعیت پردازش نسخه در ابتدا false است
    _isPrescriptionProcessing = false;

    // Initialize animation controller for input field expansion
    _inputExpandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _inputWidthAnimation = Tween<double>(
      begin: 2, // Start with a very narrow width
      end: 1, // End with full width
    ).animate(CurvedAnimation(
      parent: _inputExpandController,
      curve: Curves.easeOutCubic,
    ));

    // DEBUGGING: Check for any existing Timers in the app that might be causing refreshes
    AppLogger.i(
        'DEBUGGING: Checking for any rogue timers or periodic refreshes');

    // تنظیم مقدار اولیه تعداد نسخه‌های باقیمانده
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // اضافه کردن یک listener برای provider اشتراک
      ref.listenManual(currentPlanProvider, (previous, next) {
        // Skip updates if we're ignoring provider updates
        if (_ignoreProviderUpdates) {
          AppLogger.i(
              'Ignoring provider update due to _ignoreProviderUpdates flag');
          return;
        }

        next.whenData((plan) {
          if (plan != null && mounted) {
            // Only update if we haven't received a direct API value recently
            if (_lastDirectApiUpdate == null ||
                DateTime.now().difference(_lastDirectApiUpdate!).inSeconds >
                    5) {
              setState(() {
                _remainingPrescriptions = plan.prescriptionCount;
              });
              AppLogger.i(
                  'Subscription plan listener updated: ${plan.prescriptionCount}');
            } else {
              AppLogger.i(
                  'Ignoring provider update as we have a recent direct API value');
            }
          }
        });
      });

      // First try to get data from direct API - بدون نمایش پیام برای بارگذاری اولیه
      _forceRefreshSubscriptionWithAPI(showSnackBar: false);

      // Then try provider as fallback
      ref.read(currentPlanProvider).whenData((plan) {
        if (plan != null && mounted && !_ignoreProviderUpdates) {
          // Only update if we haven't received a direct API value yet
          if (_lastDirectApiUpdate == null) {
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  _remainingPrescriptions = plan.prescriptionCount;
                });
                AppLogger.i(
                    'Initial remaining prescriptions: ${plan.prescriptionCount}');
              }
            });
          }
        }
      });
    });

    // اسکرول تأخیری به پایین صفحه
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ابتدا 1 ثانیه صبر کنید
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _scrollController.hasClients) {
          // سپس به آرامی در طی 2 ثانیه به پایین اسکرول کنید
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
          );
        }
      });

      // Refresh subscription data only once when the screen is first shown - بدون نمایش پیام
      if (mounted) {
        AppLogger.i('Initial refresh of subscription plan');
        _forceRefreshSubscriptionWithAPI(showSnackBar: false);

        // We're removing the periodic timer to avoid constant API calls
        // The subscription will only be refreshed after specific events like prescription responses
      }
    });
  }

  // Helper method to update UI with the value from API
  void _updateUIWithAPIValue(int value) {
    // Only update if the value has changed
    if (_remainingPrescriptions != value) {
      // Use setState to update the UI
      setState(() {
        _remainingPrescriptions = value;
      });

      // Force rebuild after a short delay to ensure the UI is updated
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });

      // Log the update
      AppLogger.i('UI updated with value from API: $value');
    }
  }

  // Helper method to force refresh subscription data using direct API call
  Future<void> _forceRefreshSubscriptionWithAPI(
      {bool showSnackBar = false}) async {
    // Don't refresh if we've refreshed recently (within the last 10 seconds)
    final now = DateTime.now();
    if (_lastSubscriptionRefresh != null &&
        now.difference(_lastSubscriptionRefresh!).inSeconds < 10) {
      AppLogger.i(
          'Skipping subscription refresh - last refresh was too recent');
      // Reset the refreshing flag if we're skipping
      if (_isRefreshing) {
        setState(() {
          _isRefreshing = false;
        });
      }
      return;
    }

    // Update the last refresh timestamp
    _lastSubscriptionRefresh = now;

    // Add a specific log message to track this API call
    AppLogger.i(
        '-----> Direct API refresh of subscription plan from ChatScreen');

    try {
      // Set flag to ignore provider updates
      _ignoreProviderUpdates = true;

      // Ensure the flag is reset after a timeout even if there's an error
      Future.delayed(const Duration(seconds: 5), () {
        if (_ignoreProviderUpdates) {
          _ignoreProviderUpdates = false;
          AppLogger.i('Resumed listening to provider updates (timeout)');
        }
        // Also reset the refreshing flag after timeout
        if (_isRefreshing && mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      });

      // Get the auth token
      final authService = ref.read(authServiceProvider);
      final token = await authService.getToken();

      if (token == null) {
        AppLogger.e('No token available for subscription refresh');
        _ignoreProviderUpdates = false;
        // Reset the refreshing flag
        if (_isRefreshing && mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
        return;
      }

      // Make a direct API call to get the current subscription
      final response = await http.get(
        Uri.parse('https://darooyab.liara.run/api/subscriptions/current'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Log the raw response for debugging
        AppLogger.i('Raw API response: ${response.body}');

        // Check for remaining_uses in different possible locations in the response
        int? remainingUses;

        if (data.containsKey('remaining_uses')) {
          remainingUses = data['remaining_uses'] as int;
          AppLogger.i(
              'Found remaining_uses directly in response: $remainingUses');
        } else if (data is Map &&
            data.containsKey('plan') &&
            data.containsKey('uses_count')) {
          // If we have plan and uses_count, we can calculate remaining_uses
          final plan = data['plan'] as Map<String, dynamic>;
          final usesCount = data['uses_count'] as int;

          if (plan.containsKey('max_uses')) {
            final maxUses = plan['max_uses'] as int;
            remainingUses = maxUses - usesCount;
            AppLogger.i(
                'Calculated remaining_uses from plan.max_uses and uses_count: $remainingUses');
          }
        }

        if (remainingUses != null) {
          // Use Future.microtask to ensure we're not in the build phase
          Future.microtask(() {
            if (mounted) {
              // Update the UI with the value from the direct API call
              _updateUIWithAPIValue(remainingUses!);
              _lastDirectApiUpdate = DateTime.now();

              AppLogger.i(
                  'Direct API call updated remaining prescriptions: $remainingUses');
            }
          });

          // Resume listening to provider updates after a short delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _ignoreProviderUpdates = false;
              AppLogger.i('Resumed listening to provider updates');
              // Reset the refreshing flag
              if (_isRefreshing) {
                setState(() {
                  _isRefreshing = false;
                });
              }
            }
          });
        } else {
          AppLogger.e(
              'Could not find or calculate remaining_uses in API response');
          _ignoreProviderUpdates = false;
          // Reset the refreshing flag
          if (_isRefreshing && mounted) {
            setState(() {
              _isRefreshing = false;
            });
          }
        }
      } else {
        AppLogger.e('API error: ${response.statusCode} - ${response.body}');
        _ignoreProviderUpdates = false;
        // Reset the refreshing flag
        if (_isRefreshing && mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      AppLogger.e('Error in direct API call: $e');
      _ignoreProviderUpdates = false;
      // Reset the refreshing flag
      if (_isRefreshing && mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Helper method to force refresh subscription data
  void _forceRefreshSubscription({bool showSnackBar = false}) {
    // Force a refresh of the subscription data from the API
    _forceRefreshSubscriptionWithAPI(showSnackBar: showSnackBar);
  }

  // Helper method to directly update the remaining prescriptions count
  void _updateRemainingPrescriptions() {
    // Use the future directly to ensure we get the latest data
    ref.read(currentPlanProvider.future).then((plan) {
      if (plan != null && mounted && !_ignoreProviderUpdates) {
        // Only update if the value has changed and we're not in build phase
        if (_remainingPrescriptions != plan.prescriptionCount) {
          // Use Future.microtask to ensure we're not in the build phase
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _remainingPrescriptions = plan.prescriptionCount;
              });
              AppLogger.i(
                  'Direct update of remaining prescriptions: ${plan.prescriptionCount}');
            }
          });
        }
      }
    }).catchError((error) {
      AppLogger.e('Error updating remaining prescriptions: $error');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // We're disabling automatic refreshes in didChangeDependencies
    // to prevent frequent API calls

    // Only update the remaining prescriptions count if we're not ignoring provider updates
    // and we haven't refreshed recently
    if (!_ignoreProviderUpdates && _lastSubscriptionRefresh != null) {
      final now = DateTime.now();
      if (now.difference(_lastSubscriptionRefresh!).inSeconds > 300) {
        // Only every 5 minutes
        AppLogger.i('Updating remaining prescriptions count from provider');
        Future.microtask(() {
          if (mounted) {
            _updateRemainingPrescriptions();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputExpandController.dispose(); // Dispose the animation controller
    _ignoreProviderUpdates = false; // Reset the flag
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Method to show prescription options dialog
  void _showPrescriptionOptionsDialog() {
    // Verificar si el usuario tiene una suscripción activa
    final subscriptionState = ref.read(subscriptionProvider);
    if (!subscriptionState.hasActiveSubscription) {
      // Mostrar un mensaje y redirigir a la pantalla de suscripción
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('برای ارسال نسخه نیاز به اشتراک فعال دارید'),
          backgroundColor: AppTheme.errorColor,
          action: SnackBarAction(
            label: 'خرید اشتراک',
            onPressed: () {
              Navigator.pushNamed(context, '/subscription');
            },
          ),
        ),
      );
      return;
    }

    // Si el usuario tiene una suscripción activa, mostrar el diálogo original
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'انتخاب نوع نسخه',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'لطفاً روش ارسال نسخه خود را انتخاب کنید:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._prescriptionTypes
                          .map((type) => _buildPrescriptionTypeCard(
                                title: type['title'],
                                icon: type['icon'],
                                color: type['color'],
                                description: type['description'],
                                onTap: () {
                                  _activatePrescriptionMode(
                                      type['id'], type['placeholder']);
                                  Navigator.pop(context);
                                },
                              )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build prescription type card
  Widget _buildPrescriptionTypeCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Activate prescription mode
  void _activatePrescriptionMode(String typeId, String placeholder) {
    setState(() {
      // اگر قبلاً تصویری انتخاب شده بود، آن را پاک کنیم
      if (_hasSelectedImage) {
        _hasSelectedImage = false;
        _selectedImagePath = null;
      }

      _prescriptionModeActive = true;
      _selectedPrescriptionType = typeId;

      // Only show input field for text prescriptions, not for image/camera
      _showInputField = typeId == 'text';

      // Start the expansion animation only for text prescriptions
      if (typeId == 'text') {
        _inputExpandController.forward();
        _messageController.text = placeholder;

        // تنظیم موقعیت مکان‌نما بعد از پیشوند "نسخه: "
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: placeholder.length),
        );
      } else if (typeId == 'image') {
        _pickImageFromGallery();
      } else if (typeId == 'camera') {
        _pickImageFromCamera();
      }
    });
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _hasSelectedImage = true;
          // Hide text input field when image is selected
          _showInputField = false;
          _inputExpandController.reverse();
        });
      } else {
        // User canceled image selection, reset prescription mode
        setState(() {
          _prescriptionModeActive = false;
          _selectedPrescriptionType = '';
          _hasSelectedImage = false;
          _selectedImagePath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در انتخاب تصویر: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      setState(() {
        _prescriptionModeActive = false;
        _selectedPrescriptionType = '';
        _hasSelectedImage = false;
        _selectedImagePath = null;
      });
    }
  }

  // Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _hasSelectedImage = true;
          // Hide text input field when image is selected
          _showInputField = false;
          _inputExpandController.reverse();
        });
      } else {
        // User canceled camera, reset prescription mode
        setState(() {
          _prescriptionModeActive = false;
          _selectedPrescriptionType = '';
          _hasSelectedImage = false;
          _selectedImagePath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در گرفتن عکس: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      setState(() {
        _prescriptionModeActive = false;
        _selectedPrescriptionType = '';
        _hasSelectedImage = false;
        _selectedImagePath = null;
      });
    }
  }

  // Send image message
  Future<void> _sendImageMessage() async {
    if (_selectedImagePath == null) return;

    setState(() {
      _isPrescriptionProcessing = true;
    });

    try {
      await ref
          .read(messageListProvider(widget.chat.id).notifier)
          .sendImageMessage(_selectedImagePath!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال تصویر: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrescriptionProcessing = false;
          _prescriptionModeActive = false;
          _selectedPrescriptionType = '';
          _hasSelectedImage = false;
          _selectedImagePath = null;
        });
      }
    }
  }

  // Reset prescription mode
  void _resetPrescriptionMode() {
    // First run the collapse animation
    _inputExpandController.reverse().then((_) {
      // After animation completes, update the state
      if (mounted) {
        setState(() {
          _prescriptionModeActive = false;
          _selectedPrescriptionType = '';
          _showInputField = false;
          _messageController.clear();
        });
      }
    });
  }

  // Helper method to process tagged content
  Widget _processTaggedContent(String content) {
    // Define all the tags we want to process
    final List<Map<String, dynamic>> tagDefinitions = [
      {
        'tag': 'داروها',
        'title': 'داروها',
        'color': Colors.deepPurple.shade700,
        'icon': Icons.medication_outlined,
      },
      {
        'tag': 'تشخیص',
        'title': 'تشخیص احتمالی',
        'color': Colors.blue.shade700,
        'icon': Icons.info_outline,
      },
      {
        'tag': 'تداخلات',
        'title': 'تداخلات دارویی',
        'color': Colors.red.shade700,
        'icon': Icons.warning_outlined,
      },
      {
        'tag': 'عوارض',
        'title': 'عوارض دارویی',
        'color': Colors.orange.shade700,
        'icon': Icons.healing_outlined,
      },
      {
        'tag': 'زمان_مصرف',
        'title': 'زمان مصرف',
        'color': Colors.green.shade700,
        'icon': Icons.access_time_outlined,
      },
      {
        'tag': 'مصرف_با_غذا',
        'title': 'مصرف با غذا',
        'color': Colors.amber.shade700,
        'icon': Icons.restaurant_outlined,
      },
      {
        'tag': 'دوز_مصرف',
        'title': 'دوز مصرف',
        'color': Colors.indigo.shade700,
        'icon': Icons.format_list_numbered_outlined,
      },
      {
        'tag': 'مدیریت_عارضه',
        'title': 'مدیریت عارضه',
        'color': Colors.cyan.shade700,
        'icon': Icons.health_and_safety_outlined,
      },
    ];

    // Remove stars completely from the content
    content = content.replaceAll('***', '');
    content = content.replaceAll('**', '');
    content = content.replaceAll('*', '');
    content = content.replaceAll('✧✧✧', '');
    content = content.replaceAll('✧✧', '');
    content = content.replaceAll('✧', '');

    // Calculate the maximum width for the panel
    final double panelWidth = MediaQuery.of(context).size.width * 0.75;

    // Process the content to extract all tagged sections
    String remainingContent = content;
    List<Widget> contentWidgets = [];
    List<String> processedParagraphs = [];

    // First process <tag> format tags
    while (true) {
      int earliestTagPosition = remainingContent.length;
      Map<String, dynamic>? earliestTagDef;

      // Find the earliest tag in the remaining content
      for (var tagDef in tagDefinitions) {
        String tag = tagDef['tag'] as String;
        int tagPosition = remainingContent.indexOf('<$tag>');
        if (tagPosition != -1 && tagPosition < earliestTagPosition) {
          earliestTagPosition = tagPosition;
          earliestTagDef = tagDef;
        }
      }

      // If no more <tag> format tags found, break this loop
      if (earliestTagDef == null) {
        break;
      }

      String tag = earliestTagDef['tag'] as String;
      String openTag = '<$tag>';
      String closeTag = '</$tag>';

      // Add text before the tag
      if (earliestTagPosition > 0) {
        String beforeTagContent =
            remainingContent.substring(0, earliestTagPosition).trim();
        if (beforeTagContent.isNotEmpty) {
          processedParagraphs.add(beforeTagContent);
        }
      }

      // Extract content between tags
      int startIndex = remainingContent.indexOf(openTag) + openTag.length;
      int endIndex = remainingContent.indexOf(closeTag);

      if (startIndex < endIndex) {
        String taggedContent =
            remainingContent.substring(startIndex, endIndex).trim();

        // Log for debugging
        AppLogger.d('Found <$tag> tags in content');
        AppLogger.d('Tagged content length: ${taggedContent.length} chars');
        AppLogger.d(
            'Tagged content preview: ${taggedContent.substring(0, min(100, taggedContent.length))}...');

        // Skip empty or unhelpful content
        if (taggedContent.isNotEmpty &&
            !_isUnhelpfulContent(
                taggedContent, earliestTagDef['title'] as String)) {
          // Add expandable panel for the tagged content
          contentWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ExpandablePanel(
                title: earliestTagDef['title'] as String,
                content: taggedContent,
                color: earliestTagDef['color'] as Color,
                icon: earliestTagDef['icon'] as IconData,
                initiallyExpanded: false,
                width: panelWidth,
                id: '${earliestTagDef['title']}_${contentWidgets.length}',
                onExpansionChanged: (isExpanded, panelId) =>
                    _handlePanelExpansionChanged(isExpanded, panelId),
              ),
            ),
          );
        }

        // Update remaining content to be after the closing tag
        remainingContent =
            remainingContent.substring(endIndex + closeTag.length);
      } else {
        // If tags are malformed, just remove the opening tag and continue
        remainingContent =
            remainingContent.substring(earliestTagPosition + openTag.length);
      }
    }

    // Now process **tag** format tags in the remaining content
    // Split the content into paragraphs for easier processing
    List<String> paragraphs = remainingContent.split('\n\n');
    remainingContent = '';

    // Filter out technical or irrelevant content
    paragraphs = paragraphs.where((paragraph) {
      // Skip empty paragraphs
      if (paragraph.trim().isEmpty) return false;

      // Skip technical tags that shouldn't be shown to users
      if (paragraph.contains('Response ID') ||
          paragraph.contains('--!>') ||
          paragraph.contains('-next-') ||
          paragraph.contains('با سلام همکار گرامی')) {
        return false;
      }

      return true;
    }).toList();

    for (int i = 0; i < paragraphs.length; i++) {
      String paragraph = paragraphs[i].trim();
      bool processed = false;

      // Check if this paragraph starts with a tag format (without stars now)
      for (var tagDef in tagDefinitions) {
        String tag = tagDef['tag'] as String;

        // Check if paragraph starts with the tag
        if (paragraph.startsWith(tag) && paragraph.length > tag.length) {
          // Extract the content after the tag
          String taggedContent = paragraph.substring(tag.length).trim();

          // If the content starts with a colon, remove it
          if (taggedContent.startsWith(':')) {
            taggedContent = taggedContent.substring(1).trim();
          }

          // Skip empty or unhelpful content
          if (taggedContent.isEmpty ||
              _isUnhelpfulContent(taggedContent, tagDef['title'] as String)) {
            processed = true;
            break;
          }

          // Log for debugging
          AppLogger.d('Found $tag format in paragraph');
          AppLogger.d('Tagged content length: ${taggedContent.length} chars');
          AppLogger.d(
              'Tagged content preview: ${taggedContent.substring(0, min(100, taggedContent.length))}...');

          // Add expandable panel for the tagged content
          contentWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ExpandablePanel(
                title: tagDef['title'] as String,
                content: taggedContent,
                color: tagDef['color'] as Color,
                icon: tagDef['icon'] as IconData,
                initiallyExpanded: false,
                width: panelWidth,
                id: '${tagDef['title']}_${contentWidgets.length}',
                onExpansionChanged: _handlePanelExpansionChanged,
              ),
            ),
          );

          processed = true;
          break;
        }
      }

      // If this paragraph wasn't processed as a tag, add it to the remaining content
      if (!processed) {
        if (paragraph.isNotEmpty) {
          processedParagraphs.add(paragraph);
        }
      }
    }

    // Process remaining paragraphs into appropriate panels
    if (processedParagraphs.isNotEmpty) {
      // Group paragraphs by potential sections
      Map<String, List<String>> sections = {};
      String currentSection = 'نکات مهم';

      for (String paragraph in processedParagraphs) {
        // Skip paragraphs that contain technical information
        if (paragraph.contains('Response ID') ||
            paragraph.contains('--!>') ||
            paragraph.contains('-next-')) {
          continue;
        }

        // Skip greetings in "نکات مهم" section
        if (paragraph.contains('با سلام همکار گرامی') ||
            paragraph.contains('با سلام') ||
            paragraph.contains('سلام همکار')) {
          continue;
        }

        // Check for numbered sections (like "1. پیشگیری یا درمان کمبود...")
        final numberedSectionRegex =
            RegExp(r'^(\d+\.\s+|\d+\-\s+|[۰-۹]+\.\s+|[۰-۹]+\-\s+)(.+)$');
        final numberedMatch = numberedSectionRegex.firstMatch(paragraph);

        if (numberedMatch != null) {
          final sectionTitle = numberedMatch.group(2)!.trim();

          // If it looks like a section title (not too long, no additional content)
          if (sectionTitle.length < 50 && !sectionTitle.contains(':')) {
            currentSection = paragraph.trim();
            sections.putIfAbsent(currentSection, () => []);
            continue;
          }
        }

        // Try to identify if this paragraph is a section title
        if (paragraph.contains(':') && paragraph.split(':')[0].length < 40) {
          String potentialTitle = paragraph.split(':')[0].trim();

          // Skip technical or irrelevant titles
          if (potentialTitle.contains('-next-') ||
              potentialTitle.contains('Response') ||
              potentialTitle.contains('ID')) {
            continue;
          }

          currentSection = potentialTitle;

          // Initialize the section if it doesn't exist
          sections.putIfAbsent(currentSection, () => []);

          // Add the content after the colon
          String content =
              paragraph.substring(paragraph.indexOf(':') + 1).trim();
          if (content.isNotEmpty) {
            sections[currentSection]!.add(content);
          }
        }
        // Check for numbered items that might be section headers (like "1. تشخیص احتمالی")
        else if (RegExp(r'^\d+\.\s+').hasMatch(paragraph)) {
          final match = RegExp(r'^\d+\.\s+(.+)$').firstMatch(paragraph);
          if (match != null) {
            String potentialTitle = match.group(1)!.trim();

            // If it's just a title without content, treat it as a section header
            if (!paragraph.contains(':') && potentialTitle.length < 40) {
              currentSection = paragraph.trim();
              sections.putIfAbsent(currentSection, () => []);
              continue;
            }
          }

          // If it has content, add it to the current section
          sections.putIfAbsent(currentSection, () => []);
          sections[currentSection]!.add(paragraph);
        }
        // Check for bullet points or numbered items
        else if (paragraph.startsWith('• ') ||
            paragraph.startsWith('- ') ||
            paragraph.startsWith('* ') ||
            RegExp(r'^\d+\.').hasMatch(paragraph) ||
            RegExp(r'^[۰-۹]+\.').hasMatch(paragraph)) {
          // These are likely bullet points for "نکات مهم"
          sections.putIfAbsent('نکات مهم', () => []);
          sections['نکات مهم']!.add(paragraph);
        }
        // Check for conclusion-like paragraphs
        else if (paragraph.contains('نتیجه') ||
            paragraph.contains('خلاصه') ||
            paragraph.contains('در پایان') ||
            paragraph.contains('در نهایت')) {
          sections.putIfAbsent('نتیجه‌گیری', () => []);
          sections['نتیجه‌گیری']!.add(paragraph);
        }
        // Default case - add to current section
        else {
          sections.putIfAbsent(currentSection, () => []);
          sections[currentSection]!.add(paragraph);
        }
      }

      // Create panels for each section
      int colorIndex = 0;
      sections.forEach((title, paragraphs) {
        // Skip empty sections
        if (paragraphs.isEmpty) return;

        // Skip technical or irrelevant sections
        if (title.contains('-next-') ||
            title.contains('Response') ||
            title.contains('ID')) {
          return;
        }

        // Clean up the title if it contains any technical markers
        String cleanTitle = title
            .replaceAll('-next-', '')
            .replaceAll('Response ID', '')
            .replaceAll('--!>', '')
            .trim();

        // Skip if the title is now empty
        if (cleanTitle.isEmpty) return;

        // Combine paragraphs into one content string
        String content = paragraphs.join('\n\n');

        // Skip sections with empty or meaningless content
        if (_isUnhelpfulContent(content, cleanTitle)) {
          return;
        }

        // Select a color and icon
        Map<String, dynamic> style;
        if (specificStyles.containsKey(cleanTitle)) {
          style = specificStyles[cleanTitle]!;
        } else {
          // Try to find a partial match in specificStyles
          String matchedTitle = '';
          for (final key in specificStyles.keys) {
            if (cleanTitle.contains(key) && key.length > matchedTitle.length) {
              matchedTitle = key;
            }
          }

          if (matchedTitle.isNotEmpty) {
            style = specificStyles[matchedTitle]!;
          } else {
            // Ensure each panel gets a unique color by using the index
            style = sectionStyles[colorIndex % sectionStyles.length];
            colorIndex++;
          }
        }

        // Create the panel
        contentWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ExpandablePanel(
              title: cleanTitle,
              content: content,
              color: style['color'] as Color,
              icon: style['icon'] as IconData,
              initiallyExpanded: false,
              width: panelWidth,
              id: '${cleanTitle}_${contentWidgets.length}',
              onExpansionChanged: _handlePanelExpansionChanged,
            ),
          ),
        );
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  // Helper method to check if content is unhelpful
  bool _isUnhelpfulContent(String content, String title) {
    // Check for empty content
    if (content.trim().isEmpty) {
      return true;
    }

    // Check for content that just repeats the title
    if (content.trim().toLowerCase() == title.trim().toLowerCase()) {
      return true;
    }

    // Check for content that is just a colon followed by the title
    if (content.trim() == ":${title.trim()}") {
      return true;
    }

    // Check for content that is just "احتمالی:" or "احتمالی"
    if (content.trim() == "احتمالی:" || content.trim() == "احتمالی") {
      return true;
    }

    // Check for content that is just a colon
    if (content.trim() == ":") {
      return true;
    }

    // Check for very short content that doesn't contain specific information
    if (content.split(' ').length < 3 &&
        content.length < 15 &&
        !content.contains('میلی‌گرم') &&
        !content.contains('mg') &&
        !content.contains('دوز') &&
        !content.contains('واحد')) {
      return true;
    }

    // Check for content that contains only punctuation or single characters
    if (content.trim().replaceAll(RegExp(r'[^\w\s]'), '').trim().isEmpty) {
      return true;
    }

    // Check for content that is just a dash or bullet point
    if (content.trim() == "-" ||
        content.trim() == "•" ||
        content.trim() == "*") {
      return true;
    }

    // Check for content that is just "ندارد" or "وجود ندارد" without additional context
    if ((content.trim() == "ندارد" || content.trim() == "وجود ندارد") &&
        !title.contains("تداخل") &&
        !title.contains("عوارض")) {
      return true;
    }

    // Check for content that is just "مشخص نشده" or similar without additional context
    if (content.trim() == "مشخص نشده" ||
        content.trim() == "نامشخص" ||
        content.trim() == "تعیین نشده") {
      return true;
    }

    return false;
  }

  Widget _buildMessageContent(
      String content, bool isImage, bool isLoading, bool isThinking,
      {bool isUser = false, bool isError = false}) {
    if (isImage) {
      return ChatImageWidget(content: content);
    }

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (isThinking) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              content,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    }

    // If this is an error message, use the error message builder
    if (isError) {
      return _buildErrorMessageContent(content);
    }

    // Process content with tags (both <tag> and **tag** formats)
    // First remove all stars from the content
    content = content.replaceAll('***', '');
    content = content.replaceAll('**', '');
    content = content.replaceAll('*', '');
    content = content.replaceAll('✧✧✧', '');
    content = content.replaceAll('✧✧', '');
    content = content.replaceAll('✧', '');

    // For user messages, use simple text display
    if (isUser) {
      return Text(
        content,
        style: const TextStyle(
          color: Colors.white,
          height: 1.5,
        ),
      );
    }

    // Remove the initial greeting message that starts with "با کمال میل"
    if (content.startsWith('با کمال میل') || content.startsWith('با کمال')) {
      final firstNewlineIndex = content.indexOf('\n\n');
      if (firstNewlineIndex > 0) {
        content = content.substring(firstNewlineIndex).trim();
      }
    }

    // Remove any technical identifiers or irrelevant content
    content = _cleanupTechnicalContent(content);

    // Check if this is an error response that wasn't properly marked as an error
    if (_isErrorResponse(content)) {
      return _buildErrorMessageContent(content);
    }

    // For AI messages, use the processTaggedContent function for all content
    // This will handle both tagged and untagged content
    return _processTaggedContent(content);
  }

  // Helper method to clean up technical content before displaying
  String _cleanupTechnicalContent(String content) {
    // Remove Response ID lines
    final responseIdRegex = RegExp(r'Response ID.*?--!>', dotAll: true);
    content = content.replaceAll(responseIdRegex, '');

    // Remove -next- sections
    content = content.replaceAll('-next-', '');

    // Remove any lines with technical markers
    final lines = content.split('\n');
    final cleanedLines = lines
        .where((line) =>
            !line.contains('Response ID') &&
            !line.contains('--!>') &&
            !line.trim().startsWith('-next-'))
        .toList();

    // Join lines back together
    content = cleanedLines.join('\n');

    // Remove any remaining technical tags that might be inline
    content = content.replaceAll(RegExp(r'</?Response.*?>'), '');
    content = content.replaceAll(RegExp(r'</?ID.*?>'), '');
    content = content.replaceAll(RegExp(r'--!>'), '');

    // Clean up multiple consecutive newlines
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return content;
  }

  Widget _buildErrorMessageContent(String content) {
    // Clean up the error message to avoid repetition
    String cleanedContent = content;

    // If the content contains "لطفا دوباره تلاش کنید" multiple times, keep only one instance
    if (content.contains('لطفا دوباره تلاش کنید')) {
      final parts = content.split('لطفا دوباره تلاش کنید');
      if (parts.length > 1) {
        cleanedContent = "${parts[0]}لطفا دوباره تلاش کنید";
      }
    }

    return Row(
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            cleanedContent,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messageListProvider(widget.chat.id));
    // Obtener el estado de la suscripción
    final subscriptionState = ref.watch(subscriptionProvider);
    final hasActiveSubscription = subscriptionState.hasActiveSubscription;

    // Check for new messages and update subscription count if needed
    // Use a post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messagesAsync.whenData(_checkForNewMessages);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.title),
        actions: [
          // Widget to display remaining prescriptions - more compact version
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: _remainingPrescriptions > 0
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt,
                  size: 16,
                  color:
                      _remainingPrescriptions > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_remainingPrescriptions',
                  style: TextStyle(
                    color:
                        _remainingPrescriptions > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Add Myket rating button
          IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            tooltip: 'نظر و امتیاز دهید',
            onPressed: () {
              MyketUtils.openRatingPage();
              // Mark as rated in the service
              ref.read(myketRatingServiceProvider).markAsRated();
            },
          ),
          // Menu button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rate') {
                MyketUtils.openRatingPage();
                // Mark as rated in the service
                ref.read(myketRatingServiceProvider).markAsRated();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'rate',
                child: ListTile(
                  leading: Icon(Icons.star, color: Colors.amber),
                  title: Text('نظر و امتیاز دهید'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/animations/empty_messages.json',
                                width: 200,
                                height: 200,
                                repeat: true,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'هنوز پیامی ارسال نشده است',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'اولین پیام خود را ارسال کنید',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),

                              // Show subscription banner if no subscription
                              if (!hasActiveSubscription)
                                Padding(
                                  padding: const EdgeInsets.only(top: 24.0),
                                  child:
                                      _buildSubscriptionPromptWidget(context),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // اسکرول به پایین فقط در صورتی انجام شود که پیام جدیدی دریافت شده باشد
                      if (messages.isNotEmpty &&
                          messages.last.role == 'assistant' &&
                          !messages.last.isLoading &&
                          !messages.last.isThinking) {
                        _scrollToBottom();
                      }
                    });

                    // Create a list of widgets that includes messages and possibly the subscription banner
                    List<Widget> listItems = [];

                    // Add all messages
                    for (int index = 0; index < messages.length; index++) {
                      final message = messages[index];
                      final isUser = message.role == 'user';
                      final isImage = message.isImage;
                      final isLoading = message.isLoading;
                      final isError = message.isError;
                      final isThinking = message.isThinking;

                      listItems.add(
                        MessageBubble(
                          message: message,
                          isUser: isUser,
                          isError: isError,
                          isLoading: isLoading,
                          isThinking: isThinking,
                          isImage: isImage,
                          messageContent: isError
                              ? _buildErrorMessageContent(message.content)
                              : _buildMessageContent(message.content, isImage,
                                  isLoading, isThinking,
                                  isUser: isUser, isError: isError),
                          onRetry: isError
                              ? () {
                                  // Retry sending the failed message
                                  final originalContent = message.content
                                      .split('\n')
                                      .first
                                      .replaceFirst('خطا در ارسال پیام: ', '');
                                  if (originalContent.isNotEmpty) {
                                    ref
                                        .read(
                                            messageListProvider(widget.chat.id)
                                                .notifier)
                                        .sendMessage(originalContent);
                                  }
                                }
                              : null,
                          onPanelExpansionChanged: _handlePanelExpansionChanged,
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(messageListProvider(widget.chat.id).notifier)
                          .loadMessages(),
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        key: PageStorageKey<String>(
                            'chat_list_${widget.chat.id}'),
                        children: listItems,
                      ),
                    );
                  },
                  loading: () => Center(
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      width: 200,
                      height: 200,
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'خطا در دریافت پیام‌ها:\n${error.toString()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(
                                  messageListProvider(widget.chat.id).notifier)
                              .loadMessages(),
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add a "Close All" button to collapse all expandable panels - only show when panels are expanded
                if (_isAnyPanelExpanded)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Material(
                      color: Colors.transparent,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _collapseAllPanels,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.close_fullscreen,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'بستن همه',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Improved bottom input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // نشانگر بارگذاری در حالت پردازش نسخه
                if (_isPrescriptionProcessing)
                  const Column(
                    children: [
                      LinearProgressIndicator(
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'در حال پردازش نسخه، لطفاً صبر کنید...',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),

                // Prescription mode indicator
                if (_prescriptionModeActive && !_isPrescriptionProcessing)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _getPrescriptionTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getPrescriptionTypeColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPrescriptionTypeIcon(),
                          color: _getPrescriptionTypeColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'در حال ارسال ${_getPrescriptionTypeTitle()}',
                          style: TextStyle(
                            color: _getPrescriptionTypeColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: _resetPrescriptionMode,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 16,
                        ),
                      ],
                    ),
                  ),

                // نمایش پیش‌نمایش تصویر انتخاب شده
                if (_hasSelectedImage &&
                    _selectedImagePath != null &&
                    !_isPrescriptionProcessing)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      height: 150,
                      // Limit width to prevent overflow
                      width: MediaQuery.of(context).size.width - 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getPrescriptionTypeColor().withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // اضافه کردن قابلیت کلیک روی تصویر
                          GestureDetector(
                            onTap: () =>
                                _showFullScreenImage(_selectedImagePath!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_selectedImagePath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _hasSelectedImage = false;
                                    _selectedImagePath = null;
                                    _prescriptionModeActive = false;
                                    _selectedPrescriptionType = '';
                                  });
                                },
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          // اضافه کردن آیکون بزرگنمایی برای نشان دادن قابلیت کلیک
                          Positioned(
                            bottom: 5,
                            left: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: () =>
                                    _showFullScreenImage(_selectedImagePath!),
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Improved input row with better styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: _prescriptionModeActive
                        ? _getPrescriptionTypeColor().withOpacity(0.05)
                        : Colors.grey.withOpacity(0.05),
                    border: Border.all(
                      color: _prescriptionModeActive
                          ? _getPrescriptionTypeColor().withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: hasActiveSubscription
                      ? Row(
                          children: [
                            // Prescription button with improved styling
                            Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isPrescriptionProcessing
                                    ? Colors.grey.withOpacity(0.1)
                                    : (_prescriptionModeActive
                                        ? _getPrescriptionTypeColor()
                                            .withOpacity(0.1)
                                        : AppTheme.primaryColor
                                            .withOpacity(0.1)),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _prescriptionModeActive
                                      ? _getPrescriptionTypeIcon()
                                      : Icons.medical_services,
                                  color: _isPrescriptionProcessing
                                      ? Colors.grey
                                      : (_prescriptionModeActive
                                          ? _getPrescriptionTypeColor()
                                          : AppTheme.primaryColor),
                                  size: 22,
                                ),
                                onPressed: _isPrescriptionProcessing
                                    ? null // غیرفعال کردن دکمه در حالت پردازش نسخه
                                    : _showPrescriptionOptionsDialog,
                                tooltip: _isPrescriptionProcessing
                                    ? 'در حال پردازش نسخه...'
                                    : 'ارسال نسخه',
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),

                            // Text field with animation
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _inputExpandController,
                                builder: (context, child) {
                                  // Don't show text field at all when image is selected
                                  if (_hasSelectedImage) {
                                    return const SizedBox.shrink();
                                  }

                                  return ClipRect(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      widthFactor: _showInputField
                                          ? _inputWidthAnimation.value
                                          : 0.01,
                                      child: Container(
                                        height: _showInputField ? null : 40,
                                        width: _showInputField ? null : 2,
                                        decoration: BoxDecoration(
                                          color: _showInputField
                                              ? null
                                              : Colors.grey.shade800,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                        child: _showInputField
                                            ? TextField(
                                                controller: _messageController,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      _getInputPlaceholder(),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                                ),
                                                textInputAction:
                                                    TextInputAction.newline,
                                                keyboardType:
                                                    TextInputType.multiline,
                                                maxLines: 5,
                                                minLines: 1,
                                                enabled:
                                                    !_isPrescriptionProcessing,
                                                onChanged: (text) {
                                                  // اگر در حالت نسخه متنی هستیم، مطمئن شویم که پیشوند "نسخه: " حذف نشود
                                                  if (_prescriptionModeActive &&
                                                      _selectedPrescriptionType ==
                                                          'text' &&
                                                      !text.startsWith(
                                                          'نسخه: ')) {
                                                    _messageController.text =
                                                        'نسخه: ${text.replaceAll('نسخه:', '')}';
                                                    _messageController
                                                            .selection =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                          offset:
                                                              _messageController
                                                                  .text.length),
                                                    );
                                                  }
                                                },
                                                onSubmitted: (_) {
                                                  // این متد دیگر فراخوانی نمی‌شود چون textInputAction به newline تغییر کرده است
                                                },
                                              )
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Send button with improved styling
                            Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isPrescriptionProcessing
                                    ? Colors.grey.withOpacity(0.1)
                                    : (_hasSelectedImage ||
                                            (_showInputField &&
                                                _messageController
                                                    .text.isNotEmpty)
                                        ? (_prescriptionModeActive
                                            ? _getPrescriptionTypeColor()
                                            : AppTheme.primaryColor)
                                        : Colors.grey.withOpacity(0.1)),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isPrescriptionProcessing
                                      ? Icons.hourglass_empty
                                      : Icons.send,
                                  color: _isPrescriptionProcessing
                                      ? Colors.grey
                                      : (_hasSelectedImage ||
                                              (_showInputField &&
                                                  _messageController
                                                      .text.isNotEmpty)
                                          ? Colors.white
                                          : Colors.grey),
                                  size: 20,
                                ),
                                onPressed: _isPrescriptionProcessing
                                    ? null
                                    : (_hasSelectedImage ||
                                            (_showInputField &&
                                                _messageController
                                                    .text.isNotEmpty)
                                        ? () {
                                            if (_hasSelectedImage) {
                                              // ارسال تصویر انتخاب شده
                                              _sendImageMessage();
                                            } else if (_showInputField &&
                                                _messageController
                                                    .text.isNotEmpty) {
                                              if (_prescriptionModeActive) {
                                                final messageText =
                                                    _messageController.text;
                                                _messageController.clear();

                                                setState(() {
                                                  _isPrescriptionProcessing =
                                                      true;
                                                });

                                                ref
                                                    .read(messageListProvider(
                                                            widget.chat.id)
                                                        .notifier)
                                                    .sendMessage(messageText)
                                                    .then((_) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _isPrescriptionProcessing =
                                                          false;
                                                      _prescriptionModeActive =
                                                          false;
                                                      _selectedPrescriptionType =
                                                          '';
                                                      _showInputField = false;
                                                      _inputExpandController
                                                          .reverse();
                                                    });
                                                  }
                                                }).catchError((error) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _isPrescriptionProcessing =
                                                          false;
                                                    });

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            error.toString()),
                                                        backgroundColor:
                                                            AppTheme.errorColor,
                                                        action: SnackBarAction(
                                                          label: 'خرید اشتراک',
                                                          onPressed: () {
                                                            Navigator.pushNamed(
                                                                context,
                                                                '/subscription');
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return null;
                                                });
                                              } else {
                                                // Enviar mensaje normal
                                                _sendMessage();
                                              }
                                            }
                                          }
                                        : null),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        )
                      : _buildSubscriptionPromptWidget(context),
                ),

                // Add a hint text when no prescription option is selected
                if (!_prescriptionModeActive &&
                    !_showInputField &&
                    !_isPrescriptionProcessing &&
                    hasActiveSubscription)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'برای ارسال نسخه، روی آیکون نسخه کلیک کنید',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to collapse all expandable panels
  void _collapseAllPanels() {
    // First clear our tracking state
    setState(() {
      _expandedPanelIds.clear();
      _isAnyPanelExpanded = false;
    });

    // Use the registry to collapse all panels directly
    ExpandablePanelRegistry.collapseAll();

    // Show a snackbar to confirm the action
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('تمام بخش‌ها بسته شدند'),
        duration: Duration(seconds: 1),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  // Method to handle panel expansion state changes
  void _handlePanelExpansionChanged(bool isExpanded, String panelId) {
    if (isExpanded) {
      setState(() {
        _expandedPanelIds.add(panelId);
        _isAnyPanelExpanded = true;
      });
    } else {
      setState(() {
        _expandedPanelIds.remove(panelId);
        _isAnyPanelExpanded = _expandedPanelIds.isNotEmpty;
      });
    }
  }

  // Helper method to check if a message is an error response from the server
  bool _isErrorResponse(String content) {
    // Common error phrases in Persian
    final errorPhrases = [
      'عذر میخواهم',
      'عذر می‌خواهم',
      'متاسفانه',
      'متأسفانه',
      'خطایی رخ داده',
      'مشکلی پیش آمده',
      'لطفا دوباره تلاش کنید',
      'لطفاً دوباره تلاش کنید',
      'نتوانستم',
    ];

    // Check if content contains any of the error phrases
    for (final phrase in errorPhrases) {
      if (content.contains(phrase)) {
        return true;
      }
    }

    return false;
  }

  // Helper method to check for new messages
  void _checkForNewMessages(List<Message> messages) {
    if (messages.isEmpty) return;

    // Check if we have a new message that wasn't processed yet
    final latestMessage = messages.last;
    if (latestMessage.id != _lastProcessedMessageId &&
        latestMessage.role == 'assistant' &&
        !latestMessage.isLoading &&
        !latestMessage.isThinking) {
      // Update the last processed message ID
      _lastProcessedMessageId = latestMessage.id;

      // Scroll to bottom after a short delay to ensure the UI is updated
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // Helper method to get prescription type color
  Color _getPrescriptionTypeColor() {
    if (_prescriptionModeActive) {
      if (_selectedPrescriptionType == 'image') {
        return Colors.green;
      } else if (_selectedPrescriptionType == 'text') {
        return Colors.blue;
      } else if (_selectedPrescriptionType == 'camera') {
        return Colors.purple;
      } else {
        return AppTheme.primaryColor;
      }
    } else {
      return AppTheme.primaryColor;
    }
  }

  // Helper method to get prescription type icon
  IconData _getPrescriptionTypeIcon() {
    if (_prescriptionModeActive) {
      if (_selectedPrescriptionType == 'image') {
        return Icons.photo_library;
      } else if (_selectedPrescriptionType == 'text') {
        return Icons.text_fields;
      } else if (_selectedPrescriptionType == 'camera') {
        return Icons.camera_alt;
      } else {
        return Icons.medical_services;
      }
    } else {
      return Icons.medical_services;
    }
  }

  // Helper method to get prescription type title
  String _getPrescriptionTypeTitle() {
    if (_prescriptionModeActive) {
      if (_selectedPrescriptionType == 'image') {
        return 'تصویر نسخه';
      } else if (_selectedPrescriptionType == 'text') {
        return 'متن نسخه';
      } else {
        return 'نسخه';
      }
    } else {
      return 'نسخه';
    }
  }

  // Helper method to get input placeholder
  String _getInputPlaceholder() {
    if (_isPrescriptionProcessing) {
      return 'در حال پردازش نسخه، لطفاً صبر کنید...';
    } else if (_prescriptionModeActive) {
      if (_selectedPrescriptionType == 'image') {
        return 'توضیحات اضافی برای نسخه تصویری...';
      } else if (_selectedPrescriptionType == 'text') {
        return 'متن نسخه را وارد کنید...';
      } else if (_selectedPrescriptionType == 'camera') {
        return 'توضیحات اضافی برای عکس دوربین...';
      } else {
        return 'متن نسخه را وارد کنید...';
      }
    } else {
      return 'پیام خود را بنویسید...';
    }
  }

  // Helper method to show full screen image
  void _showFullScreenImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrl: imagePath,
          isNetworkImage: false,
          heroTag: 'image_preview_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }

  // Helper method to force collapse all panels in the widget tree
  void _forceCollapseAllPanelsInTree(BuildContext context) {
    // This is a placeholder method to fix the linter error
    // The actual implementation would be more complex
  }

  // Helper method to check if a message is a prescription response
  bool _isPrescriptionResponse(String content) {
    // Log the content for debugging
    AppLogger.i(
        'Checking if message is prescription response. Content length: ${content.length}');

    // First check if this is an error message
    if (_isErrorResponse(content)) {
      AppLogger.i(
          'Message appears to be an error response, not a prescription response');
      return false;
    }

    // Check for prescription-specific tags in the content
    bool hasPrescriptionTags = content.contains('<داروها>') ||
        content.contains('<تشخیص>') ||
        content.contains('تشخیص احتمالی') ||
        content.contains('تداخلات دارویی') ||
        content.contains('عوارض دارویی') ||
        content.contains('زمان مصرف') ||
        content.contains('نحوه مصرف') ||
        content.contains('دوز مصرف') ||
        content.contains('بررسی نسخه');

    AppLogger.i('Has prescription tags: $hasPrescriptionTags');

    // Check for specific patterns that indicate a prescription analysis
    bool hasPrescriptionPatterns = content.contains('لیست داروها') ||
        content.contains('لیست کامل داروها') ||
        content.contains('داروهای تجویز شده') ||
        content.contains('داروهای نسخه');

    AppLogger.i('Has prescription patterns: $hasPrescriptionPatterns');

    return hasPrescriptionTags || hasPrescriptionPatterns;
  }

  // Widget to show when the user doesn't have an active subscription
  Widget _buildSubscriptionPromptWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Collapsible header - always visible
        GestureDetector(
          onTap: () {
            setState(() {
              _isSubscriptionBannerCollapsed = !_isSubscriptionBannerCollapsed;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              borderRadius: _isSubscriptionBannerCollapsed
                  ? BorderRadius.circular(12)
                  : BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'اشتراک فعال نیست',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isSubscriptionBannerCollapsed
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isSubscriptionBannerCollapsed ? 0 : null,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: ClipRect(
            child: _isSubscriptionBannerCollapsed
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated icon with pulse effect
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.workspace_premium,
                                  color: AppTheme.primaryColor,
                                  size: 36,
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            // Restart animation
                            if (mounted && !_isSubscriptionBannerCollapsed) {
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Main message
                        Text(
                          'اشتراک شما فعال نیست',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Secondary message
                        Text(
                          'برای ارسال نسخه و دریافت پاسخ، نیاز به اشتراک فعال دارید',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Subscription button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/subscription');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.shopping_cart, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'خرید اشتراک',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
      ],
    );
  }

  // Method to send a message
  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    // Verificar si el usuario tiene una suscripción activa
    final subscriptionState = ref.read(subscriptionProvider);
    if (!subscriptionState.hasActiveSubscription) {
      // Mostrar un mensaje y redirigir a la pantalla de suscripción
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('برای ارسال پیام نیاز به اشتراک فعال دارید'),
          backgroundColor: AppTheme.errorColor,
          action: SnackBarAction(
            label: 'خرید اشتراک',
            onPressed: () {
              Navigator.pushNamed(context, '/subscription');
            },
          ),
        ),
      );
      return;
    }

    final messageText = _messageController.text;
    _messageController.clear();

    // Hide the input field
    setState(() {
      _showInputField = false;
      _inputExpandController.reverse();
    });

    // Send the message
    ref
        .read(messageListProvider(widget.chat.id).notifier)
        .sendMessage(messageText)
        .then((_) {
      // Scroll to bottom after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    });
  }
}
