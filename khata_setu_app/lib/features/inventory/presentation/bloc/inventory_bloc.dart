import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/data/models/product_model.dart';
import '../../../../core/data/repositories/product_repository.dart';
import '../../../../core/error/error_handler.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  ProductRepository _repository;

  InventoryBloc(this._repository) : super(InventoryInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<SearchProducts>(_onSearchProducts, transformer: _debounce());
    on<FilterByCategory>(_onFilterByCategory);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<AdjustStock>(_onAdjustStock);
  }

  /// Hot-swap the repository after login wires up remote datasource.
  void updateRepository(ProductRepository repository) {
    _repository = repository;
  }

  /// Debounce search events by 300ms to avoid excessive rebuilds
  EventTransformer<T> _debounce<T>() {
    return (events, mapper) =>
        events.debounceTime(const Duration(milliseconds: 300)).flatMap(mapper);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      List<ProductModel> products;
      if (event.forceRemote) {
        products = await _repository.getAllProductsAsync();
      } else {
        products = _repository.getAllProducts();
        // If empty, try remote
        if (products.isEmpty) {
          products = await _repository.getAllProductsAsync();
        }
      }

      // Emit InventoryEmpty if no products exist
      if (products.isEmpty) {
        emit(const InventoryEmpty());
        return;
      }

      final categories = _repository.getCategories();
      final summary = _repository.getSummary();

      emit(InventoryLoaded(
        products: products,
        filteredProducts: products,
        categories: categories,
        summary: summary,
      ));
    } catch (e) {
      debugPrint('InventoryBloc._onLoadProducts error: $e');
      emit(InventoryError(mapExceptionToFailure(e).message));
    }
  }

  void _onSearchProducts(
    SearchProducts event,
    Emitter<InventoryState> emit,
  ) {
    final current = state;
    if (current is! InventoryLoaded) return;

    final query = event.query.trim();
    List<ProductModel> filtered;

    if (query.isEmpty) {
      filtered = current.selectedCategory != null
          ? _repository.getProductsByCategory(current.selectedCategory!)
          : current.products;
    } else {
      filtered = _repository.searchProducts(query);
      if (current.selectedCategory != null) {
        filtered = filtered
            .where((p) =>
                p.category.toLowerCase() ==
                current.selectedCategory!.toLowerCase())
            .toList();
      }
    }

    emit(current.copyWith(
      filteredProducts: filtered,
      searchQuery: query,
    ));
  }

  void _onFilterByCategory(
    FilterByCategory event,
    Emitter<InventoryState> emit,
  ) {
    final current = state;
    if (current is! InventoryLoaded) return;

    List<ProductModel> filtered;

    if (event.category == null || event.category!.isEmpty) {
      // Clear filter
      filtered = current.searchQuery.isNotEmpty
          ? _repository.searchProducts(current.searchQuery)
          : current.products;
      emit(current.copyWith(
        filteredProducts: filtered,
        clearCategory: true,
      ));
    } else {
      filtered = _repository.getProductsByCategory(event.category!);
      if (current.searchQuery.isNotEmpty) {
        final q = current.searchQuery.toLowerCase();
        filtered = filtered
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                (p.localName?.toLowerCase().contains(q) ?? false))
            .toList();
      }
      emit(current.copyWith(
        filteredProducts: filtered,
        selectedCategory: event.category,
      ));
    }
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.addProduct(
        name: event.name,
        localName: event.localName,
        description: event.description,
        category: event.category,
        subCategory: event.subCategory,
        sku: event.sku,
        barcode: event.barcode,
        unit: event.unit,
        purchasePrice: event.purchasePrice,
        sellingPrice: event.sellingPrice,
        mrp: event.mrp,
        taxRate: event.taxRate,
        currentStock: event.currentStock,
        minStockLevel: event.minStockLevel,
        image: event.image,
        tags: event.tags,
        supplierName: event.supplierName,
        supplierPhone: event.supplierPhone,
        expiryDate: event.expiryDate,
      );

      emit(const InventoryActionSuccess('Product added successfully'));
      add(const LoadProducts());
    } catch (e) {
      emit(InventoryError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      final existing = _repository.getProductById(event.productId);
      if (existing == null) {
        emit(const InventoryError('Product not found'));
        return;
      }

      final updated = existing.copyWith(
        name: event.name,
        localName: event.localName,
        description: event.description,
        category: event.category,
        unit: event.unit,
        purchasePrice: event.purchasePrice,
        sellingPrice: event.sellingPrice,
        mrp: event.mrp,
        taxRate: event.taxRate,
        minStockLevel: event.minStockLevel,
        image: event.image,
        tags: event.tags,
        supplierName: event.supplierName,
        supplierPhone: event.supplierPhone,
        expiryDate: event.expiryDate,
      );

      await _repository.updateProduct(updated);

      emit(const InventoryActionSuccess('Product updated successfully'));
      add(const LoadProducts());
    } catch (e) {
      emit(InventoryError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.deleteProduct(event.productId);
      emit(const InventoryActionSuccess('Product deleted'));
      add(const LoadProducts());
    } catch (e) {
      emit(InventoryError(mapExceptionToFailure(e).message));
    }
  }

  Future<void> _onAdjustStock(
    AdjustStock event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.adjustStock(
        event.productId,
        type: event.type,
        quantity: event.quantity,
        unitPrice: event.unitPrice,
        notes: event.notes,
      );

      emit(const InventoryActionSuccess('Stock adjusted'));
      add(const LoadProducts());
    } catch (e) {
      emit(InventoryError(mapExceptionToFailure(e).message));
    }
  }
}
