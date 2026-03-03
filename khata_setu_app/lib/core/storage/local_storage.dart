import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Theme
  Future<void> saveThemeMode(int themeMode) async {
    await _prefs.setInt(StorageKeys.themeMode, themeMode);
  }

  int getThemeMode() {
    return _prefs.getInt(StorageKeys.themeMode) ?? 0; // 0 = system
  }

  // Language
  Future<void> saveLanguage(String languageCode) async {
    await _prefs.setString(StorageKeys.language, languageCode);
  }

  String getLanguage() {
    return _prefs.getString(StorageKeys.language) ?? 'en';
  }

  // Biometric
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(StorageKeys.biometricEnabled, enabled);
  }

  bool isBiometricEnabled() {
    return _prefs.getBool(StorageKeys.biometricEnabled) ?? false;
  }

  // Last Sync Time
  Future<void> saveLastSyncTime(DateTime time) async {
    await _prefs.setString(StorageKeys.lastSyncTime, time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeString = _prefs.getString(StorageKeys.lastSyncTime);
    if (timeString == null) return null;
    return DateTime.tryParse(timeString);
  }

  // User Data (cached)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(StorageKeys.userData, json.encode(userData));
  }

  Map<String, dynamic>? getUserData() {
    final dataString = _prefs.getString(StorageKeys.userData);
    if (dataString == null) return null;
    return json.decode(dataString) as Map<String, dynamic>;
  }

  Future<void> deleteUserData() async {
    await _prefs.remove(StorageKeys.userData);
  }

  // Shops List (cached)
  Future<void> saveShopsList(List<Map<String, dynamic>> shops) async {
    await _prefs.setString(StorageKeys.shopsList, json.encode(shops));
  }

  List<Map<String, dynamic>>? getShopsList() {
    final shopsString = _prefs.getString(StorageKeys.shopsList);
    if (shopsString == null) return null;
    final decoded = json.decode(shopsString) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  // Generic methods
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
