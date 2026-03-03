import 'package:equatable/equatable.dart';

import '../../../../core/data/models/customer_model.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<CustomerModel> customers;
  final String searchQuery;

  const CustomerLoaded({
    required this.customers,
    this.searchQuery = '',
  });

  /// Filtered stats
  int get totalCustomers => customers.length;
  double get totalOutstanding =>
      customers.fold(0.0, (sum, c) => sum + (c.owesUs ? c.currentBalance : 0));
  int get overdueCount => customers.where((c) => c.isOverdue).length;

  @override
  List<Object?> get props => [customers, searchQuery];
}

class CustomerAdded extends CustomerState {
  final CustomerModel customer;
  const CustomerAdded(this.customer);

  @override
  List<Object?> get props => [customer];
}

class CustomerError extends CustomerState {
  final String message;
  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}
