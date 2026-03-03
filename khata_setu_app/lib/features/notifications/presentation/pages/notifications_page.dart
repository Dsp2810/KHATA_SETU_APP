import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/models/app_notification_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatter.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return _buildErrorState(context, state.message);
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildNotificationsList(context, state.notifications);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(l10n.notifications),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoaded && state.unreadCount > 0) {
              return TextButton(
                onPressed: () {
                  context.read<NotificationBloc>().add(const MarkAllAsRead());
                },
                child: Text(
                  l10n.markAllAsRead,
                  style: TextStyle(
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: isDark ? AppColors.grey600 : AppColors.grey400,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.noNotifications,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.grey500 : AppColors.grey600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.noNotificationsDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.grey600 : AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.somethingWentWrong,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () {
              context.read<NotificationBloc>().add(const LoadNotifications());
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    List<AppNotificationModel> notifications,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () => _handleNotificationTap(context, notification),
          onDismiss: () {
            context.read<NotificationBloc>().add(
              DeleteNotification(notification.id),
            );
          },
        );
      },
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotificationModel notification,
  ) {
    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(MarkAsRead(notification.id));
    }

    // Navigate to action route if available
    if (notification.actionRoute != null) {
      context.push(notification.actionRoute!);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        color: notification.isRead
            ? (isDark ? AppColors.cardDark : AppColors.cardLight)
            : (isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.1)
                  : AppColors.primarySurface),
        elevation: notification.isRead ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: notification.isRead
              ? BorderSide.none
              : BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(context),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildContent(context)),
                if (!notification.isRead) _buildUnreadDot(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final iconData = _getIconForType(notification.type);
    final iconColor = _getColorForType(notification.type);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          notification.message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.grey400 : AppColors.grey600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          _formatTime(notification.createdAt),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.grey500 : AppColors.grey500,
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.lowStock:
        return Icons.inventory_2_outlined;
      case NotificationType.pendingUdhar:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.paymentReceived:
        return Icons.payments_outlined;
      case NotificationType.dailySummary:
        return Icons.summarize_outlined;
      case NotificationType.reminder:
        return Icons.alarm_outlined;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.lowStock:
        return AppColors.warning;
      case NotificationType.pendingUdhar:
        return AppColors.error;
      case NotificationType.paymentReceived:
        return AppColors.success;
      case NotificationType.dailySummary:
        return AppColors.info;
      case NotificationType.reminder:
        return AppColors.primary;
      case NotificationType.system:
        return AppColors.grey500;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
