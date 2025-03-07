import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    'نتیجه گیری': {
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
  };

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

    // Replace stars with better decorative elements
    content = content.replaceAll('***', '✧✧✧');
    content = content.replaceAll('**', '✧✧');
    content = content.replaceAll('*', '✧');

    // Split the content into paragraphs
    final paragraphs =
        content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    // If there's only one short paragraph, just show it as text
    if (paragraphs.length == 1 && paragraphs[0].length < 100) {
      return Text(
        paragraphs[0],
        style: const TextStyle(
          color: Colors.white,
          height: 1.5,
        ),
      );
    }

    // Process paragraphs into sections
    List<Map<String, String>> contentSections = [];

    // Check for medication list
    String medicationList = '';
    bool hasMedicationList = false;

    // Look for medication list patterns
    for (int i = 0; i < paragraphs.length; i++) {
      String paragraph = paragraphs[i].trim();

      // Check if this paragraph contains a medication list
      if (paragraph.contains('لیست داروها:') ||
          paragraph.contains('داروهای نسخه:') ||
          paragraph.contains('داروهای تجویز شده:') ||
          paragraph.startsWith('لیست داروها') ||
          paragraph.startsWith('داروهای نسخه') ||
          paragraph.startsWith('داروهای تجویز شده')) {
        medicationList = paragraph;
        hasMedicationList = true;
        AppLogger.d(
            'Found medication list: ${paragraph.substring(0, min(50, paragraph.length))}...');
        // Remove this paragraph from the list so we don't process it twice
        paragraphs.removeAt(i);
        i--;
        continue;
      }
    }

    // Try to identify logical sections in the content
    for (int i = 0; i < paragraphs.length; i++) {
      String paragraph = paragraphs[i].trim();
      String title = '';

      // Try to extract a title if possible
      if (paragraph.contains(':')) {
        final parts = paragraph.split(':');
        if (parts.length > 1 && parts[0].length < 40) {
          title = parts[0].trim();
          paragraph = parts.sublist(1).join(':').trim();
        }
      } else if (paragraph.startsWith('• ') ||
          paragraph.startsWith('- ') ||
          paragraph.startsWith('* ') ||
          paragraph.startsWith('✧ ')) {
        title = 'نکات مهم';
      } else if (i == 0) {
        title = 'خلاصه';
      } else if (i == paragraphs.length - 1) {
        title = 'نتیجه گیری';
      } else {
        // Use first few words as title
        final words = paragraph.split(' ');
        title = words.length > 3 ? words.take(3).join(' ') + '...' : paragraph;
      }

      contentSections.add({
        'title': title,
        'content': paragraph,
      });
    }

    // Add medication list as a separate section if found
    if (hasMedicationList) {
      // Try to extract just the list part if there's a title
      String listContent = medicationList;
      String listTitle = 'لیست داروها';

      if (medicationList.contains(':')) {
        final parts = medicationList.split(':');
        if (parts.length > 1 && parts[0].length < 40) {
          listTitle = parts[0].trim();
          listContent = parts.sublist(1).join(':').trim();
        }
      }

      // Add the medication list as the first section
      contentSections.insert(0, {
        'title': listTitle,
        'content': listContent,
      });
    }

    // Log the final sections for debugging
    AppLogger.d('Final sections:');
    for (final section in contentSections) {
      AppLogger.d(
          '- ${section['title']}: ${(section['content'] ?? '').length} chars');
    }

    // Calculate the maximum width for all panels to be the same width
    final double panelWidth = MediaQuery.of(context).size.width * 0.85;

    // Create a panel for each section
    List<Widget> panels = [];

    // Use a different color for each panel
    for (int i = 0; i < contentSections.length; i++) {
      final section = contentSections[i];
      final sectionTitle = section['title'] ?? 'بخش ${i + 1}';

      // Use specific style if available, otherwise use a unique style from the list
      Map<String, dynamic> style;
      if (this.specificStyles.containsKey(sectionTitle)) {
        style = this.specificStyles[sectionTitle]!;
      } else {
        // Ensure each panel gets a unique color by using the index
        style = this.sectionStyles[i % this.sectionStyles.length];
      }

      // Special style for medication list
      if (i == 0 && hasMedicationList) {
        style = {
          'color': Colors.deepPurple.shade700,
          'icon': Icons.medication_outlined
        };
      }

      panels.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ExpandablePanel(
            title: sectionTitle,
            content: section['content'] ?? '',
            color: style['color'] as Color,
            icon: style['icon'] as IconData,
            initiallyExpanded: i == 0, // Expand first section by default
            width: panelWidth, // Set the same width for all panels
          ),
        ),
      );
    }

    // Return a column with all the panels
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: panels,
    );
  }

  Widget _buildMessageContent(
      String content, bool isImage, bool isLoading, bool isThinking,
      {bool isUser = false}) {
    if (isLoading) {
      return Row(
        children: [
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            content,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    if (isThinking) {
      return Row(
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
              // Animation that makes it pulse
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            content,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    if (isImage) {
      // Debug URL in console for troubleshooting
      print('Attempting to load image from URL: $content');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: content.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: content,
                      cacheKey: "${content}_key", // Add a unique cache key
                      httpHeaders: {
                        'Accept': '*/*', // Try accepting all content types
                      },
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => SizedBox(
                        height: 160,
                        width: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  'در حال بارگذاری تصویر...\n$url',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        // Log error for debugging
                        print('Error loading image from $url: $error');

                        return GestureDetector(
                          onTap: () {
                            // Attempt to redownload the image on tap
                            CachedNetworkImage.evictFromCache(url);
                            setState(() {});
                          },
                          child: Container(
                            height: 160,
                            width: 200,
                            color: Colors.grey[800],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.white, size: 32),
                                  const SizedBox(height: 8),
                                  Flexible(
                                    child: Text(
                                      'خطا در بارگذاری تصویر\nلمس برای بارگذاری مجدد\n$url',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 10),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      fit: BoxFit.contain,
                    )
                  : Image.file(
                      File(content),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Log error for debugging
                        print(
                            'Error loading local image from $content: $error');
                        return Container(
                          height: 160,
                          width: 200,
                          color: Colors.grey[800],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.white, size: 32),
                                const SizedBox(height: 8),
                                Flexible(
                                  child: Text(
                                    'خطا در نمایش تصویر\n${error.toString().substring(0, error.toString().length > 40 ? 40 : error.toString().length)}',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 10),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تصویر نسخه',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              if (content.startsWith('http')) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    try {
                      // Try opening the image URL in browser
                      final Uri url = Uri.parse(content);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      print('Error launching URL: $e');
                    }
                  },
                  child: const Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    // For AI responses (not user messages)
    if (!isUser && !isThinking && !isLoading && !content.startsWith('خطا')) {
      // First, migrate the message if needed
      String migratedContent =
          MessageMigrationService.migrateAIMessage(content);

      // Remove the initial greeting message that starts with "با کمال میل"
      if (migratedContent.startsWith('با کمال میل') ||
          migratedContent.startsWith('با کمال')) {
        final firstNewlineIndex = migratedContent.indexOf('\n\n');
        if (firstNewlineIndex > 0) {
          migratedContent = migratedContent.substring(firstNewlineIndex).trim();
        }
      }

      // Replace stars with better decorative elements
      migratedContent = migratedContent.replaceAll('***', '✧✧✧');
      migratedContent = migratedContent.replaceAll('**', '✧✧');
      migratedContent = migratedContent.replaceAll('*', '✧');

      // Check if the message is in structured format
      if (migratedContent.contains('-next-')) {
        // Split the content into sections based on the -next- delimiter
        List<String> sections = migratedContent.split('-next-');

        // The first section is typically the introduction or summary
        String header = sections.isNotEmpty ? sections[0].trim() : '';

        // The second section contains the details
        String details = sections.length > 1 ? sections[1].trim() : '';

        // If we don't have details, just show the content as plain text
        if (details.isEmpty) {
          return Text(
            migratedContent,
            style: const TextStyle(
              color: Colors.white,
              height: 1.5,
            ),
          );
        }

        // Create expandable panels for the details section
        List<Widget> panels = [];

        // Try to identify logical sections in the details
        List<Map<String, String>> contentSections = [];

        // First check for prescription analysis sections
        if (MessageFormatter.isPrescriptionAnalysis(migratedContent)) {
          // Look for section titles
          List<String> sectionTitles = [
            '۱. تشخیص احتمالی',
            '۲. تداخلات مهم',
            '۳. عوارض مهم',
            '۴. زمان مصرف',
            '۵. نحوه مصرف',
            '۶. تعداد مصرف',
            '۷. مدیریت عارضه',
          ];

          // Additional patterns for detecting sections without numbers
          List<String> sectionPatterns = [
            'تشخیص احتمالی',
            'تداخلات',
            'تداخلات مهم',
            'تداخلات دارویی',
            'عوارض',
            'عوارض مهم',
            'عوارض شایع',
            'زمان مصرف',
            'نحوه مصرف',
            'تعداد مصرف',
            'مدیریت عارضه',
          ];

          // Check for medication list
          String medicationList = '';
          bool hasMedicationList = false;

          // Look for medication list in the details
          final paragraphs =
              details.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
          for (int i = 0; i < paragraphs.length; i++) {
            String paragraph = paragraphs[i].trim();

            // Check if this paragraph contains a medication list
            if (paragraph.contains('لیست داروها:') ||
                paragraph.contains('داروهای نسخه:') ||
                paragraph.contains('داروهای تجویز شده:') ||
                paragraph.startsWith('لیست داروها') ||
                paragraph.startsWith('داروهای نسخه') ||
                paragraph.startsWith('داروهای تجویز شده')) {
              medicationList = paragraph;
              hasMedicationList = true;
              AppLogger.d(
                  'Found medication list in structured format: ${paragraph.substring(0, min(50, paragraph.length))}...');
              break;
            }
          }

          // Split into sections based on the numbered sections
          String currentSection = 'پاسخ داروخانه';
          String currentContent = '';

          // For debugging
          AppLogger.d(
              'Processing prescription analysis content: ${details.length} chars');

          // Process each line to extract sections
          for (String line in details.split('\n')) {
            bool isNewSection = false;
            String trimmedLine = line.trim();

            // Skip medication list lines if we've already extracted it
            if (hasMedicationList && medicationList.contains(trimmedLine)) {
              continue;
            }

            // First check for numbered section titles
            for (String title in sectionTitles) {
              if (trimmedLine.startsWith(title)) {
                // Save previous section if it has content
                if (currentContent.isNotEmpty) {
                  AppLogger.d(
                      'Found section: $currentSection with ${currentContent.length} chars');
                  contentSections.add({
                    'title': currentSection,
                    'content': currentContent.trim(),
                  });
                }

                // Start new section
                currentSection = trimmedLine;
                currentContent = '';
                isNewSection = true;
                AppLogger.d('Starting new numbered section: $currentSection');
                break;
              }
            }

            // If not a numbered section, check for pattern-based sections
            if (!isNewSection) {
              for (String pattern in sectionPatterns) {
                // Check if line starts with pattern followed by colon or space
                if (trimmedLine.startsWith('$pattern:') ||
                    trimmedLine == pattern ||
                    (trimmedLine.startsWith(pattern) &&
                        trimmedLine.length > pattern.length &&
                        (trimmedLine[pattern.length] == ' ' ||
                            trimmedLine[pattern.length] == ':'))) {
                  // Save previous section if it has content
                  if (currentContent.isNotEmpty) {
                    AppLogger.d(
                        'Found section: $currentSection with ${currentContent.length} chars');
                    contentSections.add({
                      'title': currentSection,
                      'content': currentContent.trim(),
                    });
                  }

                  // Start new section
                  currentSection = trimmedLine;
                  currentContent = '';
                  isNewSection = true;
                  AppLogger.d('Starting new pattern section: $currentSection');
                  break;
                }
              }
            }

            // Special case for تداخلات section which might be embedded in another section
            if (!isNewSection &&
                currentContent.isNotEmpty &&
                (trimmedLine.startsWith('تداخلات:') ||
                    trimmedLine == 'تداخلات' ||
                    trimmedLine.startsWith('تداخلات دارویی') ||
                    trimmedLine.startsWith('تداخلات مهم'))) {
              // Save previous section
              AppLogger.d(
                  'Found embedded تداخلات section within: $currentSection');
              contentSections.add({
                'title': currentSection,
                'content': currentContent.trim(),
              });

              // Start تداخلات section
              currentSection = trimmedLine;
              currentContent = '';
              isNewSection = true;
            }

            if (!isNewSection) {
              currentContent += '$line\n';
            }
          }

          // Add the final section
          if (currentContent.isNotEmpty) {
            AppLogger.d(
                'Adding final section: $currentSection with ${currentContent.length} chars');
            contentSections.add({
              'title': currentSection,
              'content': currentContent.trim(),
            });
          }

          // Check if we have a تداخلات section, if not try to extract it from other sections
          bool hasInteractionsSection = contentSections.any((section) =>
              section['title']!.contains('تداخلات') ||
              section['title']!.contains('۲. تداخلات'));

          if (!hasInteractionsSection) {
            AppLogger.d('No تداخلات section found, searching in content');

            // Look for تداخلات in the content of other sections
            for (int i = 0; i < contentSections.length; i++) {
              String sectionContent = contentSections[i]['content'] ?? '';

              // Look for تداخلات paragraph in the content
              int interactionsIndex = sectionContent.indexOf('تداخلات:');
              if (interactionsIndex == -1) {
                interactionsIndex = sectionContent.indexOf('تداخلات ');
              }

              if (interactionsIndex >= 0) {
                AppLogger.d(
                    'Found تداخلات in section: ${contentSections[i]['title']}');

                // Extract the interactions part
                String beforeInteractions =
                    sectionContent.substring(0, interactionsIndex).trim();
                String interactionsPart =
                    sectionContent.substring(interactionsIndex).trim();

                // Update the original section with content before interactions
                contentSections[i]['content'] = beforeInteractions;

                // Add a new section for interactions
                contentSections.add({
                  'title': 'تداخلات',
                  'content': interactionsPart,
                });

                AppLogger.d('Split تداخلات into separate section');
                break;
              }
            }
          }

          // Add medication list as a separate section if found
          if (hasMedicationList) {
            // Try to extract just the list part if there's a title
            String listContent = medicationList;
            String listTitle = 'لیست داروها';

            if (medicationList.contains(':')) {
              final parts = medicationList.split(':');
              if (parts.length > 1 && parts[0].length < 40) {
                listTitle = parts[0].trim();
                listContent = parts.sublist(1).join(':').trim();
              }
            }

            // Add the medication list as the first section
            contentSections.insert(0, {
              'title': listTitle,
              'content': listContent,
            });
          }
        } else {
          // For general AI responses, split by paragraphs
          final paragraphs =
              details.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

          // Check for medication list
          String medicationList = '';
          bool hasMedicationList = false;

          // Look for medication list in the paragraphs
          for (int i = 0; i < paragraphs.length; i++) {
            String paragraph = paragraphs[i].trim();

            // Check if this paragraph contains a medication list
            if (paragraph.contains('لیست داروها:') ||
                paragraph.contains('داروهای نسخه:') ||
                paragraph.contains('داروهای تجویز شده:') ||
                paragraph.startsWith('لیست داروها') ||
                paragraph.startsWith('داروهای نسخه') ||
                paragraph.startsWith('داروهای تجویز شده')) {
              medicationList = paragraph;
              hasMedicationList = true;
              AppLogger.d(
                  'Found medication list in general format: ${paragraph.substring(0, min(50, paragraph.length))}...');
              // Remove this paragraph from the list so we don't process it twice
              paragraphs.removeAt(i);
              i--;
              continue;
            }
          }

          // Process each paragraph
          for (int i = 0; i < paragraphs.length; i++) {
            String paragraph = paragraphs[i].trim();
            String title = '';

            // Try to extract a title if possible
            if (paragraph.contains(':')) {
              final parts = paragraph.split(':');
              if (parts.length > 1 && parts[0].length < 40) {
                title = parts[0].trim();
                paragraph = parts.sublist(1).join(':').trim();
              }
            } else if (paragraph.startsWith('• ') ||
                paragraph.startsWith('- ') ||
                paragraph.startsWith('* ') ||
                paragraph.startsWith('✧ ')) {
              title = 'نکات مهم';
            } else if (i == paragraphs.length - 1) {
              title = 'نتیجه گیری';
            } else {
              // Use first few words as title
              final words = paragraph.split(' ');
              title = words.length > 3
                  ? words.take(3).join(' ') + '...'
                  : paragraph;
            }

            contentSections.add({
              'title': title,
              'content': paragraph,
            });
          }

          // Add medication list as a separate section if found
          if (hasMedicationList) {
            // Try to extract just the list part if there's a title
            String listContent = medicationList;
            String listTitle = 'لیست داروها';

            if (medicationList.contains(':')) {
              final parts = medicationList.split(':');
              if (parts.length > 1 && parts[0].length < 40) {
                listTitle = parts[0].trim();
                listContent = parts.sublist(1).join(':').trim();
              }
            }

            // Add the medication list as the first section
            contentSections.insert(0, {
              'title': listTitle,
              'content': listContent,
            });
          }
        }

        // Log the final sections for debugging
        AppLogger.d('Final sections:');
        for (final section in contentSections) {
          AppLogger.d(
              '- ${section['title']}: ${(section['content'] ?? '').length} chars');
        }

        // Calculate the maximum width for all panels to be the same width
        final double panelWidth = MediaQuery.of(context).size.width * 0.85;

        // Create a panel for each section with a unique color
        for (int i = 0; i < contentSections.length; i++) {
          final section = contentSections[i];
          final sectionTitle = section['title'] ?? 'بخش ${i + 1}';

          // Use specific style if available, otherwise use a unique style from the list
          Map<String, dynamic> style;
          if (this.specificStyles.containsKey(sectionTitle)) {
            style = this.specificStyles[sectionTitle]!;
          } else {
            // Ensure each panel gets a unique color by using the index
            style = this.sectionStyles[i % this.sectionStyles.length];
          }

          // Special style for medication list
          if (i == 0 &&
              (sectionTitle.contains('لیست داروها') ||
                  sectionTitle.contains('داروهای نسخه') ||
                  sectionTitle.contains('داروهای تجویز شده'))) {
            style = {
              'color': Colors.deepPurple.shade700,
              'icon': Icons.medication_outlined
            };
          }

          panels.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ExpandablePanel(
                title: sectionTitle,
                content: section['content'] ?? '',
                color: style['color'] as Color,
                icon: style['icon'] as IconData,
                initiallyExpanded: i == 0, // Expand first section by default
                width: panelWidth, // Set the same width for all panels
              ),
            ),
          );
        }

        // Return a column with the header text and all the panels
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text (skip if it's the greeting message)
            if (header.isNotEmpty &&
                !header.startsWith('با کمال میل') &&
                !header.startsWith('با کمال'))
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  header,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

            // Expandable panels for each section
            ...panels,
          ],
        );
      } else {
        // If not structured, use the AI response panel builder
        return _buildAIResponsePanels(migratedContent);
      }
    }

    // For user messages, just show the text
    return Text(
      content,
      style: const TextStyle(
        color: Colors.white,
        height: 1.5,
      ),
    );
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
                  _scrollToBottom();
                });

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(messageListProvider(widget.chat.id).notifier)
                      .loadMessages(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUser = message.role == 'user';
                      final isSystem = message.role == 'system';
                      final isImage = message.isImage;
                      final isLoading = message.isLoading;
                      final isError = message.isError;
                      final isThinking = message.isThinking;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : (message.role == 'assistant' &&
                                    (message.content
                                            .contains('۱. تشخیص احتمالی') ||
                                        message.content
                                            .contains('۲. تداخلات مهم') ||
                                        message.content
                                            .contains('۳. عوارض مهم') ||
                                        MessageFormatter.isPrescriptionAnalysis(
                                            message.content) ||
                                        MessageFormatter.isStructuredFormat(
                                            message.content)))
                                ? Alignment.center
                                : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isError
                                ? Colors.red[700]
                                : isThinking
                                    ? Colors.blue[700]
                                    : isUser
                                        ? AppTheme.primaryColor
                                        : const Color.fromARGB(255, 36, 47, 61),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: isThinking || isError
                                ? MediaQuery.of(context).size.width * 0.75
                                : message.role == 'assistant' &&
                                        (message.content
                                                .contains('۱. تشخیص احتمالی') ||
                                            message.content
                                                .contains('۲. تداخلات مهم') ||
                                            message.content
                                                .contains('۳. عوارض مهم') ||
                                            MessageFormatter
                                                .isPrescriptionAnalysis(
                                                    message.content) ||
                                            MessageFormatter.isStructuredFormat(
                                                message.content))
                                    ? MediaQuery.of(context).size.width * 0.85
                                    : MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              isError
                                  ? _buildErrorMessageContent(message.content)
                                  : _buildMessageContent(message.content,
                                      isImage, isLoading, isThinking,
                                      isUser: isUser),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    message.createdAt
                                        .toLocal()
                                        .toString()
                                        .split('.')[0],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isUser || isError
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  if (isError) ...[
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        // Retry sending the failed message
                                        final originalContent = message.content
                                            .split('\n')
                                            .first
                                            .replaceFirst(
                                                'خطا در ارسال پیام: ', '');
                                        if (originalContent.isNotEmpty) {
                                          ref
                                              .read(messageListProvider(
                                                      widget.chat.id)
                                                  .notifier)
                                              .sendMessage(originalContent);
                                        }
                                      },
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.refresh,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'تلاش مجدد',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
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
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (_messageController.text.isNotEmpty) {
                        ref
                            .read(messageListProvider(widget.chat.id).notifier)
                            .sendMessage(_messageController.text);
                        _messageController.clear();
                        Future.delayed(
                            const Duration(milliseconds: 100), _scrollToBottom);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      ref
                          .read(messageListProvider(widget.chat.id).notifier)
                          .sendMessage(_messageController.text);
                      _messageController.clear();
                      Future.delayed(
                          const Duration(milliseconds: 100), _scrollToBottom);
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
