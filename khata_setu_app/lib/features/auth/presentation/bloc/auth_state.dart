import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authenticated but offline — token exists, but we can't verify it
class AuthenticatedOffline extends AuthState {
  final User user;

  const AuthenticatedOffline(this.user);

  @override
  List<Object?> get props => [user];
}

/// Auth error state
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// OTP sent state
class OtpSent extends AuthState {
  final String phone;
  final String purpose;

  const OtpSent({
    required this.phone,
    required this.purpose,
  });

  @override
  List<Object?> get props => [phone, purpose];
}

/// OTP verification loading
class OtpVerifying extends AuthState {
  const OtpVerifying();
}

/// Password reset success
class PasswordResetSuccess extends AuthState {
  const PasswordResetSuccess();
}

/// Registration success (needs OTP verification)
class RegistrationPending extends AuthState {
  final String phone;

  const RegistrationPending(this.phone);

  @override
  List<Object?> get props => [phone];
}
