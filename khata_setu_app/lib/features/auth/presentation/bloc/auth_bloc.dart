import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// AuthBloc backed by [ApiService] + [SecureStorageService].
/// Handles login, register, check-session, and logout.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _api;
  final SecureStorageService _storage;
  final ConnectivityService _connectivity;

  AuthBloc({
    required ApiService apiService,
    required SecureStorageService secureStorage,
    required ConnectivityService connectivityService,
  })  : _api = apiService,
        _storage = secureStorage,
        _connectivity = connectivityService,
        super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  // ─── Check existing session ──────────────────────────────────

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      emit(const Unauthenticated());
      return;
    }

    // ── Offline path: token exists but no network ──────────────
    final isOnline = await _connectivity.checkConnectivity();
    if (!isOnline) {
      // Offline: use cached user profile for seamless offline experience
      final cachedUser = await _userFromStorage();
      if (cachedUser != null) {
        emit(AuthenticatedOffline(cachedUser));
      } else {
        // Token exists but no cached profile — still trust the token
        emit(AuthenticatedOffline(User(
          id: 'cached',
          name: await _storage.getUserName() ?? 'User',
          phone: await _storage.getUserPhone() ?? '',
          role: 'owner',
          isActive: true,
          isPhoneVerified: false,
          createdAt: DateTime.now(),
        )));
      }
      return;
    }

    // ── Online path: validate token with server ────────────────
    try {
      final data = await _api.getMe();
      final user = _userFromJson(data['user'] as Map<String, dynamic>);

      // Ensure remote datasource is wired
      final shopId = await _storage.getActiveShopId();
      if (shopId != null) {
        await registerRemoteDatasource(shopId);
      }

      emit(Authenticated(user));
    } catch (e) {
      // ── Distinguish 401 from network errors ──────────────────
      if (_isUnauthorized(e)) {
        // Token rejected (401) — attempt silent refresh
        final refreshed = await _tryRefreshAndRetry(emit);
        if (!refreshed) {
          await _storage.clearTokens();
          emit(const Unauthenticated());
        }
      } else {
        // Network timeout, socket error, server 500, etc.
        // Do NOT clear tokens — user's session is still valid.
        final cachedUser = await _userFromStorage();
        if (cachedUser != null) {
          emit(AuthenticatedOffline(cachedUser));
        } else {
          emit(AuthenticatedOffline(User(
            id: 'cached',
            name: await _storage.getUserName() ?? 'User',
            phone: await _storage.getUserPhone() ?? '',
            role: 'owner',
            isActive: true,
            isPhoneVerified: false,
            createdAt: DateTime.now(),
          )));
        }
      }
    }
  }

  /// Returns true if the error is an explicit HTTP 401 Unauthorized.
  bool _isUnauthorized(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }

  /// Attempt token refresh → retry getMe. Returns true on success.
  Future<bool> _tryRefreshAndRetry(Emitter<AuthState> emit) async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final refreshData = await _api.refreshToken(refreshToken);
      final tokens =
          refreshData['tokens'] as Map<String, dynamic>? ?? refreshData;
      await _storage.saveAccessToken(
          (tokens['accessToken'] ?? tokens['access_token'] ?? '').toString());
      if (tokens['refreshToken'] != null) {
        await _storage.saveRefreshToken(tokens['refreshToken'].toString());
      }

      // Retry getMe with new token
      final data = await _api.getMe();
      final user = _userFromJson(data['user'] as Map<String, dynamic>);

      final shopId = await _storage.getActiveShopId();
      if (shopId != null) {
        await registerRemoteDatasource(shopId);
      }

      emit(Authenticated(user));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Build a User from cached SecureStorage data (saved during login/register).
  Future<User?> _userFromStorage() async {
    final userId = await _storage.getUserId();
    final userName = await _storage.getUserName();
    final userPhone = await _storage.getUserPhone();

    if (userId == null || userName == null) return null;

    return User(
      id: userId,
      name: userName,
      phone: userPhone ?? '',
      role: 'owner',
      isActive: true,
      isPhoneVerified: false,
      createdAt: DateTime.now(),
    );
  }

  // ─── Login ───────────────────────────────────────────────────

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    if (DemoConfig.isDemoMode) {
      final demoUser = User(
        id: 'demo_user',
        name: 'Demo Shopkeeper',
        phone: event.phone.trim(),
        role: 'owner',
        isActive: true,
        isPhoneVerified: true,
        createdAt: DateTime.now(),
      );

      await _storage.saveAccessToken('demo_access_token');
      await _storage.saveRefreshToken('demo_refresh_token');
      await _storage.saveUserId(demoUser.id);
      await _storage.saveUserName(demoUser.name);
      await _storage.saveUserPhone(demoUser.phone);
      await _storage.saveActiveShopId('demo_shop_1');
      await _storage.saveActiveShopName('KhataSetu Demo Store');

      emit(AuthenticatedOffline(demoUser));
      return;
    }

    try {
      final data = await _api.login(
        phone: event.phone,
        password: event.password,
      );

      // Save tokens
      final tokens = data['tokens'] as Map<String, dynamic>;
      await _storage.saveAccessToken(tokens['accessToken'].toString());
      await _storage.saveRefreshToken(tokens['refreshToken'].toString());

      // Save user ID and profile
      final userJson = data['user'] as Map<String, dynamic>;
      final userId = (userJson['_id'] ?? userJson['id'] ?? '').toString();
      await _storage.saveUserId(userId);
      await _storage.saveUserName(userJson['name'] as String? ?? '');
      await _storage.saveUserPhone(userJson['phone'] as String? ?? '');

      // Save first shop as active
      final shops = data['shops'] as List<dynamic>?;
      if (shops != null && shops.isNotEmpty) {
        final shopId = (shops[0]['_id'] ?? shops[0]['id'] ?? '').toString();
        final shopName = (shops[0]['shopName'] ?? shops[0]['name'] ?? '').toString();
        await _storage.saveActiveShopId(shopId);
        await _storage.saveActiveShopName(shopName);
        // Wire up remote datasource
        await registerRemoteDatasource(shopId);
      }

      final user = _userFromJson(userJson);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  // ─── Register ────────────────────────────────────────────────

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final data = await _api.register(
        name: event.name,
        phone: event.phone,
        password: event.password,
        shopName: event.shopName,
      );

      // Save tokens
      final tokens = data['tokens'] as Map<String, dynamic>;
      await _storage.saveAccessToken(tokens['accessToken'].toString());
      await _storage.saveRefreshToken(tokens['refreshToken'].toString());

      // Save user
      final userJson = data['user'] as Map<String, dynamic>;
      final userId = (userJson['_id'] ?? userJson['id'] ?? '').toString();
      await _storage.saveUserId(userId);
      await _storage.saveUserName(userJson['name'] as String? ?? '');
      await _storage.saveUserPhone(userJson['phone'] as String? ?? '');

      // Save shop
      final shopJson = data['shop'] as Map<String, dynamic>?;
      if (shopJson != null) {
        final shopId = (shopJson['_id'] ?? shopJson['id'] ?? '').toString();
        final shopName = (shopJson['shopName'] ?? shopJson['name'] ?? '').toString();
        await _storage.saveActiveShopId(shopId);
        await _storage.saveActiveShopName(shopName);
        await registerRemoteDatasource(shopId);
      }

      final user = _userFromJson(userJson);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  // ─── Logout ──────────────────────────────────────────────────

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final refreshToken = await _storage.getRefreshToken();
      await _api.logout(refreshToken: refreshToken);
    } catch (_) {
      // Ignore API errors on logout
    }

    await _storage.clearTokens();
    emit(const Unauthenticated());
  }

  // ─── Helpers ─────────────────────────────────────────────────

  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      role: json['role'] as String? ?? 'owner',
      language: json['language'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastLoginAt: DateTime.tryParse(json['lastLoginAt']?.toString() ?? ''),
    );
  }

  String _extractErrorMessage(dynamic error) {
    if (error is Exception) {
      final msg = error.toString();
      // DioExceptions often wrap "Exception: message"
      if (msg.startsWith('Exception: ')) {
        return msg.substring(11);
      }
      return msg;
    }
    return 'Something went wrong. Please try again.';
  }
}
