import 'package:equatable/equatable.dart';
import '../../../../core/data/models/transaction_model.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

/// Load all transactions for a specific customer (timeline view)
class LoadTransactions extends TransactionEvent {
  final String customerId;
  const LoadTransactions(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

/// Load ALL transactions across all customers (global ledger view)
class LoadAllTransactions extends TransactionEvent {}

/// Add a credit (udhar) entry
class AddCredit extends TransactionEvent {
  final String customerId;
  final double amount;
  final List<TransactionItem> items;
  final String? description;

  const AddCredit({
    required this.customerId,
    required this.amount,
    this.items = const [],
    this.description,
  });

  @override
  List<Object?> get props => [customerId, amount];
}

/// Record a payment (debit) entry
class AddPayment extends TransactionEvent {
  final String customerId;
  final double amount;
  final int paymentMode; // 0=cash, 1=upi, 2=card, 3=other
  final String? description;

  const AddPayment({
    required this.customerId,
    required this.amount,
    this.paymentMode = 0,
    this.description,
  });

  @override
  List<Object?> get props => [customerId, amount, paymentMode];
}

/// Undo the most recent transaction for a customer
class UndoLastTransaction extends TransactionEvent {
  final String customerId;
  const UndoLastTransaction(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

/// Refresh current view
class RefreshTransactions extends TransactionEvent {
  final String? customerId;
  const RefreshTransactions({this.customerId});

  @override
  List<Object?> get props => [customerId];
}
