import 'package:uuid/uuid.dart';

import '../../utils/app_logger.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

/// Repository — Single entry point for all Product/Inventory operations.
/// Offline-first: reads from local Hive, syncs with remote API.
class ProductRepository {
  final ProductLocalDataSource _local;
  final ProductRemoteDataSource? _remote;
  final _uuid = const Uuid();

  ProductRepository(this._local, [this._remote]);

  bool get _hasRemote => _remote != null;

  // ─── Read ────────────────────────────────────────────────────

  /// Fetch products: tries remote first, falls back to local.
  Future<List<ProductModel>> getAllProductsAsync({
    String? search,
    String? category,
  }) async {
    if (_hasRemote) {
      try {
        final remoteProducts = await _remote!.getAllProducts(
          search: search,
          category: category,
        );
        // Cache locally
        for (final p in remoteProducts) {
          await _local.saveProduct(p);
        }
        return remoteProducts;
      } catch (e) {
        AppLogger.warning('Remote product fetch failed, using local: $e');
      }
    }

    // Fallback: local with optional search/category filter
    if (search != null && search.isNotEmpty) {
      return _local.searchProducts(search);
    }
    if (category != null && category.isNotEmpty) {
      return _local.getProductsByCategory(category);
    }
    return _local.getAllProducts();
  }

  /// Synchronous local-only access (for quick UI reads)
  List<ProductModel> getAllProducts() => _local.getAllProducts();

  ProductModel? getProductById(String id) => _local.getProductById(id);

  ProductModel? getProductByBarcode(String barcode) =>
      _local.getProductByBarcode(barcode);

  List<ProductModel> searchProducts(String query) =>
      _local.searchProducts(query);

  List<ProductModel> getProductsByCategory(String category) =>
      _local.getProductsByCategory(category);

  List<ProductModel> getLowStockProducts() => _local.getLowStockProducts();

  List<ProductModel> getOutOfStockProducts() =>
      _local.getOutOfStockProducts();

  List<String> getCategories() => _local.getCategories();

  Map<String, dynamic> getSummary() => _local.getSummary();

  // ─── Create ──────────────────────────────────────────────────

  Future<ProductModel> addProduct({
    required String name,
    String? localName,
    String? description,
    String category = 'General',
    String? subCategory,
    String? sku,
    String? barcode,
    String unit = 'piece',
    required double purchasePrice,
    required double sellingPrice,
    double? mrp,
    double taxRate = 0,
    double currentStock = 0,
    double minStockLevel = 5,
    double maxStockLevel = 1000,
    double reorderPoint = 10,
    String? image,
    List<String>? tags,
    String? supplierName,
    String? supplierPhone,
    DateTime? expiryDate,
  }) async {
    final localProduct = ProductModel(
      id: _uuid.v4(),
      name: name,
      localName: localName,
      description: description,
      category: category,
      subCategory: subCategory,
      sku: sku,
      barcode: barcode,
      unit: unit,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      mrp: mrp,
      taxRate: taxRate,
      currentStock: currentStock,
      minStockLevel: minStockLevel,
      maxStockLevel: maxStockLevel,
      reorderPoint: reorderPoint,
      image: image,
      tags: tags ?? [],
      supplierName: supplierName,
      supplierPhone: supplierPhone,
      expiryDate: expiryDate,
      synced: false,
    );

    // Try remote first
    if (_hasRemote) {
      try {
        final remoteProduct = await _remote!.createProduct(localProduct);
        await _local.saveProduct(remoteProduct);
        return remoteProduct;
      } catch (e) {
        AppLogger.warning('Remote create product failed, saving locally: $e');
      }
    }

    // Fallback: save locally as unsynced
    await _local.saveProduct(localProduct);
    return localProduct;
  }

  // ─── Update ──────────────────────────────────────────────────

  Future<void> updateProduct(ProductModel product) async {
    if (_hasRemote) {
      try {
        final updates = {
          'name': product.name,
          if (product.localName != null) 'localName': product.localName,
          if (product.description != null) 'description': product.description,
          'category': product.category,
          'unit': product.unit,
          'purchasePrice': product.purchasePrice,
          'sellingPrice': product.sellingPrice,
          if (product.mrp != null) 'mrp': product.mrp,
          'taxRate': product.taxRate,
          'minStockLevel': product.minStockLevel,
          if (product.supplierName != null || product.supplierPhone != null)
            'supplier': {
              if (product.supplierName != null) 'name': product.supplierName,
              if (product.supplierPhone != null)
                'phone': product.supplierPhone,
            },
          if (product.tags.isNotEmpty) 'tags': product.tags,
        };
        final updated = await _remote!.updateProduct(product.id, updates);
        await _local.saveProduct(updated);
        return;
      } catch (e) {
        AppLogger.warning('Remote update product failed, saving locally: $e');
      }
    }

    product.synced = false;
    await _local.saveProduct(product);
  }

  // ─── Delete ──────────────────────────────────────────────────

  Future<void> deleteProduct(String productId) async {
    if (_hasRemote) {
      try {
        await _remote!.deleteProduct(productId);
      } catch (e) {
        AppLogger.warning('Remote delete product failed: $e');
      }
    }
    await _local.deleteProduct(productId);
  }

  // ─── Stock Adjustment ────────────────────────────────────────

  Future<void> adjustStock(
    String productId, {
    required String type,
    required double quantity,
    double? unitPrice,
    String? notes,
  }) async {
    final quantityChange = type == 'add' ? quantity : -quantity;

    if (_hasRemote) {
      try {
        await _remote!.adjustStock(
          productId,
          type: type,
          quantity: quantity,
          unitPrice: unitPrice,
          notes: notes,
        );
      } catch (e) {
        AppLogger.warning('Remote stock adjustment failed: $e');
      }
    }

    await _local.adjustStock(productId, quantityChange);
  }

  // ─── Sync ────────────────────────────────────────────────────

  /// Sync unsynced local products to remote.
  Future<int> syncUnsyncedProducts() async {
    if (!_hasRemote) return 0;

    final unsynced = _local.getUnsyncedProducts();
    int syncedCount = 0;

    for (final product in unsynced) {
      try {
        final remoteProduct = await _remote!.createProduct(product);
        await _local.saveProduct(remoteProduct);
        syncedCount++;
      } catch (e) {
        AppLogger.warning('Failed to sync product ${product.id}: $e');
      }
    }

    return syncedCount;
  }
}
