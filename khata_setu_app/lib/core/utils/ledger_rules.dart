/// Unified transaction type enum for entire application.
/// 
/// Accounting Rule:
/// - [credit]: Customer takes goods on credit (udhar) → balance INCREASES
/// - [payment]: Customer pays money → balance DECREASES
/// 
/// NOTE: "Credit" here is from the shopkeeper's perspective - money owed TO the shop.
/// When customer takes goods without paying, they owe more (credit increases balance).
/// When customer pays, the debt reduces (payment decreases balance).
enum TransactionType {
  /// Customer takes goods on credit (udhar given).
  /// Balance increases - customer owes more.
  credit,

  /// Customer pays money (payment received).
  /// Balance decreases - customer owes less.
  payment,
}

/// Extension methods for [TransactionType]
extension TransactionTypeX on TransactionType {
  /// Convert to int for Hive storage (0 = credit, 1 = payment)
  int toInt() => this == TransactionType.credit ? 0 : 1;

  /// Human-readable label
  String get label => this == TransactionType.credit ? 'Credit (Udhar)' : 'Payment';

  /// Short label for UI badges
  String get shortLabel => this == TransactionType.credit ? 'CR' : 'PMT';

  /// Whether this transaction increases balance
  bool get increasesBalance => this == TransactionType.credit;

  /// Whether this transaction decreases balance
  bool get decreasesBalance => this == TransactionType.payment;

  /// String key for API/storage
  String get key => name; // 'credit' or 'payment'
}

/// Factory for creating [TransactionType] from various sources
extension TransactionTypeFactory on TransactionType {
  /// Create from int (Hive storage format)
  /// 0 = credit, 1 = payment
  static TransactionType fromInt(int value) {
    return value == 0 ? TransactionType.credit : TransactionType.payment;
  }

  /// Create from string key ('credit' or 'payment')
  /// Also handles legacy values: 'debit' → payment, 'CR' → credit, 'DR' → payment
  static TransactionType fromString(String value) {
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'credit':
      case 'cr':
      case 'udhar':
        return TransactionType.credit;
      case 'payment':
      case 'debit':
      case 'dr':
      case 'pmt':
        return TransactionType.payment;
      default:
        // Default to credit if unknown
        return TransactionType.credit;
    }
  }
}

/// Centralized ledger accounting rules.
/// 
/// All balance calculations MUST use this class to ensure consistency
/// across UI, BLoC, Dashboard, and PDF generation.
class LedgerRules {
  LedgerRules._(); // Private constructor - use static methods only

  /// Calculate new balance after a transaction.
  /// 
  /// [currentBalance] - Current customer balance (positive = owes money)
  /// [type] - Transaction type (credit or payment)
  /// [amount] - Transaction amount (always positive)
  /// 
  /// Returns the new balance after applying the transaction.
  /// 
  /// Example:
  /// ```dart
  /// // Customer takes ₹1000 goods on credit
  /// final newBalance = LedgerRules.calculateBalance(0, TransactionType.credit, 1000);
  /// // newBalance = 1000 (customer owes ₹1000)
  /// 
  /// // Customer pays ₹300
  /// final finalBalance = LedgerRules.calculateBalance(1000, TransactionType.payment, 300);
  /// // finalBalance = 700 (customer now owes ₹700)
  /// ```
  static double calculateBalance(
    double currentBalance,
    TransactionType type,
    double amount,
  ) {
    assert(amount >= 0, 'Transaction amount must be non-negative');
    
    return type == TransactionType.credit
        ? currentBalance + amount  // Credit increases balance
        : currentBalance - amount; // Payment decreases balance
  }

  /// Calculate balance reversal (for undo operations).
  /// 
  /// Reverses the effect of a transaction on the balance.
  static double reverseBalance(
    double currentBalance,
    TransactionType type,
    double amount,
  ) {
    // Reverse is the opposite operation
    return type == TransactionType.credit
        ? currentBalance - amount  // Undo credit = subtract
        : currentBalance + amount; // Undo payment = add back
  }

  /// Calculate total credit from a list of transactions.
  static double totalCredit(List<({TransactionType type, double amount})> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate total payments from a list of transactions.
  static double totalPayments(List<({TransactionType type, double amount})> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.payment)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate net balance from transactions (credit - payments).
  static double netBalance(List<({TransactionType type, double amount})> transactions) {
    return totalCredit(transactions) - totalPayments(transactions);
  }

  /// Validate that a payment doesn't exceed the current balance.
  /// Returns null if valid, or an error message if invalid.
  static String? validatePayment(double currentBalance, double paymentAmount) {
    if (paymentAmount <= 0) {
      return 'Payment amount must be greater than zero';
    }
    // Note: We allow overpayment (advance) - returns negative balance
    return null;
  }

  /// Check if customer has outstanding balance (owes money).
  static bool hasOutstandingBalance(double balance) => balance > 0;

  /// Check if customer has advance payment (credit balance).
  static bool hasAdvancePayment(double balance) => balance < 0;

  /// Format balance for display with appropriate sign.
  static String formatBalance(double balance, {String currencySymbol = '₹'}) {
    final absBalance = balance.abs();
    if (balance > 0) {
      return '$currencySymbol${absBalance.toStringAsFixed(2)} Due';
    } else if (balance < 0) {
      return '$currencySymbol${absBalance.toStringAsFixed(2)} Advance';
    }
    return '$currencySymbol 0.00';
  }
}
