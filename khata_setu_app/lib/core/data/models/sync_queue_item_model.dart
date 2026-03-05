import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'sync_queue_item_model.g.dart';

/// Entity types that can be queued for offline sync.
@HiveType(typeId: 10)
enum SyncEntityType {
  @HiveField(0)
  customer,

  @HiveField(1)
  transaction,

  @HiveField(2)
  product,

  @HiveField(3)
  dailyNote,
}

/// CRUD operation type.
@HiveType(typeId: 11)
enum SyncOperation {
  @HiveField(0)
  create,

  @HiveField(1)
  update,

  @HiveField(2)
  delete,
}

/// Queue item status.
@HiveType(typeId: 12)
enum SyncItemStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  syncing,

  @HiveField(2)
  failed,

  @HiveField(3)
  synced,
}

/// A single queued offline operation, persisted in Hive.
///
/// When a create/update/delete fails (offline or timeout), the operation
/// is saved here. On reconnect, [SyncService] flushes items in FIFO order.
@HiveType(typeId: 9)
class SyncQueueItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final SyncEntityType entityType;

  @HiveField(2)
  final SyncOperation operation;

  @HiveField(3)
  final String shopId;

  /// Local (Hive) ID of the entity. Used to look up + patch after sync.
  @HiveField(4)
  final String localId;

  /// Server-assigned ID. Populated after successful sync of a `create`.
  @HiveField(5)
  String? serverId;

  /// JSON-encoded payload to send to the server.
  @HiveField(6)
  final String payloadJson;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  int retryCount;

  @HiveField(10)
  String? lastError;

  @HiveField(11)
  SyncItemStatus status;

  /// Unique offline ID sent to the server for deduplication.
  /// The server should treat a second request with the same offlineId
  /// as idempotent (return the existing entity instead of creating a dup).
  @HiveField(12)
  final String offlineId;

  /// Priority for dependency ordering.
  /// Lower = processed first. Customers = 0, transactions = 1, etc.
  @HiveField(13)
  final int priority;

  SyncQueueItemModel({
    String? id,
    required this.entityType,
    required this.operation,
    required this.shopId,
    required this.localId,
    this.serverId,
    required this.payloadJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.retryCount = 0,
    this.lastError,
    this.status = SyncItemStatus.pending,
    String? offlineId,
    int? priority,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        offlineId = offlineId ?? const Uuid().v4(),
        priority = priority ?? _defaultPriority(entityType);

  /// Decode the stored JSON payload back to a Map.
  Map<String, dynamic> get payload => jsonDecode(payloadJson) as Map<String, dynamic>;

  /// Default dependency priority: customers (0) before transactions (1)
  /// before products (2) before daily_notes (3).
  static int _defaultPriority(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.customer:
        return 0;
      case SyncEntityType.transaction:
        return 1;
      case SyncEntityType.product:
        return 2;
      case SyncEntityType.dailyNote:
        return 3;
    }
  }

  /// Whether this item can still be retried.
  bool get canRetry => retryCount < 5;

  /// Exponential backoff delay: 2^retryCount seconds (1s, 2s, 4s, 8s, 16s).
  Duration get backoffDelay => Duration(seconds: 1 << retryCount);

  @override
  String toString() =>
      'SyncQueueItem(id: $id, entity: $entityType, op: $operation, '
      'localId: $localId, status: $status, retries: $retryCount)';
}
