import 'package:flutter/material.dart';

/// Utility class for formatting AI messages
class MessageFormatter {
  /// Checks if a message is already in the structured format
  static bool isStructuredFormat(String content) {
    return content.contains('-next-');
  }

  /// Checks if a message is a prescription analysis response
  static bool isPrescriptionAnalysis(String content) {
    // Look for at least 3 of the 7 question patterns
    final patterns = [
      '۱. تشخیص احتمالی',
      '۲. تداخلات مهم',
      '۳. عوارض مهم',
      '۴. اگر دارویی را باید در زمان خاصی',
      '۵. اگر دارویی رو باید با فاصله از غذا',
      '۶. تعداد مصرف روزانه',
      '۷. اگر برای عارضه‌ای',
    ];

    int matchCount = 0;
    for (final pattern in patterns) {
      if (content.contains(pattern)) {
        matchCount++;
      }
    }

    // If at least 3 of the patterns are found, consider it a prescription analysis
    return matchCount >= 3;
  }

  /// Attempts to convert an unstructured AI message to the structured format
  /// Returns the original message if conversion is not possible
  static String formatAIMessage(String content) {
    // If already structured, return as is
    if (isStructuredFormat(content)) {
      return content;
    }

    // Check if this is a prescription analysis
    if (isPrescriptionAnalysis(content)) {
      return _formatPrescriptionAnalysis(content);
    }

    // Try to identify the sections in the unstructured message
    final sections = [
      '۱. تشخیص احتمالی عارضه یا بیماری:',
      '۲. تداخلات مهم داروها که باید به بیمار گوشزد شود:',
      '۳. عوارض مهم و شایعی که حتما باید بیمار در مورد این داروها یادش باشد:',
      '۴. اگر دارویی را باید در زمان خاصی از روز مصرف کرد:',
      '۵. اگر دارویی رو باید با فاصله از غذا یا با غذا مصرف کرد:',
      '۶. تعداد مصرف روزانه هر دارو:',
      '۷. اگر برای عارضه‌ای که داروها میدهند نیاز به مدیریت خاصی وجود دارد که باید اطلاع بدم بگو:',
    ];

    // Check if the message contains at least some of the expected sections
    bool containsAnySections =
        sections.any((section) => content.contains(section));

    if (!containsAnySections) {
      return content; // Not a structured message
    }

    // Try to extract the medication list (everything before the first section)
    String medicationList = '';
    String infoSections = content;

    for (final section in sections) {
      if (content.contains(section)) {
        final parts = content.split(section);
        if (parts.isNotEmpty) {
          medicationList = parts[0].trim();
          infoSections = '$section${parts.length > 1 ? parts[1] : ''}';
          break;
        }
      }
    }

    // If we couldn't extract a medication list, use a placeholder
    if (medicationList.isEmpty) {
      medicationList = 'لیست داروهای نسخه';
    }

    // Format the message in the structured format
    return '$medicationList\n-next-\n$infoSections';
  }

  /// Formats prescription analysis into structured format
  static String _formatPrescriptionAnalysis(String content) {
    // Look for common headers before the section numbers
    final sectionHeaders = [
      'بررسی نسخه:',
      'با سلام همکار گرامی،',
      'با بررسی داروهای موجود در نسخه،',
      'لیست داروهای نسخه:',
    ];

    // Extract medication list
    String medicationList = '';
    for (final header in sectionHeaders) {
      if (content.contains(header)) {
        final parts = content.split('۱. تشخیص احتمالی');
        if (parts.isNotEmpty) {
          medicationList = parts[0].trim();
          break;
        }
      }
    }

    // If no medication list found, try to extract everything before first numbered section
    if (medicationList.isEmpty) {
      final numbered = RegExp(r'۱\.\s+تشخیص');
      final match = numbered.firstMatch(content);
      if (match != null && match.start > 0) {
        medicationList = content.substring(0, match.start).trim();
      }
    }

    // If still empty, use a default placeholder
    if (medicationList.isEmpty) {
      medicationList = 'لیست داروهای نسخه';
    }

    // Get the analysis sections
    String analysisSections = content;
    if (medicationList != 'لیست داروهای نسخه') {
      analysisSections = content
          .substring(content.indexOf(medicationList) + medicationList.length)
          .trim();
    }

    // Format the message in the structured format
    return '$medicationList\n-next-\n$analysisSections';
  }
}
