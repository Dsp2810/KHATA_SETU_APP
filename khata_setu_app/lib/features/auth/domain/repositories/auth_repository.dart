import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Login with phone and password
  Future<Either<Failure, AuthResponse>> login({
    required String phone,
    required String password,
  });

  /// Register new user
  Future<Either<Failure, AuthResponse>> register({
    required String name,
    required String phone,
    required String password,
  });

  /// Send OTP for phone verification
  Future<Either<Failure, void>> sendOtp({
    required String phone,
    required String purpose, // 'verification' | 'forgot_password'
  });

  /// Verify OTP
  Future<Either<Failure, AuthResponse>> verifyOtp({
    required String phone,
    required String otp,
  });

  /// Forgot password - request reset
  Future<Either<Failure, void>> forgotPassword({
    required String phone,
  });

  /// Reset password
  Future<Either<Failure, void>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  });

  /// Refresh tokens
  Future<Either<Failure, AuthTokens>> refreshToken({
    required String refreshToken,
  });

  /// Logout
  Future<Either<Failure, void>> logout();

  /// Get current user
  Future<Either<Failure, User>> getCurrentUser();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Get cached user
  User? getCachedUser();
}
