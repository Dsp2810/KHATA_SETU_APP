import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Maps any exception into a structured [Failure] for consistent error handling
/// across all BLoCs and repositories.
Failure mapExceptionToFailure(dynamic error) {
  if (error is Failure) return error;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          message: 'Connection timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        return _mapStatusToFailure(statusCode, data);
      case DioExceptionType.cancel:
        return const ServerFailure(message: 'Request was cancelled.');
      default:
        return ServerFailure(message: error.message ?? 'Unexpected error');
    }
  }

  if (error is AppException) {
    if (error is ServerException) {
      return ServerFailure(message: error.message, code: error.code);
    }
    if (error is NetworkException) {
      return NetworkFailure(message: error.message);
    }
    if (error is CacheException) {
      return CacheFailure(message: error.message);
    }
    if (error is ValidationException) {
      return ValidationFailure(
        message: error.message,
        fieldErrors: error.fieldErrors,
      );
    }
    if (error is AuthException) {
      return AuthFailure(message: error.message, code: error.code);
    }
    if (error is NotFoundException) {
      return NotFoundFailure(message: error.message);
    }
    if (error is RateLimitException) {
      return const RateLimitFailure();
    }
  }

  if (error is Exception) {
    final msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      return ServerFailure(message: msg.substring(11));
    }
    return ServerFailure(message: msg);
  }

  return const ServerFailure(message: 'An unexpected error occurred');
}

Failure _mapStatusToFailure(int? statusCode, dynamic data) {
  String message = 'Something went wrong';
  if (data is Map) {
    message =
        data['error']?['message'] ?? data['message'] ?? message;
  }

  switch (statusCode) {
    case 400:
      return ValidationFailure(message: message);
    case 401:
      return AuthFailure.unauthorized();
    case 403:
      return AuthFailure.forbidden();
    case 404:
      return NotFoundFailure(message: message);
    case 409:
      return ConflictFailure(message: message);
    case 429:
      return const RateLimitFailure();
    case 500:
    case 502:
    case 503:
      return ServerFailure(message: 'Server error. Try again later.');
    default:
      return ServerFailure(message: message);
  }
}

/// Wraps an async operation with consistent error handling.
/// Returns the result or throws a [Failure].
Future<T> safeApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } catch (e) {
    throw mapExceptionToFailure(e);
  }
}
