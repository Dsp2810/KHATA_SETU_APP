import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  // Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: StorageKeys.accessToken);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: StorageKeys.accessToken);
  }

  // Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: StorageKeys.refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: StorageKeys.userId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: StorageKeys.userId);
  }

  // Active Shop ID
  Future<void> saveActiveShopId(String shopId) async {
    await _storage.write(key: StorageKeys.activeShopId, value: shopId);
  }

  Future<String?> getActiveShopId() async {
    return await _storage.read(key: StorageKeys.activeShopId);
  }

  Future<void> deleteActiveShopId() async {
    await _storage.delete(key: StorageKeys.activeShopId);
  }

  // Clear Tokens (Logout)
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
    ]);
  }

  // Clear All (Full Logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ─── Generic read / write ───────────────────────────────────

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // ─── User Profile ───────────────────────────────────────────

  Future<void> saveUserName(String name) async {
    await _storage.write(key: StorageKeys.userName, value: name);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: StorageKeys.userName);
  }

  Future<void> saveUserPhone(String phone) async {
    await _storage.write(key: StorageKeys.userPhone, value: phone);
  }

  Future<String?> getUserPhone() async {
    return await _storage.read(key: StorageKeys.userPhone);
  }

  // ─── Active Shop Name ──────────────────────────────────────

  Future<void> saveActiveShopName(String name) async {
    await _storage.write(key: StorageKeys.activeShopName, value: name);
  }

  Future<String?> getActiveShopName() async {
    return await _storage.read(key: StorageKeys.activeShopName);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
