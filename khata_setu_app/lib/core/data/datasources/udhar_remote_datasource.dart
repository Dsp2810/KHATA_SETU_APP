import '../../network/api_service.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';

/// Remote data source that fetches data from the backend API
/// and converts JSON responses into local Hive models for
/// seamless offline-first operation.
class UdharRemoteDataSource {
  final ApiService _api;
  final String _shopId;

  UdharRemoteDataSource(this._api, this._shopId);

  // ─── Customer Operations ─────────────────────────────────────

  Future<List<CustomerModel>> getAllCustomers({
    int page = 1,
    int limit = 100,
    String? search,
  }) async {
    final data = await _api.getCustomers(
      _shopId,
      page: page,
      limit: limit,
      search: search,
      sortBy: 'createdAt',
      sortOrder: 'desc',
    );

    final customersJson = data['customers'] as List<dynamic>? ?? [];
    return customersJson
        .map((json) => _customerFromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerModel> getCustomerById(String id) async {
    final data = await _api.getCustomer(_shopId, id);
    return _customerFromJson(data['customer'] as Map<String, dynamic>);
  }

  Future<List<CustomerModel>> searchCustomers(String query) async {
    final results = await _api.searchCustomers(
      _shopId,
      query: query,
      limit: 20,
    );
    return results
        .map((json) => _customerFromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerModel> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    double? creditLimit,
    String? avatar,
    String? notes,
  }) async {
    final data = await _api.createCustomer(
      _shopId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      creditLimit: creditLimit,
      avatar: avatar,
      notes: notes,
    );
    return _customerFromJson(data['customer'] as Map<String, dynamic>);
  }

  Future<CustomerModel> updateCustomer(
    String customerId,
    Map<String, dynamic> updates,
  ) async {
    final data = await _api.updateCustomer(_shopId, customerId, updates);
    return _customerFromJson(data['customer'] as Map<String, dynamic>);
  }

  Future<void> deleteCustomer(String customerId) async {
    await _api.deleteCustomer(_shopId, customerId);
  }

  // ─── Ledger / Transaction Operations ─────────────────────────

  Future<List<TransactionModel>> getAllTransactions({
    int page = 1,
    int limit = 100,
    String? customerId,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    final data = await _api.getLedgerEntries(
      _shopId,
      page: page,
      limit: limit,
      customerId: customerId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      sortBy: 'createdAt',
      sortOrder: 'desc',
    );

    final entriesJson = data['entries'] as List<dynamic>? ?? [];
    return entriesJson
        .map((json) => _transactionFromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TransactionModel>> getCustomerTransactions(
    String customerId, {
    int page = 1,
    int limit = 50,
  }) async {
    final data = await _api.getCustomerLedger(
      _shopId,
      customerId,
      page: page,
      limit: limit,
    );

    final entriesJson = data['entries'] as List<dynamic>? ?? [];
    return entriesJson
        .map((json) => _transactionFromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> createLedgerEntry({
    required String customerId,
    required String type,
    required double amount,
    String? description,
    String? paymentMode,
    List<Map<String, dynamic>>? items,
  }) async {
    final data = await _api.createLedgerEntry(
      _shopId,
      customerId: customerId,
      type: type,
      amount: amount,
      description: description,
      paymentMode: paymentMode,
      items: items,
    );
    return _transactionFromJson(data['entry'] as Map<String, dynamic>);
  }

  Future<void> deleteLedgerEntry(String entryId, {String? reason}) async {
    await _api.deleteLedgerEntry(_shopId, entryId, reason: reason);
  }

  Future<Map<String, dynamic>> getLedgerSummary({
    String? startDate,
    String? endDate,
  }) async {
    return _api.getLedgerSummary(
      _shopId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ─── Dashboard ───────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard() async {
    return _api.getDashboard(_shopId);
  }

  // ─── JSON → Model Converters ─────────────────────────────────

  CustomerModel _customerFromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '').toString();
    return CustomerModel(
      id: id,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      address: json['address'] as String?,
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 5000.0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 50,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      lastTransactionAt: _parseDate(json['lastTransactionAt']),
      avatar: json['avatar'] as String?,
      notes: json['notes'] as String?,
      synced: true,
    );
  }

  TransactionModel _transactionFromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '').toString();
    final typeStr = json['type'] as String? ?? 'credit';
    final type = typeStr == 'credit' ? 0 : 1;

    // Handle customerId that might be a populated object
    String customerId;
    if (json['customerId'] is Map) {
      customerId = (json['customerId']['_id'] ?? json['customerId']['id'] ?? '').toString();
    } else {
      customerId = (json['customerId'] ?? '').toString();
    }

    // Parse payment mode
    int paymentMode = 0;
    final pm = json['paymentMode'];
    if (pm is int) {
      paymentMode = pm;
    } else if (pm is String) {
      paymentMode = _paymentModeFromString(pm);
    }

    // Parse items
    final itemsList = <TransactionItem>[];
    if (json['linkedProducts'] is List) {
      for (final item in json['linkedProducts'] as List) {
        if (item is Map<String, dynamic>) {
          itemsList.add(TransactionItem(
            name: (item['name'] ?? item['productId']?['name'] ?? 'Item').toString(),
            price: (item['price'] as num?)?.toDouble() ?? 0,
            quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
            unit: item['unit'] as String?,
          ));
        }
      }
    }
    if (json['items'] is List) {
      for (final item in json['items'] as List) {
        if (item is Map<String, dynamic>) {
          itemsList.add(TransactionItem(
            name: item['name'] as String? ?? 'Item',
            price: (item['price'] as num?)?.toDouble() ?? 0,
            quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
            unit: item['unit'] as String?,
          ));
        }
      }
    }

    return TransactionModel(
      id: id,
      customerId: customerId,
      type: type,
      totalAmount: (json['amount'] as num?)?.toDouble() ?? 0,
      items: itemsList,
      description: json['description'] as String?,
      paymentMode: paymentMode,
      timestamp: _parseDate(json['createdAt']) ?? DateTime.now(),
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      synced: true,
    );
  }

  int _paymentModeFromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'upi':
        return 1;
      case 'card':
      case 'bank':
        return 2;
      case 'other':
        return 3;
      default:
        return 0;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
