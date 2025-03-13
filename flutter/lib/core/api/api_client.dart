import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final String baseUrl;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json; charset=utf-8',
  };

  ApiClient({this.baseUrl = 'http://localhost:8080'});

  // Set authorization token
  void setToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  // Clear authorization token
  void clearToken() {
    _headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      log('GET request to: $url');

      final response = await http.get(
        url,
        headers: _headers,
      );

      log('GET response status: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      log('Network error in GET request: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? data}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      log('POST request to: $url');
      log('POST data: $data');

      final response = await http.post(
        url,
        headers: _headers,
        body: data != null ? utf8.encode(jsonEncode(data)) : null,
      );

      log('POST response status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        log('POST response body: ${response.body}');
      } else {
        log('POST error response: ${response.body}');
      }

      return _processResponse(response);
    } catch (e) {
      log('Network error in POST request: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? data}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      log('PUT request to: $url');
      log('PUT data: $data');

      final response = await http.put(
        url,
        headers: _headers,
        body: data != null ? jsonEncode(data) : null,
      );

      log('PUT response status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        log('PUT response body: ${response.body}');
      } else {
        log('PUT error response: ${response.body}');
      }

      return _processResponse(response);
    } catch (e) {
      log('Network error in PUT request: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      log('DELETE request to: $url');

      final response = await http.delete(
        url,
        headers: _headers,
      );

      log('DELETE response status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        log('DELETE response body: ${response.body}');
      } else {
        log('DELETE error response: ${response.body}');
      }

      return _processResponse(response);
    } catch (e) {
      log('Network error in DELETE request: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadFile(String endpoint, File file,
      {Map<String, String>? fields, String fileFieldName = 'file'}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      log('File upload request to: $url');

      var request = http.MultipartRequest('POST', url);

      // Add authorization header if exists
      if (_headers.containsKey('Authorization')) {
        request.headers['Authorization'] = _headers['Authorization']!;
      }

      // Add file
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final contentType = _getContentType(fileExtension);

      request.files.add(
        http.MultipartFile(
          fileFieldName,
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: fileName,
          contentType: contentType,
        ),
      );

      // Add additional fields
      if (fields != null) {
        fields.forEach((key, value) {
          request.fields[key] = value;
        });
      }

      log('Sending file upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      log('File upload response status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        log('File upload response: ${response.body}');
      } else {
        log('File upload error: ${response.body}');
      }

      return _processResponse(response);
    } catch (e) {
      log('Failed to upload file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  // Method to analyze prescription text
  Future<Map<String, dynamic>> analyzePrescriptionText(String text,
      {String? requestId}) async {
    try {
      final url = Uri.parse('$baseUrl/api/analyze-prescription/text');
      log('Analyzing prescription text at: $url');
      log('Prescription text: $text');
      if (requestId != null) {
        log('Request ID: $requestId');
      }

      final Map<String, dynamic> requestData = {
        'content': text,
      };

      // Add request ID if provided to ensure unique analysis
      if (requestId != null) {
        requestData['request_id'] = requestId;
      }

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(requestData),
      );

      log('Prescription analysis response status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        log('Prescription analysis response: ${response.body}');
      } else {
        log('Prescription analysis error: ${response.body}');
      }

      return _processResponse(response);
    } catch (e) {
      log('Failed to analyze prescription: $e');
      throw Exception('Failed to analyze prescription: $e');
    }
  }

  // Method to analyze prescription image
  Future<Map<String, dynamic>> analyzePrescriptionImage(File image,
      {String? requestId}) async {
    try {
      final url = Uri.parse('$baseUrl/api/analyze-prescription/image');
      log('Analyzing prescription image at: $url');
      if (requestId != null) {
        log('Request ID: $requestId');
      }

      // Determine the correct MIME type based on file extension
      final fileName = image.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final contentType = _getContentType(fileExtension);

      log('Image file: $fileName, extension: $fileExtension, MIME type: ${contentType.mimeType}');

      var request = http.MultipartRequest(
        'POST',
        url,
      );

      // Add authorization header if exists
      if (_headers.containsKey('Authorization')) {
        request.headers['Authorization'] = _headers['Authorization']!;
      }

      // Add request ID if provided to ensure unique analysis
      if (requestId != null) {
        request.fields['request_id'] = requestId;
      }

      request.files.add(
        http.MultipartFile(
          'image',
          image.readAsBytes().asStream(),
          image.lengthSync(),
          filename: fileName,
          contentType: contentType,
        ),
      );

      log('Sending prescription image...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      log('Prescription image analysis response status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        log('Prescription image analysis response: ${response.body}');
      } else {
        log('Prescription image analysis error: ${response.body}');
      }

      return _processResponse(response);
    } catch (e) {
      log('Failed to analyze prescription image: $e');
      throw Exception('Failed to analyze prescription image: $e');
    }
  }

  // Helper method to determine content type from file extension
  MediaType _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        // Ensure we're properly decoding the response using UTF-8
        final decodedBody =
            utf8.decode(response.bodyBytes, allowMalformed: true);
        final body = decodedBody.isNotEmpty
            ? jsonDecode(decodedBody)
            : {'success': true};

        // Wrap the response in a standard format if it's not already
        if (body is Map<String, dynamic> &&
            (body.containsKey('data') || body.containsKey('success'))) {
          return body;
        } else {
          return {'success': true, 'data': body};
        }
      } catch (e) {
        log('Error decoding JSON response: $e');
        log('Response body: ${response.body}');
        throw Exception('Invalid response format: $e');
      }
    } else {
      log('API Error: ${response.statusCode} - ${response.body}');
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Helper method to ensure UTF-8 encoding for all string values in a map
  Map<String, dynamic> _ensureUtf8Encoding(Map<String, dynamic> data) {
    Map<String, dynamic> result = {};

    data.forEach((key, value) {
      if (value is String) {
        // Ensure string values are properly encoded
        result[key] = value;
      } else if (value is Map<String, dynamic>) {
        // Recursively process nested maps
        result[key] = _ensureUtf8Encoding(value);
      } else {
        // Keep other types as they are
        result[key] = value;
      }
    });

    return result;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  // Use the host machine's IP address instead of localhost
  // so the mobile device can access it on the same network
  final baseUrl = 'http://192.168.1.4:8080';
  return ApiClient(baseUrl: baseUrl);
});
