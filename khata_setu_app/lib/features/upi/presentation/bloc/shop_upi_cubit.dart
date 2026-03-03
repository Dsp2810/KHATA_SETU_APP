import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/repositories/shop_upi_repository.dart';
import 'shop_upi_state.dart';

/// Cubit managing shop UPI configuration state.
/// Handles loading, saving config, and QR image management.
class ShopUpiCubit extends Cubit<ShopUpiState> {
  final ShopUpiRepository _repository;

  ShopUpiCubit(this._repository) : super(ShopUpiInitial());

  /// Load the active UPI config from Hive.
  Future<void> loadConfig() async {
    emit(ShopUpiLoading());
    try {
      final config = await _repository.getActiveConfig();
      emit(ShopUpiLoaded(config));
    } catch (e) {
      emit(ShopUpiError('Failed to load UPI config: $e'));
    }
  }

  /// Save or update UPI config.
  Future<void> saveConfig({
    required String upiId,
    required String shopName,
    String? merchantCode,
    String? existingId,
  }) async {
    try {
      final config = await _repository.saveConfig(
        upiId: upiId,
        shopName: shopName,
        merchantCode: merchantCode,
        existingId: existingId,
      );
      emit(ShopUpiSaved(config));
      // Reload to consistent state
      emit(ShopUpiLoaded(config));
    } catch (e) {
      emit(ShopUpiError('Failed to save UPI config: $e'));
    }
  }

  /// Save uploaded QR image bytes.
  Future<void> saveQrImage(String configId, List<int> imageBytes) async {
    try {
      final config = await _repository.saveQrImage(configId, imageBytes);
      emit(ShopUpiQrUpdated(config));
      emit(ShopUpiLoaded(config));
    } catch (e) {
      emit(ShopUpiError('Failed to save QR image: $e'));
    }
  }

  /// Remove the uploaded QR image.
  Future<void> removeQrImage(String configId) async {
    try {
      final config = await _repository.removeQrImage(configId);
      emit(ShopUpiQrUpdated(config));
      emit(ShopUpiLoaded(config));
    } catch (e) {
      emit(ShopUpiError('Failed to remove QR image: $e'));
    }
  }

  /// Delete entire UPI config.
  Future<void> deleteConfig(String id) async {
    try {
      await _repository.deleteConfig(id);
      emit(const ShopUpiLoaded(null));
    } catch (e) {
      emit(ShopUpiError('Failed to delete UPI config: $e'));
    }
  }
}
