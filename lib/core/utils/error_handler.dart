import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

class ErrorHandler {
  /// Parse exception to user-friendly message
  static String getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is FormatException) {
      return 'error.invalid_format'.tr();
    }

    return error?.toString() ?? 'error.unknown'.tr();
  }

  /// Handle Dio/Network exceptions
  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'error.timeout'.tr();

      case DioExceptionType.connectionError:
        return 'error.network'.tr();

      case DioExceptionType.badResponse:
        return _handleHttpError(error);

      case DioExceptionType.cancel:
        return 'error.cancelled'.tr();

      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return 'error.network'.tr();
        }
        return 'error.unknown'.tr();

      default:
        return 'error.unknown'.tr();
    }
  }

  /// Handle HTTP status code errors
  static String _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Try to extract message from response
    if (data is Map<String, dynamic>) {
      final message = data['message'] ??
          data['error'] ??
          data['detail'] ??
          data['detail_message'];
      if (message != null) {
        return message.toString();
      }
    }

    // Handle by status code
    switch (statusCode) {
      case 400:
        return 'error.invalid_input'.tr();
      case 401:
        return 'error.invalid_credentials'.tr();
      case 403:
        return 'error.access_denied'.tr();
      case 404:
        return 'error.not_found'.tr();
      case 409:
        return 'error.conflict'.tr();
      case 422:
        return 'error.validation_failed'.tr();
      case 429:
        return 'error.too_many_requests'.tr();
      case 500:
        return 'error.server_error'.tr();
      case 502:
      case 503:
        return 'error.service_unavailable'.tr();
      default:
        return 'error.unknown'.tr();
    }
  }

  /// Get error code for tracking/logging
  static String? getErrorCode(dynamic error) {
    if (error is AppException) {
      return error.code;
    }

    if (error is DioException) {
      return '${error.type.toString()}_${error.response?.statusCode}';
    }

    return null;
  }
}
