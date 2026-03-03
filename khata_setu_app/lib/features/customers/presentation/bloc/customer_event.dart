import 'package:equatable/equatable.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {}

class SearchCustomers extends CustomerEvent {
  final String query;
  const SearchCustomers(this.query);

  @override
  List<Object?> get props => [query];
}

class AddCustomer extends CustomerEvent {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double creditLimit;
  final String? avatar;

  const AddCustomer({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.creditLimit = 5000.0,
    this.avatar,
  });

  @override
  List<Object?> get props => [name, phone];
}

class UpdateCustomer extends CustomerEvent {
  final String id;
  final String? name;
  final String? phone;
  final double? creditLimit;
  final String? notes;

  const UpdateCustomer({
    required this.id,
    this.name,
    this.phone,
    this.creditLimit,
    this.notes,
  });

  @override
  List<Object?> get props => [id];
}

class DeleteCustomer extends CustomerEvent {
  final String id;
  const DeleteCustomer(this.id);

  @override
  List<Object?> get props => [id];
}

class RefreshCustomers extends CustomerEvent {}
