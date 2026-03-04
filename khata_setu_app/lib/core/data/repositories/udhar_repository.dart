import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../utils/app_logger.dart';
import '../datasources/udhar_local_datasource.dart';
import '../datasources/udhar_remote_datasource.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../models/daily_summary_model.dart';

/// Repository — Single entry point for all Udhar business logic.
/// Offline-first: reads from local Hive, syncs with remote API.
/// When [_remote] is available, operations go to server first,
/// then update local cache. Fallback to local-only when offline.
class UdharRepository {
  final UdharLocalDataSource _local;
  final UdharRemoteDataSource? _remote;
  final _uuid = const Uuid();

  UdharRepository(this._local, [this._remote]);

  bool get _hasRemote => _remote != null;

  // ─── Customer ────────────────────────────────────────────────

  /// Fetches customers: tries remote first, falls back to local cache.
  Future<List<CustomerModel>> getAllCustomersAsync() async {
    if (_hasRemote) {
      try {
        final remoteCustomers = await _remote!.getAllCustomers();
        // Cache locally
        for (final c in remoteCustomers) {
          await _local.saveCustomer(c);
        }
        return remoteCustomers;
      } catch (e) {
        AppLogger.warning('Remote fetch failed, using local: $e');
      }
    }
    return _local.getAllCustomers();
  }

  /// Synchronous local-only access (for quick reads)
  List<CustomerModel> getAllCustomers() => _local.getAllCustomers();

  CustomerModel? getCustomer(String id) => _local.getCustomerById(id);

  Future<List<CustomerModel>> searchCustomersAsync(String query) async {
    if (_hasRemote) {
      try {
        return await _remote!.searchCustomers(query);
      } catch (_) {}
    }
    return _local.searchCustomers(query);
  }

  List<CustomerModel> searchCustomers(String query) =>
      _local.searchCustomers(query);

