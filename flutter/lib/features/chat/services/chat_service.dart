import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/services/auth_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'mock_chat_service.dart'; // Add import for MockChatService
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Add prescription response template
const String prescriptionPromptTemplate = '''
من مسئول فنی یک داروخانه شهری هستم

خوب فکر کن و تمام جوانب رو بررسی کن و با استدلال جواب بده

و چند مورد رو به این شکل به من در مورد این نسخه جواب بده:

۱. تشخیص احتمالی عارضه یا بیماری

۲. تداخلات مهم داروها که باید به بیمار گوشزد شود

۳. عوارض مهم و شایعی که حتما باید بیمار در مورد این داروها یادش باشد

۴. اگر دارویی را باید در زمان خاصی از روز مصرف کرد

۵. اگر دارویی رو باید با فاصله از غذا یا با غذا مصرف کرد

۶. تعداد مصرف روزانه هر دارو

۷. اگر برای عارضه‌ای که داروها میدهند نیاز به مدیریت خاصی وجود دارد که باید اطلاع بدم بگو
''';

class ChatService {
  static const String baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService();
  final Dio _dio;

  // Add mock service reference
  final MockChatService? _mockService;
  final bool _useMockService;

  // Add the missing variables
  Set<String> _successfulEndpoints = {};
  Set<String> _failedEndpoints = {};

  // Regular constructor
  ChatService()
      : _mockService = null,
        _useMockService = false,
        _dio = Dio(BaseOptions(
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

  // New constructor that takes a MockChatService
  ChatService.fromMock(MockChatService mockService)
      : _mockService = mockService,
        _useMockService = true,
        _dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
        )) {
    AppLogger.i('Using MockChatService for offline operation');
  }

  Future<List<Chat>> getUserChats() async {
    if (_useMockService && _mockService != null) {
      AppLogger.i('Using mock service to get user chats');
      return _mockService.getUserChats();
    }

    AppLogger.i('Fetching user chats from API');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot fetch chats');
      return [];
    }

