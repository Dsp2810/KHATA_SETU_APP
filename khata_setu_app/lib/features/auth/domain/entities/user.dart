import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatar;
  final String role;
  final String? language;
  final bool isActive;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatar,
    required this.role,
    this.language,
    required this.isActive,
    required this.isPhoneVerified,
    required this.createdAt,
    this.lastLoginAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        avatar,
        role,
        language,
        isActive,
        isPhoneVerified,
        createdAt,
        lastLoginAt,
      ];

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatar,
    String? role,
    String? language,
    bool? isActive,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      language: language ?? this.language,
      isActive: isActive ?? this.isActive,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

class AuthResponse extends Equatable {
  final User user;
  final AuthTokens tokens;

  const AuthResponse({
    required this.user,
    required this.tokens,
  });

  @override
  List<Object?> get props => [user, tokens];
}
