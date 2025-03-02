import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'expandable_panel.dart';

class StructuredMedicationInfo extends StatelessWidget {
  final String content;

  const StructuredMedicationInfo({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the content follows the structured format
    if (!content.contains('-next-')) {
      // If not structured, return the original content
      return Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          color: AppTheme.textPrimaryColor,
        ),
      );
    }

    // Parse the structured content
    final parts = content.split('-next-');
    if (parts.length != 2) {
      return Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          color: AppTheme.textPrimaryColor,
        ),
      );
    }

    final medicationList = parts[0].trim();
    final infoSections = parts[1].trim();

    // Parse the information sections
    final List<Map<String, dynamic>> sections = [
      {
        'title': 'لیست داروهای نسخه',
        'content': medicationList,
        'color': AppTheme.primaryColor,
        'icon': MdiIcons.pill,
        'initiallyExpanded': true,
      }
    ];

    // Define section patterns and their properties
    final sectionPatterns = [
      {
        'pattern': '۱. تشخیص احتمالی عارضه یا بیماری:',
        'title': 'تشخیص احتمالی',
        'color': const Color(0xFF43A047), // Green
        'icon': MdiIcons.stethoscope,
      },
      {
        'pattern': '۲. تداخلات مهم داروها که باید به بیمار گوشزد شود:',
        'title': 'تداخلات مهم داروها',
        'color': const Color(0xFFE53935), // Red
        'icon': MdiIcons.alertCircleOutline,
      },
      {
        'pattern':
            '۳. عوارض مهم و شایعی که حتما باید بیمار در مورد این داروها یادش باشد:',
        'title': 'عوارض مهم و شایع',
        'color': const Color(0xFFFF9800), // Orange
        'icon': MdiIcons.informationOutline,
      },
      {
        'pattern': '۴. اگر دارویی را باید در زمان خاصی از روز مصرف کرد:',
        'title': 'زمان مصرف داروها',
        'color': const Color(0xFF2196F3), // Blue
        'icon': MdiIcons.clockOutline,
      },
      {
        'pattern': '۵. اگر دارویی رو باید با فاصله از غذا یا با غذا مصرف کرد:',
        'title': 'نحوه مصرف با غذا',
        'color': const Color(0xFF9C27B0), // Purple
        'icon': MdiIcons.foodApple,
      },
      {
        'pattern': '۶. تعداد مصرف روزانه هر دارو:',
        'title': 'تعداد مصرف روزانه',
        'color': const Color(0xFF00BCD4), // Cyan
        'icon': MdiIcons.calendarClock,
      },
      {
        'pattern':
            '۷. اگر برای عارضه‌ای که داروها میدهند نیاز به مدیریت خاصی وجود دارد که باید اطلاع بدم بگو:',
        'title': 'مدیریت خاص',
        'color': const Color(0xFF795548), // Brown
        'icon': MdiIcons.shieldCross,
      },
    ];

    // Extract each section's content
    String remainingText = infoSections;

    for (int i = 0; i < sectionPatterns.length; i++) {
      final pattern = sectionPatterns[i]['pattern'] as String;

      if (remainingText.contains(pattern)) {
        final startIndex = remainingText.indexOf(pattern);
        final endIndex = i < sectionPatterns.length - 1
            ? remainingText.indexOf(
                sectionPatterns[i + 1]['pattern'] as String, startIndex)
            : remainingText.length;

        if (endIndex > startIndex) {
          final sectionContent = remainingText
              .substring(startIndex + pattern.length, endIndex)
              .trim();

          if (sectionContent.isNotEmpty && sectionContent != "-") {
            sections.add({
              'title': sectionPatterns[i]['title'],
              'content': sectionContent,
              'color': sectionPatterns[i]['color'],
              'icon': sectionPatterns[i]['icon'],
              'initiallyExpanded': false,
            });
          }
        }
      }
    }

    // Build the expandable panels
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections.map((section) {
        return ExpandablePanel(
          title: section['title'] as String,
          content: section['content'] as String,
          color: section['color'] as Color,
          icon: section['icon'] as IconData,
          initiallyExpanded: section['initiallyExpanded'] as bool,
        );
      }).toList(),
    );
  }
}
