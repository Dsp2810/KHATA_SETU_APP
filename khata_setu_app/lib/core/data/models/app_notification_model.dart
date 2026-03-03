import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'app_notification_model.g.dart';

/// Notification types for categorization
enum NotificationType {
  lowStock,           // Product stock is low
  pendingUdhar,       // Customer has pending udhar
  paymentReceived,    // Payment received from customer
  dailySummary,       // Daily business summary
  reminder,           // General reminder
  system,             // System notification
}

/// Convert enum to Hive-compatible int and vice-versa
extension NotificationTypeExtension on NotificationType {
  int get value => index;
  
  static NotificationType fromValue(int value) {
    return NotificationType.values[value.clamp(0, NotificationType.values.length - 1)];
  }
  
  String get label {
    switch (this) {
      case NotificationType.lowStock:
        return 'Low Stock';
      case NotificationType.pendingUdhar:
        return 'Pending Udhar';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.dailySummary:
        return 'Daily Summary';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.system:
        return 'System';
    }
  }
  
  String get icon {
    switch (this) {
      case NotificationType.lowStock:
        return '📦';
      case NotificationType.pendingUdhar:
        return '💳';
      case NotificationType.paymentReceived:
        return '✅';
      case NotificationType.dailySummary:
        return '📊';
      case NotificationType.reminder:
        return '🔔';
      case NotificationType.system:
        return '⚙️';
    }
  }
}

/// App notification model stored locally in Hive
@HiveType(typeId: 30)
class AppNotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final int typeValue; // NotificationType as int for Hive

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final bool isRead;

  @HiveField(6)
  final String? actionRoute; // Route to navigate when tapped

  @HiveField(7)
  final Map<String, dynamic>? actionData; // Extra data for the action

  @HiveField(8)
  final String? customerId; // Related customer if any

  @HiveField(9)
  final String? productId; // Related product if any

  @HiveField(10)
  final double? amount; // Related amount if any

  AppNotificationModel({
    String? id,
    required this.title,
    required this.body,
    required this.typeValue,
    DateTime? createdAt,
    this.isRead = false,
    this.actionRoute,
    this.actionData,
    this.customerId,
    this.productId,
    this.amount,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  NotificationType get type => NotificationTypeExtension.fromValue(typeValue);
  
  /// Alias for body for compatibility
  String get message => body;

  /// Create a new notification with specific type
  factory AppNotificationModel.create({
    required String title,
    required String body,
    required NotificationType type,
    String? actionRoute,
    Map<String, dynamic>? actionData,
    String? customerId,
    String? productId,
    double? amount,
  }) {
    return AppNotificationModel(
      title: title,
      body: body,
      typeValue: type.value,
      actionRoute: actionRoute,
      actionData: actionData,
      customerId: customerId,
      productId: productId,
      amount: amount,
    );
  }

  /// Low stock notification
  factory AppNotificationModel.lowStock({
    required String productName,
    required int currentStock,
    required int minStock,
    required String productId,
  }) {
    return AppNotificationModel.create(
      title: 'Low Stock Alert',
      body: '$productName is running low ($currentStock/${minStock} units)',
      type: NotificationType.lowStock,
      productId: productId,
      actionRoute: '/inventory',
    );
  }

  /// Pending udhar notification
  factory AppNotificationModel.pendingUdhar({
    required String customerName,
    required double amount,
    required String customerId,
    int? daysPending,
  }) {
    final daysText = daysPending != null ? ' for $daysPending days' : '';
    return AppNotificationModel.create(
      title: 'Pending Payment',
      body: '$customerName has ₹${amount.toStringAsFixed(0)} pending$daysText',
      type: NotificationType.pendingUdhar,
      customerId: customerId,
      amount: amount,
      actionRoute: '/customers/$customerId',
    );
  }

  /// Payment received notification
  factory AppNotificationModel.paymentReceived({
    required String customerName,
    required double amount,
    required String customerId,
  }) {
    return AppNotificationModel.create(
      title: 'Payment Received',
      body: 'Received ₹${amount.toStringAsFixed(0)} from $customerName',
      type: NotificationType.paymentReceived,
      customerId: customerId,
      amount: amount,
      actionRoute: '/customers/$customerId',
    );
  }

  /// Daily summary notification
  factory AppNotificationModel.dailySummary({
    required double totalSales,
    required double totalPayments,
    required int transactionCount,
  }) {
    return AppNotificationModel.create(
      title: 'Daily Summary',
      body: 'Today: $transactionCount transactions | Credit: ₹${totalSales.toStringAsFixed(0)} | Received: ₹${totalPayments.toStringAsFixed(0)}',
      type: NotificationType.dailySummary,
      actionRoute: '/reports',
    );
  }

  /// System notification
  factory AppNotificationModel.system({
    required String title,
    required String body,
    String? actionRoute,
  }) {
    return AppNotificationModel.create(
      title: title,
      body: body,
      type: NotificationType.system,
      actionRoute: actionRoute,
    );
  }

  AppNotificationModel copyWith({
    String? title,
    String? body,
    int? typeValue,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? actionData,
    String? customerId,
    String? productId,
    double? amount,
  }) {
    return AppNotificationModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      typeValue: typeValue ?? this.typeValue,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      actionData: actionData ?? this.actionData,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      amount: amount ?? this.amount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotificationModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