    try {
      final response = await _dio.get(
        '/chats', // baseUrl already includes '/api'
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Get chats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Check if response.data is a Map and contains 'data' key
        if (response.data is Map && response.data.containsKey('data')) {
          final List<dynamic> chatsJson = response.data['data'];
          try {
            return chatsJson.map((json) => Chat.fromJson(json)).toList();
          } catch (parseError) {
            AppLogger.e('Error parsing chat data: $parseError');
            return [];
          }
        } else {
          // Handle case where response doesn't have expected structure
          AppLogger.w('Unexpected response format: ${response.data}');

          // If response.data is directly a List, try to use it
          if (response.data is List) {
            try {
              return (response.data as List)
                  .map((json) => Chat.fromJson(json))
                  .toList();
            } catch (parseError) {
              AppLogger.e('Error parsing direct list data: $parseError');
              return [];
            }
          }
          return [];
        }
      } else {
        AppLogger.w(
            'Failed to fetch chats: ${response.statusCode} - ${response.data}');
        return [];
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('DioException fetching chats: ${e.message}');
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout) {
          AppLogger.w(
              'Connection issue when fetching chats. Check internet connection.');
        }
      } else {
        AppLogger.e('Unexpected error fetching chats: $e');
      }
      return [];
    }
  }

  Future<Chat?> createChat(String title) async {
    if (_useMockService && _mockService != null) {
      AppLogger.i('Using mock service to create chat');
      return _mockService.createChat(title);
    }

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
    if (_useMockService && _mockService != null) {
      AppLogger.i('Using mock service to delete chat: $chatId');
      // Try to parse the ID or use a fallback ID
      int numericId = 1;
      try {
        numericId = int.parse(chatId);
      } catch (e) {
        AppLogger.w('Invalid chat ID format: $chatId, using default');
      }

      final deleted = await _mockService.deleteChat(numericId);
      if (!deleted) {
        throw Exception('Failed to delete chat: Chat not found');
      }
      return;
    }

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

  // Helper method to try different endpoint formats
  Future<Message?> _tryMultipleEndpoints(
    String chatId,
    String content,
    String role,
    String contentType,
    String token,
  ) async {
    // First, verify if the chat exists
    try {
      AppLogger.d('Verifying if chat exists: $chatId');
      final chatResponse = await _dio.get(
        '/chats/$chatId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (chatResponse.statusCode != 200) {
        AppLogger.e(
            'Chat $chatId doesn\'t exist or is inaccessible: ${chatResponse.statusCode}');
        AppLogger.d('Response: ${chatResponse.data}');
      } else {
        AppLogger.i('Chat $chatId exists and is accessible');
      }
    } catch (e) {
      AppLogger.d('Error verifying chat: $e');
      // Continue trying to send the message anyway
    }

    // List of possible endpoint patterns to try
    final endpoints = [
      '/messages', // Main endpoint with chat_id in body
      '/chats/$chatId/messages', // RESTful endpoint
      '/chat/$chatId/messages', // Alternative RESTful endpoint
      'messages', // Without leading slash
      'chats/$chatId/messages',
      'chat/$chatId/messages',
      '/api/messages', // Try with explicit /api prefix
      '/api/chats/$chatId/messages',
      '/api/chat/$chatId/messages',
    ];

    int? chatIdInt;
    try {
      chatIdInt = int.parse(chatId);
    } catch (e) {
      AppLogger.w('Failed to parse chatId to int: $e');
      return null;
    }

    for (final endpoint in endpoints) {
      try {
        AppLogger.d('Trying endpoint: $endpoint');

        // For endpoints with 'messages' in the root path, include chat_id in body
        final Map<String, dynamic> data = {
          'content': content,
          'role': role,
          'content_type': contentType,
        };

        if (endpoint == '/messages' ||
            endpoint == 'messages' ||
            endpoint == '/api/messages') {
          data['chat_id'] = chatIdInt;
        }

        // Handle full URL vs relative path
        final String url = endpoint.startsWith('/api')
            ? endpoint.replaceFirst(
                '/api', '') // Remove duplicate /api if present
            : endpoint;

        final response = await _dio.post(
          url,
          data: data,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        AppLogger.d('Response status from $endpoint: ${response.statusCode}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          AppLogger.i('Successfully created message using endpoint: $endpoint');

          // Check if the response has a 'data' field
          dynamic messageData = response.data;
          if (response.data is Map && response.data.containsKey('data')) {
            messageData = response.data['data'];
          }

          return Message.fromJson(messageData);
        }
      } catch (e) {
        AppLogger.d('Endpoint $endpoint failed: $e');
        if (e is DioException && e.response != null) {
          AppLogger.d('Response data: ${e.response?.data}');
        }
      }
    }

    // As a last resort, use the http package instead of Dio
    try {
      AppLogger.d('Trying with http package instead of Dio');
      final url = Uri.parse('${baseUrl.replaceFirst("/api", "")}/api/messages');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatIdInt,
          'content': content,
          'role': role,
          'content_type': contentType,
        }),
      );

      AppLogger.d('HTTP package response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        dynamic messageData = data;
        if (data is Map && data.containsKey('data')) {
          messageData = data['data'];
        }

        return Message.fromJson(messageData);
      }
    } catch (e) {
      AppLogger.e('HTTP package attempt failed: $e');
    }

    AppLogger.w('All endpoints failed for creating a message');
    return null;
  }

  Future<Message?> createMessage(String chatId, String content, String role,
      {String contentType = 'text'}) async {
    if (_useMockService && _mockService != null) {
      AppLogger.i('Using mock service to create message in chat: $chatId');
      // Try to parse the ID or use a fallback ID
      int numericId = 1;
      try {
        numericId = int.parse(chatId);
      } catch (e) {
        AppLogger.w('Invalid chat ID format: $chatId, using default');
      }

      return _mockService.sendTextMessage(numericId, content);
    }

    AppLogger.i(
        'Creating a new message in chat: $chatId with content type: $contentType');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot create message');
      return null;
    }

    // Verify token validity and check if the chat ID exists
    try {
      AppLogger.i('Verifying authentication token and chat access');

      // First, verify token is valid
      final tokenVerifyResponse = await _dio.get(
        '/auth/verify',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (tokenVerifyResponse.statusCode != 200) {
        AppLogger.e(
            'Token verification failed: ${tokenVerifyResponse.statusCode}');
        // Try to refresh the token or force user to login again
        await _authService.logout();
        return null;
      }

      AppLogger.i('Token verified successfully');

      // Next, check if the chat exists and is accessible
      final chatResponse = await _dio.get(
        '/chats/$chatId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (chatResponse.statusCode != 200) {
        AppLogger.e(
            'Chat $chatId not found or not accessible: ${chatResponse.statusCode}');
        AppLogger.d('Chat response: ${chatResponse.data}');
        // The chat ID might not exist or user doesn't have permission
      } else {
        AppLogger.i('Chat $chatId exists and is accessible');
      }
    } catch (e) {
      AppLogger.d('Error in pre-checks: $e');
      // Continue anyway, the message creation endpoints will perform their own validation
    }

    try {
      // Try multiple endpoints to find one that works
      final message = await _tryMultipleEndpoints(
          chatId, content, role, contentType, token);

      if (message != null) {
        return message;
      }

      AppLogger.e('Failed to create message: all endpoints returned errors');
      return null;
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
          AppLogger.d('Response data: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error creating message: $e');
      }
      return null;
    }
  }

  Future<Message?> uploadImageMessage(String chatId, String imagePath) async {
    if (_useMockService && _mockService != null) {
      AppLogger.i('Using mock service to upload image in chat: $chatId');
      // Try to parse the ID or use a fallback ID
      int numericId = 1;
      try {
        numericId = int.parse(chatId);
      } catch (e) {
        AppLogger.w('Invalid chat ID format: $chatId, using default');
      }

      return _mockService.sendImageMessage(numericId, imagePath);
    }

    AppLogger.i('Uploading image message for chat: $chatId, path: $imagePath');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot upload image');
      return null;
    }

    try {
      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        AppLogger.e('Image file does not exist: $imagePath');
        throw Exception('Image file does not exist');
      }

      // Get file info
      final fileSize = await file.length();
      final fileName = imagePath.split('/').last;
      AppLogger.d(
          'Image file: $fileName, size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // Default
      if (fileName.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }

      AppLogger.d('Using content type: $contentType for file: $fileName');

      // Create form data with the image file
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
        'role': 'user',
        'content_type': 'image',
      });

      // Log request details
      AppLogger.d(
          'Sending image upload request to: /chats/$chatId/messages/image');
      AppLogger.d('Form data: ${formData.fields}');

      // Set longer timeouts for image upload
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      );

      final response = await _dio.post(
        '/chats/$chatId/messages/image', // baseUrl already includes '/api'
        data: formData,
        options: options,
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
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
          'role': 'user',
          'content_type': 'image',
        });

        final alternativeResponse = await _dio.post(
          '/chat/$chatId/messages/image', // baseUrl already includes '/api'
          data: alternativeFormData,
          options: options,
        );

        if (alternativeResponse.statusCode == 201 ||
            alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully uploaded image using alternative endpoint');
          return Message.fromJson(alternativeResponse.data);
        }

        // Try another alternative endpoint if the first one fails
        final alternativeResponse2 = await _dio.post(
          '/api/chats/$chatId/messages/image',
          data: alternativeFormData,
          options: options,
        );

        if (alternativeResponse2.statusCode == 201 ||
            alternativeResponse2.statusCode == 200) {
          AppLogger.i(
              'Successfully uploaded image using second alternative endpoint');
          return Message.fromJson(alternativeResponse2.data);
        }
      }

      AppLogger.w(
          'Failed to upload image: ${response.statusCode} - ${response.data}');
      return null;
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('DioException uploading image: ${e.message}');
        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Error uploading image: $e');
      }
      return null;
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    if (_useMockService && _mockService != null) {
      AppLogger.i(
          'Using mock service to delete message: $messageId from chat: $chatId');
      // Call mock method if added in the future
      return;
    }

    final token = await _authService.getToken();
    if (token == null) {
      AppLogger.w('Attempted to delete message while not authenticated');
      throw Exception('Not authenticated');
    }

    try {
      AppLogger.i('Deleting message: $messageId from chat: $chatId');

      // Note: In this case, we're constructing a full URL with http client directly
      // baseUrl already contains "/api", so we need to be careful not to duplicate it
      final url = Uri.parse('$baseUrl/chats/$chatId/messages/$messageId'
          .replaceAll('/api/api/', '/api/'));

      AppLogger.d('Delete message URL: $url');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      AppLogger.network(
        'DELETE',
        url.toString(),
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
    if (_useMockService && _mockService != null) {
      AppLogger.i('Using mock service to get messages for chat: $chatId');
      // Try to parse the ID or use a fallback ID
      int numericId = 1;
      try {
        numericId = int.parse(chatId);
      } catch (e) {
        AppLogger.w('Invalid chat ID format: $chatId, using default');
      }

      return _mockService!.getChatMessages(numericId);
    }

    AppLogger.i('Fetching messages for chat: $chatId');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot fetch messages');
      return [];
    }

    try {
      // Increase timeout for potentially large responses
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
      );

      final response = await _dio.get(
        '/chats/$chatId/messages', // baseUrl already includes '/api'
        options: options,
      );

      AppLogger.d('Messages response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.d('Messages response data: ${response.data}');

        // Check if we got a valid response
        if (response.data is List) {
          List<Message> messages = [];
          for (var messageJson in response.data) {
            try {
              final message = Message.fromJson(messageJson);
              // Log complete message content for debugging
              if (message.role == 'assistant') {
                AppLogger.d('Assistant message: [ID: ${message.id}] '
                    'Length: ${message.content.length} chars');

                // Log more detailed message info for large responses
                if (message.content.length > 1000) {
                  AppLogger.d(
                      '   Content starts with: ${message.content.substring(0, min(100, message.content.length))}');
                  AppLogger.d(
                      '   Content ends with: ${message.content.substring(max(0, message.content.length - 100))}');

                  // Check if content might be truncated
                  final bool mightBeTruncated = message.content.length > 2000 &&
                      !message.content.contains('۷.');
                  if (mightBeTruncated) {
                    AppLogger.w(
                        '   ⚠️ Content might be truncated. Length: ${message.content.length}');
                  }
                }
              }
              messages.add(message);
            } catch (e) {
              AppLogger.e('Error parsing message: $e');
              AppLogger.d('Problematic message JSON: $messageJson');
            }
          }
          return messages;
        } else {
          AppLogger.e(
              'Unexpected response format: ${response.data.runtimeType}');
          return [];
        }
      } else if (response.statusCode == 404) {
        // Endpoint not found - try alternative endpoint format
        AppLogger.w(
            'Messages endpoint not found (404). Trying alternative endpoint.');

        // First fallback - try without '/api' prefix since baseUrl already has it
        final alternativeResponse = await _dio.get(
          '/chats/$chatId/messages?format=alternative', // Add query param to differentiate
          options: options,
        );

        if (alternativeResponse.statusCode == 200) {
          AppLogger.i(
              'Successfully fetched messages from alternative endpoint');
          return (alternativeResponse.data as List)
              .map((messageJson) => Message.fromJson(messageJson))
              .toList();
        }

        // Second fallback - try different path structure
        final secondAlternativeResponse = await _dio.get(
          '/chat/$chatId/messages', // baseUrl already includes '/api'
          options: options,
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

  // Diagnostic method to test various API endpoints
  Future<Map<String, dynamic>> runApiDiagnostics() async {
    final results = <String, dynamic>{};
    final token = await _authService.getToken();

    if (token == null) {
      return {'error': 'No authentication token available'};
    }

    // List of endpoints to test
    final endpoints = [
      // Auth endpoints
      {'method': 'GET', 'path': '/auth/verify', 'name': 'Verify Token'},
      {'method': 'GET', 'path': '/auth/me', 'name': 'Get User Info'},

      // Chat endpoints
      {'method': 'GET', 'path': '/chats', 'name': 'List Chats'},

      // Server info
      {'method': 'GET', 'path': '/health', 'name': 'Health Check'},
    ];

    for (final endpoint in endpoints) {
      try {
        final path = endpoint['path'] as String;
        final method = endpoint['method'] as String;
        final name = endpoint['name'] as String;

        Response? response;

        if (method == 'GET') {
          response = await _dio.get(
            path,
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
              },
            ),
          );
        }

        results[name] = {
          'status': response?.statusCode,
          'success': response?.statusCode == 200,
          'data': response?.data,
        };
      } catch (e) {
        // Get the endpoint name safely
        String endpointName = 'Unknown Endpoint';
        try {
          endpointName = endpoint['name'] as String;
        } catch (_) {}

        if (e is DioException) {
          results[endpointName] = {
            'error': e.message,
            'type': e.type.toString(),
            'response': e.response?.statusCode,
            'data': e.response?.data,
          };
        } else {
          results[endpointName] = {'error': e.toString()};
        }
      }
    }

    // Add server info
    results['Server Info'] = {
      'baseUrl': baseUrl,
      'timeout': _dio.options.connectTimeout?.inSeconds,
    };

    // Add user info
    results['User Info'] = {
      'token_available': token != null,
      'token_length': token != null ? token.length : 0,
    };

    AppLogger.i(
        'API Diagnostics completed: ${results.length} endpoints tested');
    return results;
  }
}

// Helper functions for safe substring operations
int min(int a, int b) => a < b ? a : b;
int max(int a, int b) => a > b ? a : b;
