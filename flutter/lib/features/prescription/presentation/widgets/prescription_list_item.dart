import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/prescription_entity.dart';
import '../providers/prescription_providers.dart';

class PrescriptionListItem extends ConsumerWidget {
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

    return Card(
      elevation: isSelected ? 4 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          ref
              .read(selectedPrescriptionIdProvider.notifier)
              .select(prescription.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prescription.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.file(
                      File(prescription.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.dividerColor,
                          child:
                              const Icon(Icons.image_not_supported, size: 18),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prescription.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(prescription.createdAt),
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: AppTheme.errorColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                              ref.read(
                                  deletePrescriptionProvider(prescription.id));
                            },
                            child: Text(AppStrings.delete),
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
    );
  }
}
