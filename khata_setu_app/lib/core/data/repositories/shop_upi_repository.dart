import 'package:uuid/uuid.dart';

import '../datasources/shop_upi_local_datasource.dart';
import '../models/shop_upi_model.dart';

/// Repository — Business logic for shop UPI configuration.
/// Wraps [ShopUpiLocalDataSource] with validation and UUID generation.
class ShopUpiRepository {
  final ShopUpiLocalDataSource _local;
  final _uuid = const Uuid();

  ShopUpiRepository(this._local);

  // ─── Read ──────────────────────────────────────────────────────

  /// Get the active UPI config for this shop.
  Future<ShopUpiModel?> getActiveConfig() => _local.getActiveUpiConfig();

  // ─── Write ─────────────────────────────────────────────────────

  /// Create or update the shop's UPI configuration.
  /// If no config exists, creates one with a new UUID.
  /// If one exists, updates it in-place.
  Future<ShopUpiModel> saveConfig({
    required String upiId,
    required String shopName,
    String? merchantCode,
    String? existingId,
  }) async {
    final id = existingId ?? _uuid.v4();

    // Check existing to preserve QR image path
    final existing = existingId != null
        ? await _local.getUpiConfigById(existingId)
        : null;

    final config = ShopUpiModel(
      id: id,
      upiId: upiId.trim(),
      shopName: shopName.trim(),
      merchantCode: merchantCode?.trim(),
      qrImagePath: existing?.qrImagePath,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    await _local.saveUpiConfig(config);
    return config;
  }

  /// Save uploaded QR image bytes and link to config.
  Future<ShopUpiModel> saveQrImage(String configId, List<int> imageBytes) async {
    final config = await _local.getUpiConfigById(configId);
    if (config == null) throw Exception('UPI config not found');

    // Delete old image if exists
    if (config.qrImagePath != null) {
      await _local.deleteQrImage(config.qrImagePath!);
    }

    final path = await _local.saveQrImage(configId, imageBytes);
    final updated = config.copyWith(qrImagePath: path);
    await _local.saveUpiConfig(updated);
    return updated;
  }

  /// Remove the uploaded QR image but keep the config.
  Future<ShopUpiModel> removeQrImage(String configId) async {
    final config = await _local.getUpiConfigById(configId);
    if (config == null) throw Exception('UPI config not found');

    if (config.qrImagePath != null) {
      await _local.deleteQrImage(config.qrImagePath!);
    }

    final updated = ShopUpiModel(
      id: config.id,
      upiId: config.upiId,
      shopName: config.shopName,
      merchantCode: config.merchantCode,
      qrImagePath: null,
      createdAt: config.createdAt,
      updatedAt: DateTime.now(),
      isActive: config.isActive,
    );
    await _local.saveUpiConfig(updated);
    return updated;
  }

  /// Delete the UPI config entirely.
  Future<void> deleteConfig(String id) => _local.deleteUpiConfig(id);

  /// Check if QR image still exists on disk.
  Future<bool> isQrImageAvailable(String path) => _local.qrImageExists(path);
}
