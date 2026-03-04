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

/// Logout event
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
