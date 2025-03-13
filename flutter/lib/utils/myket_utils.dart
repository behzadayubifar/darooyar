import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A utility class for Myket integration
class MyketUtils {
  /// The package name of the app
  static const String packageName = 'com.darooyar';

  /// Opens the app page in Myket
  static Future<bool> openAppPage() async {
    final Uri myketUri = Uri.parse('myket://details?id=$packageName');
    final Uri webUri = Uri.parse('https://myket.ir/app/$packageName');

    try {
      // Try to open the Myket app first
      if (await canLaunchUrl(myketUri)) {
        return await launchUrl(
          myketUri,
          mode: LaunchMode.externalApplication,
        );
      }
      // If Myket app is not installed, open the web page
      else if (await canLaunchUrl(webUri)) {
        return await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error opening Myket: $e');
    }

    return false;
  }

  /// Opens the rating page for the app in Myket
  static Future<bool> openRatingPage() async {
    final Uri myketUri = Uri.parse('myket://comment?id=$packageName');
    final Uri webUri = Uri.parse('https://myket.ir/app/$packageName');

    try {
      // Try to open the Myket app first
      if (await canLaunchUrl(myketUri)) {
        return await launchUrl(
          myketUri,
          mode: LaunchMode.externalApplication,
        );
      }
      // If Myket app is not installed, open the web page
      else if (await canLaunchUrl(webUri)) {
        return await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error opening Myket rating page: $e');
    }

    return false;
  }

  /// Opens the developer page in Myket
  static Future<bool> openDeveloperPage() async {
    final Uri myketUri = Uri.parse('myket://developer?id=$packageName');
    final Uri webUri = Uri.parse('https://myket.ir/developer/$packageName');

    try {
      // Try to open the Myket app first
      if (await canLaunchUrl(myketUri)) {
        return await launchUrl(
          myketUri,
          mode: LaunchMode.externalApplication,
        );
      }
      // If Myket app is not installed, open the web page
      else if (await canLaunchUrl(webUri)) {
        return await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error opening Myket developer page: $e');
    }

    return false;
  }

  /// Opens the list of all apps by the same developer in Myket
  /// This shows all apps published by the developer of this app
  static Future<bool> openDeveloperApps() async {
    final Uri myketUri = Uri.parse('myket://developer?id=$packageName');
    final Uri webUri = Uri.parse('https://myket.ir/developer/$packageName');

    try {
      // Try to open the Myket app first
      if (await canLaunchUrl(myketUri)) {
        return await launchUrl(
          myketUri,
          mode: LaunchMode.externalApplication,
        );
      }
      // If Myket app is not installed, open the web page
      else if (await canLaunchUrl(webUri)) {
        return await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error opening developer apps list: $e');
    }

    return false;
  }

  /// Checks if there is an update available for the app in Myket
  static Future<bool> checkForUpdate(BuildContext context) async {
    final Uri myketUri = Uri.parse('myket://download?id=$packageName');

    try {
      // Check if Myket is installed
      if (await canLaunchUrl(myketUri)) {
        // Show update dialog
        if (context.mounted) {
          showUpdateDialog(context);
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }

    return false;
  }

  /// Opens the update page for the app in Myket
  static Future<bool> openUpdatePage() async {
    final Uri myketUri = Uri.parse('myket://download?id=$packageName');
    final Uri webUri = Uri.parse('https://myket.ir/app/$packageName');

    try {
      // Try to open the Myket app first
      if (await canLaunchUrl(myketUri)) {
        return await launchUrl(
          myketUri,
          mode: LaunchMode.externalApplication,
        );
      }
      // If Myket app is not installed, open the web page
      else if (await canLaunchUrl(webUri)) {
        return await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error opening update page: $e');
    }

    return false;
  }

  /// Shows a beautiful update dialog
  static void showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Theme.of(context).primaryColor,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation
                Lottie.asset(
                  'assets/animations/update.json',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.system_update,
                      size: 80,
                      color: Colors.white,
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Title
                const Text(
                  'به‌روزرسانی جدید',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                // Description
                const Text(
                  'نسخه جدیدی از داروویار منتشر شده است. لطفاً برنامه را به‌روزرسانی کنید تا از امکانات و بهبودهای جدید بهره‌مند شوید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 25),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Later button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: const Text(
                        'بعداً',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Update now button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        openUpdatePage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'به‌روزرسانی',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
