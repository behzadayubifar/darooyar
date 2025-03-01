import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/prescription_message_entity.dart';
import '../providers/prescription_providers.dart';

class MessageBubble extends HookConsumerWidget {
  final PrescriptionMessageEntity message;
  final VoidCallback onDelete;
  final Function(String) onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = useState(false);
    final textController = useTextEditingController(text: message.content);

    final isUserMessage = message.type == MessageType.user;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMessage ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEditing.value)
              TextField(
                controller: textController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  color:
                      isUserMessage ? Colors.white : AppTheme.textPrimaryColor,
                  fontSize: 16,
                ),
                autofocus: true,
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  color:
                      isUserMessage ? Colors.white : AppTheme.textPrimaryColor,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isUserMessage
                        ? Colors.white70
                        : AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (isUserMessage) ...[
                  if (isEditing.value) ...[
                    IconButton(
                      icon: const Icon(Icons.check, size: 18),
                      color: Colors.white,
                      onPressed: () {
                        onEdit(textController.text);
                        isEditing.value = false;
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.white,
                      onPressed: () {
                        textController.text = message.content;
                        isEditing.value = false;
                      },
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: Colors.white,
                      onPressed: () {
                        isEditing.value = true;
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: Colors.white,
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
