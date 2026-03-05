import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../constants/constants.dart';
import '../data/hive_initializer.dart';
import '../data/models/customer_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/product_model.dart';
import '../data/models/daily_note_model.dart';
import '../data/models/daily_summary_model.dart';
import '../data/models/shop_upi_model.dart';
import '../data/models/app_notification_model.dart';

/// Exports all Hive box data → structured JSON → AES-256 encrypted bytes.
///
/// The encryption key is stored in [FlutterSecureStorage] and is distinct
/// from the Hive-at-rest encryption key. If no key exists, one is generated
/// on first backup.
class BackupService {
  static const _backupKeyName = 'backup_aes_key';
  static const _backupIvName = 'backup_aes_iv';
  static const _snapshotVersion = 1;

  final FlutterSecureStorage _secureStorage;
  final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  BackupService(this._secureStorage);

  // ─── Public API ────────────────────────────────────────────

  /// Create an encrypted backup of all Hive data.
  /// Returns the encrypted bytes ready for upload.
  Future<Uint8List> createBackup() async {
    _log.i('Starting backup…');

    // 1. Export all boxes to JSON-safe map
    final snapshot = _exportAll();
    _log.i('Snapshot created: ${snapshot['meta']['boxCounts']}');

    // 2. Encode JSON
    final jsonString = jsonEncode(snapshot);
    final jsonBytes = utf8.encode(jsonString);

    // 3. Compress
    final compressed = gzip.encode(jsonBytes);
    _log.i('Compressed: ${jsonBytes.length} → ${compressed.length} bytes');

    // 4. Encrypt
    final encrypted = await _encrypt(Uint8List.fromList(compressed));
    _log.i('Encrypted: ${encrypted.length} bytes');

    return encrypted;
  }

