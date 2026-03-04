import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/constants.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Dio _dio;

  /// Mutex to prevent concurrent token refresh requests.
  /// When a refresh is in progress, subsequent 401 handlers
  /// will await this same future instead of triggering a new refresh.
  Completer<bool>? _refreshCompleter;

  AuthInterceptor(this._secureStorage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip adding token for auth endpoints
    final isAuthEndpoint = options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh');

    if (!isAuthEndpoint) {
      final token = await _secureStorage.getAccessToken();
      if (token != null) {
        options.headers[ApiConstants.authorizationHeader] = 'Bearer $token';
      }

      // Add shop context
      final shopId = await _secureStorage.getActiveShopId();
      if (shopId != null) {
        options.headers[ApiConstants.shopIdHeader] = shopId;
      }
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh') &&
        !err.requestOptions.path.contains('/auth/logout')) {
      // Token expired - try refresh (with mutex)
      final refreshed = await _safeRefreshToken();
      if (refreshed) {
        // Retry original request with new token
        try {
          final response = await _retryRequest(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        // Refresh failed - clear tokens and force re-login
        await _secureStorage.clearTokens();
      }
    }
    handler.next(err);
  }

  /// Thread-safe refresh that deduplicates concurrent 401 calls.
  Future<bool> _safeRefreshToken() async {
    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final result = await _refreshToken();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      // Create new Dio instance without interceptors to avoid loop
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

      final response = await dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _secureStorage.saveAccessToken(data['accessToken']);
        if (data['refreshToken'] != null) {
          await _secureStorage.saveRefreshToken(data['refreshToken']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final token = await _secureStorage.getAccessToken();

    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        ApiConstants.authorizationHeader: 'Bearer $token',
      },
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
