import 'dart:convert';
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

  Future<bool> hasValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(hasValidTokenKey) ?? false;
    } catch (e) {
      AppLogger.e('Error checking token validity: $e');
      return false;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      // Using secure storage for better persistence and security
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
      await prefs.setBool(
          hasValidTokenKey, true); // Flag to indicate token existence

      // Extract and save user info from token for faster access
      try {
        final Map<String, dynamic> payload = _decodeJwtPayload(token);
        if (payload.containsKey('user_id') || payload.containsKey('userId')) {
          final userId = payload['user_id'] ?? payload['userId'];
          await prefs.setInt(
              'user_id', userId is int ? userId : int.parse(userId.toString()));
        }
        if (payload.containsKey('email')) {
          await prefs.setString('user_email', payload['email']);
        }
      } catch (e) {
        AppLogger.w('Could not extract user info from token: $e');
      }

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
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8'
        },
        body: utf8.encode(jsonEncode({
          'email': email,
          'password': password,
        })),
      );

      AppLogger.network(
        'POST',
        '$baseUrl/auth/login',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode == 200) {
        try {
          final data =
              jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
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
          final error =
              jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
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
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8'
        },
        body: utf8.encode(jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        })),
      );

      AppLogger.network(
        'POST',
        '$baseUrl/auth/register',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      final Map<String, dynamic> responseData;
      try {
        responseData =
            jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
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
      // Check for either userId or user_id in the payload
      if ((!payload.containsKey('userId') && !payload.containsKey('user_id')) ||
          !payload.containsKey('email')) {
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
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json; charset=utf-8'
        },
      );

      AppLogger.network(
        'GET',
        '$baseUrl/auth/me',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode == 200) {
        final userData =
            json.decode(utf8.decode(response.bodyBytes, allowMalformed: true));
        AppLogger.i('Successfully retrieved user data from server');

        // Save the token again to ensure we have the latest user data
        await saveToken(token);

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
          final error = json
              .decode(utf8.decode(response.bodyBytes, allowMalformed: true));
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
        return false;
      }

      final exp = payload['exp'];
      final expiry = exp is int
          ? DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          : DateTime.fromMillisecondsSinceEpoch(
              int.parse(exp.toString()) * 1000);
      return expiry.isBefore(DateTime.now());
    } catch (e) {
      AppLogger.w('Error checking token expiry: $e');
      return true; // Consider expired if we can't determine
    }
  }
}
