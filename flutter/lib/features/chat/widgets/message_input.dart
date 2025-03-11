import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/chat.dart';
import '../providers/message_providers.dart';
import '../../../core/theme/app_theme.dart';

/// Widget for inputting and sending messages in a chat
class MessageInput extends HookConsumerWidget {
  final Chat chat;
  final ScrollController scrollController;
  final bool isPrescriptionProcessing;
  final Function(bool) onPrescriptionProcessingChanged;
  final VoidCallback? onMessageSent;

  const MessageInput({
    Key? key,
    required this.chat,
    required this.scrollController,
    required this.isPrescriptionProcessing,
    required this.onPrescriptionProcessingChanged,
    this.onMessageSent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final isTyping = useState(false);
    final isSending = useState(false);

    // Send message function
    void sendMessage() async {
      final message = textController.text.trim();
      if (message.isEmpty || isSending.value) return;

      isSending.value = true;
      textController.clear();
      isTyping.value = false;

      try {
        await ref
            .read(messageListProvider(chat.id).notifier)
            .sendMessage(message);
        if (onMessageSent != null) {
          onMessageSent!();
        }
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال پیام: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        isSending.value = false;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Send button
          IconButton(
            icon: Icon(
              isSending.value ? Icons.hourglass_empty : Icons.send,
              color: AppTheme.primaryColor,
            ),
            onPressed: isSending.value || isPrescriptionProcessing
                ? null
                : sendMessage,
          ),

          // Text input field
          Expanded(
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: isPrescriptionProcessing
                    ? 'در حال تحلیل نسخه...'
                    : 'پیام خود را بنویسید...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              textDirection: TextDirection.rtl,
              maxLines: null,
              enabled: !isPrescriptionProcessing,
              onChanged: (value) {
                isTyping.value = value.trim().isNotEmpty;
              },
              onSubmitted: (_) {
                if (!isPrescriptionProcessing) {
                  sendMessage();
                }
              },
            ),
          ),

          // Attachment button
          IconButton(
            icon: const Icon(
              Icons.attach_file,
              color: AppTheme.primaryColor,
            ),
            onPressed: isPrescriptionProcessing
                ? null
                : () {
                    // Handle attachment
                  },
          ),
        ],
      ),
    );
  }
}
