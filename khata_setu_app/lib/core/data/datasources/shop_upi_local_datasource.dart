import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/shop_upi_model.dart';

/// Hive box name for UPI config
const String _kUpiBoxName = 'shop_upi';

/// Local data source for shop UPI configuration.
/// Handles Hive CRUD + device file storage for QR images.
class ShopUpiLocalDataSource {
  Box<ShopUpiModel>? _box;

  Future<Box<ShopUpiModel>> get _upiBox async {
    _box ??= await Hive.openBox<ShopUpiModel>(_kUpiBoxName);
    return _box!;
  }

  // ─── Read ──────────────────────────────────────────────────────

  /// Get the active UPI config (there should be at most one active).
  Future<ShopUpiModel?> getActiveUpiConfig() async {
    final box = await _upiBox;
    if (box.isEmpty) return null;

    try {
      return box.values.firstWhere((m) => m.isActive);
    } catch (_) {
      return box.values.isNotEmpty ? box.values.first : null;
    }
  }

  /// Get UPI config by ID.
  Future<ShopUpiModel?> getUpiConfigById(String id) async {
    final box = await _upiBox;
    return box.get(id);
  }

  // ─── Write ─────────────────────────────────────────────────────

  /// Save or update UPI config.
  Future<void> saveUpiConfig(ShopUpiModel config) async {
    final box = await _upiBox;
    await box.put(config.id, config);
  }

  /// Delete UPI config and its associated QR image file.
  Future<void> deleteUpiConfig(String id) async {
    final box = await _upiBox;
    final config = box.get(id);

    // Clean up QR image file if it exists
    if (config?.qrImagePath != null) {
      final file = File(config!.qrImagePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await box.delete(id);
  }

  // ─── QR Image File Storage ─────────────────────────────────────

  /// Get the directory path for storing UPI QR images.
  Future<String> get _qrImageDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/upi_qr');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Save a QR image file to local device storage.
  /// Returns the saved file path.
  Future<String> saveQrImage(String configId, List<int> imageBytes) async {
    final dirPath = await _qrImageDir;
    final filePath = '$dirPath/qr_$configId.png';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return filePath;
  }

  /// Delete a stored QR image file.
  Future<void> deleteQrImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Check if QR image file exists and is accessible.
  Future<bool> qrImageExists(String path) async {
    return File(path).exists();
  }
}
