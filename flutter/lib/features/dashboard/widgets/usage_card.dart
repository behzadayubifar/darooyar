import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class UsageCard extends StatelessWidget {
  final String title;
  final String value;
  final double percentage;
  final IconData icon;
  final VoidCallback? onTap;

  const UsageCard({
    Key? key,
    required this.title,
    required this.value,
    required this.percentage,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircularPercentIndicator(
                    radius: 25.0,
                    lineWidth: 4.0,
                    percent: percentage,
                    center: Icon(
                      icon,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    progressColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
