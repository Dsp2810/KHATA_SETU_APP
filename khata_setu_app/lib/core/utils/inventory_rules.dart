/// Single source of truth for inventory stock calculations.
///
/// All stock math flows through this utility to ensure consistency
/// across InventoryBloc, ProductRepository, dashboard summaries,
/// and inventory list UI.
///
/// Formula: initialStock + totalStockAdded - totalStockSold = currentStock
class InventoryRules {
  InventoryRules._(); // Prevent instantiation

  /// Calculate current stock from individual components.
  ///
  /// ```dart
  /// InventoryRules.calculateStock(
  ///   initialStock: 100,
  ///   totalStockAdded: 30,
  ///   totalStockSold: 50,
  /// ); // → 80.0
  /// ```
  static double calculateStock({
    required double initialStock,
    double totalStockAdded = 0,
    double totalStockSold = 0,
  }) {
    final result = initialStock + totalStockAdded - totalStockSold;
    return result < 0 ? 0 : result;
  }

  /// Calculate the new stock after a single adjustment.
  ///
  /// [type] must be one of: 'add', 'remove', 'damage', 'return'.
  /// - `add` / `return` → stock increases by [quantity]
  /// - `remove` / `damage` → stock decreases by [quantity]
  ///
  /// Result is clamped to >= 0 (stock can never go negative).
  static double calculateStockAfterAdjustment({
    required double currentStock,
    required String type,
    required double quantity,
  }) {
    final delta = _quantityDelta(type, quantity);
    final result = currentStock + delta;
    return result < 0 ? 0 : result;
  }

  /// Returns the signed quantity change for a given adjustment [type].
  static double _quantityDelta(String type, double quantity) {
    switch (type) {
      case 'add':
      case 'return':
        return quantity;
      case 'remove':
      case 'damage':
        return -quantity;
      default:
        return quantity; // Default to add for safety
    }
  }

  /// Whether stock is considered out-of-stock (zero or below).
  static bool isOutOfStock(double currentStock) => currentStock <= 0;

  /// Whether stock is considered low (above zero but at or below minimum).
  static bool isLowStock(double currentStock, double minStockLevel) =>
      currentStock > 0 && currentStock <= minStockLevel;
}
