import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
  });
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to load cached data.',
    super.code = 'CACHE_ERROR',
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });

  factory AuthFailure.unauthorized() {
    return const AuthFailure(
      message: 'Session expired. Please login again.',
      code: 'UNAUTHORIZED',
    );
  }

  factory AuthFailure.forbidden() {
    return const AuthFailure(
      message: 'You don\'t have permission for this action.',
      code: 'FORBIDDEN',
    );
  }

  factory AuthFailure.invalidCredentials() {
    return const AuthFailure(
      message: 'Invalid phone number or password.',
      code: 'INVALID_CREDENTIALS',
    );
  }
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Resource not found.',
    super.code = 'NOT_FOUND',
  });
}

/// Conflict failures (e.g., duplicate entry)
class ConflictFailure extends Failure {
  const ConflictFailure({
    required super.message,
    super.code = 'CONFLICT',
  });
}

/// Rate limit failures
class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message = 'Too many requests. Please wait and try again.',
    super.code = 'RATE_LIMITED',
  });
}
