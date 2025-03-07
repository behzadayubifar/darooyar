import 'dart:convert';
import '../utils/logger.dart';

/// Utility class for formatting AI messages
class MessageFormatter {
  /// Checks if a message is already in the structured format
  static bool isStructuredFormat(String content) {
    // Check if the content contains specific Persian section markers using RegExp
    final sectionRegexes = [
      // Persian and Arabic numbered sections
      RegExp(r'(?:۱|1)[\.\s]+(?:تشخیص احتمالی|تشخیص)', unicode: true),
      RegExp(r'(?:۲|2)[\.\s]+(?:تداخلات|تداخل)', unicode: true),
      RegExp(r'(?:۳|3)[\.\s]+(?:عوارض)', unicode: true),
      RegExp(r'(?:۴|4)[\.\s]+(?:زمان مصرف|اگر دارویی)', unicode: true),
      RegExp(r'(?:۵|5)[\.\s]+(?:مصرف با غذا|با فاصله از غذا)', unicode: true),
      RegExp(r'(?:۶|6)[\.\s]+(?:تعداد مصرف)', unicode: true),
      RegExp(r'(?:۷|7)[\.\s]+(?:مدیریت|عارضه)', unicode: true),

      // Section names without numbers
      RegExp(r'تشخیص احتمالی[\s:]+', unicode: true),
      RegExp(r'تداخلات(?:[\s:]|\s+مهم|\s+دارویی)+', unicode: true),
      RegExp(r'عوارض(?:[\s:]|\s+مهم|\s+شایع)+', unicode: true),
    ];

    // Check if the content contains the structured format delimiter
    if (content.contains('-next-')) {
      return true;
    }

    // Count how many section patterns match
    int matchCount = 0;
    for (final regex in sectionRegexes) {
      if (regex.hasMatch(content)) {
        matchCount++;
        final match = regex.firstMatch(content);
        if (match != null) {
          AppLogger.d('Found structured format regex match: ${match.group(0)}');
        }
      }
    }

    // Also check for keywords that indicate a prescription analysis
    final keywordIndicators = [
      'تحلیل نسخه',
      'بررسی نسخه',
      'داروهای نسخه',
      'لیست داروها',
    ];

    bool hasKeywordIndicator =
        keywordIndicators.any((keyword) => content.contains(keyword));

    // Consider it structured if at least 2 section markers are present or if we have an indicator and at least 1 marker
    final isStructured =
        matchCount >= 2 || (hasKeywordIndicator && matchCount >= 1);
    AppLogger.d(
        'isStructuredFormat: $isStructured (found $matchCount regex matches, has keyword indicator: $hasKeywordIndicator)');
    return isStructured;
  }

  /// Checks if a message is a prescription analysis response
  static bool isPrescriptionAnalysis(String content) {
    // Create a scoring system to determine if this is likely a prescription analysis
    int score = 0;

    // Major indicators (each worth 2 points)
    final majorIndicators = [
      'تحلیل نسخه',
      'بررسی نسخه',
      'داروهای نسخه',
      'لیست داروها',
    ];

    // Section indicators (each worth 1 point)
    final sectionIndicators = [
      RegExp(r'(?:۱|1)[\.\s]+(?:تشخیص احتمالی|تشخیص)', unicode: true),
      RegExp(r'(?:۲|2)[\.\s]+(?:تداخلات|تداخل)', unicode: true),
      RegExp(r'(?:۳|3)[\.\s]+(?:عوارض)', unicode: true),
      RegExp(r'تشخیص احتمالی[\s:]+', unicode: true),
      RegExp(r'تداخلات(?:[\s:]|\s+مهم|\s+دارویی)+', unicode: true),
      RegExp(r'عوارض(?:[\s:]|\s+مهم|\s+شایع)+', unicode: true),
    ];

    // Check major indicators
    for (final indicator in majorIndicators) {
      if (content.contains(indicator)) {
        score += 2;
        AppLogger.d(
            'Found major prescription indicator: $indicator (+2 points)');
      }
    }

    // Check section indicators
    for (final regex in sectionIndicators) {
      if (regex.hasMatch(content)) {
        score += 1;
        final match = regex.firstMatch(content);
        if (match != null) {
          AppLogger.d('Found section indicator: ${match.group(0)} (+1 point)');
        }
      }
    }

    // Consider it a prescription analysis if score >= 3
    final isPrescription = score >= 3;
    AppLogger.d(
        'isPrescriptionAnalysis: $isPrescription (total score: $score)');
    return isPrescription;
  }

  /// Attempts to convert an unstructured AI message to the structured format
  /// Returns the original message if conversion is not possible
  static String formatAIMessage(String content) {
    // Log content for debugging
    AppLogger.d('Formatting AI message (${content.length} chars)');

    // If already structured, return as is
    if (content.contains('-next-')) {
      return content;
    }

    // Try specific formats first
    // For prescription analysis responses
    if (isPrescriptionAnalysis(content)) {
      AppLogger.d('Using prescription analysis formatter');
      return _formatPrescriptionAnalysis(content);
    }

    // For general message responses
    AppLogger.d('Using generic formatter');
    return _formatGenericAIResponse(content);
  }

