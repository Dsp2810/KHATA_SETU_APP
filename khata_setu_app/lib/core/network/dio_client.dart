import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../constants/constants.dart';
import '../storage/secure_storage.dart';
import 'api_interceptors.dart';

class DioClient {
  static Dio createDio(SecureStorageService secureStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.contentType,
        },
      ),
    );

    // Add interceptors
    dio.interceptors.addAll([
      AuthInterceptor(secureStorage, dio),
      if (kDebugMode) LoggingInterceptor(),
      ErrorInterceptor(),
    ]);

    return dio;
  }
}

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 75,
      colors: true,
      printEmojis: true,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('┌─────────────────────────────────────────────────────────');
    _logger.d('│ 📤 REQUEST');
    _logger.d('│ ${options.method} ${options.path}');
    _logger.d('│ Headers: ${_sanitizeHeaders(options.headers)}');
    if (options.data != null) {
      _logger.d('│ Body: ${_sanitizeData(options.data)}');
    }
    _logger.d('└─────────────────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('┌─────────────────────────────────────────────────────────');
    _logger.d('│ 📥 RESPONSE');
    _logger.d('│ ${response.statusCode} ${response.requestOptions.path}');
    _logger.d('│ Data: ${response.data}');
    _logger.d('└─────────────────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('┌─────────────────────────────────────────────────────────');
    _logger.e('│ ❌ ERROR');
    _logger.e('│ ${err.type} ${err.requestOptions.path}');
    _logger.e('│ Message: ${err.message}');
    if (err.response != null) {
      _logger.e('│ Response: ${err.response?.data}');
    }
    _logger.e('└─────────────────────────────────────────────────────────');
    handler.next(err);
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = '[REDACTED]';
    }
    return sanitized;
  }

  dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final sanitized = Map<String, dynamic>.from(data as Map<String, dynamic>);
      final sensitiveFields = ['password', 'token', 'pin', 'otp'];
      for (final field in sensitiveFields) {
        if (sanitized.containsKey(field)) {
          sanitized[field] = '[REDACTED]';
        }
      }
      return sanitized;
    }
    return data;
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final error = _handleError(err);
    handler.next(error);
  }

  DioException _handleError(DioException err) {
    String message;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Request timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Response timeout. Server is taking too long.';
        break;
      case DioExceptionType.badResponse:
        message = _handleStatusCode(err.response?.statusCode, err.response?.data);
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        break;
      default:
        message = 'An unexpected error occurred. Please try again.';
    }

    return DioException(
      requestOptions: err.requestOptions,
      error: err.error,
      response: err.response,
      type: err.type,
      message: message,
    );
  }

  String _handleStatusCode(int? statusCode, dynamic data) {
    // Try to extract error message from API response
    String? apiMessage;
    if (data is Map) {
      apiMessage = data['error']?['message'] ?? data['message'];
    }

    switch (statusCode) {
      case 400:
        return apiMessage ?? 'Invalid request. Please check your input.';
      case 401:
        return apiMessage ?? 'Session expired. Please login again.';
      case 403:
        return apiMessage ?? 'You don\'t have permission for this action.';
      case 404:
        return apiMessage ?? 'Resource not found.';
      case 409:
        return apiMessage ?? 'Conflict occurred. Please try again.';
      case 422:
        return apiMessage ?? 'Invalid data provided.';
      case 429:
        return apiMessage ?? 'Too many requests. Please wait and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return apiMessage ?? 'Something went wrong. Please try again.';
    }
  }
}
