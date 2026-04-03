import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../datasources/udhar_local_datasource.dart';
import '../datasources/udhar_remote_datasource.dart';
import '../datasources/sync_queue_local_datasource.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../models/daily_summary_model.dart';
import '../models/sync_queue_item_model.dart';

/// Repository — Single entry point for all Udhar business logic.
/// Offline-first: reads from local Hive, syncs with remote API.
/// When [_remote] is available, operations go to server first,
/// then update local cache. Fallback to local-only when offline.
/// Failed remote calls are enqueued via [_syncQueue] for later retry.
class UdharRepository {
  final UdharLocalDataSource _local;
  final UdharRemoteDataSource? _remote;
  final SyncQueueLocalDataSource? _syncQueue;
  final _uuid = const Uuid();
  String _shopId = '';

  UdharRepository(this._local, [this._remote, this._syncQueue]);

  /// Set the active shopId (for multi-shop queue scoping).
  void setShopId(String shopId) => _shopId = shopId;

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
        debugPrint('Remote fetch failed, using local: $e');
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
        debugPrint('Remote create failed, saving locally: $e');
      }
    }

    // Fallback to local + enqueue for sync
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

    // Enqueue for later sync
    _enqueue(
      entityType: SyncEntityType.customer,
      operation: SyncOperation.create,
      localId: customer.id,
      payload: {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        'creditLimit': creditLimit,
        if (avatar != null) 'avatar': avatar,
        if (notes != null) 'notes': notes,
      },
    );

    return customer;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final updatePayload = {
      'name': customer.name,
      'phone': customer.phone,
      if (customer.email != null) 'email': customer.email,
      if (customer.address != null) 'address': customer.address,
      'creditLimit': customer.creditLimit,
      if (customer.notes != null) 'notes': customer.notes,
    };

    // Try remote
    if (_hasRemote) {
      try {
        await _remote!.updateCustomer(customer.id, updatePayload);
        customer.synced = true;
      } catch (e) {
        debugPrint('Remote update failed: $e');
        customer.synced = false;
        _enqueue(
          entityType: SyncEntityType.customer,
          operation: SyncOperation.update,
          localId: customer.id,
          payload: updatePayload,
        );
      }
    } else {
      customer.synced = false;
      _enqueue(
        entityType: SyncEntityType.customer,
        operation: SyncOperation.update,
        localId: customer.id,
        payload: updatePayload,
      );
    }
    await _local.saveCustomer(customer);
  }

  Future<void> deleteCustomer(String id) async {
    if (_hasRemote) {
      try {
        await _remote!.deleteCustomer(id);
      } catch (e) {
        debugPrint('Remote delete failed: $e');
        _enqueue(
          entityType: SyncEntityType.customer,
          operation: SyncOperation.delete,
          localId: id,
          payload: {},
        );
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
        debugPrint('Remote credit failed, saving locally: $e');
      }
    }

    // Fallback: save locally only + enqueue
    final localId = _uuid.v4();
    final txn = await _local.addTransaction(
      id: localId,
      customerId: customerId,
      type: 0,
      amount: amount,
      items: items,
      description: description,
    );

    _enqueue(
      entityType: SyncEntityType.transaction,
      operation: SyncOperation.create,
      localId: localId,
      payload: {
        'customerId': customerId,
        'type': 'credit',
        'amount': amount,
        if (description != null) 'description': description,
        'items': items
            .map((i) => {
                  'name': i.name,
                  'price': i.price,
                  'quantity': i.quantity,
                  if (i.unit != null) 'unit': i.unit,
                })
            .toList(),
      },
    );

    return txn;
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
          type: 'debit',
          amount: amount,
          description: description ?? 'Payment received',
          paymentMode: paymentModeStr,
        );
        await _local.saveTransactionDirect(remoteTxn, customerId);
        return remoteTxn;
      } catch (e) {
        debugPrint('Remote payment failed, saving locally: $e');
      }
    }

    // Fallback: save locally only + enqueue
    final localId = _uuid.v4();
    final txn = await _local.addTransaction(
      id: localId,
      customerId: customerId,
      type: 1,
      amount: amount,
      paymentMode: paymentMode,
      description: description ?? 'Payment received',
    );

    _enqueue(
      entityType: SyncEntityType.transaction,
      operation: SyncOperation.create,
      localId: localId,
      payload: {
        'customerId': customerId,
        'type': 'debit',
        'amount': amount,
        'description': description ?? 'Payment received',
        'paymentMode': paymentModeStr,
      },
    );

    return txn;
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

    // transactions are sorted newest-first, so .first is the most recent
    final lastTxn = transactions.first;

    if (_hasRemote) {
      try {
        await _remote!.deleteLedgerEntry(lastTxn.id, reason: 'Undo');
      } catch (e) {
        debugPrint('Remote undo failed: $e');
        _enqueue(
          entityType: SyncEntityType.transaction,
          operation: SyncOperation.delete,
          localId: lastTxn.id,
          payload: {'reason': 'Undo'},
        );
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

  // ─── Queue Helper ──────────────────────────────────────────

  void _enqueue({
    required SyncEntityType entityType,
    required SyncOperation operation,
    required String localId,
    required Map<String, dynamic> payload,
  }) {
    if (_syncQueue == null) return;
    _syncQueue.add(SyncQueueItemModel(
      entityType: entityType,
      operation: operation,
      shopId: _shopId,
      localId: localId,
      payloadJson: jsonEncode(payload),
    ));
  }
}
