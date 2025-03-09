import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/message_formatter.dart';
import '../../prescription/presentation/widgets/expandable_panel.dart';
import '../models/chat.dart';
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
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
        ref
            .read(messageListProvider(widget.chat.id).notifier)
            .sendImageMessage(pickedFile.path);

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
      ),
      builder: (context) => Padding(
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
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.title),
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
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.medical_services,
                    color: _showPrescriptionOptions
                        ? AppTheme.primaryColor
                        : Colors.grey,
                  ),
                  onPressed: _showPrescriptionOptionsDialog,
                  tooltip: 'ارسال نسخه',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'پیام خود را بنویسید...',
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
                    onSubmitted: (_) {
                      // این متد دیگر فراخوانی نمی‌شود چون textInputAction به newline تغییر کرده است
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      final messageText = _messageController.text;
                      _messageController.clear();

                      ref
                          .read(messageListProvider(widget.chat.id).notifier)
                          .sendMessage(messageText)
                          .catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error.toString()),
                            backgroundColor: AppTheme.errorColor,
                            action: SnackBarAction(
                              label: 'خرید اشتراک',
                              onPressed: () {
                                // Navigate to subscription screen
                                Navigator.pushNamed(context, '/subscription');
                              },
                            ),
                          ),
                        );
                        return null;
                      });

                      // اسکرول به پایین پس از ارسال پیام
                      Future.delayed(
                          const Duration(milliseconds: 300), _scrollToBottom);
                    }
                  },
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
