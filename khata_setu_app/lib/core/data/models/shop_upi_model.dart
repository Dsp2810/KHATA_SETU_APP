import 'package:hive/hive.dart';

part 'shop_upi_model.g.dart';

/// Hive model storing the shop owner's UPI configuration.
/// typeId: 4 (after Customer=0, Transaction=1, TransactionItem=2, DailySummary=3)
@HiveType(typeId: 4)
class ShopUpiModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String upiId; // e.g. "shopowner@upi"

  @HiveField(2)
  String shopName; // Display name on UPI

  @HiveField(3)
  String? merchantCode; // Optional merchant category code

  @HiveField(4)
  String? qrImagePath; // Path to uploaded QR image (device file storage)

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isActive;

  ShopUpiModel({
    required this.id,
    required this.upiId,
    required this.shopName,
    this.merchantCode,
    this.qrImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Generate UPI deep-link URI with optional amount.
  /// Format: upi://pay?pa={upiId}&pn={shopName}&am={amount}&cu=INR
  String generateUpiUri({double? amount}) {
    final params = <String, String>{
      'pa': upiId,
      'pn': shopName,
      'cu': 'INR',
    };

    if (merchantCode != null && merchantCode!.isNotEmpty) {
      params['mc'] = merchantCode!;
    }

    if (amount != null && amount > 0) {
      params['am'] = amount.toStringAsFixed(2);
    }

    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'upi://pay?$query';
  }

  ShopUpiModel copyWith({
    String? upiId,
    String? shopName,
    String? merchantCode,
    String? qrImagePath,
    bool? isActive,
  }) {
    return ShopUpiModel(
      id: id,
      upiId: upiId ?? this.upiId,
      shopName: shopName ?? this.shopName,
      merchantCode: merchantCode ?? this.merchantCode,
      qrImagePath: qrImagePath ?? this.qrImagePath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ShopUpiModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
