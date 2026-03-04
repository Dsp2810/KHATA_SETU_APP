import 'package:dio/dio.dart';

import 'api_endpoints.dart';

/// Centralized API service wrapping all backend calls.
/// Delegates HTTP to [Dio] (configured with auth interceptor).
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // ═══════════════════════ Auth ═══════════════════════

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    String? shopName,
    String? language,
  }) async {
    final response = await _dio.post(ApiEndpoints.register, data: {
      'name': name,
      'phone': phone,
      'password': password,
      'shopName': shopName ?? 'My Shop',
      'language': language ?? 'en',
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post(ApiEndpoints.login, data: {
      'phone': phone,
      'password': password,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post(ApiEndpoints.refreshToken, data: {
      'refreshToken': refreshToken,
    });
    return response.data['data'];
  }

  Future<void> logout({String? refreshToken, String? deviceId}) async {
    await _dio.post(ApiEndpoints.logout, data: {
      'refreshToken': ?refreshToken,
      'deviceId': ?deviceId,
    });
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return response.data['data'];
  }

  // ═══════════════════════ Shops ═══════════════════════

  Future<List<dynamic>> getShops() async {
    final response = await _dio.get(ApiEndpoints.shops);
    return response.data['data']['shops'] ?? response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> createShop({
    required String name,
    String? address,
    String? phone,
  }) async {
    final response = await _dio.post(ApiEndpoints.shops, data: {
      'name': name,
      'address': ?address,
      'phone': ?phone,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getShop(String shopId) async {
    final response = await _dio.get(ApiEndpoints.shop(shopId));
    return response.data['data'];
  }

  // ═══════════════════════ Customers ═══════════════════════

  Future<Map<String, dynamic>> getCustomers(
    String shopId, {
    int page = 1,
    int limit = 20,
    String? search,
    String? sortBy,
    String? sortOrder,
    String? hasBalance,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.customers(shopId),
      queryParameters: {
        'page': page,
        'limit': limit,
        'search': ?search,
        'sortBy': ?sortBy,
        'sortOrder': ?sortOrder,
        'hasBalance': ?hasBalance,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getCustomer(
      String shopId, String customerId) async {
    final response =
        await _dio.get(ApiEndpoints.customer(shopId, customerId));
    return response.data['data'];
  }

  Future<Map<String, dynamic>> createCustomer(
    String shopId, {
    required String name,
    required String phone,
    String? email,
    String? address,
    double? creditLimit,
    String? avatar,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.customers(shopId),
      data: {
        'name': name,
        'phone': phone,
        'email': ?email,
        'address': ?address,
        'creditLimit': ?creditLimit,
        'avatar': ?avatar,
        'notes': ?notes,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateCustomer(
    String shopId,
    String customerId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _dio.patch(
      ApiEndpoints.customer(shopId, customerId),
      data: updates,
    );
    return response.data['data'];
  }

  Future<void> deleteCustomer(String shopId, String customerId) async {
    await _dio.delete(ApiEndpoints.customer(shopId, customerId));
  }

  Future<Map<String, dynamic>> getCustomerStats(
      String shopId, String customerId) async {
    final response =
        await _dio.get(ApiEndpoints.customerStats(shopId, customerId));
    return response.data['data'];
  }

  Future<List<dynamic>> searchCustomers(
    String shopId, {
    required String query,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.searchCustomers(shopId),
      queryParameters: {'q': query, 'limit': limit},
    );
    return response.data['data']['customers'] ?? [];
  }

  // ═══════════════════════ Ledger ═══════════════════════

  Future<Map<String, dynamic>> getLedgerEntries(
    String shopId, {
    int page = 1,
    int limit = 20,
    String? customerId,
    String? type,
    String? startDate,
    String? endDate,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.ledger(shopId),
      queryParameters: {
        'page': page,
        'limit': limit,
        'customerId': ?customerId,
        'type': ?type,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'sortBy': ?sortBy,
        'sortOrder': ?sortOrder,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> createLedgerEntry(
    String shopId, {
    required String customerId,
    required String type,
    required double amount,
    String? description,
    String? paymentMode,
    List<Map<String, dynamic>>? items,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.ledger(shopId),
      data: {
        'customerId': customerId,
        'type': type,
        'amount': amount,
        'description': ?description,
        'paymentMode': ?paymentMode,
        'linkedProducts': ?items,
      },
    );
    return response.data['data'];
  }

  Future<void> deleteLedgerEntry(
    String shopId,
    String entryId, {
    String? reason,
  }) async {
    await _dio.delete(
      ApiEndpoints.ledgerEntry(shopId, entryId),
      data: {'reason': ?reason},
    );
  }

  Future<Map<String, dynamic>> getLedgerSummary(
    String shopId, {
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.ledgerSummary(shopId),
      queryParameters: {
        'startDate': ?startDate,
        'endDate': ?endDate,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getCustomerLedger(
    String shopId,
    String customerId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.customerLedger(shopId, customerId),
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data['data'];
  }

  // ═══════════════════════ Products ═══════════════════════

  Future<Map<String, dynamic>> getProducts(
    String shopId, {
    int page = 1,
    int limit = 100,
    String? search,
    String? category,
    bool? isLowStock,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.products(shopId),
      queryParameters: {
        'page': page,
        'limit': limit,
        'search': ?search,
        'category': ?category,
        'lowStock': ?isLowStock,
        'sortBy': ?sortBy,
        'sortOrder': ?sortOrder,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getProduct(
      String shopId, String productId) async {
    final response =
        await _dio.get(ApiEndpoints.product(shopId, productId));
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getProductByBarcode(
      String shopId, String barcode) async {
    final response =
        await _dio.get(ApiEndpoints.productBarcode(shopId, barcode));
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getProductCategories(String shopId) async {
    final response =
        await _dio.get(ApiEndpoints.productCategories(shopId));
    return response.data['data'];
  }

  Future<Map<String, dynamic>> createProduct(
    String shopId,
    Map<String, dynamic> productData,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.products(shopId),
      data: productData,
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateProduct(
    String shopId,
    String productId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _dio.patch(
      ApiEndpoints.product(shopId, productId),
      data: updates,
    );
    return response.data['data'];
  }

  Future<void> deleteProduct(String shopId, String productId) async {
    await _dio.delete(ApiEndpoints.product(shopId, productId));
  }

  Future<Map<String, dynamic>> adjustStock(
    String shopId,
    String productId, {
    required String type,
    required double quantity,
    double? unitPrice,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.productStock(shopId, productId),
      data: {
        'type': type,
        'quantity': quantity,
        'unitPrice': ?unitPrice,
        'notes': ?notes,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getLowStockProducts(String shopId) async {
    final response = await _dio.get(ApiEndpoints.lowStockProducts(shopId));
    return response.data['data'];
  }

  Future<List<dynamic>> getCategories(String shopId) async {
    final response = await _dio.get(ApiEndpoints.productCategories(shopId));
    return response.data['data']['categories'] ?? [];
  }

  // ═══════════════════════ Reports ═══════════════════════

  Future<Map<String, dynamic>> getDashboard(String shopId) async {
    final response = await _dio.get(ApiEndpoints.dashboard(shopId));
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getLedgerReport(
    String shopId, {
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.ledgerReport(shopId),
      queryParameters: {
        'startDate': ?startDate,
        'endDate': ?endDate,
      },
    );
    return response.data['data'];
  }

  // ═══════════════════════ Reminders ═══════════════════════

  Future<Map<String, dynamic>> getReminders(
    String shopId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.reminders(shopId),
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> createReminder(
    String shopId,
    Map<String, dynamic> reminderData,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.reminders(shopId),
      data: reminderData,
    );
    return response.data['data'];
  }

  // ═══════════════════════ Daily Notes ═══════════════════════

  Future<Map<String, dynamic>> getNotes(
    String shopId, {
    int page = 1,
    int limit = 20,
    String? customerId,
    String? status,
    String? priority,
    String? tag,
    String? startDate,
    String? endDate,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.notes(shopId),
      queryParameters: {
        'page': page,
        'limit': limit,
        'customerId': ?customerId,
        'status': ?status,
        'priority': ?priority,
        'tag': ?tag,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'search': ?search,
        'sortBy': ?sortBy,
        'sortOrder': ?sortOrder,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getNote(
      String shopId, String noteId) async {
    final response =
        await _dio.get(ApiEndpoints.note(shopId, noteId));
    return response.data['data'];
  }

  Future<Map<String, dynamic>> createNote(
    String shopId,
    Map<String, dynamic> noteData,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.notes(shopId),
      data: noteData,
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateNote(
    String shopId,
    String noteId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _dio.patch(
      ApiEndpoints.note(shopId, noteId),
      data: updates,
    );
    return response.data['data'];
  }

  Future<void> deleteNote(String shopId, String noteId) async {
    await _dio.delete(ApiEndpoints.note(shopId, noteId));
  }

  Future<Map<String, dynamic>> completeNote(
      String shopId, String noteId) async {
    final response =
        await _dio.post(ApiEndpoints.noteComplete(shopId, noteId));
    return response.data['data'];
  }

  Future<Map<String, dynamic>> bulkCompleteNotes(
    String shopId,
    List<String> noteIds,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.notesBulkComplete(shopId),
      data: {'noteIds': noteIds},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> bulkDeleteNotes(
    String shopId,
    List<String> noteIds, {
    String? reason,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.notesBulkDelete(shopId),
      data: {
        'noteIds': noteIds,
        'reason': ?reason,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getTodayNotes(String shopId) async {
    final response = await _dio.get(ApiEndpoints.notesToday(shopId));
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getNoteSummary(
    String shopId, {
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.notesSummary(shopId),
      queryParameters: {
        'startDate': ?startDate,
        'endDate': ?endDate,
      },
    );
    return response.data['data'];
  }
}
