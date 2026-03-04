import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/datasources/udhar_local_datasource.dart';
import '../utils/app_logger.dart';
import '../data/datasources/udhar_remote_datasource.dart';

/// Background sync service that pushes unsynced local changes to the backend.
///
/// Runs periodically (default: every 5 minutes) or can be triggered manually.
/// Only active when a remote datasource is available (user is online & logged in).
class SyncService {
  final UdharLocalDataSource _local;
  UdharRemoteDataSource? _remote;

  Timer? _timer;
  bool _isSyncing = false;

  /// Callback to notify listeners of sync status changes
  ValueChanged<SyncStatus>? onStatusChanged;

  SyncService(this._local, [this._remote]);

  /// Update the remote datasource (called after login with shop context)
  void setRemote(UdharRemoteDataSource remote) {
    _remote = remote;
  }

  /// Start periodic sync (call after login)
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    stopPeriodicSync();
    _timer = Timer.periodic(interval, (_) => syncAll());
    // Also sync immediately
    syncAll();
  }

  /// Stop periodic sync (call on logout)
  void stopPeriodicSync() {
    _timer?.cancel();
    _timer = null;
  }

  /// Manually trigger a full sync
  Future<SyncResult> syncAll() async {
    if (_remote == null || _isSyncing) {
      return SyncResult(
        success: false,
        message: _isSyncing ? 'Sync already in progress' : 'No remote connection',
      );
    }

    _isSyncing = true;
    onStatusChanged?.call(SyncStatus.syncing);

    int syncedTransactions = 0;
    int syncedCustomers = 0;
    int errors = 0;

    try {
      // 1. Push unsynced customers
      final customers = _local.getAllCustomers();
      for (final customer in customers) {
        if (!customer.synced) {
          try {
            await _remote!.updateCustomer(customer.id, {
              'name': customer.name,
              'phone': customer.phone,
              if (customer.email != null) 'email': customer.email,
              if (customer.address != null) 'address': customer.address,
              'creditLimit': customer.creditLimit,
              if (customer.notes != null) 'notes': customer.notes,
            });
            customer.synced = true;
            await customer.save();
            syncedCustomers++;
          } catch (e) {
            AppLogger.warning('Sync customer ${customer.id} failed: $e');
            errors++;
          }
        }
      }

      // 2. Push unsynced transactions
      final unsyncedTxns = _local.getUnsyncedTransactions();
      for (final txn in unsyncedTxns) {
        try {
          await _remote!.createLedgerEntry(
            customerId: txn.customerId,
            type: txn.isCredit ? 'credit' : 'payment',
            amount: txn.totalAmount,
            description: txn.description,
            paymentMode: _paymentModeToString(txn.paymentMode),
            items: txn.items
                .map((i) => {
                      'name': i.name,
                      'price': i.price,
                      'quantity': i.quantity,
                      if (i.unit != null) 'unit': i.unit,
                    })
                .toList(),
          );
          txn.synced = true;
          await txn.save();
          syncedTransactions++;
        } catch (e) {
          AppLogger.warning('Sync transaction ${txn.id} failed: $e');
          errors++;
        }
      }

      // 3. Pull latest data from remote to update local cache
      try {
        final remoteCustomers = await _remote!.getAllCustomers();
        for (final c in remoteCustomers) {
          await _local.saveCustomer(c);
        }
      } catch (e) {
        AppLogger.warning('Pull remote customers failed: $e');
      }

      _isSyncing = false;
      onStatusChanged?.call(errors > 0 ? SyncStatus.error : SyncStatus.synced);

      return SyncResult(
        success: errors == 0,
        syncedCustomers: syncedCustomers,
        syncedTransactions: syncedTransactions,
        errors: errors,
        message: errors == 0
            ? 'Synced $syncedCustomers customers, $syncedTransactions transactions'
            : 'Completed with $errors errors',
      );
    } catch (e) {
      _isSyncing = false;
      onStatusChanged?.call(SyncStatus.error);

      return SyncResult(
        success: false,
        errors: errors,
        message: 'Sync failed: $e',
      );
    }
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

  void dispose() {
    stopPeriodicSync();
  }
}

enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
}

class SyncResult {
  final bool success;
  final int syncedCustomers;
  final int syncedTransactions;
  final int errors;
  final String message;

  const SyncResult({
    required this.success,
    this.syncedCustomers = 0,
    this.syncedTransactions = 0,
    this.errors = 0,
    this.message = '',
  });

  @override
  String toString() =>
      'SyncResult(success: $success, customers: $syncedCustomers, '
      'transactions: $syncedTransactions, errors: $errors, message: $message)';
}
