/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => message;
}

/// Server exception
class ServerException extends AppException {
  final int? statusCode;
  final dynamic data;

  const ServerException({
    required super.message,
    super.code,
    this.statusCode,
    this.data,
  });

  factory ServerException.fromResponse(int? statusCode, dynamic data) {
    String message = 'An error occurred';
    String? code;

    if (data is Map) {
      message = data['error']?['message'] ?? data['message'] ?? message;
      code = data['error']?['code'] ?? data['code'];
    }

    return ServerException(
      message: message,
      code: code,
      statusCode: statusCode,
      data: data,
    );
  }
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code = 'NETWORK_ERROR',
  });
}

/// Cache exception
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error',
    super.code = 'CACHE_ERROR',
  });
}

/// Validation exception
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
  });
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
  });

  factory AuthException.unauthorized() {
    return const AuthException(
      message: 'Unauthorized access',
      code: 'UNAUTHORIZED',
    );
  }

  factory AuthException.sessionExpired() {
    return const AuthException(
      message: 'Session expired. Please login again.',
      code: 'SESSION_EXPIRED',
    );
  }
}

/// Not found exception
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.code = 'NOT_FOUND',
  });
}

/// Rate limit exception
class RateLimitException extends AppException {
  final Duration? retryAfter;

  const RateLimitException({
    super.message = 'Too many requests',
    super.code = 'RATE_LIMITED',
    this.retryAfter,
  });
}
