import 'dart:io';
import 'package:riverpod/riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../../../core/utils/logger.dart';

class ChatApiService {
  final ApiClient _apiClient;

  ChatApiService(this._apiClient);

  // Get all chats for the current user
  Future<List<Chat>> getUserChats() async {
    try {
      final response = await _apiClient.get('api/chats');
      final List<dynamic> chatsJson = response['data'] ?? [];
      return chatsJson.map((json) => Chat.fromJson(json)).toList();
    } catch (e) {
      AppLogger.e('Error fetching chats: $e');
      return [];
    }
  }

  // Get a single chat by ID
  Future<Chat?> getChat(int chatId) async {
    try {
      final response = await _apiClient.get('api/chats/$chatId');
      return Chat.fromJson(response['data']);
    } catch (e) {
      AppLogger.e('Error fetching chat: $e');
      return null;
    }
  }

  // Create a new chat
  Future<Chat?> createChat(String title) async {
    try {
      final response = await _apiClient.post('api/chats', data: {
        'title': title,
      });
      return Chat.fromJson(response['data']);
    } catch (e) {
      AppLogger.e('Error creating chat: $e');
      return null;
    }
  }

  // Delete a chat
  Future<bool> deleteChat(int chatId) async {
    try {
      await _apiClient.delete('api/chats/$chatId');
      return true;
    } catch (e) {
      AppLogger.e('Error deleting chat: $e');
      return false;
    }
  }

  // Get all messages for a chat
  Future<List<Message>> getChatMessages(int chatId) async {
    try {
      final response = await _apiClient.get('api/chats/$chatId/messages');
      final List<dynamic> messagesJson = response['data'] ?? [];
      return messagesJson.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      AppLogger.e('Error fetching messages: $e');
      return [];
    }
  }

  // Send a text message
  Future<Message?> sendTextMessage(int chatId, String content) async {
    try {
      final response =
          await _apiClient.post('api/chats/$chatId/messages', data: {
        'role': 'user',
        'content': content,
      });
      return Message.fromJson(response['data']);
    } catch (e) {
      AppLogger.e('Error sending text message: $e');
      return null;
    }
  }

  // Send an image message
  Future<Message?> sendImageMessage(int chatId, String imagePath) async {
    try {
      final file = File(imagePath);
      final response = await _apiClient.uploadFile(
        'api/chats/$chatId/messages',
        file,
        fields: {
          'role': 'user',
          'content_type': 'image',
        },
        fileFieldName: 'image',
      );
      return Message.fromJson(response['data']);
    } catch (e) {
      AppLogger.e('Error sending image message: $e');
      return null;
    }
  }
}

final chatApiServiceProvider = Provider<ChatApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatApiService(apiClient);
});
