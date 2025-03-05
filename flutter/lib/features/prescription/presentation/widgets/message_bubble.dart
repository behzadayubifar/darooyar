import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_size.dart';
import '../../domain/entities/prescription_message_entity.dart';
import 'structured_medication_info.dart';

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
    final isHovering = useState(false);

    final isUserMessage = message.type == MessageType.user;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: MouseRegion(
        onEnter: (_) => isHovering.value = true,
        onExit: (_) => isHovering.value = false,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveSize.width(isUserMessage ? 75 : 90),
          ),
          margin: EdgeInsets.symmetric(
              vertical: ResponsiveSize.vertical(1),
              horizontal: ResponsiveSize.horizontal(4)),
          decoration: BoxDecoration(
            color: isUserMessage ? AppTheme.primaryColor : AppTheme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(ResponsiveSize.size(20)),
              topRight: Radius.circular(ResponsiveSize.size(20)),
              bottomLeft: isUserMessage
                  ? Radius.circular(ResponsiveSize.size(20))
                  : Radius.circular(ResponsiveSize.size(4)),
              bottomRight: isUserMessage
                  ? Radius.circular(ResponsiveSize.size(4))
                  : Radius.circular(ResponsiveSize.size(20)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: ResponsiveSize.size(8),
                offset: Offset(0, ResponsiveSize.size(2)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message content
              Padding(
                padding: isUserMessage
                    ? EdgeInsets.fromLTRB(
                        ResponsiveSize.horizontal(4),
                        ResponsiveSize.vertical(2),
                        ResponsiveSize.horizontal(4),
                        ResponsiveSize.vertical(1))
                    : EdgeInsets.fromLTRB(
                        ResponsiveSize.horizontal(4),
                        ResponsiveSize.vertical(2),
                        ResponsiveSize.horizontal(4),
                        ResponsiveSize.vertical(1)),
                child: isEditing.value
                    ? TextField(
                        controller: textController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          color: isUserMessage
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                          fontSize: ResponsiveSize.fontSize(16),
                        ),
                        autofocus: true,
                      )
                    : isUserMessage
                        ? Text(
                            message.content,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveSize.fontSize(16),
                              height: 1.4,
                            ),
                          )
                        : StructuredMedicationInfo(content: message.content),
              ),

              // Message footer with timestamp and actions
              Container(
                padding: EdgeInsets.fromLTRB(ResponsiveSize.horizontal(4), 0,
                    ResponsiveSize.horizontal(4), ResponsiveSize.vertical(1.5)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: ResponsiveSize.size(8),
                      children: [
                        // Timestamp
                        Container(
                          constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.3),
                          child: Text(
                            '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: isUserMessage
                                  ? Colors.white70
                                  : AppTheme.textSecondaryColor,
                              fontSize: ResponsiveSize.fontSize(12),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Action buttons for user messages
                        if (isUserMessage &&
                            (isHovering.value || isEditing.value))
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEditing.value) ...[
                                // Save button
                                AnimatedOpacity(
                                  opacity: isEditing.value ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: Icon(Icons.check,
                                        size: ResponsiveSize.size(18)),
                                    color: Colors.white,
                                    onPressed: () {
                                      onEdit(textController.text);
                                      isEditing.value = false;
                                    },
                                    tooltip: 'Save changes',
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: ResponsiveSize.size(24),
                                      minHeight: ResponsiveSize.size(24),
                                    ),
                                  ),
                                ),
                                // Cancel button
                                AnimatedOpacity(
                                  opacity: isEditing.value ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: Icon(Icons.close,
                                        size: ResponsiveSize.size(18)),
                                    color: Colors.white,
                                    onPressed: () {
                                      textController.text = message.content;
                                      isEditing.value = false;
                                    },
                                    tooltip: 'Cancel editing',
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: ResponsiveSize.size(24),
                                      minHeight: ResponsiveSize.size(24),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Edit button
                                AnimatedOpacity(
                                  opacity: isHovering.value ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: Icon(Icons.edit_outlined,
                                        size: ResponsiveSize.size(18)),
                                    color: Colors.white,
                                    onPressed: () {
                                      isEditing.value = true;
                                    },
                                    tooltip: 'Edit message',
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: ResponsiveSize.size(24),
                                      minHeight: ResponsiveSize.size(24),
                                    ),
                                  ),
                                ),
                                // Delete button
                                AnimatedOpacity(
                                  opacity: isHovering.value ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: ResponsiveSize.size(18)),
                                    color: Colors.white,
                                    onPressed: onDelete,
                                    tooltip: 'Delete message',
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: ResponsiveSize.size(24),
                                      minHeight: ResponsiveSize.size(24),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
