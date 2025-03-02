import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 300),
        receiveTimeout: const Duration(seconds: 300),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }
  }

  // Method to analyze prescription text
  Future<Map<String, dynamic>> analyzePrescriptionText(String text) async {
    try {
      final response = await _dio.post(
        AppConstants.prescriptionTextAnalysisEndpoint,
        data: {'text': text},
      );

      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      throw Exception(AppStrings.unknownErrorMessage);
    }
  }

  // Method to analyze prescription image
  Future<Map<String, dynamic>> analyzePrescriptionImage(File image) async {
    try {
      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        AppConstants.prescriptionImageAnalysisEndpoint,
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      throw Exception(AppStrings.unknownErrorMessage);
    }
  }

  // Method to analyze prescription using AI
  Future<Map<String, dynamic>> analyzeAIPrescription(String text) async {
    try {
      final response = await _dio.post(
        AppConstants.aiPrescriptionAnalysisEndpoint,
        data: {'text': text},
      );

      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      throw Exception(AppStrings.unknownErrorMessage);
    }
  }

  // Helper method to handle Dio errors
  void _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        throw Exception(AppStrings.networkErrorMessage);
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null && statusCode >= 500) {
          throw Exception(AppStrings.serverErrorMessage);
        } else {
          final errorMessage =
              e.response?.data?['message'] ?? AppStrings.unknownErrorMessage;
          throw Exception(errorMessage);
        }
      default:
        throw Exception(AppStrings.unknownErrorMessage);
    }
  }
}
