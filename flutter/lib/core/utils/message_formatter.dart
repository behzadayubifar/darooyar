import 'package:flutter/material.dart';

/// Utility class for formatting AI messages
class MessageFormatter {
  /// Checks if a message is already in the structured format
  static bool isStructuredFormat(String content) {
    return content.contains('-next-');
  }

  /// Attempts to convert an unstructured AI message to the structured format
  /// Returns the original message if conversion is not possible
  static String formatAIMessage(String content) {
    // If already structured, return as is
    if (isStructuredFormat(content)) {
      return content;
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
}
