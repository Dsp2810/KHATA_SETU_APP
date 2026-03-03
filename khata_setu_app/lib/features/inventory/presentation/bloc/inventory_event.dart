import 'package:equatable/equatable.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

/// Load all products (optionally from remote)
class LoadProducts extends InventoryEvent {
  final bool forceRemote;
  const LoadProducts({this.forceRemote = false});
  @override
  List<Object?> get props => [forceRemote];
}

/// Search products by query
class SearchProducts extends InventoryEvent {
  final String query;
  const SearchProducts(this.query);
  @override
  List<Object?> get props => [query];
}

/// Filter by category
class FilterByCategory extends InventoryEvent {
  final String? category;
  const FilterByCategory(this.category);
  @override
  List<Object?> get props => [category];
}

/// Add a new product
class AddProduct extends InventoryEvent {
  final String name;
  final String? localName;
  final String? description;
  final String category;
  final String? subCategory;
  final String? sku;
  final String? barcode;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double? mrp;
  final double taxRate;
  final double currentStock;
  final double minStockLevel;
  final String? image;
  final List<String>? tags;
  final String? supplierName;
  final String? supplierPhone;
  final DateTime? expiryDate;

  const AddProduct({
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
    this.image,
    this.tags,
    this.supplierName,
    this.supplierPhone,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [name, purchasePrice, sellingPrice];
}

/// Update existing product
class UpdateProduct extends InventoryEvent {
  final String productId;
  final String name;
  final String? localName;
  final String? description;
  final String category;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double? mrp;
  final double taxRate;
  final double minStockLevel;
  final String? image;
  final List<String>? tags;
  final String? supplierName;
  final String? supplierPhone;
  final DateTime? expiryDate;

  const UpdateProduct({
    required this.productId,
    required this.name,
    this.localName,
    this.description,
    this.category = 'General',
    this.unit = 'piece',
    required this.purchasePrice,
    required this.sellingPrice,
    this.mrp,
    this.taxRate = 0,
    this.minStockLevel = 5,
    this.image,
    this.tags,
    this.supplierName,
    this.supplierPhone,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [productId, name];
}

/// Delete a product (soft delete)
class DeleteProduct extends InventoryEvent {
  final String productId;
  const DeleteProduct(this.productId);
  @override
  List<Object?> get props => [productId];
}

/// Adjust stock (add/remove)
class AdjustStock extends InventoryEvent {
  final String productId;
  final String type; // 'add' | 'remove' | 'damage' | 'return'
  final double quantity;
  final double? unitPrice;
  final String? notes;

  const AdjustStock({
    required this.productId,
    required this.type,
    required this.quantity,
    this.unitPrice,
    this.notes,
  });

  @override
  List<Object?> get props => [productId, type, quantity];
}
