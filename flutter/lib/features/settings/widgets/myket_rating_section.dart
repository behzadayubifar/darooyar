import 'package:flutter/material.dart';
import 'package:darooyar/utils/myket_utils.dart';
import 'package:darooyar/widgets/myket_rating_button.dart';

/// A widget that displays a section in the settings screen for rating the app on Myket
class MyketRatingSection extends StatelessWidget {
  const MyketRatingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8.0),
                Text(
                  'نظر و امتیاز',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              'اگر از برنامه راضی هستید، لطفا با دادن امتیاز و نظر در مایکت از ما حمایت کنید.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    MyketUtils.openDeveloperApps();
                  },
                  icon: Icon(Icons.apps, color: colorScheme.primary),
                  label: Text(
                    'برنامه‌های دیگر ما',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    MyketUtils.openAppPage();
                  },
                  child: Text(
                    'مشاهده برنامه در مایکت',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    MyketUtils.openRatingPage();
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('امتیاز دهید'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            Divider(
              height: 32.0,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            InkWell(
              onTap: () {
                MyketUtils.checkForUpdate(context);
              },
              borderRadius: BorderRadius.circular(8.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.system_update,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بررسی به‌روزرسانی',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'برای بررسی وجود نسخه جدید برنامه کلیک کنید',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
