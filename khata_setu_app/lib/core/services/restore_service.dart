import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../data/hive_initializer.dart';
import '../data/models/customer_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/product_model.dart';
import '../data/models/daily_note_model.dart';
import '../data/models/daily_summary_model.dart';
import '../data/models/shop_upi_model.dart';
import '../data/models/app_notification_model.dart';

/// Restores a decrypted backup snapshot into Hive boxes.
///
/// The restore process:
/// 1. Validates snapshot structure.
/// 2. Clears all existing Hive boxes.
/// 3. Re-imports every record from the snapshot.
class RestoreService {
  final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Restore all data from a decrypted snapshot map.
  /// Throws [FormatException] if the snapshot is invalid.
  Future<RestoreResult> restore(Map<String, dynamic> snapshot) async {
    _log.i('Starting restore…');

    // 1. Validate
    _validateSnapshot(snapshot);
    final meta = snapshot['meta'] as Map<String, dynamic>;
    _log.i('Restoring snapshot v${meta['snapshotVersion']} '
        'from ${meta['createdAt']}');

    // 2. Clear all boxes
    await _clearAllBoxes();
    _log.i('All boxes cleared');

    // 3. Import each entity
    final counts = <String, int>{};

    counts['customers'] = await _importCustomers(
        (snapshot['customers'] as List?)?.cast<Map<String, dynamic>>() ?? []);

    counts['transactions'] = await _importTransactions(
        (snapshot['transactions'] as List?)?.cast<Map<String, dynamic>>() ??
            []);

    counts['products'] = await _importProducts(
        (snapshot['products'] as List?)?.cast<Map<String, dynamic>>() ?? []);

    counts['dailyNotes'] = await _importDailyNotes(
        (snapshot['dailyNotes'] as List?)?.cast<Map<String, dynamic>>() ?? []);

    counts['dailySummaries'] = await _importDailySummaries(
        (snapshot['dailySummaries'] as List?)?.cast<Map<String, dynamic>>() ??
            []);

    counts['shopUpi'] = await _importShopUpi(
        (snapshot['shopUpi'] as List?)?.cast<Map<String, dynamic>>() ?? []);

    counts['notifications'] = await _importNotifications(
        (snapshot['notifications'] as List?)?.cast<Map<String, dynamic>>() ??
            []);

    await _importAppMeta(
        snapshot['appMeta'] as Map<String, dynamic>? ?? {});

    _log.i('Restore complete: $counts');
    return RestoreResult(
      success: true,
      counts: counts,
      snapshotDate: DateTime.tryParse(meta['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // ─── Validation ────────────────────────────────────────────

  void _validateSnapshot(Map<String, dynamic> snapshot) {
    if (!snapshot.containsKey('meta')) {
      throw const FormatException(
          'Invalid backup: missing meta section');
    }
    final meta = snapshot['meta'];
    if (meta is! Map || !meta.containsKey('snapshotVersion')) {
      throw const FormatException(
          'Invalid backup: missing snapshotVersion');
    }
  }

  // ─── Clear ─────────────────────────────────────────────────

  Future<void> _clearAllBoxes() async {
    await Hive.box<CustomerModel>(HiveBoxes.customers).clear();
    await Hive.box<TransactionModel>(HiveBoxes.transactions).clear();
    await Hive.box<ProductModel>(HiveBoxes.products).clear();
    await Hive.box<DailyNoteModel>(HiveBoxes.dailyNotes).clear();
    await Hive.box<DailySummaryModel>(HiveBoxes.dailySummaries).clear();
    await Hive.box<ShopUpiModel>(HiveBoxes.shopUpi).clear();
    await Hive.box<AppNotificationModel>(HiveBoxes.notifications).clear();
    await Hive.box(HiveBoxes.appMeta).clear();
  }

  // ─── Importers ─────────────────────────────────────────────

  Future<int> _importCustomers(List<Map<String, dynamic>> records) async {
    final box = Hive.box<CustomerModel>(HiveBoxes.customers);
    for (final r in records) {
      final model = CustomerModel(
        id: r['id'] as String,
        name: r['name'] as String,
        phone: r['phone'] as String,
        email: r['email'] as String?,
        address: r['address'] as String?,
        creditLimit: (r['creditLimit'] as num?)?.toDouble() ?? 5000.0,
        currentBalance: (r['currentBalance'] as num?)?.toDouble() ?? 0.0,
        trustScore: (r['trustScore'] as num?)?.toInt() ?? 50,
        isActive: r['isActive'] as bool? ?? true,
        createdAt: DateTime.tryParse(r['createdAt'] ?? '') ?? DateTime.now(),
        lastTransactionAt: r['lastTransactionAt'] != null
            ? DateTime.tryParse(r['lastTransactionAt'])
            : null,
        avatar: r['avatar'] as String?,
        notes: r['notes'] as String?,
        synced: r['synced'] as bool? ?? false,
        schemaVersion: (r['schemaVersion'] as num?)?.toInt() ?? 1,
      );
      await box.put(model.id, model);
    }
    return records.length;
  }

  Future<int> _importTransactions(List<Map<String, dynamic>> records) async {
    final box = Hive.box<TransactionModel>(HiveBoxes.transactions);
    for (final r in records) {
      final items = (r['items'] as List?)
              ?.map((i) => TransactionItem(
                    name: i['name'] as String,
                    price: (i['price'] as num).toDouble(),
                    quantity: (i['quantity'] as num?)?.toDouble() ?? 1,
                    unit: i['unit'] as String?,
                  ))
              .toList() ??
          [];

      final model = TransactionModel(
        id: r['id'] as String,
        customerId: r['customerId'] as String,
        type: (r['type'] as num).toInt(),
        totalAmount: (r['totalAmount'] as num).toDouble(),
        items: items,
        description: r['description'] as String?,
        paymentMode: (r['paymentMode'] as num?)?.toInt() ?? 0,
        timestamp: DateTime.tryParse(r['timestamp'] ?? '') ?? DateTime.now(),
        balanceAfter: (r['balanceAfter'] as num).toDouble(),
        synced: r['synced'] as bool? ?? false,
        isDeleted: r['isDeleted'] as bool? ?? false,
        undoneBy: r['undoneBy'] as String?,
        schemaVersion: (r['schemaVersion'] as num?)?.toInt() ?? 1,
      );
      await box.put(model.id, model);
    }
    return records.length;
  }

  Future<int> _importProducts(List<Map<String, dynamic>> records) async {
    final box = Hive.box<ProductModel>(HiveBoxes.products);
    for (final r in records) {
      final model = ProductModel(
        id: r['id'] as String,
        name: r['name'] as String,
        localName: r['localName'] as String?,
        description: r['description'] as String?,
        category: r['category'] as String? ?? 'General',
        subCategory: r['subCategory'] as String?,
        sku: r['sku'] as String?,
        barcode: r['barcode'] as String?,
        unit: r['unit'] as String? ?? 'piece',
        purchasePrice: (r['purchasePrice'] as num).toDouble(),
        sellingPrice: (r['sellingPrice'] as num).toDouble(),
        mrp: (r['mrp'] as num?)?.toDouble(),
        taxRate: (r['taxRate'] as num?)?.toDouble() ?? 0,
        currentStock: (r['currentStock'] as num?)?.toDouble() ?? 0,
        minStockLevel: (r['minStockLevel'] as num?)?.toDouble() ?? 5,
        maxStockLevel: (r['maxStockLevel'] as num?)?.toDouble() ?? 1000,
        reorderPoint: (r['reorderPoint'] as num?)?.toDouble() ?? 10,
        image: r['image'] as String?,
        isActive: r['isActive'] as bool? ?? true,
        createdAt:
            DateTime.tryParse(r['createdAt'] ?? '') ?? DateTime.now(),
        lastRestockedAt: r['lastRestockedAt'] != null
            ? DateTime.tryParse(r['lastRestockedAt'])
            : null,
        synced: r['synced'] as bool? ?? false,
        tags: (r['tags'] as List?)?.cast<String>() ?? [],
        supplierName: r['supplierName'] as String?,
        supplierPhone: r['supplierPhone'] as String?,
        expiryDate: r['expiryDate'] != null
            ? DateTime.tryParse(r['expiryDate'])
            : null,
      );
      await box.put(model.id, model);
    }
    return records.length;
  }

  Future<int> _importDailyNotes(List<Map<String, dynamic>> records) async {
    final box = Hive.box<DailyNoteModel>(HiveBoxes.dailyNotes);
    for (final r in records) {
      final items = (r['items'] as List?)
              ?.map((i) => DailyItemModel(
                    productName: i['productName'] as String? ?? '',
                    quantity: (i['quantity'] as num?)?.toDouble() ?? 0,
                    unitPrice: (i['unitPrice'] as num?)?.toDouble() ?? 0,
                    unit: i['unit'] as String?,
                    note: i['note'] as String?,
                    timeLabel: (i['timeLabel'] as num?)?.toInt() ?? 0,
                    productId: i['productId'] as String?,
                  ))
              .toList() ??
          [];

      final model = DailyNoteModel(
        id: r['id'] as String,
        customerId: r['customerId'] as String?,
        dateKey: r['dateKey'] as String? ??
            DateTime.now().toIso8601String().substring(0, 10),
        title: r['title'] as String? ?? '',
        description: r['description'] as String?,
        priority: r['priority'] as String? ?? 'medium',
        status: r['status'] as String? ?? 'pending',
        noteDate: r['noteDate'] != null
            ? DateTime.tryParse(r['noteDate'])
            : null,
        reminderAt: r['reminderAt'] != null
            ? DateTime.tryParse(r['reminderAt'])
            : null,
        tags: (r['tags'] as List?)?.cast<String>() ?? [],
        storedTotalAmount:
            (r['storedTotalAmount'] as num?)?.toDouble() ?? 0,
        completedAt: r['completedAt'] != null
            ? DateTime.tryParse(r['completedAt'])
            : null,
        completedBy: r['completedBy'] as String?,
        createdBy: r['createdBy'] as String?,
        modifiedBy: r['modifiedBy'] as String?,
        offlineId: r['offlineId'] as String?,
        syncedAt: r['syncedAt'] != null
            ? DateTime.tryParse(r['syncedAt'])
            : null,
        convertedToLedger: r['convertedToLedger'] as bool? ?? false,
        synced: r['synced'] as bool? ?? false,
        isLedgerSynced: r['isLedgerSynced'] as bool? ?? false,
        ledgerTransactionId: r['ledgerTransactionId'] as String?,
        isDeleted: r['isDeleted'] as bool? ?? false,
        customerName: r['customerName'] as String?,
        customerPhone: r['customerPhone'] as String?,
        items: items,
      );
      await box.put(model.id, model);
    }
    return records.length;
  }

  Future<int> _importDailySummaries(
      List<Map<String, dynamic>> records) async {
    final box = Hive.box<DailySummaryModel>(HiveBoxes.dailySummaries);
    for (final r in records) {
      final model = DailySummaryModel(
        id: r['id'] as String,
        customerId: r['customerId'] as String,
        dateKey: r['dateKey'] as String,
        totalCredit: (r['totalCredit'] as num?)?.toDouble() ?? 0,
        totalPayment: (r['totalPayment'] as num?)?.toDouble() ?? 0,
        transactionCount: (r['transactionCount'] as num?)?.toInt() ?? 0,
        openingBalance: (r['openingBalance'] as num?)?.toDouble() ?? 0,
        closingBalance: (r['closingBalance'] as num?)?.toDouble() ?? 0,
      );
      await box.put(model.id, model);
    }
    return records.length;
  }

  Future<int> _importShopUpi(List<Map<String, dynamic>> records) async {
    final box = Hive.box<ShopUpiModel>(HiveBoxes.shopUpi);
    for (final r in records) {
      final model = ShopUpiModel(
        id: r['id'] as String,
        upiId: r['upiId'] as String,
        shopName: r['shopName'] as String,
        merchantCode: r['merchantCode'] as String?,
        qrImagePath: r['qrImagePath'] as String?,
        createdAt: DateTime.tryParse(r['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(r['updatedAt'] ?? '') ?? DateTime.now(),
        isActive: r['isActive'] as bool? ?? true,
      );
      await box.put(model.id, model);
    }
    return records.length;
  }

  Future<int> _importNotifications(
      List<Map<String, dynamic>> records) async {
    final box = Hive.box<AppNotificationModel>(HiveBoxes.notifications);
    for (final r in records) {
      final model = AppNotificationModel(
        title: r['title'] as String,
        body: r['body'] as String,
        typeValue: (r['typeValue'] as num).toInt(),
        isRead: r['isRead'] as bool? ?? false,
        actionRoute: r['actionRoute'] as String?,
        actionData: (r['actionData'] as Map?)?.cast<String, dynamic>(),
        customerId: r['customerId'] as String?,
        productId: r['productId'] as String?,
        amount: (r['amount'] as num?)?.toDouble(),
      );
      await box.put(r['id'] as String, model);
    }
    return records.length;
  }

  Future<void> _importAppMeta(Map<String, dynamic> data) async {
    final box = Hive.box(HiveBoxes.appMeta);
    for (final entry in data.entries) {
      await box.put(entry.key, entry.value);
    }
  }
}

/// Result of a restore operation.
class RestoreResult {
  final bool success;
  final Map<String, int> counts;
  final DateTime snapshotDate;

  RestoreResult({
    required this.success,
    required this.counts,
    required this.snapshotDate,
  });

  int get totalRecords => counts.values.fold(0, (a, b) => a + b);
}
