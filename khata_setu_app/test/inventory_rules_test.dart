import 'package:flutter_test/flutter_test.dart';
import 'package:khata_setu/core/utils/inventory_rules.dart';

void main() {
  group('InventoryRules.calculateStock', () {
    test('basic formula: initialStock + added - sold = currentStock', () {
      expect(
        InventoryRules.calculateStock(
          initialStock: 100,
          totalStockAdded: 30,
          totalStockSold: 50,
        ),
        80.0,
      );
    });

    test('result is clamped to 0 when oversold', () {
      expect(
        InventoryRules.calculateStock(initialStock: 10, totalStockSold: 50),
        0.0,
      );
    });

    test('zero initial stock with additions', () {
      expect(
        InventoryRules.calculateStock(initialStock: 0, totalStockAdded: 25),
        25.0,
      );
    });
  });

  group('InventoryRules.calculateStockAfterAdjustment', () {
    test('initial=100, sell 20 → stock=80', () {
      expect(
        InventoryRules.calculateStockAfterAdjustment(
          currentStock: 100,
          type: 'remove',
          quantity: 20,
        ),
        80.0,
      );
    });

    test('initial=50, add 30 → stock=80', () {
      expect(
        InventoryRules.calculateStockAfterAdjustment(
          currentStock: 50,
          type: 'add',
          quantity: 30,
        ),
        80.0,
      );
    });

    test('multiple operations maintain consistency', () {
      double stock = 100;

      // Sell 20
      stock = InventoryRules.calculateStockAfterAdjustment(
        currentStock: stock,
        type: 'remove',
        quantity: 20,
      );
      expect(stock, 80.0);

      // Add 50
      stock = InventoryRules.calculateStockAfterAdjustment(
        currentStock: stock,
        type: 'add',
        quantity: 50,
      );
      expect(stock, 130.0);

      // Damage 10
      stock = InventoryRules.calculateStockAfterAdjustment(
        currentStock: stock,
        type: 'damage',
        quantity: 10,
      );
      expect(stock, 120.0);

      // Return 5
      stock = InventoryRules.calculateStockAfterAdjustment(
        currentStock: stock,
        type: 'return',
        quantity: 5,
      );
      expect(stock, 125.0);
    });

    test('stock never goes below 0', () {
      expect(
        InventoryRules.calculateStockAfterAdjustment(
          currentStock: 5,
          type: 'remove',
          quantity: 100,
        ),
        0.0,
      );
    });

    test('zero-quantity adjustment is idempotent', () {
      expect(
        InventoryRules.calculateStockAfterAdjustment(
          currentStock: 42,
          type: 'add',
          quantity: 0,
        ),
        42.0,
      );
    });
  });

  group('InventoryRules stock status helpers', () {
    test('isOutOfStock returns true when stock <= 0', () {
      expect(InventoryRules.isOutOfStock(0), true);
      expect(InventoryRules.isOutOfStock(-1), true);
      expect(InventoryRules.isOutOfStock(1), false);
    });

    test('isLowStock returns true when stock > 0 and <= minLevel', () {
      expect(InventoryRules.isLowStock(3, 5), true);
      expect(InventoryRules.isLowStock(5, 5), true);
      expect(InventoryRules.isLowStock(0, 5), false); // out of stock, not low
      expect(InventoryRules.isLowStock(10, 5), false); // above min
    });
  });
}
