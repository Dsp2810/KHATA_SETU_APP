import 'package:logger/logger.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// OneSignal service for push notifications and SMS.
class OneSignalService {
  static const String _appId = 'e2a6f9f2-4b7d-11ec-81d7-0242ac130003';
  static final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  bool _initialized = false;

  /// Initialize OneSignal.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Set OneSignal log level
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Initialize with app ID
      OneSignal.initialize(_appId);

      // Request notification permission (iOS)
      await OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.notification.display();
        _log.i('Foreground notification: ${event.notification.title}');
      });

      OneSignal.Notifications.addClickListener((event) {
        _log.i('Notification clicked: ${event.notification.title}');
      });

      _initialized = true;
      _log.i('OneSignal initialized successfully');
    } catch (e) {
      _log.e('Failed to initialize OneSignal: $e');
    }
  }

  /// Set user email for notification targeting.
  Future<void> setUserEmail(String email) async {
    try {
      await OneSignal.User.addEmail(email);
      _log.i('User email set: $email');
    } catch (e) {
      _log.e('Failed to set user email: $e');
    }
  }

  /// Set user phone for SMS notifications.
  Future<void> setUserPhone(String phone) async {
    try {
      await OneSignal.User.addSms(phone);
      _log.i('User phone set for SMS: $phone');
    } catch (e) {
      _log.e('Failed to set user phone: $e');
    }
  }

  /// Set user ID (typically shop ID or unique identifier).
  Future<void> setUserId(String userId) async {
    try {
      await OneSignal.login(userId);
      _log.i('User ID set: $userId');
    } catch (e) {
      _log.e('Failed to set user ID: $e');
    }
  }

  /// Enable push notifications.
  Future<void> enableNotifications() async {
    try {
      await OneSignal.User.pushSubscription.optIn();
      _log.i('Push notifications enabled');
    } catch (e) {
      _log.e('Failed to enable notifications: $e');
    }
  }

  /// Disable push notifications.
  Future<void> disableNotifications() async {
    try {
      await OneSignal.User.pushSubscription.optOut();
      _log.i('Push notifications disabled');
    } catch (e) {
      _log.e('Failed to disable notifications: $e');
    }
  }

  /// Check if notifications are enabled.
  Future<bool> areNotificationsEnabled() async {
    try {
      final subscribed = OneSignal.User.pushSubscription.optedIn;
      return subscribed ?? false;
    } catch (e) {
      _log.e('Failed to check notification status: $e');
      return false;
    }
  }

  /// Add custom tag to user (using addTags method).
  Future<void> addTag(String key, String value) async {
    try {
      OneSignal.User.addTags({key: value});
      _log.i('Tag added: $key=$value');
    } catch (e) {
      _log.e('Failed to add tag: $e');
    }
  }

  /// Get OneSignal player ID.
  String? getPlayerId() {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (e) {
      _log.e('Failed to get player ID: $e');
      return null;
    }
  }

  /// Logout user and unsubscribe from notifications.
  Future<void> logout() async {
    try {
      await OneSignal.logout();
      _log.i('User logged out from OneSignal');
    } catch (e) {
      _log.e('Failed to logout: $e');
    }
  }

  /// Delete user data (via logout instead).
  Future<void> deleteUser() async {
    try {
      await OneSignal.logout();
      _log.i('User logout and data cleared');
    } catch (e) {
      _log.e('Failed to delete user: $e');
    }
  }
}
