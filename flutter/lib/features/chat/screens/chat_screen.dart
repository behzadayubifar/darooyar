import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async'; // Add this import for Timer
import 'dart:convert'; // Add this import for json encoding/decoding
import 'package:http/http.dart' as http; // Add this import for HTTP requests
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/message_formatter.dart';
import '../../prescription/presentation/widgets/expandable_panel.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/message_providers.dart';
import 'dart:io';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/message_migration_service.dart';
import 'image_viewer_screen.dart';
import '../widgets/chat_image_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_actions.dart';
import '../utils/message_utils.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../auth/providers/auth_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatScreen({Key? key, required this.chat}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  bool _showPrescriptionOptions = false;
  bool _initialScrollDone = false; // متغیر برای کنترل اسکرول اولیه
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

  @override
  void initState() {
    super.initState();

    // اطمینان از اینکه وضعیت پردازش نسخه در ابتدا false است
    _isPrescriptionProcessing = false;

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
          _initialScrollDone = true;
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
      });

      // Get the auth token
      final authService = ref.read(authServiceProvider);
      final token = await authService.getToken();

      if (token == null) {
        AppLogger.e('No token available for subscription refresh');
        _ignoreProviderUpdates = false;
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
            }
          });
        } else {
          AppLogger.e(
              'Could not find or calculate remaining_uses in API response');
          _ignoreProviderUpdates = false;
        }
      } else {
        AppLogger.e('API error: ${response.statusCode} - ${response.body}');
        _ignoreProviderUpdates = false;
      }
    } catch (e) {
      AppLogger.e('Error in direct API call: $e');
      _ignoreProviderUpdates = false;
    }

    // پس از به‌روزرسانی موفق اشتراک، در صورت نیاز پیام نمایش بده
    if (showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('یک نسخه از اشتراک شما استفاده شد'),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 3),
        ),
      );
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

  void _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        // تنظیم وضعیت پردازش نسخه
        setState(() {
          _isPrescriptionProcessing = true;
        });

        ref
            .read(messageListProvider(widget.chat.id).notifier)
            .sendImageMessage(pickedFile.path)
            .catchError((error) {
          // در صورت خطا، وضعیت پردازش را به روز کن
          setState(() {
            _isPrescriptionProcessing = false;
          });

          AppLogger.e('Error sending image: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در ارسال تصویر: ${error.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return null;
        });

        // اسکرول به پایین پس از ارسال تصویر
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    } catch (e) {
      AppLogger.e('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در انتخاب تصویر. لطفا دوباره تلاش کنید.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showPrescriptionOptionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'نوع نسخه را انتخاب کنید',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    const Icon(Icons.text_fields, color: AppTheme.primaryColor),
                title: const Text('نسخه متنی'),
                subtitle: const Text('ارسال نسخه به صورت متن'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _showPrescriptionOptions = false;
                  });
                  // Focus on text field
                  FocusScope.of(context).requestFocus(FocusNode());
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _messageController.text = 'نسخه: ';
                    FocusScope.of(context).unfocus();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      FocusScope.of(context).requestFocus(FocusNode());
                    });
                  });
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_camera, color: AppTheme.primaryColor),
                title: const Text('عکس از دوربین'),
                subtitle: const Text('گرفتن عکس از نسخه با دوربین'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppTheme.primaryColor),
                title: const Text('انتخاب از گالری'),
                subtitle: const Text('انتخاب تصویر نسخه از گالری'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build expandable panels for AI responses
  Widget _buildAIResponsePanels(String content) {
    // Check if the content is empty
    if (content.isEmpty) {
      return const Text(
        'پاسخی دریافت نشد.',
        style: TextStyle(
          color: Colors.white,
          fontStyle: FontStyle.italic,
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

    // Remove stars completely instead of replacing them with decorative elements
    content = content.replaceAll('***', '');
    content = content.replaceAll('**', '');
    content = content.replaceAll('*', '');
    content = content.replaceAll('✧✧✧', '');
    content = content.replaceAll('✧✧', '');
    content = content.replaceAll('✧', '');

    // Use the processTaggedContent method to handle all content
    return _processTaggedContent(content);
  }

  // Helper method to extract individual medications from a medication list
  void _extractMedicationItems(
      String medicationList, List<Map<String, String>> medicationItems) {
    // Try to extract individual medications
    // Look for numbered items like "1. دارو" or "۱. دارو" or "- دارو" or "• دارو"
    final List<String> lines = medicationList.split('\n');

    // Skip the first line if it's a title
    int startIndex = 0;
    if (lines.isNotEmpty &&
        (lines[0].contains('لیست داروها') ||
            lines[0].contains('داروهای نسخه') ||
            lines[0].contains('داروهای تجویز شده'))) {
      startIndex = 1;
    }

    String currentMedicationName = '';
    String currentMedicationDetails = '';

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check if this line starts a new medication
      if (line.isEmpty) continue;

      // Check for numbered items or bullet points
      bool isNewMedication = RegExp(
              r'^(\d+\.|\d+\-|۱\.|۲\.|۳\.|۴\.|۵\.|۶\.|۷\.|۸\.|۹\.|۰\.|\-|\•|\*|\✧)')
          .hasMatch(line);

      // Also check for lines that start with a medication name pattern
      if (!isNewMedication) {
        isNewMedication = line.contains('قرص') ||
            line.contains('کپسول') ||
            line.contains('شربت') ||
            line.contains('آمپول') ||
            line.contains('اسپری') ||
            line.contains('پماد') ||
            line.contains('قطره');
      }

      if (isNewMedication) {
        // Save previous medication if exists
        if (currentMedicationName.isNotEmpty) {
          medicationItems.add({
            'name': currentMedicationName,
            'details': currentMedicationDetails.trim()
          });
        }

        // Start new medication
        currentMedicationName = line;
        currentMedicationDetails = '';
      } else if (currentMedicationName.isNotEmpty) {
        // Add to current medication details
        currentMedicationDetails += line + '\n';
      }
    }

    // Add the last medication
    if (currentMedicationName.isNotEmpty) {
      medicationItems.add({
        'name': currentMedicationName,
        'details': currentMedicationDetails.trim()
      });
    }

    // If we couldn't extract any medications but have content, create a single item
    if (medicationItems.isEmpty && medicationList.isNotEmpty) {
      String title = 'لیست داروها';
      String content = medicationList;

      // Try to extract a title
      if (medicationList.contains(':')) {
        final parts = medicationList.split(':');
        if (parts.length > 1 && parts[0].length < 40) {
          title = parts[0].trim();
          content = parts.sublist(1).join(':').trim();
        }
      }

      medicationItems.add({'name': title, 'details': content});
    }
  }

  // Helper method to extract content between tags and create expandable panels
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

    // Check if any tags are present in the content (both <tag> and **tag** formats)
    bool hasAnyTags = false;
    for (var tagDef in tagDefinitions) {
      String tag = tagDef['tag'] as String;
      if (content.contains('<$tag>') && content.contains('</$tag>')) {
        hasAnyTags = true;
        break;
      }
      // Since we've removed all stars, we need to check for the tag without stars
      if (content.contains(tag)) {
        hasAnyTags = true;
        break;
      }
    }

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
            ),
          ),
        );

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
        // Try to identify if this paragraph is a section title
        if (paragraph.contains(':') && paragraph.split(':')[0].length < 40) {
          String potentialTitle = paragraph.split(':')[0].trim();
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

        // Combine paragraphs into one content string
        String content = paragraphs.join('\n\n');

        // Select a color and icon
        Map<String, dynamic> style;
        if (specificStyles.containsKey(title)) {
          style = specificStyles[title]!;
        } else {
          // Try to find a partial match in specificStyles
          String matchedTitle = '';
          specificStyles.keys.forEach((key) {
            if (title.contains(key) && key.length > matchedTitle.length) {
              matchedTitle = key;
            }
          });

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
              title: title,
              content: content,
              color: style['color'] as Color,
              icon: style['icon'] as IconData,
              initiallyExpanded: false,
              width: panelWidth,
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

  Widget _buildMessageContent(
      String content, bool isImage, bool isLoading, bool isThinking,
      {bool isUser = false}) {
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

    // For AI messages, use the processTaggedContent function for all content
    // This will handle both tagged and untagged content
    return _processTaggedContent(content);
  }

  Widget _buildErrorMessageContent(String content) {
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
            content,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messageListProvider(widget.chat.id));

    // Check for new messages and update subscription count if needed
    // Use a post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messagesAsync.whenData(_checkForNewMessages);
    });

    // Create a unique key for the Chip widget to force rebuild when _remainingPrescriptions changes
    final chipKey = Key(
        'prescription_count_${DateTime.now().millisecondsSinceEpoch}_$_remainingPrescriptions');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.title),
        actions: [
          // Widget to display remaining prescriptions
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    AppLogger.i('Manually refreshing subscription plan');
                    _forceRefreshSubscription(showSnackBar: true);
                  },
                  tooltip: 'به‌روزرسانی اطلاعات اشتراک',
                ),
                // Prescription count chip
                Chip(
                  key: chipKey,
                  label: Text(
                    '$_remainingPrescriptions نسخه باقیمانده',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                  avatar: const Icon(
                    Icons.medical_services_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
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
                      ],
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

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(messageListProvider(widget.chat.id).notifier)
                      .loadMessages(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    key: PageStorageKey<String>('chat_list_${widget.chat.id}'),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUser = message.role == 'user';
                      final isSystem = message.role == 'system';
                      final isImage = message.isImage;
                      final isLoading = message.isLoading;
                      final isError = message.isError;
                      final isThinking = message.isThinking;

                      return MessageBubble(
                        message: message,
                        isUser: isUser,
                        isError: isError,
                        isLoading: isLoading,
                        isThinking: isThinking,
                        isImage: isImage,
                        messageContent: isError
                            ? _buildErrorMessageContent(message.content)
                            : _buildMessageContent(
                                message.content, isImage, isLoading, isThinking,
                                isUser: isUser),
                        onRetry: isError
                            ? () {
                                // Retry sending the failed message
                                final originalContent = message.content
                                    .split('\n')
                                    .first
                                    .replaceFirst('خطا در ارسال پیام: ', '');
                                if (originalContent.isNotEmpty) {
                                  ref
                                      .read(messageListProvider(widget.chat.id)
                                          .notifier)
                                      .sendMessage(originalContent);
                                }
                              }
                            : null,
                      );
                    },
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
                          .read(messageListProvider(widget.chat.id).notifier)
                          .loadMessages(),
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
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
                  Column(
                    children: [
                      const LinearProgressIndicator(
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'در حال پردازش نسخه، لطفاً صبر کنید...',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.medical_services,
                        color: _isPrescriptionProcessing
                            ? Colors.grey
                            : (_showPrescriptionOptions
                                ? AppTheme.primaryColor
                                : Colors.grey),
                      ),
                      onPressed: _isPrescriptionProcessing
                          ? null // غیرفعال کردن دکمه در حالت پردازش نسخه
                          : _showPrescriptionOptionsDialog,
                      tooltip: _isPrescriptionProcessing
                          ? 'در حال پردازش نسخه...'
                          : 'ارسال نسخه',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: _isPrescriptionProcessing
                              ? 'در حال پردازش نسخه، لطفاً صبر کنید...'
                              : 'پیام خود را بنویسید...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.grey[100]
                                  : AppTheme.textPrimaryColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        maxLines: 5,
                        minLines: 1,
                        enabled:
                            !_isPrescriptionProcessing, // غیرفعال کردن فیلد در حالت پردازش نسخه
                        onSubmitted: (_) {
                          // این متد دیگر فراخوانی نمی‌شود چون textInputAction به newline تغییر کرده است
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _isPrescriptionProcessing
                          ? null // غیرفعال کردن دکمه در حالت پردازش نسخه
                          : () {
                              if (_messageController.text.isNotEmpty) {
                                final messageText = _messageController.text;
                                _messageController.clear();

                                // بررسی اینکه آیا این پیام یک نسخه است یا نه
                                bool isPrescription =
                                    messageText.startsWith('نسخه:') ||
                                        messageText.contains('نسخه') ||
                                        messageText.contains('دارو') ||
                                        messageText.contains('قرص') ||
                                        messageText.contains('کپسول') ||
                                        messageText.contains('شربت') ||
                                        messageText.contains('آمپول');

                                // اگر این پیام یک نسخه است، وضعیت پردازش را به روز کن
                                if (isPrescription) {
                                  setState(() {
                                    _isPrescriptionProcessing = true;
                                  });
                                }

                                ref
                                    .read(messageListProvider(widget.chat.id)
                                        .notifier)
                                    .sendMessage(messageText)
                                    .catchError((error) {
                                  // در صورت خطا، وضعیت پردازش را به روز کن
                                  if (isPrescription) {
                                    setState(() {
                                      _isPrescriptionProcessing = false;
                                    });
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error.toString()),
                                      backgroundColor: AppTheme.errorColor,
                                      action: SnackBarAction(
                                        label: 'خرید اشتراک',
                                        onPressed: () {
                                          // Navigate to subscription screen
                                          Navigator.pushNamed(
                                              context, '/subscription');
                                        },
                                      ),
                                    ),
                                  );
                                  return null;
                                });

                                // اسکرول به پایین پس از ارسال پیام
                                Future.delayed(
                                    const Duration(milliseconds: 300),
                                    _scrollToBottom);
                              }
                            },
                      mini: true,
                      backgroundColor: _isPrescriptionProcessing
                          ? Colors.grey
                          : null, // تغییر رنگ دکمه در حالت پردازش
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add a method to check for new messages and update the subscription count
  void _checkForNewMessages(List<Message> messages) {
    if (messages.isEmpty) return;

    final lastMessage = messages.last;
    
    // اگر پیام جدید در حالت "thinking" یا "loading" است و هنوز وضعیت پردازش نسخه تنظیم نشده
    if ((lastMessage.isThinking || lastMessage.isLoading) && 
         lastMessage.role == 'assistant' && 
         !_isPrescriptionProcessing) {
      // بررسی کنیم که آیا پیام قبلی از کاربر بوده و حاوی کلمات کلیدی نسخه است
      if (messages.length >= 2) {
        final previousMessage = messages[messages.length - 2];
        if (previousMessage.role == 'user') {
          bool isPrescription = previousMessage.content.startsWith('نسخه:') || 
                               previousMessage.content.contains('نسخه') || 
                               previousMessage.content.contains('دارو') ||
                               previousMessage.content.contains('قرص') ||
                               previousMessage.content.contains('کپسول') ||
                               previousMessage.content.contains('شربت') ||
                               previousMessage.content.contains('آمپول') ||
                               previousMessage.isImage; // تصاویر معمولاً نسخه هستند
                               
          if (isPrescription) {
            setState(() {
              _isPrescriptionProcessing = true;
            });
            AppLogger.i('Detected prescription processing from message content');
          }
        }
      }
    }

    // Only process each message once
    if (lastMessage.id == _lastProcessedMessageId) return;

    // Check if this is a completed AI response
    if (lastMessage.role == 'assistant' &&
        !lastMessage.isLoading &&
        !lastMessage.isThinking) {
      // Update the last processed message ID
      _lastProcessedMessageId = lastMessage.id;

      // Check if the message is a prescription response by looking for specific tags
      bool isPrescriptionResponse =
          _isPrescriptionResponse(lastMessage.content);
      AppLogger.i('Is prescription response: $isPrescriptionResponse');

      // بررسی کنید که آیا در حال پردازش نسخه بوده‌ایم و اکنون پاسخی دریافت کرده‌ایم
      if (_isPrescriptionProcessing) {
        // بازنشانی وضعیت پردازش نسخه
        setState(() {
          _isPrescriptionProcessing = false;
        });
        AppLogger.i('Prescription processing completed, enabling input');
      }

      if (isPrescriptionResponse) {
        // Wait a moment to ensure the server has processed the subscription update
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // Log for debugging
            AppLogger.i(
                'Refreshing subscription plan after receiving prescription response');

            // Force refresh the subscription data - just once is enough
            _forceRefreshSubscriptionWithAPI(showSnackBar: true);
          }
        });
      }
    } else if (lastMessage.isError && _isPrescriptionProcessing) {
      // در صورت خطا نیز وضعیت پردازش نسخه را بازنشانی کنید
      setState(() {
        _isPrescriptionProcessing = false;
      });
      AppLogger.i('Prescription processing failed, enabling input');
    }
  }

  // Helper method to check if a message is a prescription response
  bool _isPrescriptionResponse(String content) {
    // Log the content for debugging
    AppLogger.i(
        'Checking if message is prescription response. Content length: ${content.length}');

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
}
