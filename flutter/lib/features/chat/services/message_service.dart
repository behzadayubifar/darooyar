import 'dart:developer';
import '../../../core/api/api_client.dart';
import '../models/message.dart';

class MessageService {
  final ApiClient _apiClient;

  MessageService(this._apiClient);

  Future<List<Message>> getMessages(int chatId) async {
    try {
      log('Fetching messages for chat ID: $chatId');
      final response = await _apiClient.get('chats/$chatId/messages');
      log('Received messages response: $response');

      final List<dynamic> messagesJson = response['data'] ?? [];
      return messagesJson.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<Message> sendMessage(
      int chatId, String content, bool isPrescription) async {
    try {
      log('Sending message to chat ID: $chatId, isPrescription: $isPrescription');
      log('Message content: $content');

      // First, create and return the user message
      final userMessageResponse = await _apiClient.post(
        'chats/$chatId/messages',
        data: {
          'chat_id': chatId,
          'content': content,
          'role': 'user',
          'content_type': 'text',
        },
      );

      log('User message response: $userMessageResponse');

      // If this is a prescription analysis request, send it for analysis
      if (isPrescription) {
        log('Processing prescription analysis');
        try {
          // Send the prescription for analysis
          final analysisResponse =
              await _apiClient.analyzePrescriptionText(content);
          log('Analysis response: $analysisResponse');

          // Create the AI response message
          final aiMessageResponse = await _apiClient.post(
            'chats/$chatId/messages',
            data: {
              'chat_id': chatId,
              'content':
                  analysisResponse['analysis'] ?? 'No analysis available',
              'role': 'assistant',
              'content_type': 'text',
            },
          );

          log('AI message response: $aiMessageResponse');
        } catch (analysisError) {
          log('Error during prescription analysis: $analysisError');
          // Still return the user message even if analysis fails
        }
      }

      return Message.fromJson(userMessageResponse['data']);
    } catch (e) {
      log('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }
}
