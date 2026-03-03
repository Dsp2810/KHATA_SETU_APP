import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 5)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? localName;

  @HiveField(3)
  String? description;

  @HiveField(4)
  String category;

  @HiveField(5)
  String? subCategory;

  @HiveField(6)
  String? sku;

  @HiveField(7)
  String? barcode;

  @HiveField(8)
  String unit; // piece, kg, gram, liter, ml, meter, dozen, packet, box, bundle, other

  @HiveField(9)
  double purchasePrice;

  @HiveField(10)
  double sellingPrice;

  @HiveField(11)
  double? mrp;

  @HiveField(12)
  double taxRate;

  @HiveField(13)
  double currentStock;

  @HiveField(14)
  double minStockLevel;

  @HiveField(15)
  double maxStockLevel;

  @HiveField(16)
  double reorderPoint;

  @HiveField(17)
  String? image;

  @HiveField(18)
  bool isActive;

  @HiveField(19)
  DateTime createdAt;

  @HiveField(20)
  DateTime? lastRestockedAt;

  @HiveField(21)
  bool synced;

  @HiveField(22)
  List<String> tags;

  @HiveField(23)
  String? supplierName;

  @HiveField(24)
  String? supplierPhone;

  @HiveField(25)
  DateTime? expiryDate;

  ProductModel({
    required this.id,
    required this.name,
    this.localName,
    this.description,
    this.category = 'General',
    this.subCategory,
    this.sku,
    this.barcode,
    this.unit = 'piece',
    required this.purchasePrice,
    required this.sellingPrice,
    this.mrp,
    this.taxRate = 0,
    this.currentStock = 0,
    this.minStockLevel = 5,
    this.maxStockLevel = 1000,
    this.reorderPoint = 10,
    this.image,
    this.isActive = true,
    DateTime? createdAt,
    this.lastRestockedAt,
    this.synced = false,
    List<String>? tags,
    this.supplierName,
    this.supplierPhone,
    this.expiryDate,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  // ─── Computed ────────────────────────────────────────────────

  bool get isLowStock => currentStock > 0 && currentStock <= minStockLevel;
  bool get isOutOfStock => currentStock <= 0;
  double get profitMargin =>
      sellingPrice > 0 ? ((sellingPrice - purchasePrice) / sellingPrice) * 100 : 0;
  double get stockValue => currentStock * purchasePrice;

  /// Emoji based on category for display
  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'grocery':
      case 'kirana':
        return '🛒';
      case 'dairy':
        return '🥛';
      case 'snacks':
        return '🍪';
      case 'beverages':
        return '🥤';
      case 'personal care':
        return '🧴';
      case 'stationery':
        return '✏️';
      case 'household':
        return '🏠';
      case 'medical':
      case 'medicine':
        return '💊';
      case 'electronics':
        return '📱';
      case 'clothing':
        return '👕';
      case 'hardware':
        return '🔧';
      case 'fruits':
      case 'vegetables':
        return '🥬';
      default:
        return '📦';
    }
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? localName,
    String? description,
    String? category,
    String? subCategory,
    String? sku,
    String? barcode,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    double? mrp,
    double? taxRate,
    double? currentStock,
    double? minStockLevel,
    double? maxStockLevel,
    double? reorderPoint,
    String? image,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastRestockedAt,
    bool? synced,
    List<String>? tags,
    String? supplierName,
    String? supplierPhone,
    DateTime? expiryDate,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      localName: localName ?? this.localName,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
      taxRate: taxRate ?? this.taxRate,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
      synced: synced ?? this.synced,
      tags: tags ?? this.tags,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
