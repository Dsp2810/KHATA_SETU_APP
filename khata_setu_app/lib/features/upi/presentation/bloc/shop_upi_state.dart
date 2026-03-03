import 'package:equatable/equatable.dart';
import '../../../../core/data/models/shop_upi_model.dart';

/// States for UPI configuration management.
abstract class ShopUpiState extends Equatable {
  const ShopUpiState();

  @override
  List<Object?> get props => [];
}

class ShopUpiInitial extends ShopUpiState {}

class ShopUpiLoading extends ShopUpiState {}

/// UPI config loaded (or null if not configured yet).
class ShopUpiLoaded extends ShopUpiState {
  final ShopUpiModel? config;

  const ShopUpiLoaded(this.config);

  bool get isConfigured => config != null;
  bool get hasQrImage => config?.qrImagePath != null;

  @override
  List<Object?> get props => [config];
}

/// Config saved successfully.
class ShopUpiSaved extends ShopUpiState {
  final ShopUpiModel config;

  const ShopUpiSaved(this.config);

  @override
  List<Object?> get props => [config];
}

/// QR image saved/updated.
class ShopUpiQrUpdated extends ShopUpiState {
  final ShopUpiModel config;

  const ShopUpiQrUpdated(this.config);

  @override
  List<Object?> get props => [config];
}

/// Error state.
class ShopUpiError extends ShopUpiState {
  final String message;

  const ShopUpiError(this.message);

  @override
  List<Object?> get props => [message];
}
