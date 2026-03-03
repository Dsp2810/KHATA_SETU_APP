import 'package:hive/hive.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 0)
class CustomerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? address;

  @HiveField(5)
  double creditLimit;

  @HiveField(6)
  double currentBalance; // +ve = customer owes shop (udhar)

  @HiveField(7)
  int trustScore; // 0-100

  @HiveField(8)
  bool isActive;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? lastTransactionAt;

  @HiveField(11)
  String? avatar; // Emoji or URL

  @HiveField(12)
  String? notes;

  @HiveField(13)
  bool synced;

  @HiveField(14)
  int schemaVersion;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.creditLimit = 5000.0,
    this.currentBalance = 0.0,
    this.trustScore = 50,
    this.isActive = true,
    required this.createdAt,
    this.lastTransactionAt,
    this.avatar,
    this.notes,
    this.synced = false,
    this.schemaVersion = 1,
  });

  /// Whether customer owes us (udhar)
  bool get owesUs => currentBalance > 0;

  /// Whether balance exceeds credit limit
  bool get isOverCreditLimit =>
      creditLimit > 0 && currentBalance > creditLimit;

  /// Days since last transaction
  int? get daysSinceLastTransaction {
    if (lastTransactionAt == null) return null;
    return DateTime.now().difference(lastTransactionAt!).inDays;
  }

  /// Whether overdue (> 30 days unpaid with balance)
  bool get isOverdue =>
      owesUs && (daysSinceLastTransaction ?? 0) > 30;

  /// Trust level label
  String get trustLevel {
    if (trustScore >= 80) return 'Excellent';
    if (trustScore >= 60) return 'Good';
    if (trustScore >= 40) return 'Average';
    return 'Low';
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? creditLimit,
    double? currentBalance,
    int? trustScore,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastTransactionAt,
    String? avatar,
    String? notes,
    bool? synced,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      trustScore: trustScore ?? this.trustScore,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
      avatar: avatar ?? this.avatar,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      schemaVersion: schemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CustomerModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
