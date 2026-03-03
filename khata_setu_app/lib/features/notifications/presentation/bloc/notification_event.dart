import 'package:equatable/equatable.dart';

import '../../../../core/data/models/app_notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load all notifications
class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

/// Refresh notifications (check for new alerts)
class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}

/// Add a new notification
class AddNotification extends NotificationEvent {
  final AppNotificationModel notification;

  const AddNotification(this.notification);

  @override
  List<Object?> get props => [notification];
}

/// Mark notification as read
class MarkAsRead extends NotificationEvent {
  final String notificationId;

  const MarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read
class MarkAllAsRead extends NotificationEvent {
  const MarkAllAsRead();
}

/// Delete notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Clear all notifications
class ClearAllNotifications extends NotificationEvent {
  const ClearAllNotifications();
}

/// Check for low stock and create notifications
class CheckLowStockAlerts extends NotificationEvent {
  const CheckLowStockAlerts();
}

/// Check for pending udhar and create reminders
class CheckPendingUdharAlerts extends NotificationEvent {
  const CheckPendingUdharAlerts();
}
