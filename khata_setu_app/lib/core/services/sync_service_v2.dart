import 'dart:async';

import '../data/datasources/sync_queue_local_datasource.dart';
import '../data/datasources/udhar_local_datasource.dart';
import '../data/datasources/udhar_remote_datasource.dart';
import '../data/datasources/product_local_datasource.dart';
import '../data/datasources/product_remote_datasource.dart';
import '../data/datasources/daily_note_local_datasource.dart';
import '../data/datasources/daily_note_remote_datasource.dart';
import '../data/models/sync_queue_item_model.dart';
import '../utils/app_logger.dart';
import 'connectivity_service.dart';

/// Unified sync engine that flushes a persistent [SyncQueueLocalDataSource]
/// whenever the device goes online.
///
/// Features:
/// - FIFO processing with dependency ordering (customers before transactions)
/// - Exponential back-off per item (1s → 2s → 4s → 8s → 16s, max 5 retries)
/// - Mutex to prevent concurrent flush runs
/// - Emits [SyncProgress] via a broadcast stream for UI banners
/// - Periodic background sweep + immediate flush on connectivity change
class SyncService {
  final SyncQueueLocalDataSource _queue;
  final ConnectivityService _connectivity;

  // Remote datasources — nullable; set after login
  UdharLocalDataSource? _udharLocal;
  UdharRemoteDataSource? _udharRemote;
  ProductLocalDataSource? _productLocal;
  ProductRemoteDataSource? _productRemote;
  DailyNoteLocalDataSource? _dailyNoteLocal;
  DailyNoteRemoteDataSource? _dailyNoteRemote;

  Timer? _periodicTimer;
  bool _isFlushing = false;
  StreamSubscription<bool>? _connectivitySub;

  // ── Sync progress stream ──────────────────────────────────
  final _progressController = StreamController<SyncProgress>.broadcast();
  Stream<SyncProgress> get progressStream => _progressController.stream;

  SyncProgress _lastProgress = const SyncProgress();
  SyncProgress get lastProgress => _lastProgress;

  SyncService({
    required SyncQueueLocalDataSource queue,
    required ConnectivityService connectivity,
  })  : _queue = queue,
        _connectivity = connectivity;

  // ── Datasource injection (called after login) ──────────────

  void setUdharDatasources(
      UdharLocalDataSource local, UdharRemoteDataSource remote) {
    _udharLocal = local;
    _udharRemote = remote;
  }

  void setProductDatasources(
      ProductLocalDataSource local, ProductRemoteDataSource remote) {
    _productLocal = local;
    _productRemote = remote;
  }

  void setDailyNoteDatasources(
      DailyNoteLocalDataSource local, DailyNoteRemoteDataSource remote) {
    _dailyNoteLocal = local;
    _dailyNoteRemote = remote;
  }

  // ── Lifecycle ──────────────────────────────────────────────

