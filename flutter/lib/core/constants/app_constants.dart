class AppConstants {
  // API endpoints
  static const String baseUrl = 'http://localhost:8080/api';
  static const String prescriptionTextAnalysisEndpoint =
      '/analyze-prescription/text';
  static const String prescriptionImageAnalysisEndpoint =
      '/analyze-prescription/image';

  // API keys
  static const String apiKey = 'YOUR_API_KEY';

  // Database
  static const String databaseName = 'darooyar_db';

  // App settings
  static const int messageHistoryLimit = 100;
  static const Duration apiTimeout = Duration(seconds: 30);

  // Image settings
  static const double maxImageWidth = 1024;
  static const double maxImageHeight = 1024;
  static const int imageQuality = 85;

  // Local Storage
  static const String prescriptionHistoryCollection = 'prescription_history';

  // App
  static const String appName = 'دارویار';
  static const String appVersion = '1.0.0';
}
