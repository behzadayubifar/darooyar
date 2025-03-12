import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/message_formatter.dart';
import '../models/message.dart';
import 'message_actions.dart';
import '../../../features/prescription/presentation/widgets/expandable_panel.dart';

/// ویجت نمایش حباب پیام با دکمه‌های عملیات
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isUser;
  final bool isError;
  final bool isLoading;
  final bool isThinking;
  final bool isImage;
  final Widget messageContent;
  final VoidCallback? onRetry;
  final Function(bool)? onPanelExpansionChanged;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.isError,
    required this.isLoading,
    required this.isThinking,
    required this.isImage,
    required this.messageContent,
    this.onRetry,
    this.onPanelExpansionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : (message.role == 'assistant' &&
                  (message.content.contains('۱. تشخیص احتمالی') ||
                      message.content.contains('۲. تداخلات مهم') ||
                      message.content.contains('۳. عوارض مهم') ||
                      MessageFormatter.isPrescriptionAnalysis(
                          message.content) ||
                      MessageFormatter.isStructuredFormat(message.content)))
              ? Alignment.center
              : Alignment.centerLeft,
      // Use NotificationListener for touch/drag scrolling and Listener for mouse wheel
      child: NotificationListener<ScrollNotification>(
        // Allow scroll notifications to propagate to parent
        onNotification: (ScrollNotification notification) {
          // Return false to allow the notification to continue to be dispatched to further ancestors
          return false;
        },
        child: Listener(
          // Handle mouse wheel events
          onPointerSignal: (PointerSignalEvent event) {
            // Do nothing, allowing the event to propagate to parent
          },
          // Use IgnorePointer to specifically ignore drag gestures for scrolling but keep taps for actions
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
                          (message.content.contains('۱. تشخیص احتمالی') ||
                              message.content.contains('۲. تداخلات مهم') ||
                              message.content.contains('۳. عوارض مهم') ||
                              MessageFormatter.isPrescriptionAnalysis(
                                  message.content) ||
                              MessageFormatter.isStructuredFormat(
                                  message.content))
                      ? MediaQuery.of(context).size.width * 0.85
                      : MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pass the onPanelExpansionChanged callback to the content
                NotificationListener<ExpandablePanelExpansionNotification>(
                  onNotification: (notification) {
                    if (onPanelExpansionChanged != null) {
                      onPanelExpansionChanged!(notification.isExpanded);
                    }
                    return false;
                  },
                  child: messageContent,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        message.createdAt.toLocal().toString().split('.')[0],
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser || isError
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // اضافه کردن دکمه‌های عملیات
                    MessageActions(
                      content: message.content,
                      isUser: isUser,
                      isError: isError,
                      isLoading: isLoading,
                      isThinking: isThinking,
                      isImage: isImage,
                      onRetry: isError ? onRetry : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
