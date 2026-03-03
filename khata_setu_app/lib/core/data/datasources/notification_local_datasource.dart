import 'package:hive/hive.dart';

import '../hive_initializer.dart';
import '../models/app_notification_model.dart';

/// Local data source for notifications backed by Hive.
/// Offline-first storage for app notifications.
class NotificationLocalDataSource {
  Box<AppNotificationModel> get _box =>
      Hive.box<AppNotificationModel>(HiveBoxes.notifications);

  /// Get all notifications, sorted by date (newest first)
  List<AppNotificationModel> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get unread notifications
  List<AppNotificationModel> getUnread() {
    return _box.values
        .where((n) => !n.isRead)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get unread count
  int getUnreadCount() {
    return _box.values.where((n) => !n.isRead).length;
  }

  /// Get notification by ID
  AppNotificationModel? getById(String id) {
    return _box.get(id);
  }

  /// Add a new notification
  Future<void> add(AppNotificationModel notification) async {
    await _box.put(notification.id, notification);
  }

  /// Add multiple notifications
  Future<void> addAll(List<AppNotificationModel> notifications) async {
    final map = {for (final n in notifications) n.id: n};
    await _box.putAll(map);
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    final notification = _box.get(id);
    if (notification != null) {
      await _box.put(id, notification.copyWith(isRead: true));
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final updates = <String, AppNotificationModel>{};
    for (final n in _box.values) {
      if (!n.isRead) {
        updates[n.id] = n.copyWith(isRead: true);
      }
    }
    if (updates.isNotEmpty) {
      await _box.putAll(updates);
    }
  }

  /// Delete notification
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Delete notifications older than specified days
  Future<void> deleteOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final toDelete = _box.values
        .where((n) => n.createdAt.isBefore(cutoff))
        .map((n) => n.id)
        .toList();
    for (final id in toDelete) {
      await _box.delete(id);
    }
  }
}
