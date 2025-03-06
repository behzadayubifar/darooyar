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

  Widget _buildMessageContent(
      String content, bool isImage, bool isLoading, bool isThinking) {
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: content,
              placeholder: (context, url) => const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
              fit: BoxFit.cover,
              width: 200,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'تصویر نسخه',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      );
    }

    // Check if the message contains any of the structured AI content patterns
    if (content.contains('۱. تشخیص احتمالی') ||
        content.contains('۲. تداخلات مهم') ||
        content.contains('۳. عوارض مهم') ||
        MessageFormatter.isPrescriptionAnalysis(content) ||
        MessageFormatter.isStructuredFormat(content)) {
      // Format the message if needed
      String formattedContent = MessageFormatter.isStructuredFormat(content)
          ? content
          : MessageFormatter.formatAIMessage(content);

      // If we have a properly structured message, build expandable panels
      if (MessageFormatter.isStructuredFormat(formattedContent)) {
        // Split the content into sections based on the -next- delimiter
        List<String> sections = formattedContent.split('-next-');

        // The first section is typically the medication list or a summary
        String header = sections.isNotEmpty ? sections[0].trim() : '';

        // Create a list of expandable panels for each content section after the first
        List<Widget> panels = [];

        if (sections.length > 1) {
          // Process the remaining sections
          String remainingContent = sections.sublist(1).join('\n').trim();

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

          // Split into sections based on the numbered sections
          Map<String, String> contentSections = {};
          String currentSection = 'پاسخ داروخانه';
          String currentContent = '';

          // Process each line to extract sections
          for (String line in remainingContent.split('\n')) {
            bool isNewSection = false;

            for (String title in sectionTitles) {
              if (line.trim().startsWith(title)) {
                // Save previous section if it has content
                if (currentContent.isNotEmpty) {
                  contentSections[currentSection] = currentContent.trim();
                }

                // Start new section
                currentSection = line.trim();
                currentContent = '';
                isNewSection = true;
                break;
              }
            }

            if (!isNewSection) {
              currentContent += '$line\n';
            }
          }

          // Add the final section
          if (currentContent.isNotEmpty) {
            contentSections[currentSection] = currentContent.trim();
          }

          // Create a panel for each section
          contentSections.forEach((title, content) {
            // Choose a different color for each panel based on content
            Color panelColor;
            IconData panelIcon;

            if (title.contains('تشخیص')) {
              panelColor = Colors.blue;
              panelIcon = Icons.medical_information;
            } else if (title.contains('تداخلات')) {
              panelColor = Colors.orange;
              panelIcon = Icons.warning_amber;
            } else if (title.contains('عوارض')) {
              panelColor = Colors.red;
              panelIcon = Icons.health_and_safety;
            } else if (title.contains('زمان')) {
              panelColor = Colors.purple;
              panelIcon = Icons.access_time;
            } else if (title.contains('نحوه')) {
              panelColor = Colors.teal;
              panelIcon = Icons.food_bank;
            } else if (title.contains('تعداد')) {
              panelColor = Colors.green;
              panelIcon = Icons.numbers;
            } else if (title.contains('مدیریت')) {
              panelColor = Colors.brown;
              panelIcon = Icons.settings;
            } else {
              panelColor = Colors.indigo;
              panelIcon = Icons.info;
            }

            panels.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ExpandablePanel(
                  title: title,
                  content: content,
                  color: panelColor,
                  icon: panelIcon,
                  initiallyExpanded: false,
                ),
              ),
            );
          });
        }

        // Return a column with the header text and all the panels
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (first section with medications list)
            if (header.isNotEmpty)
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
      }
    }

    // Process Markdown-like formatting in text for regular messages
    try {
      // Format the text for better readability - especially AI responses
      // This is a simple approach without using external packages

      // Replace bold markers
      final processedContent = content
          .replaceAllMapped(
            RegExp(r'\*\*(.*?)\*\*'),
            (match) => match.group(1) ?? '', // Remove ** markers
          )
          // Replace bullet points with proper bullets
          .replaceAllMapped(
            RegExp(r'^\s*\*\s+(.*?)$', multiLine: true),
            (match) => '• ${match.group(1) ?? ''}',
          )
          // Keep numbering in numbered lists
          .replaceAllMapped(
            RegExp(r'^\s*(\d+)\.\s+(.*?)$', multiLine: true),
            (match) => '${match.group(1)}. ${match.group(2) ?? ''}',
          );

      return Text(
        processedContent,
        style: const TextStyle(
          color: Colors.white,
          height: 1.5, // Increased line height for better readability
        ),
      );
    } catch (e) {
      // Fallback to simple text if processing fails
      return Text(
        content,
        style: const TextStyle(color: Colors.white),
      );
    }
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
                                      isImage, isLoading, isThinking),
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
