import 'package:hive/hive.dart';

part 'daily_summary_model.g.dart';

@HiveType(typeId: 3)
class DailySummaryModel extends HiveObject {
  @HiveField(0)
  final String id; // "$customerId_$dateKey" e.g. "cust1_2026-03-01"

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String dateKey; // "yyyy-MM-dd"

  @HiveField(3)
  double totalCredit; // Total udhar given today

  @HiveField(4)
  double totalPayment; // Total payment received today

  @HiveField(5)
  int transactionCount;

  @HiveField(6)
  double openingBalance; // Balance at start of day

  @HiveField(7)
  double closingBalance; // Balance at end of day

  DailySummaryModel({
    required this.id,
    required this.customerId,
    required this.dateKey,
    this.totalCredit = 0.0,
    this.totalPayment = 0.0,
    this.transactionCount = 0,
    this.openingBalance = 0.0,
    this.closingBalance = 0.0,
  });

  double get netAmount => totalCredit - totalPayment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DailySummaryModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
