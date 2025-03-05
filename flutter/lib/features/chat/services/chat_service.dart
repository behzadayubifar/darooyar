import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/services/auth_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService();
  final Dio _dio;

  // Add the missing variables
  Set<String> _successfulEndpoints = {};
  Set<String> _failedEndpoints = {};

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

  Future<Message?> createMessage(String chatId, String content, String role,
      {String contentType = 'text'}) async {
    AppLogger.i(
        'Creating a new message in chat: $chatId with content type: $contentType');
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
          'content_type': contentType,
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
      } else if (response.statusCode == 404 || response.statusCode == 405) {
        // Try alternative endpoint format
        AppLogger.w(
            'Message creation endpoint not found (${response.statusCode}). Trying alternative endpoint.');
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
        AppLogger.w(
            'Unable to create message. Both endpoints returned errors.');
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

  Future<Message?> uploadImageMessage(String chatId, String imagePath) async {
    AppLogger.i('Uploading image message for chat: $chatId');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot upload image');
      return null;
    }

    try {
      // Create form data with the image file
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: 'image.jpg'),
        'role': 'user',
        'content_type': 'image',
      });

      final response = await _dio.post(
        '/chats/$chatId/messages/image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          contentType: 'multipart/form-data',
        ),
      );

      AppLogger.d('Upload image response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.d('Upload image response data: ${response.data}');
        final message = Message.fromJson(response.data);
        AppLogger.i('Successfully uploaded image message: ${message.id}');
        return message;
      } else if (response.statusCode == 404) {
        // Try alternative endpoint format
        AppLogger.w(
            'Image upload endpoint not found (404). Trying alternative endpoint.');
        final alternativeFormData = FormData.fromMap({
          'image':
              await MultipartFile.fromFile(imagePath, filename: 'image.jpg'),
          'role': 'user',
          'content_type': 'image',
        });

        final alternativeResponse = await _dio.post(
          '/api/chat/$chatId/messages/image', // Try alternative endpoint format
          data: alternativeFormData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
            contentType: 'multipart/form-data',
          ),
        );

        if (alternativeResponse.statusCode == 201 ||
            alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully uploaded image using alternative endpoint');
          return Message.fromJson(alternativeResponse.data);
        }
      }

      AppLogger.w(
          'Failed to upload image: ${response.statusCode} - ${response.data}');
      return null;
    } catch (e) {
      AppLogger.e('Error uploading image: $e');
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

  // Discover API endpoints by trying different variations
  Future<void> discoverApiEndpoints() async {
    AppLogger.i('Starting API endpoint discovery');

    // Check if we have a token before proceeding
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      AppLogger.w('No auth token found, skipping API endpoint discovery');
      return;
    }

    // Load cached endpoints first
    await _loadCachedEndpoints();

    // If we already have cached successful endpoints, use them first
    if (_successfulEndpoints.isNotEmpty) {
      AppLogger.i(
          'Using ${_successfulEndpoints.length} cached successful endpoints');
      return;
    }

    // Only try to discover endpoints if we don't have cached ones
    final endpoints = [
      '/chats',
      '/chat',
      '/conversations',
      '/conversation',
      '/messages',
      '/message',
    ];

    for (final endpoint in endpoints) {
      // Skip if we already know this endpoint works
      if (_successfulEndpoints.contains(endpoint)) {
        AppLogger.i('Using cached successful endpoint: $endpoint');
        continue;
      }

      // Skip if we already know this endpoint fails
      if (_failedEndpoints.contains(endpoint)) {
        AppLogger.d('Skipping known failed endpoint: $endpoint');
        continue;
      }

      try {
        AppLogger.d('Trying endpoint: $endpoint');
        final response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {'Authorization': 'Bearer $token'},
        );

        AppLogger.network('GET', '$baseUrl$endpoint', response.statusCode);

        if (response.statusCode == 200) {
          _successfulEndpoints.add(endpoint);
          await _cacheEndpoint(endpoint, true);

          // Try to parse the response to see if it's a valid chat list
          try {
            final data = json.decode(response.body);
            if (data is List) {
              AppLogger.i('Endpoint $endpoint returned ${data.length} chats');
              // We found a working endpoint, no need to try others
              break;
            }
          } catch (e) {
            AppLogger.w('Endpoint $endpoint returned 200 but invalid JSON: $e');
          }
        } else {
          _failedEndpoints.add(endpoint);
          await _cacheEndpoint(endpoint, false);
          AppLogger.d(
              'Endpoint $endpoint failed with status ${response.statusCode}');
        }
      } catch (e) {
        _failedEndpoints.add(endpoint);
        await _cacheEndpoint(endpoint, false);
        AppLogger.w('Error trying endpoint $endpoint: $e');
      }
    }

    // Save the discovered endpoints
    await _saveCachedEndpoints();

    if (_successfulEndpoints.isEmpty) {
      AppLogger.w('No successful endpoints found during discovery');
    } else {
      AppLogger.i(
          'Discovered ${_successfulEndpoints.length} working endpoints');
    }
  }

  // Load cached endpoints from shared preferences
  Future<void> _loadCachedEndpoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final successfulJson = prefs.getString('successful_endpoints');
      final failedJson = prefs.getString('failed_endpoints');

      if (successfulJson != null) {
        final List<dynamic> successful = json.decode(successfulJson);
        _successfulEndpoints = successful.cast<String>().toSet();
        AppLogger.d(
            'Loaded ${_successfulEndpoints.length} cached successful endpoints');
      }

      if (failedJson != null) {
        final List<dynamic> failed = json.decode(failedJson);
        _failedEndpoints = failed.cast<String>().toSet();
        AppLogger.d(
            'Loaded ${_failedEndpoints.length} cached failed endpoints');
      }
    } catch (e) {
      AppLogger.e('Error loading cached endpoints: $e');
      // Reset caches if there's an error
      _successfulEndpoints = {};
      _failedEndpoints = {};
    }
  }

  // Save cached endpoints to shared preferences
  Future<void> _saveCachedEndpoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'successful_endpoints', json.encode(_successfulEndpoints.toList()));
      await prefs.setString(
          'failed_endpoints', json.encode(_failedEndpoints.toList()));
      AppLogger.d(
          'Saved ${_successfulEndpoints.length} successful and ${_failedEndpoints.length} failed endpoints');
    } catch (e) {
      AppLogger.e('Error saving cached endpoints: $e');
    }
  }

  // Cache a single endpoint result
  Future<void> _cacheEndpoint(String endpoint, bool isSuccess) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final successfulJson = prefs.getString('successful_endpoints') ?? '[]';
      final failedJson = prefs.getString('failed_endpoints') ?? '[]';

      final List<dynamic> successfulList = json.decode(successfulJson);
      final List<dynamic> failedList = json.decode(failedJson);

      final Set<String> successful = successfulList.cast<String>().toSet();
      final Set<String> failed = failedList.cast<String>().toSet();

      if (isSuccess) {
        successful.add(endpoint);
        failed.remove(endpoint);
      } else {
        failed.add(endpoint);
        successful.remove(endpoint);
      }

      await prefs.setString(
          'successful_endpoints', json.encode(successful.toList()));
      await prefs.setString('failed_endpoints', json.encode(failed.toList()));
    } catch (e) {
      AppLogger.e('Error caching endpoint $endpoint: $e');
    }
  }
}
