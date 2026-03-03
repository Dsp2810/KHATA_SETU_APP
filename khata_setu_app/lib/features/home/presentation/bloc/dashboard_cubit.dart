import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/secure_storage.dart';

// ─── States ─────────────────────────────────────────────────

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardShopLoaded extends DashboardState {
  final String shopName;
  final List<Map<String, dynamic>> shops;

  const DashboardShopLoaded({
    required this.shopName,
    this.shops = const [],
  });

  @override
  List<Object?> get props => [shopName, shops];
}

class DashboardShopError extends DashboardState {
  final String message;
  const DashboardShopError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ──────────────────────────────────────────────────

/// Lightweight cubit for dashboard-specific data (shop info).
/// Customer and transaction data are handled by their own BLoCs.
class DashboardCubit extends Cubit<DashboardState> {
  final SecureStorageService _secureStorage;
  final ApiService _apiService;

  DashboardCubit({
    required SecureStorageService secureStorage,
    required ApiService apiService,
  })  : _secureStorage = secureStorage,
        _apiService = apiService,
        super(DashboardInitial());

  /// Loads shop info — first from local storage, then tries remote.
  Future<void> loadShopInfo() async {
    try {
      final shopName = await _secureStorage.read('shop_name') ?? 'My Shop';
      emit(DashboardShopLoaded(shopName: shopName));

      // Try loading shops from API for full list
      try {
        final shops = await _apiService.getShops();
        final shopList =
            shops.map((s) => s as Map<String, dynamic>).toList();
        final name = shopList.isNotEmpty
            ? (shopList.first['name'] ?? shopName).toString()
            : shopName;
        emit(DashboardShopLoaded(shopName: name, shops: shopList));
      } catch (_) {
        // Offline — keep the local shop name, don't emit error
      }
    } catch (e) {
      emit(DashboardShopError(mapExceptionToFailure(e).message));
    }
  }
}
