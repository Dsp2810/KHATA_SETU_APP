import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

part 'daily_note_model.g.dart';

/// A single structured item row in a daily note.
/// Maps to backend `structuredItems[]`.
@HiveType(typeId: 7)
class DailyItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String productName;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  double unitPrice;

  @HiveField(4)
  String? unit; // piece, kg, gram, liter, ml, meter, dozen, packet, box, bundle, other

  @HiveField(5)
  String? note;

  @HiveField(6)
  int timeLabel; // 0 = morning, 1 = afternoon, 2 = evening (local-only)

  @HiveField(7)
  DateTime timestamp;

  @HiveField(8)
  String? productId; // link to backend Product._id

  DailyItemModel({
    String? id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.unit,
    this.note,
    this.timeLabel = 0,
    DateTime? timestamp,
    this.productId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Auto-calculated total for this item
  double get totalPrice => quantity * unitPrice;

  /// Human-readable time label
  String get timeLabelText {
    switch (timeLabel) {
      case 0:
        return 'Morning';
      case 1:
        return 'Afternoon';
      case 2:
        return 'Evening';
      default:
        return '';
    }
  }

  /// Convert to JSON for backend API (structuredItem format)
  Map<String, dynamic> toJson() => {
        if (productId != null) 'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unit': unit ?? 'piece',
        'unitPrice': unitPrice,
      };

  /// Create from backend JSON (structuredItem or populated)
  factory DailyItemModel.fromJson(Map<String, dynamic> json) {
    // productId can be a populated object or a string
    String? prodId;
    String prodName = json['productName'] ?? '';

    if (json['productId'] != null) {
      if (json['productId'] is Map) {
        prodId = json['productId']['_id']?.toString();
        // Use populated product name if productName is empty
        if (prodName.isEmpty) {
          prodName = json['productId']['name'] ?? '';
        }
      } else {
        prodId = json['productId'].toString();
      }
    }

    return DailyItemModel(
      productName: prodName,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String?,
      productId: prodId,
    );
  }

  DailyItemModel copyWith({
    String? productName,
    double? quantity,
    double? unitPrice,
    String? unit,
    String? note,
    int? timeLabel,
    String? productId,
  }) {
    return DailyItemModel(
      id: id,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      timeLabel: timeLabel ?? this.timeLabel,
      timestamp: timestamp,
      productId: productId ?? this.productId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyItemModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Daily note / to-do item for shopkeepers.
/// Can be attached to a customer (optional), contains structured items,
/// priority, status, tags, and reminder support.
///
/// Maps to backend `DailyNote` model.
@HiveType(typeId: 6)
class DailyNoteModel extends HiveObject {
  // ─── Existing fields (indices 0–9, preserved for Hive compat) ────

  @HiveField(0)
  final String id;

  @HiveField(1)
  String? customerId; // nullable — note can be standalone

  @HiveField(2)
  String dateKey; // "yyyy-MM-dd" derived from noteDate

  @HiveField(3)
  List<DailyItemModel> items;

  @HiveField(4)
  String? description; // was "note" — maps to backend description

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isLedgerSynced; // backward compat — use convertedToLedger

  @HiveField(8)
  String? ledgerTransactionId;

  @HiveField(9)
  bool isDeleted;

  // ─── New fields (indices 10+) ────────────────────────────────

  @HiveField(10)
  String title;

  @HiveField(11)
  String priority; // low, medium, high

  @HiveField(12)
  String status; // pending, completed, cancelled

  @HiveField(13)
  DateTime? noteDate;

  @HiveField(14)
  DateTime? reminderAt;

  @HiveField(15)
  List<String> tags;

  @HiveField(16)
  double storedTotalAmount; // from backend, fallback to computed

  @HiveField(17)
  DateTime? completedAt;

  @HiveField(18)
  String? completedBy;

  @HiveField(19)
  String? createdBy;

  @HiveField(20)
  String? modifiedBy;

  @HiveField(21)
  String? offlineId;

  @HiveField(22)
  DateTime? syncedAt;

  @HiveField(23)
  bool convertedToLedger;

  @HiveField(24)
  bool synced; // whether this note has been synced with remote

  @HiveField(25)
  String? customerName; // cached for display without lookup

  @HiveField(26)
  String? customerPhone;

  DailyNoteModel({
    String? id,
    this.customerId,
    String? dateKey,
    List<DailyItemModel>? items,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isLedgerSynced = false,
    this.ledgerTransactionId,
    this.isDeleted = false,
    this.title = '',
    this.priority = 'medium',
    this.status = 'pending',
    this.noteDate,
    this.reminderAt,
    List<String>? tags,
    double? storedTotalAmount,
    this.completedAt,
    this.completedBy,
    this.createdBy,
    this.modifiedBy,
    this.offlineId,
    this.syncedAt,
    this.convertedToLedger = false,
    this.synced = false,
    this.customerName,
    this.customerPhone,
  })  : id = id ?? const Uuid().v4(),
        dateKey = dateKey ??
            DateFormat('yyyy-MM-dd').format(noteDate ?? DateTime.now()),
        items = items ?? [],
        tags = tags ?? [],
        storedTotalAmount = storedTotalAmount ?? 0,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Total amount — prefer backend value, fall back to local computation
  double get totalAmount {
    if (items.isNotEmpty) {
      return items.fold(0.0, (sum, item) => sum + item.totalPrice);
    }
    return storedTotalAmount;
  }

  /// Number of structured items
  int get itemCount => items.length;

  /// Whether this note has structured line-items
  bool get hasItems => items.isNotEmpty;

  /// Whether the note is overdue (pending + past date)
  bool get isOverdue {
    if (status != 'pending') return false;
    final nd = noteDate ?? DateFormat('yyyy-MM-dd').parse(dateKey);
    final today = DateTime.now();
    return nd.isBefore(DateTime(today.year, today.month, today.day));
  }

  /// Whether the reminder is overdue
  bool get isReminderOverdue {
    if (reminderAt == null || status != 'pending') return false;
    return DateTime.now().isAfter(reminderAt!);
  }

  /// Is this note completed?
  bool get isCompleted => status == 'completed';

  /// Is this note cancelled?
  bool get isCancelled => status == 'cancelled';

  /// Is this note pending?
  bool get isPending => status == 'pending';

  /// Items grouped by time label (for editor display)
  Map<int, List<DailyItemModel>> get itemsByTimeLabel {
    final map = <int, List<DailyItemModel>>{};
    for (final item in items) {
      map.putIfAbsent(item.timeLabel, () => []).add(item);
    }
    return map;
  }

  /// Display name for the note card
  String get displayName => customerName ?? customerId ?? title;

  /// Convert to JSON for backend API (create/update)
  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (customerId != null) 'customerId': customerId,
        'structuredItems': items.map((i) => i.toJson()).toList(),
        'priority': priority,
        'status': status,
        if (noteDate != null) 'noteDate': noteDate!.toIso8601String(),
        if (reminderAt != null) 'reminderAt': reminderAt!.toIso8601String(),
        'tags': tags,
        if (offlineId != null) 'offlineId': offlineId,
      };

  /// Create from backend JSON response (populated format)
  factory DailyNoteModel.fromJson(Map<String, dynamic> json) {
    // Handle customerId — can be populated object or string
    String? custId;
    String? custName;
    String? custPhone;
    if (json['customerId'] != null) {
      if (json['customerId'] is Map) {
        custId = json['customerId']['_id']?.toString();
        custName = json['customerId']['name'] as String?;
        custPhone = json['customerId']['phone'] as String?;
      } else {
        custId = json['customerId'].toString();
      }
    }

    // Handle createdBy — can be populated or string
    String? createdById;
    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map) {
        createdById = json['createdBy']['_id']?.toString();
      } else {
        createdById = json['createdBy'].toString();
      }
    }

    // Handle completedBy
    String? completedById;
    if (json['completedBy'] != null) {
      if (json['completedBy'] is Map) {
        completedById = json['completedBy']['_id']?.toString();
      } else {
        completedById = json['completedBy'].toString();
      }
    }

    // Parse structured items
    final itemsList = <DailyItemModel>[];
    if (json['structuredItems'] != null) {
      for (final item in (json['structuredItems'] as List)) {
        itemsList.add(DailyItemModel.fromJson(item as Map<String, dynamic>));
      }
    }

    // Parse noteDate
    DateTime? noteDate;
    if (json['noteDate'] != null) {
      noteDate = DateTime.tryParse(json['noteDate'].toString());
    }

    // Parse tags
    final tags = <String>[];
    if (json['tags'] != null) {
      for (final t in (json['tags'] as List)) {
        tags.add(t.toString());
      }
    }

    return DailyNoteModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? const Uuid().v4(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      customerId: custId,
      customerName: custName,
      customerPhone: custPhone,
      items: itemsList,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      noteDate: noteDate,
      dateKey: noteDate != null
          ? DateFormat('yyyy-MM-dd').format(noteDate)
          : json['dateKey'] as String? ??
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
      reminderAt: json['reminderAt'] != null
          ? DateTime.tryParse(json['reminderAt'].toString())
          : null,
      tags: tags,
      storedTotalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      completedBy: completedById,
      createdBy: createdById,
      modifiedBy: json['modifiedBy']?.toString(),
      offlineId: json['offlineId'] as String?,
      syncedAt: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt'].toString())
          : null,
      convertedToLedger: json['convertedToLedger'] as bool? ?? false,
      ledgerTransactionId: json['ledgerEntryId']?.toString(),
      isLedgerSynced: json['convertedToLedger'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      synced: true, // came from server → already synced
    );
  }

  DailyNoteModel copyWith({
    String? title,
    String? description,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? dateKey,
    List<DailyItemModel>? items,
    DateTime? updatedAt,
    bool? isLedgerSynced,
    String? ledgerTransactionId,
    bool? isDeleted,
    String? priority,
    String? status,
    DateTime? noteDate,
    DateTime? reminderAt,
    List<String>? tags,
    double? storedTotalAmount,
    DateTime? completedAt,
    String? completedBy,
    String? createdBy,
    String? modifiedBy,
    String? offlineId,
    DateTime? syncedAt,
    bool? convertedToLedger,
    bool? synced,
  }) {
    return DailyNoteModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      dateKey: dateKey ?? this.dateKey,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isLedgerSynced: isLedgerSynced ?? this.isLedgerSynced,
      ledgerTransactionId: ledgerTransactionId ?? this.ledgerTransactionId,
      isDeleted: isDeleted ?? this.isDeleted,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      noteDate: noteDate ?? this.noteDate,
      reminderAt: reminderAt ?? this.reminderAt,
      tags: tags ?? this.tags,
      storedTotalAmount: storedTotalAmount ?? this.storedTotalAmount,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      offlineId: offlineId ?? this.offlineId,
      syncedAt: syncedAt ?? this.syncedAt,
      convertedToLedger: convertedToLedger ?? this.convertedToLedger,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyNoteModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Filter parameters for querying notes.
class NoteFilters {
  final String? customerId;
  final String? status;
  final String? priority;
  final String? tag;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sortBy;
  final String? sortOrder;

  const NoteFilters({
    this.customerId,
    this.status,
    this.priority,
    this.tag,
    this.startDate,
    this.endDate,
    this.sortBy,
    this.sortOrder,
  });

  bool get hasActiveFilters =>
      customerId != null ||
      status != null ||
      priority != null ||
      tag != null ||
      startDate != null ||
      endDate != null;

  int get activeFilterCount {
    int count = 0;
    if (customerId != null) count++;
    if (status != null) count++;
    if (priority != null) count++;
    if (tag != null) count++;
    if (startDate != null || endDate != null) count++;
    return count;
  }

  NoteFilters copyWith({
    String? customerId,
    String? status,
    String? priority,
    String? tag,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
    bool clearCustomerId = false,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearTag = false,
    bool clearDateRange = false,
  }) {
    return NoteFilters(
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      tag: clearTag ? null : (tag ?? this.tag),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static const NoteFilters empty = NoteFilters();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteFilters &&
          other.customerId == customerId &&
          other.status == status &&
          other.priority == priority &&
          other.tag == tag &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.sortBy == sortBy &&
          other.sortOrder == sortOrder);

  @override
  int get hashCode => Object.hash(
      customerId, status, priority, tag, startDate, endDate, sortBy, sortOrder);
}

/// Summary statistics from the backend /summary endpoint.
class NoteSummary {
  final int total;
  final int pending;
  final int completed;
  final int cancelled;
  final int highPriority;
  final double totalAmount;
  final int withCustomer;
  final int todayTotal;
  final int todayPending;

  const NoteSummary({
    this.total = 0,
    this.pending = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.highPriority = 0,
    this.totalAmount = 0,
    this.withCustomer = 0,
    this.todayTotal = 0,
    this.todayPending = 0,
  });

  factory NoteSummary.fromJson(Map<String, dynamic> json) {
    return NoteSummary(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
      highPriority: json['highPriority'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      withCustomer: json['withCustomer'] as int? ?? 0,
      todayTotal: json['todayTotal'] as int? ?? 0,
      todayPending: json['todayPending'] as int? ?? 0,
    );
  }

  double get completionRate =>
      total > 0 ? (completed / total * 100) : 0;
}