  /// Start listening to connectivity + periodic sweep.
  void start() {
    // Listen for online events
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        AppLogger.info('[SyncService] Online — flushing queue');
        flushQueue();
      } else {
        _emitProgress(isOnline: false);
      }
    });

    // Periodic sweep every 2 minutes (catches items that errored transiently)
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) {
        if (_connectivity.isOnline) flushQueue();
      },
    );

    // Initial emit
    _emitProgress(isOnline: _connectivity.isOnline);

    // Flush immediately if already online
    if (_connectivity.isOnline) {
      flushQueue();
    }
  }

  /// Stop everything (call on logout).
  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void dispose() {
    stop();
    _progressController.close();
  }

  // ── Enqueue ────────────────────────────────────────────────

  /// Enqueue an offline operation. Deduplicates by localId + entityType.
  Future<void> enqueue(SyncQueueItemModel item) async {
    // Dedup: if a pending/failed item already exists for same localId+entity, skip
    final existing = _queue.findByLocalId(item.localId, item.entityType);
    if (existing != null) {
      AppLogger.info('[SyncService] Dedup: skipping enqueue for ${item.localId}');
      return;
    }

    await _queue.add(item);
    _emitProgress(isOnline: _connectivity.isOnline);

    // If online, try flushing immediately
    if (_connectivity.isOnline) {
      flushQueue();
    }
  }

  // ── Flush Queue ────────────────────────────────────────────

  /// Process all pending items in priority+FIFO order.
  /// Mutex-protected: only one flush can run at a time.
  Future<void> flushQueue() async {
    if (_isFlushing) return;
    _isFlushing = true;

    try {
      _emitProgress(isOnline: true, isSyncing: true);

      while (true) {
        final batch = _queue.getPending(limit: 10);
        if (batch.isEmpty) break;

        for (final item in batch) {
          if (!_connectivity.isOnline) {
            // Lost connection mid-flush — stop
            _emitProgress(isOnline: false);
            return;
          }

          await _processItem(item);
        }
      }

      // Cleanup synced items
      await _queue.clearSynced();

      _emitProgress(isOnline: true, isSyncing: false);
    } catch (e) {
      AppLogger.error('[SyncService] flushQueue error: $e');
    } finally {
      _isFlushing = false;
    }
  }

  /// Process a single queue item.
  Future<void> _processItem(SyncQueueItemModel item) async {
    // Apply exponential backoff
    if (item.retryCount > 0) {
      await Future.delayed(item.backoffDelay);
    }

    // Mark as syncing
    await _queue.updateStatus(item.id, status: SyncItemStatus.syncing);

    try {
      await _dispatch(item);

      // Success
      await _queue.updateStatus(item.id, status: SyncItemStatus.synced);
      AppLogger.info(
          '[SyncService] Synced: ${item.entityType.name}.${item.operation.name} '
          'localId=${item.localId}');
    } catch (e) {
      final newRetry = item.retryCount + 1;
      final errorMsg = e.toString();

      if (newRetry >= 5) {
        await _queue.markFailed(item.id, errorMsg);
        AppLogger.error(
            '[SyncService] Permanently failed after 5 retries: '
            '${item.entityType.name}.${item.operation.name} localId=${item.localId}');
      } else {
        await _queue.updateStatus(
          item.id,
          status: SyncItemStatus.failed,
          retryCount: newRetry,
          lastError: errorMsg,
        );
        AppLogger.warning(
            '[SyncService] Retry $newRetry/5 for ${item.localId}: $errorMsg');
      }
    }

    _emitProgress(isOnline: _connectivity.isOnline, isSyncing: true);
  }

  /// Route item to the correct remote API call.
  Future<void> _dispatch(SyncQueueItemModel item) async {
    switch (item.entityType) {
      case SyncEntityType.customer:
        await _syncCustomer(item);
        break;
      case SyncEntityType.transaction:
        await _syncTransaction(item);
        break;
      case SyncEntityType.product:
        await _syncProduct(item);
        break;
      case SyncEntityType.dailyNote:
        await _syncDailyNote(item);
        break;
    }
  }

  // ── Entity-specific sync handlers ─────────────────────────

  /// Resolve the server-assigned ID for a locally-created entity.
  /// Falls back to `localId` if no mapping exists (entity was created online).
  String _resolveServerId(String localId, SyncEntityType entityType) {
    return _queue.findServerIdByLocalId(localId, entityType) ?? localId;
  }

  Future<void> _syncCustomer(SyncQueueItemModel item) async {
    final remote = _udharRemote;
    final local = _udharLocal;
    if (remote == null || local == null) {
      throw StateError('Udhar datasources not configured');
    }

    final payload = item.payload;

    switch (item.operation) {
      case SyncOperation.create:
        final remoteCustomer = await remote.createCustomer(
          name: payload['name'] as String,
          phone: payload['phone'] as String,
          email: payload['email'] as String?,
          address: payload['address'] as String?,
          creditLimit: (payload['creditLimit'] as num?)?.toDouble(),
          avatar: payload['avatar'] as String?,
          notes: payload['notes'] as String?,
        );
        // Update local entity with server ID
        final localCustomer = local.getCustomerById(item.localId);
        if (localCustomer != null) {
          localCustomer.synced = true;
          await localCustomer.save();
        }
        // Store the server ID mapping
        await _queue.updateStatus(item.id,
            status: SyncItemStatus.synced, serverId: remoteCustomer.id);
        // Also save the remote version locally for data freshness
        await local.saveCustomer(remoteCustomer);
        break;

      case SyncOperation.update:
        // Resolve UUID → server ObjectId if created offline
        final serverId = _resolveServerId(
            item.localId, SyncEntityType.customer);
        await remote.updateCustomer(serverId, payload);
        final localCustomer = local.getCustomerById(item.localId);
        if (localCustomer != null) {
          localCustomer.synced = true;
          await localCustomer.save();
        }
        break;

      case SyncOperation.delete:
        final serverId = _resolveServerId(
            item.localId, SyncEntityType.customer);
        await remote.deleteCustomer(serverId);
        break;
    }
  }

  Future<void> _syncTransaction(SyncQueueItemModel item) async {
    final remote = _udharRemote;
    final local = _udharLocal;
    if (remote == null || local == null) {
      throw StateError('Udhar datasources not configured');
    }

    final payload = item.payload;

    switch (item.operation) {
      case SyncOperation.create:
        // Resolve customerId: if the customer was also created offline,
        // we need the server-assigned ID (MongoDB ObjectId).
        String customerId = payload['customerId'] as String;
        final resolvedCustomerId = _queue.findServerIdByLocalId(
            customerId, SyncEntityType.customer);
        if (resolvedCustomerId != null) {
          customerId = resolvedCustomerId;
        }

        // The items in the payload use {name, price, quantity, unit}
        // which is what createLedgerEntry expects as its `items` param.
        // The ApiService maps these to `linkedProducts` with the backend's
        // expected shape {productId, quantity, pricePerUnit}.
        final items = (payload['items'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        final remoteTxn = await remote.createLedgerEntry(
          customerId: customerId,
          type: payload['type'] as String,
          amount: (payload['amount'] as num).toDouble(),
          description: payload['description'] as String?,
          paymentMode: payload['paymentMode'] as String?,
          items: items,
        );

        // Mark local transaction as synced
        final localTxns = local.getAllTransactions();
        final localTxn =
            localTxns.where((t) => t.id == item.localId).firstOrNull;
        if (localTxn != null) {
          localTxn.synced = true;
          await localTxn.save();
        }

        await _queue.updateStatus(item.id,
            status: SyncItemStatus.synced, serverId: remoteTxn.id);
        break;

      case SyncOperation.update:
        // Transactions are typically immutable; skip if not needed
        break;

      case SyncOperation.delete:
        // Resolve UUID → server ObjectId
        final serverId = _resolveServerId(
            item.localId, SyncEntityType.transaction);
        await remote.deleteLedgerEntry(serverId,
            reason: payload['reason'] as String? ?? 'Deleted offline');
        break;
    }
  }

  Future<void> _syncProduct(SyncQueueItemModel item) async {
    final remote = _productRemote;
    final local = _productLocal;
    if (remote == null || local == null) {
      throw StateError('Product datasources not configured');
    }

    switch (item.operation) {
      case SyncOperation.create:
        final localProduct = local.getProductById(item.localId);
        if (localProduct == null) break;

        final remoteProduct = await remote.createProduct(localProduct);
        // Save the remote version (with server ID) locally
        await local.saveProduct(remoteProduct);
        await _queue.updateStatus(item.id,
            status: SyncItemStatus.synced, serverId: remoteProduct.id);
        break;

      case SyncOperation.update:
        // Resolve UUID → server ObjectId if created offline
        final serverId = _resolveServerId(
            item.localId, SyncEntityType.product);
        final payload = item.payload;
        await remote.updateProduct(serverId, payload);
        final localProduct = local.getProductById(item.localId);
        if (localProduct != null) {
          localProduct.synced = true;
          await localProduct.save();
        }
        break;

      case SyncOperation.delete:
        final serverId = _resolveServerId(
            item.localId, SyncEntityType.product);
        await remote.deleteProduct(serverId);
        break;
    }
  }

  Future<void> _syncDailyNote(SyncQueueItemModel item) async {
    final remote = _dailyNoteRemote;
    final local = _dailyNoteLocal;
    if (remote == null || local == null) {
      throw StateError('DailyNote datasources not configured');
    }

    switch (item.operation) {
      case SyncOperation.create:
        final localNote = local.getDailyNoteById(item.localId);
        if (localNote == null) break;

        // If the note references an offline-created customer, resolve the ID
        // Note: localNote.toJson() will include the local UUID for customerId.
        // The remote.createNote sends the model's toJson(), so we must
        // update the model's customerId before sending.
        if (localNote.customerId != null) {
          final resolvedCustId = _queue.findServerIdByLocalId(
              localNote.customerId!, SyncEntityType.customer);
          if (resolvedCustId != null) {
            // Update the local model's customerId to the server ID
            final updatedNote = localNote.copyWith(customerId: resolvedCustId);
            await local.saveDailyNote(updatedNote);
            final remoteNote = await remote.createNote(updatedNote);
            await local.saveDailyNote(remoteNote);
            await _queue.updateStatus(item.id,
                status: SyncItemStatus.synced, serverId: remoteNote.id);
            break;
          }
        }

        final remoteNote = await remote.createNote(localNote);
        await local.saveDailyNote(remoteNote);
        await _queue.updateStatus(item.id,
            status: SyncItemStatus.synced, serverId: remoteNote.id);
        break;

      case SyncOperation.update:
        final serverId = _resolveServerId(
            item.localId, SyncEntityType.dailyNote);
        final payload = item.payload;
        await remote.updateNote(serverId, payload);
        final localNote = local.getDailyNoteById(item.localId);
        if (localNote != null) {
          localNote.synced = true;
          await localNote.save();
        }
        break;

      case SyncOperation.delete:
        final serverId = _resolveServerId(
            item.localId, SyncEntityType.dailyNote);
        await remote.deleteNote(serverId);
        break;
    }
  }

  // ── Progress emission ──────────────────────────────────────

  void _emitProgress({
    required bool isOnline,
    bool isSyncing = false,
  }) {
    final pending = _queue.getCountPending();
    final failed = _queue.getCountFailed();

    _lastProgress = SyncProgress(
      isOnline: isOnline,
      isSyncing: isSyncing,
      pendingCount: pending,
      failedCount: failed,
    );
    if (!_progressController.isClosed) {
      _progressController.add(_lastProgress);
    }
  }

  // ── Manual controls ────────────────────────────────────────

  /// Manually trigger sync (e.g. from Settings "Sync Now" button).
  Future<void> syncNow() async {
    if (_connectivity.isOnline) {
      await flushQueue();
    }
  }

  /// Retry all permanently failed items.
  Future<void> retryFailed() async {
    await _queue.retryAllFailed();
    _emitProgress(isOnline: _connectivity.isOnline);
    if (_connectivity.isOnline) {
      await flushQueue();
    }
  }

  /// Get the current pending count (for quick UI reads).
  int get pendingCount => _queue.getCountPending();
}

/// Immutable snapshot of sync progress for UI consumption.
class SyncProgress {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;

  const SyncProgress({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
  });

  bool get hasWork => pendingCount > 0 || failedCount > 0;
  bool get isIdle => !isSyncing && pendingCount == 0;

  @override
  String toString() =>
      'SyncProgress(online: $isOnline, syncing: $isSyncing, '
      'pending: $pendingCount, failed: $failedCount)';
}
