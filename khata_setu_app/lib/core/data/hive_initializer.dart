import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/customer_model.dart';
import 'models/transaction_model.dart';
import 'models/daily_summary_model.dart';
import 'models/shop_upi_model.dart';
import 'models/product_model.dart';
import 'models/daily_note_model.dart';
import 'models/app_notification_model.dart';
import 'models/sync_queue_item_model.dart';

/// Hive box names
class HiveBoxes {
  static const String customers = 'customers';
  static const String transactions = 'transactions';
  static const String dailySummaries = 'daily_summaries';
  static const String shopUpi = 'shop_upi';
  static const String products = 'products';
  static const String appMeta = 'app_meta';
  static const String dailyNotes = 'daily_notes';
  static const String notifications = 'app_notifications';
  static const String syncQueue = 'sync_queue';
}

/// Key used to persist the Hive encryption key in flutter_secure_storage.
const _hiveEncryptionKeyName = 'hive_encryption_key';

/// Centralized Hive initialization — register adapters + open encrypted boxes
class HiveInitializer {
  static bool _initialized = false;

  /// Retrieves or generates a 256-bit AES key for Hive encryption.
  /// The key is stored in flutter_secure_storage so it persists across launches.
  static Future<Uint8List> _getEncryptionKey(
      FlutterSecureStorage secureStorage) async {
    final existing = await secureStorage.read(key: _hiveEncryptionKeyName);
    if (existing != null) {
      return base64Url.decode(existing);
    }
    // First launch — generate and persist a new key
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: _hiveEncryptionKeyName,
      value: base64UrlEncode(key),
    );
    return Uint8List.fromList(key);
  }

  static Future<void> init(FlutterSecureStorage secureStorage) async {
    if (_initialized) return;

    final encryptionKey = await _getEncryptionKey(secureStorage);
    final cipher = HiveAesCipher(encryptionKey);

    // Register adapters
    Hive.registerAdapter(CustomerModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(TransactionItemAdapter());
    Hive.registerAdapter(DailySummaryModelAdapter());
    Hive.registerAdapter(ShopUpiModelAdapter());
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(DailyNoteModelAdapter());
    Hive.registerAdapter(DailyItemModelAdapter());
    Hive.registerAdapter(AppNotificationModelAdapter());
    Hive.registerAdapter(SyncQueueItemModelAdapter());
    Hive.registerAdapter(SyncEntityTypeAdapter());
    Hive.registerAdapter(SyncOperationAdapter());
    Hive.registerAdapter(SyncItemStatusAdapter());

    // Open encrypted boxes (appMeta unencrypted — no sensitive data)
    await Future.wait([
      Hive.openBox<CustomerModel>(HiveBoxes.customers,
          encryptionCipher: cipher),
      Hive.openBox<TransactionModel>(HiveBoxes.transactions,
          encryptionCipher: cipher),
      Hive.openBox<DailySummaryModel>(HiveBoxes.dailySummaries,
          encryptionCipher: cipher),
      Hive.openBox<ShopUpiModel>(HiveBoxes.shopUpi,
          encryptionCipher: cipher),
      Hive.openBox<ProductModel>(HiveBoxes.products,
          encryptionCipher: cipher),
      Hive.openBox<DailyNoteModel>(HiveBoxes.dailyNotes,
          encryptionCipher: cipher),
      Hive.openBox<AppNotificationModel>(HiveBoxes.notifications,
          encryptionCipher: cipher),
      Hive.openBox<SyncQueueItemModel>(HiveBoxes.syncQueue,
          encryptionCipher: cipher),
      Hive.openBox(HiveBoxes.appMeta), // meta stays unencrypted
    ]);

    // Run migrations
    await _runMigrations();

    _initialized = true;
  }

  static Future<void> _runMigrations() async {
    final metaBox = Hive.box(HiveBoxes.appMeta);
    final currentVersion =
        metaBox.get('schema_version', defaultValue: 0) as int;

    if (currentVersion < 1) {
      // Version 1: Initial schema — nothing to migrate
      await metaBox.put('schema_version', 1);
    }

    // Future migrations go here:
    // if (currentVersion < 2) { ... }
  }

  static Future<void> clearAll() async {
    await Hive.box<CustomerModel>(HiveBoxes.customers).clear();
    await Hive.box<TransactionModel>(HiveBoxes.transactions).clear();
    await Hive.box<DailySummaryModel>(HiveBoxes.dailySummaries).clear();
    await Hive.box<ProductModel>(HiveBoxes.products).clear();
    await Hive.box<SyncQueueItemModel>(HiveBoxes.syncQueue).clear();
  }
}
