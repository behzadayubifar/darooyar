import 'package:flutter/material.dart';
import 'package:darooyar/utils/myket_utils.dart';
import 'package:darooyar/widgets/myket_rating_button.dart';

/// A widget that displays a section in the settings screen for rating the app on Myket
class MyketRatingSection extends StatelessWidget {
  const MyketRatingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              'اگر از برنامه راضی هستید، لطفا با دادن امتیاز و نظر در مایکت از ما حمایت کنید.',
              style: Theme.of(context).textTheme.bodyMedium,
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
                  icon: const Icon(Icons.apps),
                  label: const Text('برنامه‌های دیگر ما'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    MyketUtils.openAppPage();
                  },
                  child: const Text('مشاهده برنامه در مایکت'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    MyketUtils.openRatingPage();
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('امتیاز دهید'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(height: 32.0),
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
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بررسی به‌روزرسانی',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'برای بررسی وجود نسخه جدید برنامه کلیک کنید',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16.0),
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
