import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = AppConstants.baseUrl;
  static const String tokenKey = 'auth_token';
  static const String hasValidTokenKey = 'has_valid_token';

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      if (token == null) {
        AppLogger.d('No token found');
        return null;
      }

      AppLogger.d('Token retrieved from storage');
      return token;
    } catch (e) {
      AppLogger.e('Error retrieving token: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      // Using secure storage for better persistence and security
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
      await prefs.setBool(
          hasValidTokenKey, true); // Flag to indicate token existence
      AppLogger.i('Token saved successfully');
    } catch (e) {
      AppLogger.e('Error saving token: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      AppLogger.i('Logging out user');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(hasValidTokenKey);
      AppLogger.i('User logged out, token removed');
    } catch (e) {
      AppLogger.e('Error during logout: $e');
    }
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('Attempting login for email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      AppLogger.network(
        'POST',
        '$baseUrl/auth/login',
        response.statusCode,
        body: response.body,
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          await saveToken(data['token']);
          AppLogger.i('Login successful for user: ${data['user']['email']}');
          return User.fromJson(data['user']);
        } catch (e) {
          AppLogger.e('Error parsing successful response: $e');
          throw Exception('Invalid server response format');
        }
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? 'Invalid credentials';
        } catch (e) {
          AppLogger.e('Error parsing error response: $e');
          if (response.body.trim().isNotEmpty) {
            errorMessage = response.body.trim();
          } else {
            errorMessage = 'Invalid credentials';
          }
        }
        AppLogger.e('Login failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('Login error: $e');
      if (e is FormatException) {
        throw Exception('Server returned an invalid response');
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<User> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      AppLogger.i('Attempting registration for email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      AppLogger.network(
        'POST',
        '$baseUrl/auth/register',
        response.statusCode,
        body: response.body,
      );

      final Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        AppLogger.e('Error parsing response: $e');
        throw Exception('Server returned an invalid response');
      }

      if (response.statusCode == 201) {
        try {
          await saveToken(responseData['token']);
          AppLogger.i(
              'Registration successful for user: ${responseData['user']['email']}');
          return User.fromJson(responseData['user']);
        } catch (e) {
          AppLogger.e('Error processing successful response: $e');
          throw Exception('Invalid server response format');
        }
      } else {
        String errorMessage = responseData['message'] ?? 'Failed to register';
        AppLogger.e('Registration failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('Registration error: $e');
      if (e is FormatException) {
        throw Exception('Server returned an invalid response');
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<User?> getCurrentUser() async {
    AppLogger.i('Getting current user');

    final token = await getToken();
    if (token == null) {
      AppLogger.d('No token found');
      return null;
    }

    // Try to validate token locally first
    try {
      // Basic check for token format - should be a JWT with 3 parts
      if (!_isValidJwtFormat(token)) {
        AppLogger.w('Token is not in valid JWT format');
        await logout();
        return null;
      }

      // Check if the token is expired
      if (_isTokenExpired(token)) {
        AppLogger.w('Token is expired');
        await logout();
        return null;
      }

      // Extract user info from token payload
      final Map<String, dynamic> payload = _decodeJwtPayload(token);
      if (!payload.containsKey('userId') || !payload.containsKey('email')) {
        AppLogger.w('Token payload missing required user fields');
        // Continue to server validation as the token format might be different
      } else {
        AppLogger.d('Token validated locally, contains user data');
      }
    } catch (e) {
      AppLogger.w('Error validating token locally: $e');
      // Continue to server validation as the local validation is just an optimization
    }

    // Validate with server
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      AppLogger.network(
        'GET',
        '$baseUrl/auth/me',
        response.statusCode,
        body: response.body,
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        AppLogger.i('Successfully retrieved user data from server');
        return User.fromJson(userData);
      } else if (response.statusCode == 404) {
        AppLogger.w(
            'Auth endpoint not found (404). Token may be invalid or expired.');
        await logout();
        return null;
      } else if (response.statusCode == 401) {
        AppLogger.w('Unauthorized (401). Token is invalid.');
        await logout();
        return null;
      } else {
        String errorMessage;
        try {
          final error = json.decode(response.body);
          errorMessage = error['message'] ?? 'Failed to get user data';
        } catch (e) {
          errorMessage = 'Unknown error: ${response.statusCode}';
        }
        AppLogger.e('Error getting user: $errorMessage');
        return null;
      }
    } catch (e) {
      AppLogger.e('Exception getting current user: $e');
      return null;
    }
  }

  // Check if token is in valid JWT format (3 parts separated by periods)
  bool _isValidJwtFormat(String token) {
    final parts = token.split('.');
    return parts.length == 3;
  }

  // Decode the JWT payload (middle part)
  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return {};
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    return json.decode(resp);
  }

  // Check if the token is expired based on the "exp" claim
  bool _isTokenExpired(String token) {
    try {
      final Map<String, dynamic> payload = _decodeJwtPayload(token);

      if (!payload.containsKey('exp')) {
        return false; // No expiration claim, assume not expired
      }

      final int expTimestamp = payload['exp'];
      final DateTime expiration =
          DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
      return DateTime.now().isAfter(expiration);
    } catch (e) {
      AppLogger.w('Error checking token expiration: $e');
      return true; // Assume expired if we can't validate
    }
  }
}
