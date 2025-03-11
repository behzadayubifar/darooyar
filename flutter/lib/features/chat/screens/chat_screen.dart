import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async'; // Add this import for Timer
import 'dart:convert'; // Add this import for json encoding/decoding
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

  Future<void> _pickImage(ImageSource source) async {
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
          if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در انتخاب تصویر. لطفا دوباره تلاش کنید.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Show options for prescription input
  void _showPrescriptionOptionsDialog() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                  if (mounted) {
                    FocusScope.of(context).requestFocus(FocusNode());
                  }
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (!mounted) return;
                    _messageController.text = 'نسخه: ';
                    if (mounted) {
                      FocusScope.of(context).unfocus();
                    }
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (!mounted) return;
                      if (mounted) {
                        FocusScope.of(context).requestFocus(FocusNode());
                      }
                    });
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera,
                    color: AppTheme.primaryColor),
                title: const Text('عکس از دوربین'),
                subtitle: const Text('گرفتن عکس از نسخه با دوربین'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppTheme.primaryColor),
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
          for (final key in specificStyles.keys) {
            if (title.contains(key) && key.length > matchedTitle.length) {
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

    // Check if this is an error response that wasn't properly marked as an error
    if (_isErrorResponse(content)) {
      return _buildErrorMessageContent(content);
    }

    // For AI messages, use the processTaggedContent function for all content
    // This will handle both tagged and untagged content
    return _processTaggedContent(content);
  }

  Widget _buildErrorMessageContent(String content) {
    // Clean up the error message to avoid repetition
    String cleanedContent = content;

    // If the content contains "لطفا دوباره تلاش کنید" multiple times, keep only one instance
    if (content.contains('لطفا دوباره تلاش کنید')) {
      final parts = content.split('لطفا دوباره تلاش کنید');
      if (parts.length > 1) {
        cleanedContent = parts[0] + 'لطفا دوباره تلاش کنید';
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Refresh button
                IconButton(
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  onPressed: _isRefreshing
                      ? null
                      : () {
                          setState(() {
                            _isRefreshing = true;
                          });
                          AppLogger.i('Manually refreshing subscription plan');
                          _forceRefreshSubscription(showSnackBar: false);
                        },
                  tooltip: 'به‌روزرسانی اطلاعات اشتراک',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                // Compact prescription count indicator
                Tooltip(
                  message: '$_remainingPrescriptions نسخه باقیمانده',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.medical_services_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_remainingPrescriptions',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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

                                  if (!mounted) return;
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
      'قادر به پردازش نیستم',
      'قادر به تحلیل نیستم',
      'امکان پردازش وجود ندارد',
      'امکان تحلیل وجود ندارد',
      'خطا در پردازش',
      'خطا در تحلیل',
      'نمی‌توانم تحلیل کنم',
      'نمی‌توانم پردازش کنم',
      'نمی‌توانم تشخیص دهم',
      'نمی‌توانم بخوانم',
      'قادر به خواندن نیستم',
      'تصویر واضح نیست',
      'تصویر قابل تشخیص نیست',
      'نسخه قابل خواندن نیست',
      'نسخه واضح نیست',
      'خطا در پردازش نسخه',
    ];

    // Check if the content contains any of the error phrases
    for (final phrase in errorPhrases) {
      if (content.contains(phrase)) {
        AppLogger.i('Detected error phrase in response: "$phrase"');
        return true;
      }
    }

    // Check for common error patterns
    if ((content.contains('لطفا') || content.contains('لطفاً')) &&
        (content.contains('دوباره') || content.contains('مجدد'))) {
      AppLogger.i('Detected error pattern: request to try again');
      return true;
    }

    // Check if the content is very short (likely an error)
    if (content.length < 100 &&
        (content.contains('خطا') ||
            content.contains('مشکل') ||
            content.contains('عذر') ||
            content.contains('متاسف'))) {
      AppLogger.i('Detected short error message');
      return true;
    }

    // Check if the content lacks prescription-specific information but mentions prescription
    if (content.contains('نسخه') &&
        content.length < 200 &&
        !(content.contains('داروها') ||
            content.contains('تشخیص') ||
            content.contains('تداخل') ||
            content.contains('عوارض'))) {
      AppLogger.i(
          'Detected error response related to prescription without analysis');
      return true;
    }

    // Check if the content lacks prescription-specific information
    bool hasPrescriptionContent = content.contains('دارو') ||
        content.contains('قرص') ||
        content.contains('کپسول') ||
        content.contains('شربت') ||
        content.contains('آمپول') ||
        content.contains('تشخیص') ||
        content.contains('تداخل') ||
        content.contains('عوارض') ||
        content.contains('مصرف');

    if (!hasPrescriptionContent && content.length < 200) {
      AppLogger.i('Detected response without prescription content');
      return true;
    }

    return false;
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
            AppLogger.i(
                'Detected prescription processing from message content');
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

      // Check if the message content indicates an error
      bool isErrorResponse = _isErrorResponse(lastMessage.content);

      // بررسی کنید که آیا در حال پردازش نسخه بوده‌ایم و اکنون پاسخی دریافت کرده‌ایم
      if (_isPrescriptionProcessing) {
        // بازنشانی وضعیت پردازش نسخه
        setState(() {
          _isPrescriptionProcessing = false;
        });
        AppLogger.i('Prescription processing completed, enabling input');

        // If this is an error response, convert it to an error message
        if (isErrorResponse) {
          AppLogger.i('Converting error response to error message');

          // Use the message provider to replace the message with an error message
          ref
              .read(messageListProvider(widget.chat.id).notifier)
              .convertToErrorMessage(lastMessage.id,
                  'خطا در پردازش نسخه: ${lastMessage.content.split('\n').first}');

          // Don't refresh subscription for error responses
          return;
        }
      } else {
        // Even if we're not processing a prescription, check if this is an error response
        // that needs to be converted to an error message
        if (isErrorResponse && !lastMessage.isError) {
          AppLogger.i(
              'Converting non-prescription error response to error message');

          // Use the message provider to replace the message with an error message
          ref
              .read(messageListProvider(widget.chat.id).notifier)
              .convertToErrorMessage(lastMessage.id,
                  'خطا: ${lastMessage.content.split('\n').first}');

          return;
        }
      }

      // Only check for prescription response if it's not an error
      if (!isErrorResponse) {
        // Check if the message is a prescription response by looking for specific tags
        bool isPrescriptionResponse =
            _isPrescriptionResponse(lastMessage.content);
        AppLogger.i('Is prescription response: $isPrescriptionResponse');

        if (isPrescriptionResponse) {
          // Wait a moment to ensure the server has processed the subscription update
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              // Log for debugging
              AppLogger.i(
                  'Refreshing subscription plan after receiving prescription response');

              // Force refresh the subscription data - just once is enough
              _forceRefreshSubscriptionWithAPI(showSnackBar: false);
            }
          });
        }
      }
    } else if (lastMessage.isError && _isPrescriptionProcessing) {
      // در صورت خطا نیز وضعیت پردازش نسخه را بازنشانی کنید
      setState(() {
        _isPrescriptionProcessing = false;
      });
      AppLogger.i('Prescription processing failed, enabling input');
    }
  }
}
