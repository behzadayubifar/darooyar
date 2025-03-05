import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/services/auth_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'package:dio/dio.dart';

class ChatService {
  static const String baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService();
  final Dio _dio;

  ChatService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
          validateStatus: (status) {
            // Only treat 500+ as errors, handle 4xx separately
            return status != null && status < 500;
          },
        )) {
    // Log all requests and responses
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.network(
            options.method, '${options.baseUrl}${options.path}', null);
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.network(
          response.requestOptions.method,
          '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          response.statusCode,
          body: response.data.toString(),
        );
        return handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.network(
          error.requestOptions.method,
          '${error.requestOptions.baseUrl}${error.requestOptions.path}',
          error.response?.statusCode,
          body: error.response?.data.toString(),
          error: error.message,
        );
        return handler.next(error);
      },
    ));
  }

  Future<List<Chat>> getUserChats() async {
    AppLogger.i('Fetching user chats');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot fetch chats');
      return [];
    }

    try {
      final response = await _dio.get(
        '/chats',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Chats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.d('Chats response data: ${response.data}');
        return (response.data as List)
            .map((chatJson) => Chat.fromJson(chatJson))
            .toList();
      } else if (response.statusCode == 404) {
        // Endpoint not found - the API endpoint might not be implemented yet or has a different path
        AppLogger.w('Chats endpoint not found (404). Check API endpoint path.');
        // Check if the issue is with the API URL structure
        final alternativeResponse = await _dio.get(
          '/api/chat', // Try alternative endpoint format
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully fetched chats from alternative endpoint');
          return (alternativeResponse.data as List)
              .map((chatJson) => Chat.fromJson(chatJson))
              .toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        AppLogger.w('Authentication failed (401). Token may be invalid.');
        await _authService.logout(); // Force logout on auth failure
        return [];
      } else {
        AppLogger.w('Unexpected status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('Error fetching chats: ${e.message}');

        // Check if there's a connection issue rather than a 404
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout) {
          AppLogger.w(
              'Connection issue when fetching chats. Check internet connection.');
        }

        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error fetching chats: $e');
      }
      return [];
    }
  }

  Future<Chat?> createChat(String title) async {
    AppLogger.i('Creating a new chat with title: $title');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot create chat');
      return null;
    }

    try {
      final response = await _dio.post(
        '/chats',
        data: {'title': title},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Create chat response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.d('Create chat response data: ${response.data}');
        final chat = Chat.fromJson(response.data);
        AppLogger.i('Successfully created chat: ${chat.id}');
        return chat;
      } else if (response.statusCode == 404) {
        // Try alternative endpoint format
        AppLogger.w(
            'Chat creation endpoint not found (404). Trying alternative endpoint.');
        final alternativeResponse = await _dio.post(
          '/api/chat', // Try alternative endpoint format
          data: {'title': title},
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 201 ||
            alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully created chat using alternative endpoint');
          return Chat.fromJson(alternativeResponse.data);
        }
        AppLogger.w('Unable to create chat. Both endpoints returned 404.');
        return null;
      } else if (response.statusCode == 401) {
        AppLogger.w(
            'Authentication failed (401) when creating chat. Token may be invalid.');
        await _authService.logout(); // Force logout on auth failure
        return null;
      } else {
        AppLogger.w(
            'Unexpected status code when creating chat: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('Error creating chat: ${e.message}');

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout) {
          AppLogger.w(
              'Connection issue when creating chat. Check internet connection.');
        }

        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error creating chat: $e');
      }
      return null;
    }
  }

  Future<void> deleteChat(String chatId) async {
    final token = await _authService.getToken();
    if (token == null) {
      AppLogger.w('Attempted to delete chat while not authenticated');
      throw Exception('Not authenticated');
    }

    try {
      AppLogger.i('Deleting chat with ID: $chatId');

      final response = await _dio.delete(
        '/chats/$chatId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != 200) {
        String errorMessage;
        try {
          errorMessage = response.data['message'] ?? 'Failed to delete chat';
        } catch (e) {
          errorMessage = 'Failed to delete chat: ${response.statusCode}';
        }
        AppLogger.e('Error deleting chat: $errorMessage');
        throw Exception(errorMessage);
      }

      AppLogger.i('Chat deleted successfully: $chatId');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 405) {
        // Method not allowed - try alternative endpoint
        AppLogger.w(
            'Delete method not allowed (405). Trying alternative endpoint.');
        try {
          // Try with a POST request with _method=DELETE parameter
          final alternativeResponse = await _dio.post(
            '/chats/$chatId/delete',
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
              },
            ),
          );

          if (alternativeResponse.statusCode == 200) {
            AppLogger.i('Successfully deleted chat using alternative endpoint');
            return;
          }

          AppLogger.e('Alternative delete endpoint also failed');
          throw Exception(
              'Failed to delete chat: Method not supported by server');
        } catch (innerE) {
          AppLogger.e('Exception in alternative delete attempt: $innerE');
          throw Exception('Failed to delete chat: ${innerE.toString()}');
        }
      }

      AppLogger.e('Exception deleting chat: $e');
      throw Exception('Failed to delete chat: ${e.toString()}');
    }
  }

  Future<Chat?> updateChat(String chatId,
      {String? title, int? folderId}) async {
    final token = await _authService.getToken();
    if (token == null) {
      AppLogger.w('Attempted to update chat while not authenticated');
      return null;
    }

    try {
      AppLogger.i('Updating chat with ID: $chatId');

      // Build update data
      final Map<String, dynamic> updateData = {};
      if (title != null) {
        updateData['title'] = title;
      }
      if (folderId != null) {
        updateData['folder_id'] = folderId;
      }

      // Don't proceed if there's nothing to update
      if (updateData.isEmpty) {
        AppLogger.w('No update data provided for chat update');
        return null;
      }

      final response = await _dio.put(
        '/chats/$chatId',
        data: updateData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        AppLogger.i('Chat updated successfully: $chatId');
        return Chat.fromJson(response.data);
      } else if (response.statusCode == 404) {
        // Try alternative endpoint
        AppLogger.w(
            'Update endpoint not found (404). Trying alternative endpoint.');
        final alternativeResponse = await _dio.put(
          '/api/chats/$chatId',
          data: updateData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully updated chat using alternative endpoint');
          return Chat.fromJson(alternativeResponse.data);
        }

        String errorMessage;
        try {
          errorMessage = response.data['message'] ?? 'Failed to update chat';
        } catch (e) {
          errorMessage = 'Failed to update chat: ${response.statusCode}';
        }
        AppLogger.e('Error updating chat: $errorMessage');
        return null;
      } else {
        String errorMessage;
        try {
          errorMessage = response.data['message'] ?? 'Failed to update chat';
        } catch (e) {
          errorMessage = 'Failed to update chat: ${response.statusCode}';
        }
        AppLogger.e('Error updating chat: $errorMessage');
        return null;
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('Error updating chat: ${e.message}');
        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error updating chat: $e');
      }
      return null;
    }
  }

  Future<Message?> createMessage(
      String chatId, String content, String role) async {
    AppLogger.i('Creating a new message in chat: $chatId');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot create message');
      return null;
    }

    try {
      final response = await _dio.post(
        '/chats/$chatId/messages',
        data: {
          'content': content,
          'role': role,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Create message response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.d('Create message response data: ${response.data}');
        final message = Message.fromJson(response.data);
        AppLogger.i('Successfully created message: ${message.id}');
        return message;
      } else if (response.statusCode == 404) {
        // Try alternative endpoint format
        AppLogger.w(
            'Message creation endpoint not found (404). Trying alternative endpoint.');
        final alternativeResponse = await _dio.post(
          '/api/chat/$chatId/messages', // Try alternative endpoint format
          data: {
            'content': content,
            'role': role,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 201 ||
            alternativeResponse.statusCode == 200) {
          AppLogger.i(
              'Successfully created message using alternative endpoint');
          return Message.fromJson(alternativeResponse.data);
        }
        AppLogger.w('Unable to create message. Both endpoints returned 404.');
        return null;
      } else if (response.statusCode == 401) {
        AppLogger.w(
            'Authentication failed (401) when creating message. Token may be invalid.');
        await _authService.logout(); // Force logout on auth failure
        return null;
      } else {
        AppLogger.w(
            'Unexpected status code when creating message: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('Error creating message: ${e.message}');

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout) {
          AppLogger.w(
              'Connection issue when creating message. Check internet connection.');
        }

        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error creating message: $e');
      }
      return null;
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    final token = await _authService.getToken();
    if (token == null) {
      AppLogger.w('Attempted to delete message while not authenticated');
      throw Exception('Not authenticated');
    }

    try {
      AppLogger.i('Deleting message: $messageId from chat: $chatId');
      final response = await http.delete(
        Uri.parse('$baseUrl/chats/$chatId/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      AppLogger.network(
        'DELETE',
        '$baseUrl/chats/$chatId/messages/$messageId',
        response.statusCode,
        body: response.body,
      );

      if (response.statusCode != 200) {
        String errorMessage;
        try {
          errorMessage = jsonDecode(response.body)['message'] ??
              'Failed to delete message';
        } catch (e) {
          errorMessage = 'Failed to delete message: ${response.statusCode}';
        }
        AppLogger.e('Error deleting message: $errorMessage');
        throw Exception(errorMessage);
      }

      AppLogger.i('Message deleted successfully: $messageId');
    } catch (e) {
      AppLogger.e('Exception deleting message: $e');
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    AppLogger.i('Fetching messages for chat: $chatId');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot fetch messages');
      return [];
    }

    try {
      final response = await _dio.get(
        '/chats/$chatId/messages',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Messages response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.d('Messages response data: ${response.data}');
        return (response.data as List)
            .map((messageJson) => Message.fromJson(messageJson))
            .toList();
      } else if (response.statusCode == 404) {
        // Endpoint not found - try alternative endpoint format
        AppLogger.w(
            'Messages endpoint not found (404). Trying alternative endpoint.');

        final alternativeResponse = await _dio.get(
          '/api/chats/$chatId/messages', // Try alternative endpoint format
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 200) {
          AppLogger.i(
              'Successfully fetched messages from alternative endpoint');
          return (alternativeResponse.data as List)
              .map((messageJson) => Message.fromJson(messageJson))
              .toList();
        }

        // Try a second alternative endpoint format
        final secondAlternativeResponse = await _dio.get(
          '/api/chat/$chatId/messages', // Another possible endpoint format
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (secondAlternativeResponse.statusCode == 200) {
          AppLogger.i(
              'Successfully fetched messages from second alternative endpoint');
          return (secondAlternativeResponse.data as List)
              .map((messageJson) => Message.fromJson(messageJson))
              .toList();
        }

        AppLogger.w('Unable to fetch messages. All endpoints returned 404.');
        return [];
      } else if (response.statusCode == 401) {
        AppLogger.w('Authentication failed (401). Token may be invalid.');
        await _authService.logout(); // Force logout on auth failure
        return [];
      } else {
        AppLogger.w('Unexpected status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('Error fetching messages: ${e.message}');

        // Check if there's a connection issue rather than a 404
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout) {
          AppLogger.w(
              'Connection issue when fetching messages. Check internet connection.');
        }

        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error fetching messages: $e');
      }
      return [];
    }
  }

  // Add this method to help discover the correct API endpoints
  Future<void> discoverApiEndpoints() async {
    AppLogger.i('Starting API endpoint discovery');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot perform API discovery');
      return;
    }

    // List of potential endpoints to try
    final endpointVariations = [
      '/chats',
      '/api/chats',
      '/api/chat',
      '/chat',
      '/conversation',
      '/api/conversation',
    ];

    for (final endpoint in endpointVariations) {
      try {
        AppLogger.d('Trying endpoint: $endpoint');
        final response = await _dio.get(
          endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        AppLogger.i('Endpoint $endpoint returned ${response.statusCode}');
        if (response.statusCode == 200) {
          AppLogger.i('SUCCESS: Found working endpoint: $endpoint');
          try {
            final chats = (response.data as List)
                .map((json) => Chat.fromJson(json))
                .toList();
            AppLogger.i('Endpoint $endpoint returned ${chats.length} chats');
          } catch (e) {
            AppLogger.w(
                'Endpoint $endpoint returned 200 but data format is not compatible: $e');
          }
        }
      } catch (e) {
        AppLogger.d(
            'Endpoint $endpoint failed: ${e.toString().substring(0, min(100, e.toString().length))}');
      }
    }

    AppLogger.i('API endpoint discovery completed');
  }
}
