import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is logged in
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

/// Login event
class LoginRequested extends AuthEvent {
  final String phone;
  final String password;

  const LoginRequested({
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [phone, password];
}

/// Register event
class RegisterRequested extends AuthEvent {
  final String name;
  final String phone;
  final String password;
  final String? shopName;

  const RegisterRequested({
    required this.name,
    required this.phone,
    required this.password,
    this.shopName,
  });

  @override
  List<Object?> get props => [name, phone, password, shopName];
}

/// Send OTP event
class SendOtpRequested extends AuthEvent {
  final String phone;
  final String purpose;

  const SendOtpRequested({
    required this.phone,
    required this.purpose,
  });

  @override
  List<Object?> get props => [phone, purpose];
}

/// Verify OTP event
class VerifyOtpRequested extends AuthEvent {
  final String phone;
  final String otp;

  const VerifyOtpRequested({
    required this.phone,
    required this.otp,
  });

  @override
  List<Object?> get props => [phone, otp];
}

/// Forgot password event
class ForgotPasswordRequested extends AuthEvent {
  final String phone;

  const ForgotPasswordRequested({required this.phone});

  @override
  List<Object?> get props => [phone];
}

/// Reset password event
class ResetPasswordRequested extends AuthEvent {
  final String phone;
  final String otp;
  final String newPassword;

  const ResetPasswordRequested({
    required this.phone,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [phone, otp, newPassword];
}

/// Logout event
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Demo mode login (offline, no backend)
class DemoLoginRequested extends AuthEvent {
  const DemoLoginRequested();
}
