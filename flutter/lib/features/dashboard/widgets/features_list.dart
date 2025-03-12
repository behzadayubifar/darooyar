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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.list_alt,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ویژگی‌های اشتراک',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
