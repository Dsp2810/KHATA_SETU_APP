import 'package:hive_flutter/hive_flutter.dart';

import '../models/sync_queue_item_model.dart';

/// Hive-backed local data source for the offline sync queue.
///
/// All writes use Hive's key-value API (key = item.id) for O(1) lookups.
/// Pending items are sorted by [priority] then [createdAt] for FIFO + dependency order.
class SyncQueueLocalDataSource {
  static const String boxName = 'sync_queue';

  Box<SyncQueueItemModel> get _box => Hive.box<SyncQueueItemModel>(boxName);

  /// Enqueue a new sync operation.
  Future<void> add(SyncQueueItemModel item) async {
    await _box.put(item.id, item);
  }

  /// Update just the status + metadata of an existing queue item.
  Future<void> updateStatus(
    String id, {
    required SyncItemStatus status,
    String? lastError,
    int? retryCount,
    String? serverId,
  }) async {
    final item = _box.get(id);
    if (item == null) return;

    item.status = status;
    item.updatedAt = DateTime.now();
    if (lastError != null) item.lastError = lastError;
    if (retryCount != null) item.retryCount = retryCount;
    if (serverId != null) item.serverId = serverId;

    await item.save();
  }

  /// Get pending items sorted by priority (customers first) then createdAt (FIFO).
  /// [limit] caps the batch size to avoid processing too many at once.
  List<SyncQueueItemModel> getPending({int limit = 50}) {
    final items = _box.values
        .where((item) =>
            item.status == SyncItemStatus.pending ||
            (item.status == SyncItemStatus.failed && item.canRetry))
        .toList()
      ..sort((a, b) {
        // Sort by priority first (lower = higher priority)
        final pCmp = a.priority.compareTo(b.priority);
        if (pCmp != 0) return pCmp;
        // Then by creation time (oldest first = FIFO)
        return a.createdAt.compareTo(b.createdAt);
      });

    return items.take(limit).toList();
  }

  /// Count of items that still need syncing (pending + retryable failed).
  int getCountPending() {
    return _box.values
        .where((item) =>
            item.status == SyncItemStatus.pending ||
            item.status == SyncItemStatus.syncing ||
            (item.status == SyncItemStatus.failed && item.canRetry))
        .length;
  }

  /// Count of permanently failed items (exhausted retries).
  int getCountFailed() {
    return _box.values
        .where((item) =>
            item.status == SyncItemStatus.failed && !item.canRetry)
        .length;
  }

  /// Remove all synced items (call periodically to keep the box small).
  Future<void> clearSynced() async {
    final syncedKeys = _box.values
        .where((item) => item.status == SyncItemStatus.synced)
        .map((item) => item.id)
        .toList();

    for (final key in syncedKeys) {
      await _box.delete(key);
    }
  }

  /// Mark an item as permanently failed (no more retries).
  Future<void> markFailed(String id, String error) async {
    await updateStatus(
      id,
      status: SyncItemStatus.failed,
      lastError: error,
      retryCount: 5, // force max
    );
  }

  /// Delete a specific queue item.
  Future<void> deleteItem(String id) async {
    await _box.delete(id);
  }

  /// Check if an operation with the same offlineId already exists
  /// (dedup guard against double-taps).
  bool hasOfflineId(String offlineId) {
    return _box.values.any((item) => item.offlineId == offlineId);
  }

  /// Find a queue item by localId and entityType (for dedup on re-enqueue).
  SyncQueueItemModel? findByLocalId(String localId, SyncEntityType entityType) {
    return _box.values
        .where((item) =>
            item.localId == localId &&
            item.entityType == entityType &&
            item.status != SyncItemStatus.synced)
        .firstOrNull;
  }

  /// Get all items (for debug / settings UI).
  List<SyncQueueItemModel> getAll() => _box.values.toList();

  /// Reset all failed items back to pending (manual retry from settings).
  Future<void> retryAllFailed() async {
    final failed = _box.values
        .where((item) => item.status == SyncItemStatus.failed)
        .toList();

    for (final item in failed) {
      item.status = SyncItemStatus.pending;
      item.retryCount = 0;
      item.lastError = null;
      item.updatedAt = DateTime.now();
      await item.save();
    }
  }

  /// Clear everything (for logout / debug).
  Future<void> clearAll() async {
    await _box.clear();
  }
}
