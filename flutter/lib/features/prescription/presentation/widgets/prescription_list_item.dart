import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/prescription_entity.dart';
import '../providers/prescription_providers.dart';

class PrescriptionListItem extends HookConsumerWidget {
  final PrescriptionEntity prescription;
  final bool isSelected;

  const PrescriptionListItem({
    super.key,
    required this.prescription,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Persian date format
    final dateFormat = DateFormat('yyyy/MM/dd • HH:mm');
    final isHovering = useState(false);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            ref
                .read(selectedPrescriptionIdProvider.notifier)
                .select(prescription.id);
          },
          onHover: (value) {
            isHovering.value = value;
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: AppTheme.primaryColor.withOpacity(0.1),
          highlightColor: AppTheme.primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Prescription image or icon
                Hero(
                  tag: 'prescription_list_${prescription.id}',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: prescription.imageUrl == null
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: prescription.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.file(
                              File(prescription.imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.dividerColor,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 18,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.description,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Prescription details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        prescription.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(prescription.createdAt),
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button
                AnimatedOpacity(
                  opacity: isHovering.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppTheme.errorColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: AppStrings.delete,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppStrings.deletePrescription),
                          content:
                              Text(AppStrings.deletePrescriptionConfirmation),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(AppStrings.cancel),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref.read(deletePrescriptionProvider(
                                    prescription.id));
                              },
                              child: Text(
                                AppStrings.delete,
                                style:
                                    const TextStyle(color: AppTheme.errorColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
