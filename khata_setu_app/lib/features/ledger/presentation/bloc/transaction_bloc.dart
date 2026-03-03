import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/repositories/udhar_repository.dart';
import '../../../../core/data/models/transaction_model.dart';
import '../../../../core/error/error_handler.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  UdharRepository _repository;

  TransactionBloc(this._repository) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadCustomerTransactions);
    on<LoadAllTransactions>(_onLoadAll);
    on<AddCredit>(_onAddCredit);
    on<AddPayment>(_onAddPayment);
    on<UndoLastTransaction>(_onUndo);
    on<RefreshTransactions>(_onRefresh);
  }

  /// Hot-swap the repository after login wires up remote datasource.
  void updateRepository(UdharRepository repository) {
    _repository = repository;
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  void _onLoadCustomerTransactions(
      LoadTransactions event, Emitter<TransactionState> emit) {
    try {
      final customer = _repository.getCustomer(event.customerId);
      final transactions = _repository.getTransactions(event.customerId);
      final grouped = _repository.getGroupedTransactions(event.customerId);
      final summaries = _repository.getSummaries(event.customerId);

      emit(TransactionLoaded(
        customerId: event.customerId,
        customer: customer,
        transactions: transactions,
        groupedByDate: grouped,
        dailySummaries: summaries,
      ));
    } catch (e) {
      emit(TransactionError(mapExceptionToFailure(e).message));
    }
  }

  void _onLoadAll(
      LoadAllTransactions event, Emitter<TransactionState> emit) {
    try {
      final transactions = _repository.getAllTransactions();

      // Group all transactions by date
      final grouped = <String, List<TransactionModel>>{};
      for (final txn in transactions) {
        final key = _dateKey(txn.timestamp);
        grouped.putIfAbsent(key, () => []).add(txn);
      }

      emit(AllTransactionsLoaded(
        transactions: transactions,
        groupedByDate: grouped,
      ));
    } catch (e) {
      emit(TransactionError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onAddCredit(
      AddCredit event, Emitter<TransactionState> emit) async {
    try {
      final txn = await _repository.addCredit(
        customerId: event.customerId,
        amount: event.amount,
        items: event.items,
        description: event.description,
      );

      final updatedCustomer = _repository.getCustomer(event.customerId);
      emit(TransactionAdded(
          transaction: txn, updatedCustomer: updatedCustomer));

      // Reload the customer timeline
      _emitReload(event.customerId, emit);
    } catch (e) {
      emit(TransactionError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onAddPayment(
      AddPayment event, Emitter<TransactionState> emit) async {
    try {
      final txn = await _repository.addPayment(
        customerId: event.customerId,
        amount: event.amount,
        paymentMode: event.paymentMode,
        description: event.description,
      );

      final updatedCustomer = _repository.getCustomer(event.customerId);
      emit(TransactionAdded(
          transaction: txn, updatedCustomer: updatedCustomer));

      // Reload the customer timeline
      _emitReload(event.customerId, emit);
    } catch (e) {
      emit(TransactionError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onUndo(
      UndoLastTransaction event, Emitter<TransactionState> emit) async {
    try {
      final undone = await _repository.undoLastTransaction(event.customerId);
      if (undone != null) {
        emit(TransactionUndone(undone));
        _emitReload(event.customerId, emit);
      } else {
        emit(const TransactionError('No transaction to undo'));
      }
    } catch (e) {
      emit(TransactionError(mapExceptionToFailure(e).message));
    }
  }

  void _onRefresh(
      RefreshTransactions event, Emitter<TransactionState> emit) {
    if (event.customerId != null) {
      _emitReload(event.customerId!, emit);
    } else {
      add(LoadAllTransactions());
    }
  }

  void _emitReload(String customerId, Emitter<TransactionState> emit) {
    final customer = _repository.getCustomer(customerId);
    final transactions = _repository.getTransactions(customerId);
    final grouped = _repository.getGroupedTransactions(customerId);
    final summaries = _repository.getSummaries(customerId);

    emit(TransactionLoaded(
      customerId: customerId,
      customer: customer,
      transactions: transactions,
      groupedByDate: grouped,
      dailySummaries: summaries,
    ));
  }
}