  /// Decrypt backup bytes and return the parsed JSON snapshot.
  Future<Map<String, dynamic>> decryptBackup(Uint8List encryptedData) async {
    // 1. Decrypt
    final compressed = await _decrypt(encryptedData);

    // 2. Decompress
    final jsonBytes = gzip.decode(compressed);

    // 3. Parse JSON
    final jsonString = utf8.decode(jsonBytes);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // ─── Snapshot Export ───────────────────────────────────────

  Map<String, dynamic> _exportAll() {
    final customers = _exportCustomers();
    final transactions = _exportTransactions();
    final products = _exportProducts();
    final dailyNotes = _exportDailyNotes();
    final dailySummaries = _exportDailySummaries();
    final shopUpi = _exportShopUpi();
    final notifications = _exportNotifications();
    final appMeta = _exportAppMeta();

    return {
      'meta': {
        'snapshotVersion': _snapshotVersion,
        'appVersion': AppConstants.appVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'platform': _platformName(),
        'boxCounts': {
          'customers': customers.length,
          'transactions': transactions.length,
          'products': products.length,
          'dailyNotes': dailyNotes.length,
          'dailySummaries': dailySummaries.length,
          'shopUpi': shopUpi.length,
          'notifications': notifications.length,
        },
      },
      'customers': customers,
      'transactions': transactions,
      'products': products,
      'dailyNotes': dailyNotes,
      'dailySummaries': dailySummaries,
      'shopUpi': shopUpi,
      'notifications': notifications,
      'appMeta': appMeta,
    };
  }

  List<Map<String, dynamic>> _exportCustomers() {
    final box = Hive.box<CustomerModel>(HiveBoxes.customers);
    return box.values.map((c) => {
      'id': c.id,
      'name': c.name,
      'phone': c.phone,
      'email': c.email,
      'address': c.address,
      'creditLimit': c.creditLimit,
      'currentBalance': c.currentBalance,
      'trustScore': c.trustScore,
      'isActive': c.isActive,
      'createdAt': c.createdAt.toIso8601String(),
      'lastTransactionAt': c.lastTransactionAt?.toIso8601String(),
      'avatar': c.avatar,
      'notes': c.notes,
      'synced': c.synced,
      'schemaVersion': c.schemaVersion,
    }).toList();
  }

  List<Map<String, dynamic>> _exportTransactions() {
    final box = Hive.box<TransactionModel>(HiveBoxes.transactions);
    return box.values.map((t) => {
      'id': t.id,
      'customerId': t.customerId,
      'type': t.type,
      'totalAmount': t.totalAmount,
      'items': t.items.map((i) => {
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity,
        'unit': i.unit,
      }).toList(),
      'description': t.description,
      'paymentMode': t.paymentMode,
      'timestamp': t.timestamp.toIso8601String(),
      'balanceAfter': t.balanceAfter,
      'synced': t.synced,
      'isDeleted': t.isDeleted,
      'undoneBy': t.undoneBy,
      'schemaVersion': t.schemaVersion,
    }).toList();
  }

  List<Map<String, dynamic>> _exportProducts() {
    final box = Hive.box<ProductModel>(HiveBoxes.products);
    return box.values.map((p) => {
      'id': p.id,
      'name': p.name,
      'localName': p.localName,
      'description': p.description,
      'category': p.category,
      'subCategory': p.subCategory,
      'sku': p.sku,
      'barcode': p.barcode,
      'unit': p.unit,
      'purchasePrice': p.purchasePrice,
      'sellingPrice': p.sellingPrice,
      'mrp': p.mrp,
      'taxRate': p.taxRate,
      'currentStock': p.currentStock,
      'minStockLevel': p.minStockLevel,
      'maxStockLevel': p.maxStockLevel,
      'reorderPoint': p.reorderPoint,
      'image': p.image,
      'isActive': p.isActive,
      'createdAt': p.createdAt.toIso8601String(),
      'lastRestockedAt': p.lastRestockedAt?.toIso8601String(),
      'synced': p.synced,
      'tags': p.tags,
      'supplierName': p.supplierName,
      'supplierPhone': p.supplierPhone,
      'expiryDate': p.expiryDate?.toIso8601String(),
    }).toList();
  }

  List<Map<String, dynamic>> _exportDailyNotes() {
    final box = Hive.box<DailyNoteModel>(HiveBoxes.dailyNotes);
    return box.values.map((n) => {
      'id': n.id,
      'customerId': n.customerId,
      'dateKey': n.dateKey,
      'title': n.title,
      'description': n.description,
      'priority': n.priority,
      'status': n.status,
      'noteDate': n.noteDate?.toIso8601String(),
      'reminderAt': n.reminderAt?.toIso8601String(),
      'tags': n.tags,
      'storedTotalAmount': n.storedTotalAmount,
      'completedAt': n.completedAt?.toIso8601String(),
      'completedBy': n.completedBy,
      'createdBy': n.createdBy,
      'modifiedBy': n.modifiedBy,
      'offlineId': n.offlineId,
      'syncedAt': n.syncedAt?.toIso8601String(),
      'convertedToLedger': n.convertedToLedger,
      'synced': n.synced,
      'isLedgerSynced': n.isLedgerSynced,
      'ledgerTransactionId': n.ledgerTransactionId,
      'isDeleted': n.isDeleted,
      'customerName': n.customerName,
      'customerPhone': n.customerPhone,
      'createdAt': n.createdAt.toIso8601String(),
      'updatedAt': n.updatedAt.toIso8601String(),
      'items': n.items.map((i) => {
        'id': i.id,
        'productName': i.productName,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
        'unit': i.unit,
        'note': i.note,
        'timeLabel': i.timeLabel,
        'timestamp': i.timestamp.toIso8601String(),
        'productId': i.productId,
      }).toList(),
    }).toList();
  }

  List<Map<String, dynamic>> _exportDailySummaries() {
    final box = Hive.box<DailySummaryModel>(HiveBoxes.dailySummaries);
    return box.values.map((s) => {
      'id': s.id,
      'customerId': s.customerId,
      'dateKey': s.dateKey,
      'totalCredit': s.totalCredit,
      'totalPayment': s.totalPayment,
      'transactionCount': s.transactionCount,
      'openingBalance': s.openingBalance,
      'closingBalance': s.closingBalance,
    }).toList();
  }

  List<Map<String, dynamic>> _exportShopUpi() {
    final box = Hive.box<ShopUpiModel>(HiveBoxes.shopUpi);
    return box.values.map((u) => {
      'id': u.id,
      'upiId': u.upiId,
      'shopName': u.shopName,
      'merchantCode': u.merchantCode,
      'qrImagePath': u.qrImagePath,
      'createdAt': u.createdAt.toIso8601String(),
      'updatedAt': u.updatedAt.toIso8601String(),
      'isActive': u.isActive,
    }).toList();
  }

  List<Map<String, dynamic>> _exportNotifications() {
    final box = Hive.box<AppNotificationModel>(HiveBoxes.notifications);
    return box.values.map((n) => {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'typeValue': n.typeValue,
      'createdAt': n.createdAt.toIso8601String(),
      'isRead': n.isRead,
      'actionRoute': n.actionRoute,
      'actionData': n.actionData,
      'customerId': n.customerId,
      'productId': n.productId,
      'amount': n.amount,
    }).toList();
  }

  Map<String, dynamic> _exportAppMeta() {
    final box = Hive.box(HiveBoxes.appMeta);
    final result = <String, dynamic>{};
    for (final key in box.keys) {
      result[key.toString()] = box.get(key);
    }
    return result;
  }

  // ─── Encryption ────────────────────────────────────────────

  Future<Uint8List> _encrypt(Uint8List data) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIv();

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    return encrypted.bytes;
  }

  Future<Uint8List> _decrypt(Uint8List data) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIv();

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(enc.Encrypted(data), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  Future<enc.Key> _getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _backupKeyName);
    if (existing != null) {
      return enc.Key.fromBase64(existing);
    }
    final key = enc.Key.fromSecureRandom(32); // AES-256
    await _secureStorage.write(key: _backupKeyName, value: key.base64);
    return key;
  }

  Future<enc.IV> _getOrCreateIv() async {
    final existing = await _secureStorage.read(key: _backupIvName);
    if (existing != null) {
      return enc.IV.fromBase64(existing);
    }
    final iv = enc.IV.fromSecureRandom(16);
    await _secureStorage.write(key: _backupIvName, value: iv.base64);
    return iv;
  }

  String _platformName() {
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }
}
