import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_size.dart';
import '../../../domain/entities/prescription_entity.dart';
import '../../providers/prescription_providers.dart';
import '../prescription_list_item.dart';

class HistoryPanel extends ConsumerWidget {
  final List<PrescriptionEntity> prescriptions;
  final String? selectedPrescriptionId;

  const HistoryPanel({
    super.key,
    required this.prescriptions,
    required this.selectedPrescriptionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: ResponsiveSize.size(1.25),
            offset: Offset(ResponsiveSize.size(0.5), 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveSize.vertical(2),
              horizontal: ResponsiveSize.horizontal(4),
            ),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor,
                  blurRadius: ResponsiveSize.size(0.5),
                  offset: Offset(0, ResponsiveSize.size(0.25)),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(width: ResponsiveSize.horizontal(3)),
                      Flexible(
                        child: Text(
                          AppStrings.prescriptionHistory,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveSize.fontSize(24),
                            color: AppTheme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.textSecondaryColor,
                    size: ResponsiveSize.size(32),
                  ),
                  onPressed: () {
                    ref.read(showHistoryPanelProvider.notifier).state = false;
                  },
                  tooltip: 'Close history panel',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: ResponsiveSize.size(8),
                    minHeight: ResponsiveSize.size(8),
                  ),
                ),
              ],
            ),
          ),

          // Prescription list
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                itemCount: prescriptions.length,
                padding:
                    EdgeInsets.symmetric(vertical: ResponsiveSize.vertical(1)),
                itemBuilder: (context, index) {
                  final prescription = prescriptions[index];
                  final isSelected = prescription.id == selectedPrescriptionId;

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () {
                            // Select this prescription
                            ref
                                .read(selectedPrescriptionIdProvider.notifier)
                                .select(prescription.id);
                            // Close history panel on mobile
                            if (MediaQuery.of(context).size.width <
                                ResponsiveSize.width(60)) {
                              ref
                                  .read(showHistoryPanelProvider.notifier)
                                  .update((state) => false);
                            }
                          },
                          child: PrescriptionListItem(
                            prescription: prescription,
                            isSelected: isSelected,
                          ),
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
    );
  }
}
