import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';

/// کلاس کمکی برای عملیات‌های مرتبط با پیام‌ها
class MessageUtils {
  /// تمیز کردن محتوای پیام از تگ‌ها و علامت‌های اضافی
  static String cleanMessageContent(String content) {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('***', '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('✧✧✧', '')
        .replaceAll('✧✧', '')
        .replaceAll('✧', '');
  }

  /// کپی کردن محتوای پیام در کلیپ‌بورد
  static void copyMessageContent(BuildContext context, String content) {
    String cleanContent = cleanMessageContent(content);

    Clipboard.setData(ClipboardData(text: cleanContent)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('متن با موفقیت کپی شد'),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  /// اشتراک‌گذاری محتوای پیام
  static void shareMessageContent(String content) {
    String cleanContent = cleanMessageContent(content);

    Share.share(
      cleanContent,
      subject: 'پاسخ دارویار',
    );
  }

  // Helper function to detect prescription messages
  static bool isPrescriptionMessage(String content, {bool isImage = false}) {
    // If it's an image, it's always considered a prescription
    if (isImage) {
      return true;
    }

    // Common patterns for prescriptions in Persian and English
    final prescriptionMarkers = [
      "نسخه:",
      "نسخه :",
      "نسخه ",
      "prescription:",
      "prescription ",
      "rx:",
      "rx ",
      "دارو:",
      "دارو ",
      "داروی ",
      "قرص ",
      "کپسول ",
      "شربت ",
      "آمپول ",
    ];

    final lowerContent = content.toLowerCase();

    for (final marker in prescriptionMarkers) {
      if (lowerContent.contains(marker.toLowerCase())) {
        return true;
      }
    }

    return false;
  }
}
