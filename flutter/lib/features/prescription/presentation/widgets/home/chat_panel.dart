import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_size.dart';
import '../../../domain/entities/prescription_message_entity.dart';
import '../../providers/prescription_providers.dart';
import '../message_bubble.dart';
import 'prescription_header.dart';

class ChatPanel extends ConsumerStatefulWidget {
  final String prescriptionId;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final bool showHistoryPanel;

  const ChatPanel({
    super.key,
    required this.prescriptionId,
    required this.scrollController,
    required this.messageController,
    required this.showHistoryPanel,
  });

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final selectedPrescriptionAsync = ref.watch(selectedPrescriptionProvider);
    final messagesAsync =
        ref.watch(prescriptionMessagesProvider(widget.prescriptionId));

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prescription header
            selectedPrescriptionAsync.when(
              data: (prescription) {
                if (prescription == null) {
                  return const SizedBox.shrink();
                }

                return PrescriptionHeader(
                  prescription: prescription,
                  showHistoryPanel: widget.showHistoryPanel,
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(AppStrings.deletePrescription),
                            content: const Text(
                                AppStrings.deletePrescriptionConfirmation),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text(AppStrings.cancel),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                ),
                                child: const Text(AppStrings.delete),
                              ),
                            ],
                          ),
                        ) ??
                        false;

                    if (confirmed && context.mounted) {
                      await ref.read(
                          deletePrescriptionProvider(prescription.id).future);
                      ref.invalidate(prescriptionsProvider);
                    }
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Messages list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * 0.7,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: ResponsiveSize.size(16),
                                  color: AppTheme.primaryColor.withOpacity(0.5),
                                ),
                                SizedBox(height: ResponsiveSize.vertical(2)),
                                Text(
                                  AppStrings.noPrescriptions,
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: ResponsiveSize.fontSize(16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return AnimationLimiter(
                      child: ListView.builder(
                        controller: widget.scrollController,
                        itemCount: messages.length,
                        padding: EdgeInsets.symmetric(
                            vertical: ResponsiveSize.vertical(2)),
                        itemBuilder: (context, index) {
                          final message = messages[index];

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 20.0,
                              child: FadeInAnimation(
                                child: MessageBubble(
                                  message: message,
                                  onDelete: () {
                                    if (message.type == MessageType.user) {
                                      ref.read(deleteMessageProvider(
                                        (
                                          messageId: message.id,
                                          prescriptionId: widget.prescriptionId
                                        ),
                                      ));
                                    }
                                  },
                                  onEdit: (newContent) {
                                    if (message.type == MessageType.user) {
                                      final updatedMessage =
                                          PrescriptionMessageEntity(
                                        id: message.id,
                                        prescriptionId: message.prescriptionId,
                                        type: message.type,
                                        content: newContent,
                                        timestamp: message.timestamp,
                                      );

                                      ref.read(updateMessageProvider(
                                          updatedMessage));
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child:
                        Text('${AppStrings.errorDisplay}${error.toString()}'),
                  ),
                ),
              ),
            ),

            // Message input
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.horizontal(2),
                vertical: ResponsiveSize.vertical(1),
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: ResponsiveSize.size(1),
                    offset: Offset(0, ResponsiveSize.size(-0.25)),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // For very small widths, stack the input and button vertically
                  if (constraints.maxWidth < ResponsiveSize.width(50)) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: widget.messageController,
                          decoration: InputDecoration(
                            hintText: AppStrings.messageHint,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(ResponsiveSize.size(6)),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResponsiveSize.horizontal(4),
                              vertical: ResponsiveSize.vertical(1),
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            prefixIcon: Icon(
                              Icons.chat_bubble_outline,
                              color: AppTheme.primaryColor,
                              size: ResponsiveSize.size(4.5),
                            ),
                          ),
                          maxLines: null,
                        ),
                        SizedBox(height: ResponsiveSize.vertical(1)),
                        SizedBox(
                          width: ResponsiveSize.size(10),
                          height: ResponsiveSize.size(10),
                          child: FloatingActionButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    final message =
                                        widget.messageController.text.trim();
                                    if (message.isNotEmpty) {
                                      _sendMessage(message);
                                    }
                                  },
                            mini: true,
                            child: _isLoading
                                ? SizedBox(
                                    width: ResponsiveSize.size(24),
                                    height: ResponsiveSize.size(24),
                                    child: CircularProgressIndicator(
                                      color: AppTheme.surfaceColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.send,
                                    size: ResponsiveSize.size(4.5)),
                          ),
                        ),
                      ],
                    );
                  }

                  // For normal widths, use the horizontal layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.messageController,
                          decoration: InputDecoration(
                            hintText: AppStrings.messageHint,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(ResponsiveSize.size(6)),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResponsiveSize.horizontal(4),
                              vertical: ResponsiveSize.vertical(1.5),
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            prefixIcon: Icon(
                              Icons.chat_bubble_outline,
                              color: AppTheme.primaryColor,
                              size: ResponsiveSize.size(24),
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.horizontal(2)),
                      SizedBox(
                        width: ResponsiveSize.size(48),
                        height: ResponsiveSize.size(48),
                        child: FloatingActionButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  final message =
                                      widget.messageController.text.trim();
                                  if (message.isNotEmpty) {
                                    _sendMessage(message);
                                  }
                                },
                          mini: true,
                          child: _isLoading
                              ? SizedBox(
                                  width: ResponsiveSize.size(24),
                                  height: ResponsiveSize.size(24),
                                  child: CircularProgressIndicator(
                                    color: AppTheme.surfaceColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.send, size: ResponsiveSize.size(32)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(sendFollowUpMessageProvider((
        prescriptionId: widget.prescriptionId,
        message: message,
      )).future);

      widget.messageController.clear();

      // Scroll to the bottom after a short delay to ensure the new message is rendered
      Future.delayed(const Duration(milliseconds: 300), () {
        if (widget.scrollController.hasClients) {
          widget.scrollController.animateTo(
            widget.scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.errorGeneric} $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
