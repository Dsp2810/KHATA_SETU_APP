import 'package:equatable/equatable.dart';
import '../../../../core/data/models/transaction_model.dart';
import '../../../../core/data/models/daily_summary_model.dart';
import '../../../../core/data/models/customer_model.dart';
import '../../../../core/utils/ledger_rules.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

/// Customer-scoped transaction list (timeline view)
class TransactionLoaded extends TransactionState {
  final String customerId;
  final CustomerModel? customer;
  final List<TransactionModel> transactions;
  final Map<String, List<TransactionModel>> groupedByDate;
  final List<DailySummaryModel> dailySummaries;

  const TransactionLoaded({
    required this.customerId,
    this.customer,
    required this.transactions,
    required this.groupedByDate,
    required this.dailySummaries,
  });

  /// Total credit using centralized type checking
  double get totalCredit => transactions.fold(
      0.0, (s, t) => s + (t.transactionType == TransactionType.credit ? t.totalAmount : 0));
  
  /// Total payment using centralized type checking
  double get totalPayment => transactions.fold(
      0.0, (s, t) => s + (t.transactionType == TransactionType.payment ? t.totalAmount : 0));
  
  double get netBalance => customer?.currentBalance ?? 0;
  int get transactionCount => transactions.length;

  @override
  List<Object?> get props => [customerId, transactions, groupedByDate];
}

/// Global ledger view (all customers)
class AllTransactionsLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final Map<String, List<TransactionModel>> groupedByDate;

  const AllTransactionsLoaded({
    required this.transactions,
    required this.groupedByDate,
  });

  /// Total credit using centralized type checking
  double get totalCredit => transactions.fold(
      0.0, (s, t) => s + (t.transactionType == TransactionType.credit ? t.totalAmount : 0));
  
  /// Total payment using centralized type checking
  double get totalPayment => transactions.fold(
      0.0, (s, t) => s + (t.transactionType == TransactionType.payment ? t.totalAmount : 0));

  @override
  List<Object?> get props => [transactions];
}

/// Emitted briefly after a successful transaction add
class TransactionAdded extends TransactionState {
  final TransactionModel transaction;
  final CustomerModel? updatedCustomer;

  const TransactionAdded({required this.transaction, this.updatedCustomer});

  @override
  List<Object?> get props => [transaction];
}

/// Emitted after a successful undo
class TransactionUndone extends TransactionState {
  final TransactionModel undoneTransaction;
  const TransactionUndone(this.undoneTransaction);

  @override
  List<Object?> get props => [undoneTransaction];
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}
