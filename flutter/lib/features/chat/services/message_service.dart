import 'dart:developer';
import '../../../core/api/api_client.dart';
import '../models/message.dart';
import '../../../core/utils/logger.dart';

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
          // Generate a unique request ID using timestamp to prevent duplicate responses
          final requestTimestamp = DateTime.now().millisecondsSinceEpoch;
          log('Prescription analysis request timestamp: $requestTimestamp');

          // Send the prescription for analysis with retry mechanism
          Map<String, dynamic>? analysisResponse;
          bool analysisSuccess = false;
          int retryCount = 0;
          const maxRetries = 3;

          while (!analysisSuccess && retryCount < maxRetries) {
            try {
              // Add timestamp to ensure we get a fresh analysis
              analysisResponse = await _apiClient.analyzePrescriptionText(
                content,
                requestId: 'req_$requestTimestamp',
              );
              analysisSuccess = true;
              log('Analysis response received successfully');
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
                  'request_id':
                      'req_$requestTimestamp', // Add request ID to link this response to the request
                },
              );

              log('AI message response: $aiMessageResponse');
              break;
            } catch (retryError) {
              retryCount++;
              log('Error during prescription analysis (attempt $retryCount): $retryError');
              if (retryCount < maxRetries) {
                log('Retrying prescription analysis in 2 seconds...');
                await Future.delayed(Duration(seconds: 2));
              }
            }
          }

          if (!analysisSuccess) {
            log('Failed to analyze prescription after $maxRetries attempts');
            // Create a fallback message to inform the user
            await _apiClient.post(
              'chats/$chatId/messages',
              data: {
                'chat_id': chatId,
                'content':
                    'متأسفانه در تحلیل نسخه خطایی رخ داد. لطفا دوباره تلاش کنید یا با پشتیبانی تماس بگیرید.',
                'role': 'system',
                'content_type': 'error',
                'request_id':
                    'req_$requestTimestamp', // Add request ID to link this error to the request
              },
            );
          }
        } catch (analysisError) {
          log('Unhandled error during prescription analysis: $analysisError');
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
