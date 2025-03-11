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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 30.0,
                lineWidth: 5.0,
                percent: percentage,
                center: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                progressColor: AppTheme.primaryColor,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