  /// Formats prescription analysis into structured format
  static String _formatPrescriptionAnalysis(String content) {
    // Extract the medication list (content before the first section)
    String medicationList = '';
    String analysisSections = content;

    // Define regexes for section headers that would mark the end of the medication list
    final sectionHeaderPatterns = [
      RegExp(r'(?:۱|1)[\.\s]+(?:تشخیص احتمالی|تشخیص)', unicode: true),
      RegExp(r'تشخیص احتمالی[\s:]+', unicode: true),
      RegExp(r'(?:۲|2)[\.\s]+(?:تداخلات|تداخل)', unicode: true),
      RegExp(r'تداخلات(?:[\s:]|\s+مهم|\s+دارویی)+', unicode: true),
    ];

    // Find the first section header to split the content
    int firstSectionIndex = content.length;
    String firstSectionText = '';

    for (final regex in sectionHeaderPatterns) {
      final match = regex.firstMatch(content);
      if (match != null && match.start < firstSectionIndex) {
        firstSectionIndex = match.start;
        firstSectionText = match.group(0) ?? '';
      }
    }

    if (firstSectionIndex < content.length) {
      // Extract the medication list and analysis sections
      medicationList = content.substring(0, firstSectionIndex).trim();
      analysisSections = content.substring(firstSectionIndex).trim();
      AppLogger.d('Split content at first section: $firstSectionText');
      AppLogger.d('Medication list length: ${medicationList.length} chars');
    } else {
      // If no section headers found, look for common dividers
      final dividerPatterns = [
        '\n\n',
        '-----',
        '=====',
        '***',
        '---',
        '• ',
        '- ',
      ];

      for (final divider in dividerPatterns) {
        int index = content.indexOf(divider);
        if (index > 20 && index < content.length / 3) {
          // Reasonable position for a divider
          medicationList = content.substring(0, index).trim();
          analysisSections = content.substring(index).trim();
          AppLogger.d('Split content using divider: $divider');
          break;
        }
      }
    }

    // If we still don't have a medication list, try to find common medication list headers
    if (medicationList.isEmpty) {
      final medListHeaders = [
        'لیست داروها:',
        'داروهای نسخه:',
        'داروهای تجویز شده:',
        'داروها:',
      ];

      for (final header in medListHeaders) {
        if (content.contains(header)) {
          int startIdx = content.indexOf(header) + header.length;
          int endIdx = content.length;

          // Look for the first section header after this
          for (final regex in sectionHeaderPatterns) {
            final match = regex.firstMatch(content.substring(startIdx));
            if (match != null) {
              endIdx = startIdx + match.start;
              break;
            }
          }

          if (endIdx > startIdx) {
            medicationList = content.substring(startIdx, endIdx).trim();
            analysisSections = content.substring(endIdx).trim();
            AppLogger.d('Extracted medication list using header: $header');
            break;
          }
        }
      }
    }

    // If still empty, use a default placeholder
    if (medicationList.isEmpty) {
      medicationList = 'لیست داروهای نسخه';
      AppLogger.d('Using default medication list placeholder');
    }

    // If we don't have any analysis sections, use the original content
    if (analysisSections.isEmpty || analysisSections == medicationList) {
      analysisSections = content;
      AppLogger.d('Using full content for analysis sections');
    }

    // Format the message in the structured format
    AppLogger.d(
        'Formatted prescription analysis with medication list (${medicationList.length} chars) and analysis sections (${analysisSections.length} chars)');
    return '$medicationList\n-next-\n$analysisSections';
  }

  static String _formatGenericAIResponse(String content) {
    // For general AI responses, try to identify logical sections

    // First, check if the content has multiple paragraphs
    final paragraphs =
        content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    // If we have multiple paragraphs, use the first one as an introduction
    if (paragraphs.length > 1) {
      final introduction = paragraphs[0].trim();
      final details = paragraphs.sublist(1).join('\n\n').trim();

      return '$introduction\n-next-\n$details';
    }

    // If no clear paragraphs, try to split by bullet points or numbered lists
    final bulletPattern = RegExp(r'(^|\n)[•\-*]\s+', multiLine: true);
    if (bulletPattern.hasMatch(content)) {
      // Find the text before the first bullet point
      final firstBulletIndex = bulletPattern.firstMatch(content)?.start ?? 0;
      if (firstBulletIndex > 0) {
        final introduction = content.substring(0, firstBulletIndex).trim();
        final details = content.substring(firstBulletIndex).trim();

        return '$introduction\n-next-\n$details';
      }
    }

    // If no clear structure, just return the original content
    return content;
  }

  // Helper for safe substring operations
  static int min(int a, int b) => a < b ? a : b;
}
