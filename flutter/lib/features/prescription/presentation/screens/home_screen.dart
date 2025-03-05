import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_size.dart';
import '../providers/prescription_providers.dart';
import '../widgets/home/chat_panel.dart';
import '../widgets/home/empty_state.dart';
import '../widgets/home/help_message.dart';
import '../widgets/home/history_panel.dart';
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
          ref.read(showHistoryPanelProvider.notifier).update((state) => false);
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
          ref.read(showHistoryPanelProvider.notifier).update((state) => true);
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
                ref
                    .read(showHistoryPanelProvider.notifier)
                    .update((state) => true);
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
              return const EmptyState();
            }

            return Column(
              children: [
                // Help text at the top
                if (selectedPrescriptionId == null && !showHistoryPanel)
                  const HelpMessage(),

                // Main content area with history panel and chat
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Prescription list (left panel) - conditionally show based on showHistoryPanel
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width:
                              showHistoryPanel ? ResponsiveSize.width(90) : 0,
                          curve: Curves.easeInOut,
                          child: showHistoryPanel
                              ? HistoryPanel(
                                  prescriptions: prescriptions,
                                  selectedPrescriptionId:
                                      selectedPrescriptionId,
                                )
                              : null,
                        ),

                        // Chat panel (right panel)
                        if (!showHistoryPanel)
                          Expanded(
                            child: selectedPrescriptionId == null
                                ? Container() // Empty container instead of the icon
                                : ChatPanel(
                                    prescriptionId: selectedPrescriptionId,
                                    scrollController: scrollController,
                                    messageController: messageController,
                                    showHistoryPanel: showHistoryPanel,
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
              padding: EdgeInsets.all(ResponsiveSize.size(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: ResponsiveSize.size(48),
                  ),
                  SizedBox(height: ResponsiveSize.vertical(2)),
                  Text(
                    '${AppStrings.errorDisplay}${error.toString()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: ResponsiveSize.fontSize(16),
                    ),
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
        floatingActionButtonLocation:
            FloatingActionButtonLocation.startFloat, // Adjust for RTL layout
      ),
    );
  }
}
