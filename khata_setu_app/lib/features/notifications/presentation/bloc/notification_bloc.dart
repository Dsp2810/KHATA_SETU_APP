import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/datasources/notification_local_datasource.dart';
import '../../../../core/data/models/app_notification_model.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationLocalDataSource _dataSource;

  NotificationBloc({
    required NotificationLocalDataSource dataSource,
  })  : _dataSource = dataSource,
        super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoad);
    on<RefreshNotifications>(_onRefresh);
    on<AddNotification>(_onAdd);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDelete);
    on<ClearAllNotifications>(_onClearAll);
  }

  /// Hot-swap datasource (for future remote support)
  void updateDataSource(NotificationLocalDataSource ds) {
    _dataSource = ds;
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());
    try {
      final notifications = await _dataSource.getAll();
      final unreadCount = await _dataSource.getUnreadCount();
      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final notifications = await _dataSource.getAll();
      final unreadCount = await _dataSource.getUnreadCount();
      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      // If refresh fails, keep existing state
      final current = state;
      if (current is! NotificationLoaded) {
        emit(NotificationError(e.toString()));
      }
    }
  }

  Future<void> _onAdd(
    AddNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _dataSource.add(event.notification);
      // Reload to get updated list
      add(const RefreshNotifications());
    } catch (e) {
      // Silent fail for add - don't interrupt user flow
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _dataSource.markAsRead(event.notificationId);
      // Update local state without full reload
      final current = state;
      if (current is NotificationLoaded) {
        final updated = current.notifications.map((n) {
          if (n.id == event.notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        emit(NotificationLoaded(
          notifications: updated,
          unreadCount: current.unreadCount - 1,
        ));
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _dataSource.markAllAsRead();
      // Update local state
      final current = state;
      if (current is NotificationLoaded) {
        final updated = current.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        emit(NotificationLoaded(
          notifications: updated,
          unreadCount: 0,
        ));
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onDelete(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _dataSource.delete(event.notificationId);
      // Update local state
      final current = state;
      if (current is NotificationLoaded) {
        final deleted = current.notifications.firstWhere(
          (n) => n.id == event.notificationId,
          orElse: () => AppNotificationModel.system(
            title: '',
            body: '',
          ),
        );
        final updated = current.notifications
            .where((n) => n.id != event.notificationId)
            .toList();
        emit(NotificationLoaded(
          notifications: updated,
          unreadCount: deleted.isRead
              ? current.unreadCount
              : current.unreadCount - 1,
        ));
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onClearAll(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _dataSource.clearAll();
      emit(const NotificationLoaded(
        notifications: [],
        unreadCount: 0,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
