import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/data/repositories/udhar_repository.dart';
import '../../../../core/error/error_handler.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  UdharRepository _repository;

  CustomerBloc(this._repository) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoad);
    on<SearchCustomers>(_onSearch, transformer: _debounce());
    on<AddCustomer>(_onAdd);
    on<UpdateCustomer>(_onUpdate);
    on<DeleteCustomer>(_onDelete);
    on<RefreshCustomers>(_onRefresh);
  }

  /// Hot-swap the repository after login wires up remote datasource.
  /// Avoids re-registering the BLoC in GetIt (which breaks MultiBlocProvider).
  void updateRepository(UdharRepository repository) {
    _repository = repository;
  }

  /// Debounce search events by 300ms
  EventTransformer<T> _debounce<T>() {
    return (events, mapper) =>
        events.debounceTime(const Duration(milliseconds: 300)).flatMap(mapper);
  }

  /// Loads customers from remote API (falls back to local cache).
  Future<void> _onLoad(
      LoadCustomers event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      final customers = await _repository.getAllCustomersAsync();
      emit(CustomerLoaded(customers: customers));
    } catch (e) {
      emit(CustomerError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onSearch(
      SearchCustomers event, Emitter<CustomerState> emit) async {
    try {
      final customers = await _repository.searchCustomersAsync(event.query);
      emit(CustomerLoaded(customers: customers, searchQuery: event.query));
    } catch (e) {
      emit(CustomerError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onAdd(AddCustomer event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      final customer = await _repository.addCustomer(
        name: event.name,
        phone: event.phone,
        email: event.email,
        address: event.address,
        creditLimit: event.creditLimit,
        avatar: event.avatar,
      );
      emit(CustomerAdded(customer));
      // Reload list from remote to get server-synced data
      final customers = await _repository.getAllCustomersAsync();
      emit(CustomerLoaded(customers: customers));
    } catch (e) {
      emit(CustomerError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onUpdate(
      UpdateCustomer event, Emitter<CustomerState> emit) async {
    try {
      final existing = _repository.getCustomer(event.id);
      if (existing == null) {
        emit(const CustomerError('Customer not found'));
        return;
      }

      final updated = existing.copyWith(
        name: event.name ?? existing.name,
        phone: event.phone ?? existing.phone,
        creditLimit: event.creditLimit ?? existing.creditLimit,
      );
      if (event.notes != null) updated.notes = event.notes;

      await _repository.updateCustomer(updated);
      // Reload from remote to get server-authoritative data
      final customers = await _repository.getAllCustomersAsync();
      emit(CustomerLoaded(customers: customers));
    } catch (e) {
      emit(CustomerError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onDelete(
      DeleteCustomer event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      await _repository.deleteCustomer(event.id);
      // Reload from remote so UI reflects server state
      final customers = await _repository.getAllCustomersAsync();
      emit(CustomerLoaded(customers: customers));
    } catch (e) {
      emit(CustomerError(mapExceptionToFailure(e).message));
    }
  }

  /// Refresh customers from remote API (e.g., after a transaction changes balances)
  Future<void> _onRefresh(
      RefreshCustomers event, Emitter<CustomerState> emit) async {
    try {
      final customers = await _repository.getAllCustomersAsync();
      emit(CustomerLoaded(customers: customers));
    } catch (e) {
      emit(CustomerError(mapExceptionToFailure(e).message));
    }
  }
}
