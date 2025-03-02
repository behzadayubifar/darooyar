import 'package:flutter/foundation.dart';
import '../../features/prescription/domain/entities/prescription_message_entity.dart';
import 'database_service.dart';
import 'message_formatter.dart';

/// Service to migrate existing AI messages to the structured format
class MessageMigrationService {
  final DatabaseService _databaseService;

  MessageMigrationService({
    required DatabaseService databaseService,
  }) : _databaseService = databaseService;

  /// Migrates all AI messages to the structured format
  Future<void> migrateAIMessages() async {
    try {
      // Get all prescriptions
      final prescriptions = await _databaseService.getAllPrescriptions();

      // For each prescription, get all AI messages
      for (final prescription in prescriptions) {
        final messages =
            await _databaseService.getMessagesByPrescriptionId(prescription.id);

        // Filter for AI messages
        final aiMessages =
            messages.where((msg) => msg.type == MessageType.ai).toList();

        // Update each AI message if needed
        for (final message in aiMessages) {
          // Skip messages that are already in the structured format
          if (MessageFormatter.isStructuredFormat(message.content)) {
            continue;
          }

          // Format the message
          final formattedContent =
              MessageFormatter.formatAIMessage(message.content);

          // Skip if the formatter couldn't structure the message
          if (!MessageFormatter.isStructuredFormat(formattedContent)) {
            continue;
          }

          // Update the message in the database
          final updatedMessage = PrescriptionMessageEntity(
            id: message.id,
            prescriptionId: message.prescriptionId,
            type: message.type,
            content: formattedContent,
            timestamp: message.timestamp,
          );

          await _databaseService.updateMessage(updatedMessage);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error migrating AI messages: $e');
      }
    }
  }
}
