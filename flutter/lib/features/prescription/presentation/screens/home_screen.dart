import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/entities/prescription_message_entity.dart';
import '../providers/prescription_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/prescription_list_item.dart';
import 'new_prescription_screen.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(prescriptionsProvider);
    final selectedPrescriptionId = ref.watch(selectedPrescriptionIdProvider);

    final messageController = useTextEditingController();
    final scrollController = useScrollController();

    // Scroll to bottom when new messages are added
    useEffect(() {
      if (selectedPrescriptionId != null) {
        final messagesAsync =
            ref.watch(prescriptionMessagesProvider(selectedPrescriptionId));
        messagesAsync.whenData((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        });
      }
      return null;
    }, [selectedPrescriptionId]);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewPrescriptionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: prescriptionsAsync.when(
        data: (prescriptions) {
          if (prescriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.medical_information,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    AppStrings.noHistoryMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewPrescriptionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(AppStrings.newPrescription),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              // Prescription list (left panel)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.backgroundColor,
                      child: Text(
                        AppStrings.prescriptionHistory,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: prescriptions.length,
                        itemBuilder: (context, index) {
                          final prescription = prescriptions[index];
                          final isSelected =
                              prescription.id == selectedPrescriptionId;

                          return PrescriptionListItem(
                            prescription: prescription,
                            isSelected: isSelected,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                color: AppTheme.dividerColor,
              ),

              // Chat panel (right panel)
              Expanded(
                child: selectedPrescriptionId == null
                    ? Center(
                        child: Text(
                          AppStrings.selectPrescription,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      )
                    : _buildChatPanel(
                        context,
                        ref,
                        selectedPrescriptionId,
                        scrollController,
                        messageController,
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('${AppStrings.errorDisplay}${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildChatPanel(
    BuildContext context,
    WidgetRef ref,
    String prescriptionId,
    ScrollController scrollController,
    TextEditingController messageController,
  ) {
    final selectedPrescriptionAsync = ref.watch(selectedPrescriptionProvider);
    final messagesAsync =
        ref.watch(prescriptionMessagesProvider(prescriptionId));

    return Column(
      children: [
        // Prescription title
        selectedPrescriptionAsync.when(
          data: (prescription) {
            if (prescription == null) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.backgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prescription.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (prescription.imageUrl != null)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppBar(
                                  title: Text(AppStrings.prescriptionImage),
                                  automaticallyImplyLeading: false,
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                Image.file(
                                  File(prescription.imageUrl!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(AppStrings.errorImageUpload),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(
                            File(prescription.imageUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported);
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Messages list
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(
                  child: Text(AppStrings.noPrescriptions),
                );
              }

              return ListView.builder(
                controller: scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];

                  return MessageBubble(
                    message: message,
                    onDelete: () {
                      if (message.type == MessageType.user) {
                        ref.read(deleteMessageProvider(
                          (
                            messageId: message.id,
                            prescriptionId: prescriptionId
                          ),
                        ));
                      }
                    },
                    onEdit: (newContent) {
                      if (message.type == MessageType.user) {
                        final updatedMessage = PrescriptionMessageEntity(
                          id: message.id,
                          prescriptionId: message.prescriptionId,
                          type: message.type,
                          content: newContent,
                          timestamp: message.timestamp,
                        );

                        ref.read(updateMessageProvider(updatedMessage));
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('${AppStrings.errorDisplay}${error.toString()}'),
            ),
          ),
        ),

        // Message input
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: AppStrings.messageHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () {
                  final message = messageController.text.trim();
                  if (message.isNotEmpty) {
                    ref.read(sendFollowUpMessageProvider(
                      (prescriptionId: prescriptionId, message: message),
                    ));
                    messageController.clear();
                  }
                },
                mini: true,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
