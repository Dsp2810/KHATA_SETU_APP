import 'package:flutter/foundation.dart';

/// Cart Item Model
class CartItem {
  final String productId;
  final String productName;
  final double price;
  final String unit;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.unit,
    this.quantity = 1,
  });

  double get total => price * quantity;

  CartItem copyWith({
    String? productId,
    String? productName,
    double? price,
    String? unit,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Cart State Manager (Simple State without BLoC for demo)
class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _selectedCustomerId;
  String? _selectedCustomerName;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double _discount = 0;
  double get discount => _discount;
  double get total => subtotal - _discount;

  String? get selectedCustomerId => _selectedCustomerId;
  String? get selectedCustomerName => _selectedCustomerName;

  void selectCustomer(String id, String name) {
    _selectedCustomerId = id;
    _selectedCustomerName = name;
    notifyListeners();
  }

  void clearCustomer() {
    _selectedCustomerId = null;
    _selectedCustomerName = null;
    notifyListeners();
  }

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.productId == item.productId);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void setDiscount(double value) {
    _discount = value.clamp(0, subtotal);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discount = 0;
    _selectedCustomerId = null;
    _selectedCustomerName = null;
    notifyListeners();
  }

  bool hasProduct(String productId) {
    return _items.any((i) => i.productId == productId);
  }

  int getQuantity(String productId) {
    final item = _items.where((i) => i.productId == productId).firstOrNull;
    return item?.quantity ?? 0;
  }
}
