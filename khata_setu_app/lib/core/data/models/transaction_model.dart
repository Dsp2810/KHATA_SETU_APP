import 'package:hive/hive.dart';
import '../../utils/ledger_rules.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final int type; // 0 = credit (udhar given), 1 = debit (payment received)

  @HiveField(3)
  final double totalAmount;

  @HiveField(4)
  final List<TransactionItem> items;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final int paymentMode; // 0=cash, 1=upi, 2=card, 3=other

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final double balanceAfter; // Running balance after this txn

  @HiveField(9)
  bool synced;

  @HiveField(10)
  bool isDeleted; // Soft delete for undo

  @HiveField(11)
  final String? undoneBy; // ID of txn that reversed this

  @HiveField(12)
  int schemaVersion;

  TransactionModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.totalAmount,
    this.items = const [],
    this.description,
    this.paymentMode = 0,
    required this.timestamp,
    required this.balanceAfter,
    this.synced = false,
    this.isDeleted = false,
    this.undoneBy,
    this.schemaVersion = 1,
  });

  /// Get the transaction type as enum.
  /// Use this instead of directly checking `type` int.
  TransactionType get transactionType => TransactionTypeFactory.fromInt(type);

  /// Whether this is a credit transaction (customer takes goods on udhar).
  /// Balance increases.
  bool get isCredit => type == 0;

  /// Whether this is a payment transaction (customer pays money).
  /// Balance decreases.
  /// NOTE: Legacy property name. Prefer using `isPayment` for clarity.
  bool get isDebit => type == 1;

  /// Whether this is a payment transaction (customer pays money).
  /// Balance decreases. Preferred over `isDebit`.
  bool get isPayment => type == 1;

  /// Human-readable type label using centralized enum.
  String get typeLabel => transactionType.label;

  String get paymentModeLabel {
    switch (paymentMode) {
      case 0: return 'Cash';
      case 1: return 'UPI';
      case 2: return 'Card';
      default: return 'Other';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TransactionModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 2)
class TransactionItem extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double price;

  @HiveField(2)
  final double quantity;

  @HiveField(3)
  final String? unit;

  TransactionItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.unit,
  });

  double get total => price * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionItem &&
          other.name == name &&
          other.price == price &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(name, price, quantity);
}
