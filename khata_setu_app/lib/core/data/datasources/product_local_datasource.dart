import 'package:hive/hive.dart';

import '../models/product_model.dart';
import '../hive_initializer.dart';
import '../../utils/inventory_rules.dart';

/// Local data source for product/inventory operations via Hive.
class ProductLocalDataSource {
  Box<ProductModel> get _productBox =>
      Hive.box<ProductModel>(HiveBoxes.products);

  // ─── Read Operations ─────────────────────────────────────────

  List<ProductModel> getAllProducts() {
    return _productBox.values.where((p) => p.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  ProductModel? getProductById(String id) {
    try {
      return _productBox.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ProductModel? getProductByBarcode(String barcode) {
    try {
      return _productBox.values.firstWhere(
        (p) => p.barcode == barcode && p.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> searchProducts(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return getAllProducts();

    return _productBox.values
        .where(
          (p) =>
              p.isActive &&
              (p.name.toLowerCase().contains(q) ||
                  (p.localName?.toLowerCase().contains(q) ?? false) ||
                  (p.sku?.toLowerCase().contains(q) ?? false) ||
                  (p.barcode?.contains(q) ?? false) ||
                  p.category.toLowerCase().contains(q)),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ProductModel> getProductsByCategory(String category) {
    return _productBox.values
        .where(
          (p) =>
              p.isActive && p.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  List<ProductModel> getLowStockProducts() {
    return _productBox.values.where((p) => p.isActive && p.isLowStock).toList();
  }

  List<ProductModel> getOutOfStockProducts() {
    return _productBox.values
        .where((p) => p.isActive && p.isOutOfStock)
        .toList();
  }

  List<String> getCategories() {
    final cats = <String>{};
    for (final p in _productBox.values) {
      if (p.isActive && p.category.isNotEmpty) {
        cats.add(p.category);
      }
    }
    return cats.toList()..sort();
  }

  // ─── Write Operations ────────────────────────────────────────

  Future<void> saveProduct(ProductModel product) async {
    await _productBox.put(product.id, product);
  }

  Future<void> deleteProduct(String id) async {
    final product = getProductById(id);
    if (product != null) {
      product.isActive = false;
      await product.save();
    }
  }

  /// Set stock to an exact value (pre-calculated by InventoryRules).
  Future<void> setStock(
    String productId,
    double newStock, {
    bool isRestock = false,
  }) async {
    final product = getProductById(productId);
    if (product == null) return;
    product.currentStock = newStock;
    product.lastRestockedAt = isRestock
        ? DateTime.now()
        : product.lastRestockedAt;
    product.synced = false;
    await product.save();
  }

  /// Adjust stock using InventoryRules as single source of truth.
  Future<void> adjustStock(String productId, double quantityChange) async {
    final product = getProductById(productId);
    if (product == null) return;
    final newStock = InventoryRules.calculateStockAfterAdjustment(
      currentStock: product.currentStock,
      type: quantityChange >= 0 ? 'add' : 'remove',
      quantity: quantityChange.abs(),
    );
    product.currentStock = newStock;
    product.lastRestockedAt = quantityChange > 0
        ? DateTime.now()
        : product.lastRestockedAt;
    product.synced = false;
    await product.save();
  }

  // ─── Summary ─────────────────────────────────────────────────

  Map<String, dynamic> getSummary() {
    final active = _productBox.values.where((p) => p.isActive).toList();
    double totalStockValue = 0;
    int lowStockCount = 0;
    int outOfStockCount = 0;

    for (final p in active) {
      totalStockValue += p.stockValue;
      if (p.isOutOfStock) {
        outOfStockCount++;
      } else if (p.isLowStock) {
        lowStockCount++;
      }
    }

    return {
      'totalProducts': active.length,
      'totalStockValue': totalStockValue,
      'lowStockCount': lowStockCount,
      'outOfStockCount': outOfStockCount,
    };
  }

  List<ProductModel> getUnsyncedProducts() {
    return _productBox.values.where((p) => !p.synced && p.isActive).toList();
  }
}
