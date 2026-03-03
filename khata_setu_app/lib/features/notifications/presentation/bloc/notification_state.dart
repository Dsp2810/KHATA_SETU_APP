import 'package:equatable/equatable.dart';

import '../../../../core/data/models/app_notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// Loading notifications
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// Notifications loaded successfully
class NotificationLoaded extends NotificationState {
  final List<AppNotificationModel> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  NotificationLoaded copyWith({
    List<AppNotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [notifications.length, unreadCount, ...notifications.map((n) => n.id)];
}

/// Error state
class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
