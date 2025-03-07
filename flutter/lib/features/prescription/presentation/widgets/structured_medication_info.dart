import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/message_formatter.dart';
import '../../../../core/utils/logger.dart';
import 'expandable_panel.dart';

class StructuredMedicationInfo extends StatelessWidget {
  final String content;

  const StructuredMedicationInfo({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Log content length for debugging
    AppLogger.d('AI Content length: ${content.length} characters');
    if (content.length > 1000) {
      AppLogger.d(
          'First 100 chars: ${content.substring(0, min(100, content.length))}');
      AppLogger.d(
          'Last 100 chars: ${content.substring(max(0, content.length - 100))}');
    }

    // Check for truncated content
    final bool mightBeTruncated =
        content.length > 2000 && !content.contains('۷.');
    if (mightBeTruncated) {
      AppLogger.w(
          'Content might be truncated. Length: ${content.length}, does not contain section 7');
    }

    // Format the content if needed
    final formattedContent = MessageFormatter.formatAIMessage(content);

    // If not structured or potentially truncated, just return scrollable text
    if (!MessageFormatter.isStructuredFormat(formattedContent) ||
        mightBeTruncated) {
      AppLogger.d(
          'Displaying content as plain text. Structured format: ${MessageFormatter.isStructuredFormat(formattedContent)}');
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SelectableText(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
    }

    // Parse the structured content
    final parts = formattedContent.split('-next-');
    if (parts.length != 2) {
      AppLogger.d(
          'Content split into ${parts.length} parts instead of expected 2');
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SelectableText(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
    }

    final medicationList = parts[0].trim();
    final infoSections = parts[1].trim();

    // Define section patterns and their properties
    final List<Map<String, dynamic>> sectionDefinitions = [
      {
        'title': 'تشخیص احتمالی',
        'color': const Color(0xFF43A047), // Green
        'icon': MdiIcons.stethoscope,
        'regexPatterns': [
          r'(?:۱|1)[\.\s]+(?:تشخیص احتمالی|تشخیص)',
          r'تشخیص احتمالی[\s:]+',
        ],
      },
      {
        'title': 'تداخلات مهم داروها',
        'color': const Color(0xFFE53935), // Red
        'icon': MdiIcons.alertCircleOutline,
        'regexPatterns': [
          r'(?:۲|2)[\.\s]+(?:تداخلات|تداخلات مهم|تداخلات دارویی)',
          r'تداخلات(?:[\s:]|\s+مهم|\s+دارویی)+',
          r'drug interactions',
        ],
      },
      {
        'title': 'عوارض مهم و شایع',
        'color': const Color(0xFFFF9800), // Orange
        'icon': MdiIcons.informationOutline,
        'regexPatterns': [
          r'(?:۳|3)[\.\s]+(?:عوارض|عوارض مهم)',
          r'عوارض(?:[\s:]|\s+مهم|\s+شایع)+',
        ],
      },
      {
        'title': 'زمان مصرف داروها',
        'color': const Color(0xFF2196F3), // Blue
        'icon': MdiIcons.clockOutline,
        'regexPatterns': [
          r'(?:۴|4)[\.\s]+(?:زمان مصرف|اگر دارویی را باید در زمان خاصی)',
          r'زمان مصرف(?:[\s:])+',
        ],
      },
      {
        'title': 'نحوه مصرف با غذا',
        'color': const Color(0xFF9C27B0), // Purple
        'icon': MdiIcons.foodApple,
        'regexPatterns': [
          r'(?:۵|5)[\.\s]+(?:مصرف با غذا|اگر دارویی رو باید با فاصله از غذا)',
          r'مصرف با غذا(?:[\s:])+',
        ],
      },
      {
        'title': 'تعداد مصرف روزانه',
        'color': const Color(0xFF00BCD4), // Cyan
        'icon': MdiIcons.calendarClock,
        'regexPatterns': [
          r'(?:۶|6)[\.\s]+(?:تعداد مصرف|تعداد مصرف روزانه)',
          r'تعداد مصرف(?:[\s:]|\s+روزانه)+',
        ],
      },
      {
        'title': 'مدیریت خاص',
        'color': const Color(0xFF795548), // Brown
        'icon': MdiIcons.shieldCross,
        'regexPatterns': [
          r'(?:۷|7)[\.\s]+(?:مدیریت|اگر برای عارضه‌ای|مدیریت خاص)',
          r'مدیریت خاص(?:[\s:])+',
        ],
      },
    ];

    // Prepare the initial medication list section
    List<Map<String, dynamic>> sections = [
      {
        'title': 'لیست داروهای نسخه',
        'content': medicationList,
        'color': AppTheme.primaryColor,
        'icon': MdiIcons.pill,
        'initiallyExpanded': true,
      }
    ];

    // Use RegExp to find all section headers and their positions
    List<Map<String, dynamic>> sectionMatches = [];

    for (final sectionDef in sectionDefinitions) {
      for (final regexPattern in sectionDef['regexPatterns']) {
        final RegExp regex = RegExp(regexPattern, unicode: true);
        final matches = regex.allMatches(infoSections);

        for (final match in matches) {
          sectionMatches.add({
            'title': sectionDef['title'],
            'color': sectionDef['color'],
            'icon': sectionDef['icon'],
            'startIndex': match.start,
            'endIndex': match.end,
            'matchText': infoSections.substring(match.start, match.end),
          });

          AppLogger.d(
              'Found section ${sectionDef['title']} at position ${match.start} with text: ${infoSections.substring(match.start, match.end)}');
        }
      }
    }

    // Sort matches by their position in the text
    sectionMatches.sort(
        (a, b) => (a['startIndex'] as int).compareTo(b['startIndex'] as int));

    // Extract content for each section
    for (int i = 0; i < sectionMatches.length; i++) {
      final startContentIdx = sectionMatches[i]['endIndex'] as int;
      final endContentIdx = i < sectionMatches.length - 1
          ? sectionMatches[i + 1]['startIndex'] as int
          : infoSections.length;

      if (startContentIdx < endContentIdx) {
        final sectionContent =
            infoSections.substring(startContentIdx, endContentIdx).trim();

        if (sectionContent.isNotEmpty) {
          sections.add({
            'title': sectionMatches[i]['title'],
            'content': sectionContent,
            'color': sectionMatches[i]['color'],
            'icon': sectionMatches[i]['icon'],
            'initiallyExpanded': false,
          });

          AppLogger.d(
              'Added section: ${sectionMatches[i]['title']} with ${sectionContent.length} chars');

          // Special log for تداخلات
          if (sectionMatches[i]['title'] == 'تداخلات مهم داروها') {
            AppLogger.d(
                'تداخلات section content: ${sectionContent.substring(0, min(100, sectionContent.length))}');
          }
        }
      }
    }

    // Special handling for تداخلات if not found above
    if (!sections.any((s) => s['title'] == 'تداخلات مهم داروها')) {
      AppLogger.d(
          'تداخلات section not found with regex, trying alternative method');

      // Try to find تداخلات using simple string search
      final List<String> tadalholPatterns = [
        'تداخلات:',
        'تداخلات دارویی:',
        '۲. تداخلات:',
        '2. تداخلات:',
        'تداخلات دارو',
        'تداخلات مهم',
      ];

      for (final pattern in tadalholPatterns) {
        if (infoSections.contains(pattern)) {
          int startIndex = infoSections.indexOf(pattern) + pattern.length;
          int endIndex = infoSections.length;

          // Try to find where this section ends
          for (final nextPattern in ['۳', '3', 'عوارض', 'تشخیص', '۱', '1']) {
            int nextIndex = infoSections.indexOf(nextPattern, startIndex);
            if (nextIndex != -1 && nextIndex < endIndex) {
              // Make sure it's actually a section start, not part of content
              bool isNewSection = false;
              final text = infoSections.substring(
                  nextIndex, min(nextIndex + 15, infoSections.length));

              for (final sectionDef in sectionDefinitions) {
                for (final regexPattern in sectionDef['regexPatterns']) {
                  if (RegExp(regexPattern, unicode: true).hasMatch(text)) {
                    isNewSection = true;
                    break;
                  }
                }
                if (isNewSection) break;
              }

              if (isNewSection) {
                endIndex = nextIndex;
                break;
              }
            }
          }

          if (endIndex > startIndex) {
            final sectionContent =
                infoSections.substring(startIndex, endIndex).trim();

            if (sectionContent.isNotEmpty) {
              sections.add({
                'title': 'تداخلات مهم داروها',
                'content': sectionContent,
                'color': const Color(0xFFE53935), // Red
                'icon': MdiIcons.alertCircleOutline,
                'initiallyExpanded': false,
              });

              AppLogger.d(
                  'Added تداخلات section using string match with ${sectionContent.length} chars');
              break;
            }
          }
        }
      }
    }

    // Force consistent section order based on definition list
    final orderedSections = <Map<String, dynamic>>[];

    // Always add medication list first
    orderedSections
        .add(sections.firstWhere((s) => s['title'] == 'لیست داروهای نسخه'));

    // Add other sections in the defined order
    for (final sectionDef in sectionDefinitions) {
      final title = sectionDef['title'];
      final matchingSections =
          sections.where((s) => s['title'] == title).toList();

      if (matchingSections.isNotEmpty) {
        // Use the first match for each section title
        orderedSections.add(matchingSections.first);
        AppLogger.d('Ordered section: $title');
      }
    }

    // Log the final sections we found
    AppLogger.d('Final section count: ${orderedSections.length}');
    for (final section in orderedSections) {
      AppLogger.d(
          'Section: ${section['title']} with ${(section['content'] as String).length} chars');
    }

    // Build the expandable panels
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: orderedSections.map((section) {
          return ExpandablePanel(
            title: section['title'] as String,
            content: section['content'] as String,
            color: section['color'] as Color,
            icon: section['icon'] as IconData,
            initiallyExpanded: section['initiallyExpanded'] as bool,
          );
        }).toList(),
      ),
    );
  }
}

// Helper functions for safe substring operations
int min(int a, int b) => a < b ? a : b;
int max(int a, int b) => a > b ? a : b;
