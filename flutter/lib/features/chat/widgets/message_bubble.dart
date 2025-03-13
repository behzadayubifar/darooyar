import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/message_formatter.dart';
import '../models/message.dart';
import 'message_actions.dart';
import '../../../features/prescription/presentation/widgets/expandable_panel.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// ویجت نمایش حباب پیام با دکمه‌های عملیات
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isUser;
  final bool isError;
  final bool isLoading;
  final bool isThinking;
  final bool isImage;
  final Widget messageContent;
  final VoidCallback? onRetry;
  final dynamic onPanelExpansionChanged;

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
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final ValueNotifier<bool> isHovering = ValueNotifier<bool>(false);

  @override
  void dispose() {
    isHovering.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isUser
          ? Alignment.centerRight
          : (widget.message.role == 'assistant' &&
                  (widget.message.content.contains('۱. تشخیص احتمالی') ||
                      widget.message.content.contains('۲. تداخلات مهم') ||
                      widget.message.content.contains('۳. عوارض مهم') ||
                      MessageFormatter.isPrescriptionAnalysis(
                          widget.message.content) ||
                      MessageFormatter.isStructuredFormat(
                          widget.message.content)))
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
          onPointerSignal: (PointerSignalEvent event) {
            // Do nothing, allowing the event to propagate to parent
          },
          child: MouseRegion(
            onEnter: (_) => isHovering.value = true,
            onExit: (_) => isHovering.value = false,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isError
                    ? Colors.red[700]
                    : widget.isThinking
                        ? Colors.blue[700]
                        : widget.isUser
                            ? AppTheme.primaryColor
                            : const Color.fromARGB(255, 36, 47, 61),
                borderRadius: BorderRadius.circular(16),
              ),
              constraints: BoxConstraints(
                maxWidth: widget.isThinking || widget.isError
                    ? MediaQuery.of(context).size.width * 0.75
                    : widget.message.role == 'assistant' &&
                            (widget.message.content
                                    .contains('۱. تشخیص احتمالی') ||
                                widget.message.content
                                    .contains('۲. تداخلات مهم') ||
                                widget.message.content
                                    .contains('۳. عوارض مهم') ||
                                MessageFormatter.isPrescriptionAnalysis(
                                    widget.message.content) ||
                                MessageFormatter.isStructuredFormat(
                                    widget.message.content))
                        ? MediaQuery.of(context).size.width * 0.85
                        : MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pass the onPanelExpansionChanged callback to the content
                  NotificationListener<ExpandablePanelExpansionNotification>(
                    onNotification: (notification) {
                      if (widget.onPanelExpansionChanged != null) {
                        try {
                          // Try to call with two parameters
                          widget.onPanelExpansionChanged(
                              notification.isExpanded, notification.panelId);
                        } catch (e) {
                          // If that fails, try with one parameter
                          try {
                            (widget.onPanelExpansionChanged as Function(
                                bool))(notification.isExpanded);
                          } catch (e) {
                            // Ignore if both fail
                          }
                        }
                      }
                      return false;
                    },
                    child: widget.messageContent,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.message.createdAt
                              .toLocal()
                              .toString()
                              .split('.')[0],
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isUser || widget.isError
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // اضافه کردن دکمه‌های عملیات
                      MessageActions(
                        content: widget.message.content,
                        isUser: widget.isUser,
                        isError: widget.isError,
                        isLoading: widget.isLoading,
                        isThinking: widget.isThinking,
                        isImage: widget.isImage,
                        onRetry: widget.isError ? widget.onRetry : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
