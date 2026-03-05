import '../../network/api_service.dart';
import '../models/product_model.dart';

/// Remote data source for product operations via backend API.
class ProductRemoteDataSource {
  final ApiService _api;
  final String shopId;

  ProductRemoteDataSource(this._api, this.shopId);

  // ─── Read ────────────────────────────────────────────────────

  Future<List<ProductModel>> getAllProducts({
    int page = 1,
    int limit = 100,
    String? search,
    String? category,
    bool? isLowStock,
    String? sortBy,
    String? sortOrder,
  }) async {
    final data = await _api.getProducts(
      shopId,
      page: page,
      limit: limit,
      search: search,
      category: category,
      isLowStock: isLowStock,
      sortBy: sortBy ?? 'createdAt',
      sortOrder: sortOrder ?? 'desc',
    );

    final productsJson = data['products'] as List<dynamic>? ?? [];
    return productsJson
        .map((json) => _productFromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> getProductById(String productId) async {
    final data = await _api.getProduct(shopId, productId);
    return _productFromJson(data['product'] as Map<String, dynamic>);
  }

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      final data = await _api.getProductByBarcode(shopId, barcode);
      if (data['product'] == null) return null;
      return _productFromJson(data['product'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> getCategories() async {
    final data = await _api.getProductCategories(shopId);
    final cats = data['categories'] as List<dynamic>? ?? [];
    return cats.map((c) => c.toString()).toList();
  }

  Future<List<ProductModel>> getLowStockProducts() async {
    final data = await _api.getLowStockProducts(shopId);
    final productsJson = data['products'] as List<dynamic>? ?? [];
    return productsJson
        .map((json) => _productFromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Write ───────────────────────────────────────────────────

  Future<ProductModel> createProduct(ProductModel product) async {
    final productData = _productToJson(product);
    final data = await _api.createProduct(shopId, productData);
    return _productFromJson(data['product'] as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct(
      String productId, Map<String, dynamic> updates) async {
    final data = await _api.updateProduct(shopId, productId, updates);
    return _productFromJson(data['product'] as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String productId) async {
    await _api.deleteProduct(shopId, productId);
  }

  Future<void> adjustStock(
    String productId, {
    required String type,
    required double quantity,
    double? unitPrice,
    String? notes,
  }) async {
    await _api.adjustStock(
      shopId,
      productId,
      type: type,
      quantity: quantity,
      unitPrice: unitPrice,
      notes: notes,
    );
  }

  // ─── Model → JSON ───────────────────────────────────────────

  Map<String, dynamic> _productToJson(ProductModel p) {
    return {
      'name': p.name,
      if (p.localName != null) 'localName': p.localName,
      if (p.description != null) 'description': p.description,
      'category': p.category,
      if (p.subCategory != null) 'subCategory': p.subCategory,
      if (p.sku != null) 'sku': p.sku,
      if (p.barcode != null) 'barcode': p.barcode,
      'unit': p.unit,
      'purchasePrice': p.purchasePrice,
      'sellingPrice': p.sellingPrice,
      if (p.mrp != null) 'mrp': p.mrp,
      'taxRate': p.taxRate,
      'currentStock': p.currentStock,
      'minStockLevel': p.minStockLevel,
      if (p.image != null) 'image': p.image,
      if (p.supplierName != null || p.supplierPhone != null)
        'supplier': {
          if (p.supplierName != null) 'name': p.supplierName,
          if (p.supplierPhone != null) 'phone': p.supplierPhone,
        },
      if (p.expiryDate != null) 'expiryDate': p.expiryDate!.toIso8601String(),
      if (p.tags.isNotEmpty) 'tags': p.tags,
    };
  }

  // ─── JSON → Model ───────────────────────────────────────────

  ProductModel _productFromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '').toString();

    // Parse supplier
    String? supplierName;
    String? supplierPhone;
    if (json['supplier'] is Map) {
      supplierName = json['supplier']['name'] as String?;
      supplierPhone = json['supplier']['phone'] as String?;
    }

    return ProductModel(
      id: id,
      name: json['name'] as String? ?? '',
      localName: json['localName'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'General',
      subCategory: json['subCategory'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      unit: json['unit'] as String? ?? 'piece',
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      mrp: (json['mrp'] as num?)?.toDouble(),
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
      minStockLevel: (json['minStockLevel'] as num?)?.toDouble() ?? 5,
      maxStockLevel: (json['maxStockLevel'] as num?)?.toDouble() ?? 1000,
      reorderPoint: (json['reorderPoint'] as num?)?.toDouble() ?? 10,
      image: (json['images'] is List && (json['images'] as List).isNotEmpty)
          ? (json['images'] as List).first['url'] as String?
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      lastRestockedAt: _parseDate(json['lastRestockedAt']),
      synced: true,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
      supplierName: supplierName,
      supplierPhone: supplierPhone,
      expiryDate: _parseDate(json['expiryDate']),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
