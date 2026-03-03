import 'package:equatable/equatable.dart';
import '../../../../core/data/models/product_model.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

/// State when products exist
class InventoryLoaded extends InventoryState {
  final List<ProductModel> products;
  final List<ProductModel> filteredProducts;
  final List<String> categories;
  final String? selectedCategory;
  final String searchQuery;
  final Map<String, dynamic> summary;

  const InventoryLoaded({
    required this.products,
    required this.filteredProducts,
    required this.categories,
    this.selectedCategory,
    this.searchQuery = '',
    required this.summary,
  });

  @override
  List<Object?> get props => [
    products.length,
    filteredProducts.length,
    categories,
    selectedCategory,
    searchQuery,
    summary,
  ];

  InventoryLoaded copyWith({
    List<ProductModel>? products,
    List<ProductModel>? filteredProducts,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    Map<String, dynamic>? summary,
    bool clearCategory = false,
  }) {
    return InventoryLoaded(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      categories: categories ?? this.categories,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      summary: summary ?? this.summary,
    );
  }
}

/// State when no products exist yet
class InventoryEmpty extends InventoryState {
  const InventoryEmpty();
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Transient state emitted briefly after a product is added/updated/deleted
class InventoryActionSuccess extends InventoryState {
  final String message;
  const InventoryActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
