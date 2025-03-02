import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
    final showHistoryPanel = ref.watch(showHistoryPanelProvider);

    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // Animation for panel sliding
    final panelAnimation = useAnimation(
      Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      )),
    );

    // Control animation based on panel visibility
    useEffect(() {
      if (showHistoryPanel) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [showHistoryPanel]);

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

    // Hide history panel when a prescription is selected
    useEffect(() {
      if (selectedPrescriptionId != null) {
        Future.microtask(() {
          ref.read(showHistoryPanelProvider.notifier).state = false;
        });
      }
      return null;
    }, [selectedPrescriptionId]);

    // Handle back button press
    Future<bool> handleBackPress() async {
      if (selectedPrescriptionId != null) {
        // If a prescription is selected, clear it and show history panel
        ref.read(selectedPrescriptionIdProvider.notifier).select(null);
        // Use Future.microtask to avoid updating state during build
        Future.microtask(() {
          ref.read(showHistoryPanelProvider.notifier).state = true;
        });
        return false; // Prevent default back behavior
      }
      return true; // Allow default back behavior (exit app)
    }

    return WillPopScope(
      onWillPop: handleBackPress,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          elevation: 0,
          centerTitle: false,
          titleSpacing: 8,
          actions: [
            // Always show history button in app bar
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                ref.read(showHistoryPanelProvider.notifier).state = true;
              },
              tooltip: AppStrings.prescriptionHistory,
            ),
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
              tooltip: AppStrings.newPrescription,
            ),
          ],
        ),
        body: prescriptionsAsync.when(
          data: (prescriptions) {
            if (prescriptions.isEmpty) {
              return _buildEmptyState(context);
            }

            return Column(
              children: [
                // Help text at the top
                Visibility(
                  visible: selectedPrescriptionId == null && !showHistoryPanel,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.selectPrescription,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "برای مشاهده جزئیات و گفتگو، یک نسخه را از فهرست انتخاب کنید",
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main content area with history panel and chat
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Prescription list (left panel) - conditionally show based on showHistoryPanel
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: showHistoryPanel
                              ? MediaQuery.of(context).size.width * 0.9
                              : 0,
                          curve: Curves.easeInOut,
                          child: showHistoryPanel
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.shadowColor,
                                        blurRadius: 5,
                                        offset: const Offset(2, 0),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.backgroundColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.shadowColor,
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.history,
                                                    size: 20,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Flexible(
                                                    child: Text(
                                                      AppStrings
                                                          .prescriptionHistory,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                              onPressed: () {
                                                ref
                                                    .read(
                                                        showHistoryPanelProvider
                                                            .notifier)
                                                    .state = false;
                                              },
                                              tooltip: 'Close history panel',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: AnimationLimiter(
                                          child: ListView.builder(
                                            itemCount: prescriptions.length,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            itemBuilder: (context, index) {
                                              final prescription =
                                                  prescriptions[index];
                                              final isSelected =
                                                  prescription.id ==
                                                      selectedPrescriptionId;

                                              return AnimationConfiguration
                                                  .staggeredList(
                                                position: index,
                                                duration: const Duration(
                                                    milliseconds: 375),
                                                child: SlideAnimation(
                                                  verticalOffset: 50.0,
                                                  child: FadeInAnimation(
                                                    child: PrescriptionListItem(
                                                      prescription:
                                                          prescription,
                                                      isSelected: isSelected,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),

                        // Chat panel (right panel)
                        if (!showHistoryPanel)
                          Expanded(
                            child: selectedPrescriptionId == null
                                ? Container() // Empty container instead of the icon
                                : _buildChatPanel(
                                    context,
                                    ref,
                                    selectedPrescriptionId,
                                    scrollController,
                                    messageController,
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${AppStrings.errorDisplay}${error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: prescriptionsAsync.maybeWhen(
          data: (prescriptions) {
            if (prescriptions.isEmpty) {
              return FloatingActionButton.extended(
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
              );
            }
            // Remove the history button FAB
            return null;
          },
          orElse: () => null,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: AnimationLimiter(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_information,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                AppStrings.noHistoryMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'برای شروع، یک نسخه جدید اضافه کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
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
    final showHistoryPanel = ref.watch(showHistoryPanelProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prescription title
            selectedPrescriptionAsync.when(
              data: (prescription) {
                if (prescription == null) {
                  return const SizedBox.shrink();
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowColor,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // For very narrow widths, use a more compact layout
                      if (constraints.maxWidth < 150) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Back button only for very narrow widths
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: AppTheme.primaryColor,
                                  size: 16,
                                ),
                                onPressed: () {
                                  // Clear selected prescription
                                  ref
                                      .read(selectedPrescriptionIdProvider
                                          .notifier)
                                      .select(null);
                                  // Show history panel
                                  ref
                                      .read(showHistoryPanelProvider.notifier)
                                      .state = true;
                                },
                                tooltip: 'Back to prescription list',
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                iconSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                prescription.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        );
                      }

                      // For normal widths, use the standard layout
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // History toggle button
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return RotationTransition(
                                    turns: Tween<double>(begin: 0.5, end: 1.0)
                                        .animate(animation),
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Icon(
                                  showHistoryPanel
                                      ? Icons.menu_open
                                      : Icons.menu,
                                  key: ValueKey<bool>(showHistoryPanel),
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(showHistoryPanelProvider.notifier)
                                    .state = !showHistoryPanel;
                              },
                              tooltip: showHistoryPanel
                                  ? 'Hide prescription history'
                                  : 'Show prescription history',
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Back button
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppTheme.primaryColor,
                                size: 18,
                              ),
                              onPressed: () {
                                // Clear selected prescription
                                ref
                                    .read(
                                        selectedPrescriptionIdProvider.notifier)
                                    .select(null);
                                // Show history panel
                                ref
                                    .read(showHistoryPanelProvider.notifier)
                                    .state = true;
                              },
                              tooltip: 'Back to prescription list',
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              prescription.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (prescription.imageUrl != null)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppBar(
                                          title: Text(
                                              AppStrings.prescriptionImage),
                                          automaticallyImplyLeading: false,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                          ),
                                          actions: [
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                          ],
                                        ),
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.8,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.6,
                                            child: Image.file(
                                              File(prescription.imageUrl!),
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Text(AppStrings
                                                      .errorImageUpload),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: 'prescription_image_${prescription.id}',
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppTheme.dividerColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.shadowColor,
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.file(
                                      File(prescription.imageUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.image_not_supported,
                                          size: 16,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Messages list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
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
                                  size: 64,
                                  color: AppTheme.primaryColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  AppStrings.noPrescriptions,
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 16,
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
                        controller: scrollController,
                        itemCount: messages.length,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                          prescriptionId: prescriptionId
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // For very small widths, stack the input and button vertically
                  if (constraints.maxWidth < 200) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: AppStrings.messageHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            prefixIcon: const Icon(
                              Icons.chat_bubble_outline,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: FloatingActionButton(
                            onPressed: () {
                              final message = messageController.text.trim();
                              if (message.isNotEmpty) {
                                ref.read(sendFollowUpMessageProvider(
                                  (
                                    prescriptionId: prescriptionId,
                                    message: message
                                  ),
                                ));
                                messageController.clear();
                              }
                            },
                            mini: true,
                            child: const Icon(Icons.send, size: 18),
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
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            prefixIcon: const Icon(
                              Icons.chat_bubble_outline,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: FloatingActionButton(
                          onPressed: () {
                            final message = messageController.text.trim();
                            if (message.isNotEmpty) {
                              ref.read(sendFollowUpMessageProvider(
                                (
                                  prescriptionId: prescriptionId,
                                  message: message
                                ),
                              ));
                              messageController.clear();
                            }
                          },
                          mini: true,
                          child: const Icon(Icons.send),
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
}