  Future<CustomerModel> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    double creditLimit = 5000.0,
    String? avatar,
    String? notes,
  }) async {
    // Try remote first
    if (_hasRemote) {
      try {
        final remoteCustomer = await _remote!.createCustomer(
          name: name,
          phone: phone,
          email: email,
          address: address,
          creditLimit: creditLimit,
          avatar: avatar,
          notes: notes,
        );
        await _local.saveCustomer(remoteCustomer);
        return remoteCustomer;
      } catch (e) {
        AppLogger.warning('Remote create failed, saving locally: $e');
      }
    }

    // Fallback to local
    final customer = CustomerModel(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      email: email,
      address: address,
      creditLimit: creditLimit,
      avatar: avatar,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _local.saveCustomer(customer);
    return customer;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    // Try remote — use the server's response to keep balance in sync
    if (_hasRemote) {
      try {
        final remoteCustomer = await _remote!.updateCustomer(customer.id, {
          'name': customer.name,
          'phone': customer.phone,
          if (customer.email != null) 'email': customer.email,
          if (customer.address != null) 'address': customer.address,
          'creditLimit': customer.creditLimit,
          if (customer.notes != null) 'notes': customer.notes,
        });
        // Save the server-returned model (has authoritative balance)
        await _local.saveCustomer(remoteCustomer);
        return;
      } catch (e) {
        AppLogger.warning('Remote update failed: $e');
        customer.synced = false;
      }
    } else {
      customer.synced = false;
    }
    await _local.saveCustomer(customer);
  }

  Future<void> deleteCustomer(String id) async {
    if (_hasRemote) {
      try {
        await _remote!.deleteCustomer(id);
      } catch (e) {
        AppLogger.warning('Remote delete failed: $e');
      }
    }
    await _local.deleteCustomer(id);
  }

  // ─── Transactions ────────────────────────────────────────────

  List<TransactionModel> getTransactions(String customerId) =>
      _local.getTransactionsForCustomer(customerId);

  List<TransactionModel> getAllTransactions() => _local.getAllTransactions();

  Map<String, List<TransactionModel>> getGroupedTransactions(
          String customerId) =>
      _local.getGroupedTransactions(customerId);

  Future<TransactionModel> addCredit({
    required String customerId,
    required double amount,
    List<TransactionItem> items = const [],
    String? description,
  }) async {
    // Try remote first
    if (_hasRemote) {
      try {
        final remoteTxn = await _remote!.createLedgerEntry(
          customerId: customerId,
          type: 'credit',
          amount: amount,
          description: description,
          items: items
              .map((i) => {
                    'name': i.name,
                    'price': i.price,
                    'quantity': i.quantity,
                    if (i.unit != null) 'unit': i.unit,
                  })
              .toList(),
        );
        // Save remotely-created transaction locally
        await _local.saveTransactionDirect(remoteTxn, customerId);
        return remoteTxn;
      } catch (e) {
        AppLogger.warning('Remote credit failed, saving locally: $e');
      }
    }

    // Fallback: save locally only
    return _local.addTransaction(
      id: _uuid.v4(),
      customerId: customerId,
      type: 0,
      amount: amount,
      items: items,
      description: description,
    );
  }

  Future<TransactionModel> addPayment({
    required String customerId,
    required double amount,
    int paymentMode = 0,
    String? description,
  }) async {
    final paymentModeStr = _paymentModeToString(paymentMode);

    // Try remote first
    if (_hasRemote) {
      try {
        final remoteTxn = await _remote!.createLedgerEntry(
          customerId: customerId,
          type: 'debit', // Backend enum: 'credit' | 'debit'
          amount: amount,
          description: description ?? 'Payment received',
          paymentMode: paymentModeStr,
        );
        await _local.saveTransactionDirect(remoteTxn, customerId);
        return remoteTxn;
      } catch (e) {
        AppLogger.warning('Remote payment failed, saving locally: $e');
      }
    }

    // Fallback: save locally only
    return _local.addTransaction(
      id: _uuid.v4(),
      customerId: customerId,
      type: 1,
      amount: amount,
      paymentMode: paymentMode,
      description: description ?? 'Payment received',
    );
  }

  String _paymentModeToString(int mode) {
    switch (mode) {
      case 1:
        return 'upi';
      case 2:
        return 'card';
      case 3:
        return 'other';
      default:
        return 'cash';
    }
  }

  Future<TransactionModel?> undoLastTransaction(String customerId) async {
    // Get last transaction to find its ID for remote deletion
    final transactions = _local.getTransactionsForCustomer(customerId);
    if (transactions.isEmpty) return null;

    // Use .first because list is sorted newest-first (desc by timestamp)
    final lastTxn = transactions.first;

    if (_hasRemote) {
      try {
        await _remote!.deleteLedgerEntry(lastTxn.id, reason: 'Undo');
      } catch (e) {
        AppLogger.warning('Remote undo failed: $e');
      }
    }

    return _local.undoLastTransaction(customerId);
  }

  // ─── Daily Summary ───────────────────────────────────────────

  DailySummaryModel? getTodaySummary(String customerId) =>
      _local.getDailySummary(customerId, DateTime.now());

  List<DailySummaryModel> getSummaries(String customerId) =>
      _local.getSummariesForCustomer(customerId);

  // ─── Export ──────────────────────────────────────────────────

  Map<String, dynamic> getCustomerStatement(String customerId) =>
      _local.exportCustomerStatement(customerId);

  /// Write daily backup JSON to app documents directory.
  Future<String> generateDailyBackup() async {
    final data = _local.exportFullBackup();
    final json = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final now = DateTime.now();
    final fileName =
        'khatasetu_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
    final file = File('${backupDir.path}/$fileName');
    await file.writeAsString(json);

    return file.path;
  }

  // ─── Sync Preparation ───────────────────────────────────────

  List<TransactionModel> getUnsyncedTransactions() =>
      _local.getUnsyncedTransactions();

  /// Mark transactions as synced (called after successful API push)
  Future<void> markAsSynced(List<String> transactionIds) async {
    for (final id in transactionIds) {
      final txns = _local.getAllTransactions();
      final txn = txns.where((t) => t.id == id).firstOrNull;
      if (txn != null) {
        txn.synced = true;
        await txn.save();
      }
    }
  }
}
