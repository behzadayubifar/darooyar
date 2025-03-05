import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_size.dart';

class HelpMessage extends StatelessWidget {
  const HelpMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(ResponsiveSize.size(4)),
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveSize.vertical(2),
        horizontal: ResponsiveSize.horizontal(5),
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveSize.size(4)),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: ResponsiveSize.size(1),
            offset: Offset(0, ResponsiveSize.size(0.5)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveSize.size(2.5)),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
              size: ResponsiveSize.size(32),
            ),
          ),
          SizedBox(width: ResponsiveSize.horizontal(4)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.selectPrescription,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: ResponsiveSize.fontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveSize.vertical(0.5)),
                Text(
                  "برای مشاهده جزئیات و گفتگو، یک نسخه را از فهرست انتخاب کنید",
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: ResponsiveSize.fontSize(14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
