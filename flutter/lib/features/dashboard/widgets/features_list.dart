import 'package:flutter/material.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../../core/theme/app_theme.dart';

class FeaturesList extends StatelessWidget {
  final SubscriptionPlan plan;

  const FeaturesList({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ویژگی‌های اشتراک',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'تحلیل نسخه',
              plan.prescriptionCount > 0
                  ? '${plan.prescriptionCount} نسخه'
                  : 'نامحدود',
              Icons.description,
            ),
            _buildFeatureItem(
              'مدت زمان',
              plan.hasTimeLimit ? '${plan.timeLimitDays} روز' : 'نامحدود',
              Icons.access_time,
            ),
            _buildFeatureItem(
              'حفظ اطلاعات',
              plan.keepsPreviousVersions
                  ? '${plan.dataRetentionDays} روز'
                  : 'ندارد',
              Icons.storage,
            ),
            _buildFeatureItem(
              'قیمت',
              '${plan.price} هزار تومان',
              Icons.monetization_on,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
