import 'package:flutter/foundation.dart';

/// A utility class for structured logging throughout the app.
///
/// This class provides different log levels and formats logs consistently,
/// making it easier to filter and read logs.
class AppLogger {
  // Flag to enable/disable logging - can be toggled for different environments
  static bool _isEnabled = true;

  // Enable or disable logging (useful for production builds)
  static void enable(bool enable) {
    _isEnabled = enable;
  }

  // Debug level logs - for detailed information (disabled in release mode)
  static void d(String message) {
    if (_isEnabled && kDebugMode) {
      debugPrint('💡 DEBUG: $message');
    }
  }

  // Info level logs - for general information
  static void i(String message) {
    if (_isEnabled) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  // Warning level logs - for potential issues
  static void w(String message) {
    if (_isEnabled) {
      debugPrint('⚠️ WARN: $message');
    }
  }

  // Error level logs - for actual errors
  static void e(String message, [StackTrace? stackTrace]) {
    if (_isEnabled) {
      debugPrint('🔴 ERROR: $message');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  // Network request logs with formatted output
  static void network(String method, String url, int? statusCode,
      {String? body, String? error}) {
    if (_isEnabled) {
      final status = statusCode != null ? '[$statusCode]' : '';
      debugPrint('🌐 NET $method $url $status');

      if (body != null && body.isNotEmpty) {
        // Limit response body size in logs
        final limitedBody =
            body.length > 500 ? '${body.substring(0, 500)}...' : body;
        debugPrint('📦 RESPONSE: $limitedBody');
      }

      if (error != null) {
        debugPrint('❌ NET ERROR: $error');
      }
    }
  }
}
