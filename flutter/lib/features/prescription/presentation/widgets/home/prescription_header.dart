import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_size.dart';
import '../../../domain/entities/prescription_entity.dart';
import '../../providers/prescription_providers.dart';

class PrescriptionHeader extends ConsumerWidget {
  final PrescriptionEntity prescription;
  final bool showHistoryPanel;
  final VoidCallback onDelete;

  const PrescriptionHeader({
    super.key,
    required this.prescription,
    required this.showHistoryPanel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveSize.vertical(1.5),
        horizontal: ResponsiveSize.horizontal(3),
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: ResponsiveSize.size(1),
            offset: Offset(0, ResponsiveSize.size(0.25)),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // For very narrow widths, use a more compact layout
          if (constraints.maxWidth < ResponsiveSize.width(37.5)) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back button only for very narrow widths
                SizedBox(
                  width: ResponsiveSize.size(7),
                  height: ResponsiveSize.size(7),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppTheme.primaryColor,
                      size: ResponsiveSize.size(4),
                    ),
                    onPressed: () {
                      // Clear selected prescription
                      ref
                          .read(selectedPrescriptionIdProvider.notifier)
                          .select(null);
                      // Show history panel
                      ref
                          .read(showHistoryPanelProvider.notifier)
                          .update((state) => true);
                    },
                    tooltip: 'Back to prescription list',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    iconSize: ResponsiveSize.size(4),
                  ),
                ),
                SizedBox(width: ResponsiveSize.horizontal(1)),
                Expanded(
                  child: Text(
                    prescription.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveSize.fontSize(13),
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
              // // History toggle button
              // SizedBox(
              //   width: ResponsiveSize.size(8),
              //   height: ResponsiveSize.size(8),
              //   child: IconButton(
              //     icon: AnimatedSwitcher(
              //       duration: const Duration(milliseconds: 300),
              //       transitionBuilder:
              //           (Widget child, Animation<double> animation) {
              //         return RotationTransition(
              //           turns: Tween<double>(begin: 0.5, end: 1.0)
              //               .animate(animation),
              //           child: ScaleTransition(
              //             scale: animation,
              //             child: child,
              //           ),
              //         );
              //       },
              //       child: Icon(
              //         showHistoryPanel ? Icons.menu_open : Icons.menu,
              //         key: ValueKey<bool>(showHistoryPanel),
              //         color: AppTheme.primaryColor,
              //         size: ResponsiveSize.size(4.5),
              //       ),
              //     ),
              //     onPressed: () {
              //       ref
              //           .read(showHistoryPanelProvider.notifier)
              //           .update((state) => !showHistoryPanel);
              //     },
              //     tooltip: showHistoryPanel
              //         ? 'Hide prescription history'
              //         : 'Show prescription history',
              //     padding: EdgeInsets.zero,
              //     visualDensity: VisualDensity.compact,
              //     iconSize: ResponsiveSize.size(4.5),
              //   ),
              // ),
              // SizedBox(width: ResponsiveSize.horizontal(1)),
              // // Back button
              // SizedBox(
              //   width: ResponsiveSize.size(8),
              //   height: ResponsiveSize.size(8),
              //   child: IconButton(
              //     icon: Icon(
              //       Icons.arrow_back,
              //       color: AppTheme.primaryColor,
              //       size: ResponsiveSize.size(4.5),
              //     ),
              //     onPressed: () {
              //       // Clear selected prescription
              //       ref
              //           .read(selectedPrescriptionIdProvider.notifier)
              //           .select(null);
              //       // Show history panel
              //       ref
              //           .read(showHistoryPanelProvider.notifier)
              //           .update((state) => true);
              //     },
              //     tooltip: 'Back to prescription list',
              //     padding: EdgeInsets.zero,
              //     visualDensity: VisualDensity.compact,
              //     iconSize: ResponsiveSize.size(4.5),
              //   ),
              // ),
              SizedBox(width: ResponsiveSize.horizontal(2)),
              Expanded(
                child: Text(
                  prescription.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveSize.fontSize(15),
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
                          borderRadius:
                              BorderRadius.circular(ResponsiveSize.size(4)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBar(
                              title: Text(AppStrings.prescriptionImage),
                              automaticallyImplyLeading: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft:
                                      Radius.circular(ResponsiveSize.size(4)),
                                  topRight:
                                      Radius.circular(ResponsiveSize.size(4)),
                                ),
                              ),
                              actions: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                bottomLeft:
                                    Radius.circular(ResponsiveSize.size(4)),
                                bottomRight:
                                    Radius.circular(ResponsiveSize.size(4)),
                              ),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: Image.file(
                                  File(prescription.imageUrl!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Padding(
                                      padding: EdgeInsets.all(
                                          ResponsiveSize.size(4)),
                                      child: Text(AppStrings.errorImageUpload),
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
                      width: ResponsiveSize.size(9),
                      height: ResponsiveSize.size(9),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(ResponsiveSize.size(2)),
                        border: Border.all(color: AppTheme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.shadowColor,
                            blurRadius: ResponsiveSize.size(0.5),
                            offset: Offset(0, ResponsiveSize.size(0.25)),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(ResponsiveSize.size(1.75)),
                        child: Image.file(
                          File(prescription.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              size: ResponsiveSize.size(4),
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
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deletePrescription),
        content: Text(AppStrings.deletePrescriptionConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
