import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../models/daily_summary_model.dart';
import '../hive_initializer.dart';
import '../../utils/ledger_rules.dart';

/// Local data source for all Udhar transaction operations.
/// All methods are synchronous Hive reads or async writes.
class UdharLocalDataSource {
  Box<CustomerModel> get _customerBox =>
      Hive.box<CustomerModel>(HiveBoxes.customers);

  Box<TransactionModel> get _transactionBox =>
      Hive.box<TransactionModel>(HiveBoxes.transactions);

  Box<DailySummaryModel> get _summaryBox =>
      Hive.box<DailySummaryModel>(HiveBoxes.dailySummaries);

  // ─── Customer Operations ─────────────────────────────────────

  List<CustomerModel> getAllCustomers() {
    return _customerBox.values.where((c) => c.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  CustomerModel? getCustomerById(String id) {
    try {
      return _customerBox.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CustomerModel> searchCustomers(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return getAllCustomers();

    return _customerBox.values
        .where((c) =>
            c.isActive &&
            (c.name.toLowerCase().contains(q) ||
             c.phone.contains(q)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    await _customerBox.put(customer.id, customer);
  }

  Future<void> deleteCustomer(String id) async {
    final customer = getCustomerById(id);
    if (customer != null) {
      customer.isActive = false;
      await customer.save();
    }
  }

  // ─── Transaction Operations ──────────────────────────────────

  List<TransactionModel> getTransactionsForCustomer(String customerId) {
    return _transactionBox.values
        .where((t) => t.customerId == customerId && !t.isDeleted)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionModel> getTransactionsForDate(
      String customerId, DateTime date) {
    final dateKey = _dateKey(date);
    return _transactionBox.values
        .where((t) =>
            t.customerId == customerId &&
            !t.isDeleted &&
            _dateKey(t.timestamp) == dateKey)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionModel> getAllTransactions() {
    return _transactionBox.values
        .where((t) => !t.isDeleted)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionModel> getUnsyncedTransactions() {
    return _transactionBox.values
        .where((t) => !t.synced && !t.isDeleted)
        .toList();
  }

  TransactionModel? getLastTransaction(String customerId) {
    final txns = getTransactionsForCustomer(customerId);
    return txns.isNotEmpty ? txns.first : null;
  }

  /// Add a transaction and update customer balance + daily summary atomically.
  Future<TransactionModel> addTransaction({
    required String id,
    required String customerId,
    required int type, // 0=credit, 1=payment
    required double amount,
    List<TransactionItem> items = const [],
    String? description,
    int paymentMode = 0,
    DateTime? timestamp,
  }) async {
    final customer = getCustomerById(customerId);
    if (customer == null) {
      throw Exception('Customer not found: $customerId');
    }

    final now = timestamp ?? DateTime.now();

    // Calculate new balance using centralized LedgerRules
    final txnType = TransactionTypeFactory.fromInt(type);
    final newBalance = LedgerRules.calculateBalance(
      customer.currentBalance,
      txnType,
      amount,
    );

    // Create transaction
    final txn = TransactionModel(
      id: id,
      customerId: customerId,
      type: type,
      totalAmount: amount,
      items: items,
      description: description,
      paymentMode: paymentMode,
      timestamp: now,
      balanceAfter: newBalance,
    );

    // Save transaction
    await _transactionBox.put(txn.id, txn);

    // Update customer balance
    customer.currentBalance = newBalance;
    customer.lastTransactionAt = now;
    customer.synced = false;

    // Adjust trust score based on payments
    if (txnType == TransactionType.payment) {
      // Payment received — increase trust
      customer.trustScore = (customer.trustScore + 2).clamp(0, 100);
    }
    await customer.save();

    // Update daily summary
    await _updateDailySummary(customerId, now, type, amount, newBalance);

    return txn;
  }

  /// Save a transaction model directly (e.g. from remote API)
  /// and update the customer balance + daily summary accordingly.
  Future<void> saveTransactionDirect(
      TransactionModel txn, String customerId) async {
    // Save the transaction to Hive
    await _transactionBox.put(txn.id, txn);

    // Update customer balance
    final customer = getCustomerById(customerId);
    if (customer != null) {
      customer.currentBalance = txn.balanceAfter;
      customer.lastTransactionAt = txn.timestamp;
      customer.synced = true;
      await customer.save();
    }

    // Update daily summary
    await _updateDailySummary(
      customerId,
      txn.timestamp,
      txn.type,
      txn.totalAmount,
      txn.balanceAfter,
    );
  }

  /// Undo the last transaction for a customer (soft delete + reverse balance)
  Future<TransactionModel?> undoLastTransaction(String customerId) async {
    final txns = getTransactionsForCustomer(customerId);
    if (txns.isEmpty) return null;

    final lastTxn = txns.first;
    final customer = getCustomerById(customerId);
    if (customer == null) return null;

    // Reverse the balance change using centralized LedgerRules
    customer.currentBalance = LedgerRules.reverseBalance(
      customer.currentBalance,
      lastTxn.transactionType,
      lastTxn.totalAmount,
    );
    customer.synced = false;
    await customer.save();

    // Soft-delete the transaction
    lastTxn.isDeleted = true;
    await lastTxn.save();

    // Update daily summary
    await _rebuildDailySummary(customerId, lastTxn.timestamp);

    return lastTxn;
  }

  // ─── Daily Summary Operations ────────────────────────────────

  DailySummaryModel? getDailySummary(String customerId, DateTime date) {
    final key = '${customerId}_${_dateKey(date)}';
    return _summaryBox.get(key);
  }

  List<DailySummaryModel> getSummariesForCustomer(String customerId) {
    return _summaryBox.values
        .where((s) => s.customerId == customerId)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  /// Group transactions by date for timeline view
  Map<String, List<TransactionModel>> getGroupedTransactions(
      String customerId) {
    final txns = getTransactionsForCustomer(customerId);
    final grouped = <String, List<TransactionModel>>{};

    for (final txn in txns) {
      final key = _dateKey(txn.timestamp);
      grouped.putIfAbsent(key, () => []).add(txn);
    }

    return grouped;
  }

  // ─── Export / Backup ─────────────────────────────────────────

  Map<String, dynamic> exportCustomerStatement(String customerId) {
    final customer = getCustomerById(customerId);
    if (customer == null) return {};

    final txns = getTransactionsForCustomer(customerId);
    final summaries = getSummariesForCustomer(customerId);

    return {
      'customer': {
        'id': customer.id,
        'name': customer.name,
        'phone': customer.phone,
        'currentBalance': customer.currentBalance,
        'creditLimit': customer.creditLimit,
        'trustScore': customer.trustScore,
      },
      'transactions': txns
          .map((t) => {
                'id': t.id,
                'type': t.isCredit ? 'credit' : 'debit',
                'amount': t.totalAmount,
                'description': t.description,
                'timestamp': t.timestamp.toIso8601String(),
                'balanceAfter': t.balanceAfter,
                'items': t.items
                    .map((i) => {
                          'name': i.name,
                          'price': i.price,
                          'qty': i.quantity,
                        })
                    .toList(),
              })
          .toList(),
      'dailySummaries': summaries
          .map((s) => {
                'date': s.dateKey,
                'credit': s.totalCredit,
                'payment': s.totalPayment,
                'net': s.netAmount,
                'txnCount': s.transactionCount,
              })
          .toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> exportFullBackup() {
    final customers = getAllCustomers();
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'customers': customers
          .map((c) => exportCustomerStatement(c.id))
          .toList(),
    };
  }

  // ─── Internal Helpers ────────────────────────────────────────

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _updateDailySummary(
    String customerId,
    DateTime date,
    int type,
    double amount,
    double closingBalance,
  ) async {
    final key = '${customerId}_${_dateKey(date)}';
    var summary = _summaryBox.get(key);

    if (summary == null) {
      // First transaction today — opening balance was before this txn
      final openingBalance =
          type == 0 ? closingBalance - amount : closingBalance + amount;
      summary = DailySummaryModel(
        id: key,
        customerId: customerId,
        dateKey: _dateKey(date),
        totalCredit: type == 0 ? amount : 0,
        totalPayment: type == 1 ? amount : 0,
        transactionCount: 1,
        openingBalance: openingBalance,
        closingBalance: closingBalance,
      );
    } else {
      if (type == 0) {
        summary.totalCredit += amount;
      } else {
        summary.totalPayment += amount;
      }
      summary.transactionCount += 1;
      summary.closingBalance = closingBalance;
    }

    await _summaryBox.put(key, summary);
  }

  Future<void> _rebuildDailySummary(
    String customerId,
    DateTime date,
  ) async {
    final key = '${customerId}_${_dateKey(date)}';
    final txns = getTransactionsForDate(customerId, date);

    if (txns.isEmpty) {
      await _summaryBox.delete(key);
      return;
    }

    // Sort oldest first for recalculation
    txns.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalCredit = 0;
    double totalPayment = 0;
    for (final t in txns) {
      if (t.isCredit) {
        totalCredit += t.totalAmount;
      } else {
        totalPayment += t.totalAmount;
      }
    }

    final openingBalance = txns.first.balanceAfter -
        (txns.first.isCredit
            ? txns.first.totalAmount
            : -txns.first.totalAmount);

    final summary = DailySummaryModel(
      id: key,
      customerId: customerId,
      dateKey: _dateKey(date),
      totalCredit: totalCredit,
      totalPayment: totalPayment,
      transactionCount: txns.length,
      openingBalance: openingBalance,
      closingBalance: txns.last.balanceAfter,
    );

    await _summaryBox.put(key, summary);
  }
}
