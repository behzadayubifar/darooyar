import '../utils/message_formatter.dart';
import '../utils/logger.dart';

/// Service to migrate old AI messages to the structured format
class MessageMigrationService {
  /// Migrates an AI message to the structured format if needed
  static String migrateAIMessage(String content) {
    // Skip migration for empty messages or already structured messages
    if (content.isEmpty || content.contains('-next-')) {
      return content;
    }

    // Check if the message is a prescription analysis
    if (MessageFormatter.isPrescriptionAnalysis(content)) {
      AppLogger.d('Migrating prescription analysis message');
      return MessageFormatter.formatAIMessage(content);
    }

    // For general AI messages, check if they need structuring
    if (content.length > 150) {
      // Check if the message has multiple paragraphs
      final paragraphs =
          content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
      if (paragraphs.length > 1) {
        AppLogger.d('Migrating multi-paragraph AI message');
        return MessageFormatter.formatAIMessage(content);
      }

      // Check if the message has bullet points
      final bulletPattern = RegExp(r'(^|\n)[•\-*]\s+', multiLine: true);
      if (bulletPattern.hasMatch(content)) {
        AppLogger.d('Migrating bullet-point AI message');
        return MessageFormatter.formatAIMessage(content);
      }
    }

    // Return the original content if no migration is needed
    return content;
  }
}
