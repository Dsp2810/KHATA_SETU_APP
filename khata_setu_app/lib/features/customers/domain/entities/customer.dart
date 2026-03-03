import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String shopId;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? avatar;
  final double creditLimit;
  final double currentBalance; // Positive = customer owes, Negative = we owe
  final int trustScore;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTransactionAt;

  const Customer({
    required this.id,
    required this.shopId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.avatar,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.trustScore = 50,
    this.isActive = true,
    required this.createdAt,
    this.lastTransactionAt,
  });

  @override
  List<Object?> get props => [
        id,
        shopId,
        name,
        phone,
        email,
        address,
        avatar,
        creditLimit,
        currentBalance,
        trustScore,
        isActive,
        createdAt,
        lastTransactionAt,
      ];

  Customer copyWith({
    String? id,
    String? shopId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? avatar,
    double? creditLimit,
    double? currentBalance,
    int? trustScore,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastTransactionAt,
  }) {
    return Customer(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      trustScore: trustScore ?? this.trustScore,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
    );
  }

  /// Returns true if customer owes money
  bool get owesUs => currentBalance > 0;

  /// Returns true if we owe customer money
  bool get weOwe => currentBalance < 0;

  /// Returns formatted balance display
  String get balanceDisplay {
    final absBalance = currentBalance.abs();
    if (owesUs) {
      return '₹${absBalance.toStringAsFixed(2)} to receive';
    } else if (weOwe) {
      return '₹${absBalance.toStringAsFixed(2)} to pay';
    }
    return '₹0.00 (Settled)';
  }

  /// Returns trust level based on score
  String get trustLevel {
    if (trustScore >= 80) return 'High';
    if (trustScore >= 50) return 'Medium';
    return 'Low';
  }
}
