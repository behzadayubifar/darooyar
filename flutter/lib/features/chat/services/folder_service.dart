import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/services/auth_service.dart';
import '../models/folder.dart';

class FolderService {
  static const String baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService();
  final Dio _dio;

  FolderService()
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

  Future<List<Folder>> getUserFolders() async {
    AppLogger.i('Fetching user folders');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot fetch folders');
      return [];
    }

    try {
      final response = await _dio.get(
        '/folders',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Folders response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.d('Folders response data: ${response.data}');
        return (response.data as List)
            .map((folderJson) => Folder.fromJson(folderJson))
            .toList();
      } else if (response.statusCode == 404) {
        // Endpoint not found - the API endpoint might not be implemented yet or has a different path
        AppLogger.w(
            'Folders endpoint not found (404). Check API endpoint path.');
        // Check if the issue is with the API URL structure
        final alternativeResponse = await _dio.get(
          '/api/folders', // Try alternative endpoint format
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully fetched folders from alternative endpoint');
          return (alternativeResponse.data as List)
              .map((folderJson) => Folder.fromJson(folderJson))
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
        AppLogger.e('Error fetching folders: ${e.message}');

        // Check if there's a connection issue rather than a 404
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout) {
          AppLogger.w(
              'Connection issue when fetching folders. Check internet connection.');
        }

        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error fetching folders: $e');
      }
      return [];
    }
  }

  Future<Folder?> getFolder(int id) async {
    AppLogger.i('Fetching folder with ID: $id');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot fetch folder');
      return null;
    }

    try {
      final response = await _dio.get(
        '/folders/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Get folder response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.d('Get folder response data: ${response.data}');
        return Folder.fromJson(response.data);
      } else if (response.statusCode == 404) {
        // Try alternative endpoint format
        AppLogger.w(
            'Folder endpoint not found (404). Trying alternative endpoint.');
        final alternativeResponse = await _dio.get(
          '/api/folders/$id', // Try alternative endpoint format
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully fetched folder using alternative endpoint');
          return Folder.fromJson(alternativeResponse.data);
        }
        AppLogger.w('Folder not found or endpoint not available');
        return null;
      } else if (response.statusCode == 401) {
        AppLogger.w(
            'Authentication failed (401) when fetching folder. Token may be invalid.');
        await _authService.logout(); // Force logout on auth failure
        return null;
      } else {
        AppLogger.w(
            'Unexpected status code when fetching folder: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('Error fetching folder: ${e.message}');
        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error fetching folder: $e');
      }
      return null;
    }
  }

  Future<Folder?> createFolder(String name, {String? color}) async {
    AppLogger.i('Creating a new folder with name: $name, color: $color');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot create folder');
      return null;
    }

    try {
      final Map<String, dynamic> data = {'name': name};
      if (color != null) {
        data['color'] = color;
      }

      final response = await _dio.post(
        '/folders',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Create folder response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.d('Create folder response data: ${response.data}');
        final folder = Folder.fromJson(response.data);
        AppLogger.i('Successfully created folder: ${folder.id}');
        return folder;
      } else if (response.statusCode == 404) {
        // Try alternative endpoint format
        AppLogger.w(
            'Folder creation endpoint not found (404). Trying alternative endpoint.');
        final alternativeResponse = await _dio.post(
          '/api/folders', // Try alternative endpoint format
          data: data,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 201 ||
            alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully created folder using alternative endpoint');
          return Folder.fromJson(alternativeResponse.data);
        }
        AppLogger.w('Unable to create folder. Both endpoints returned 404.');
        return null;
      } else if (response.statusCode == 401) {
        AppLogger.w(
            'Authentication failed (401) when creating folder. Token may be invalid.');
        await _authService.logout(); // Force logout on auth failure
        return null;
      } else {
        AppLogger.w(
            'Unexpected status code when creating folder: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('Error creating folder: ${e.message}');
        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error creating folder: $e');
      }
      return null;
    }
  }

  Future<Folder?> updateFolder(int id, String name, {String? color}) async {
    AppLogger.i(
        'Updating folder with ID: $id, new name: $name, new color: $color');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot update folder');
      return null;
    }

    try {
      final Map<String, dynamic> data = {'name': name};
      if (color != null) {
        data['color'] = color;
      }

      final response = await _dio.put(
        '/folders/$id',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Update folder response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.d('Update folder response data: ${response.data}');
        final folder = Folder.fromJson(response.data);
        AppLogger.i('Successfully updated folder: ${folder.id}');
        return folder;
      } else if (response.statusCode == 404) {
        // Try alternative endpoint format
        AppLogger.w(
            'Folder update endpoint not found (404). Trying alternative endpoint.');
        final alternativeResponse = await _dio.put(
          '/api/folders/$id', // Try alternative endpoint format
          data: data,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully updated folder using alternative endpoint');
          return Folder.fromJson(alternativeResponse.data);
        }
        AppLogger.w('Unable to update folder. Both endpoints returned 404.');
        return null;
      } else if (response.statusCode == 401) {
        AppLogger.w(
            'Authentication failed (401) when updating folder. Token may be invalid.');
        await _authService.logout(); // Force logout on auth failure
        return null;
      } else {
        AppLogger.w(
            'Unexpected status code when updating folder: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('Error updating folder: ${e.message}');
        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error updating folder: $e');
      }
      return null;
    }
  }

  Future<bool> deleteFolder(int id) async {
    AppLogger.i('Deleting folder with ID: $id');
    final token = await _authService.getToken();

    if (token == null) {
      AppLogger.w('No token available, cannot delete folder');
      return false;
    }

    try {
      final response = await _dio.delete(
        '/folders/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      AppLogger.d('Delete folder response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.i('Successfully deleted folder: $id');
        return true;
      } else if (response.statusCode == 404) {
        // Try alternative endpoint format
        AppLogger.w(
            'Folder deletion endpoint not found (404). Trying alternative endpoint.');
        final alternativeResponse = await _dio.delete(
          '/api/folders/$id', // Try alternative endpoint format
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (alternativeResponse.statusCode == 200) {
          AppLogger.i('Successfully deleted folder using alternative endpoint');
          return true;
        }
        AppLogger.w('Unable to delete folder. Both endpoints returned 404.');
        return false;
      } else if (response.statusCode == 401) {
        AppLogger.w(
            'Authentication failed (401) when deleting folder. Token may be invalid.');
        await _authService.logout(); // Force logout on auth failure
        return false;
      } else {
        AppLogger.w(
            'Unexpected status code when deleting folder: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        AppLogger.e('Error deleting folder: ${e.message}');
        AppLogger.d('DioException type: ${e.type}');
        if (e.response != null) {
          AppLogger.d('Error response: ${e.response?.data}');
        }
      } else {
        AppLogger.e('Unexpected error deleting folder: $e');
      }
      return false;
    }
  }

  /// Explicitly refresh folder data to update chat counts
  Future<List<Folder>> refreshFolders() async {
    AppLogger.i('Explicitly refreshing folder data');
    // Force a fresh request to the server
    return await getUserFolders();
  }
}
