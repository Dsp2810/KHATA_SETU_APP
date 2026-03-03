/// Centralized API endpoint paths matching the backend routes.
/// Base URL is configured in [ApiConstants.baseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String changePassword = '/auth/change-password';
  static const String me = '/auth/me';
  static const String fcmToken = '/auth/fcm-token';

  // ─── Shops ───────────────────────────────────────────────────
  static const String shops = '/shops';
  static String shop(String shopId) => '/shops/$shopId';
  static String shopSettings(String shopId) => '/shops/$shopId/settings';
  static String employees(String shopId) => '/shops/$shopId/employees';

  // ─── Customers ───────────────────────────────────────────────
  static String customers(String shopId) => '/shops/$shopId/customers';
  static String customer(String shopId, String customerId) =>
      '/shops/$shopId/customers/$customerId';
  static String customerStats(String shopId, String customerId) =>
      '/shops/$shopId/customers/$customerId/stats';
  static String searchCustomers(String shopId) =>
      '/shops/$shopId/customers/search';

  // ─── Ledger ──────────────────────────────────────────────────
  static String ledger(String shopId) => '/shops/$shopId/ledger';
  static String ledgerEntry(String shopId, String entryId) =>
      '/shops/$shopId/ledger/$entryId';
  static String ledgerSummary(String shopId) =>
      '/shops/$shopId/ledger/summary';
  static String customerLedger(String shopId, String customerId) =>
      '/shops/$shopId/ledger/customers/$customerId';

  // ─── Products ────────────────────────────────────────────────
  static String products(String shopId) => '/shops/$shopId/products';
  static String product(String shopId, String productId) =>
      '/shops/$shopId/products/$productId';
  static String productBarcode(String shopId, String barcode) =>
      '/shops/$shopId/products/barcode/$barcode';
  static String productCategories(String shopId) =>
      '/shops/$shopId/products/categories';
  static String lowStockProducts(String shopId) =>
      '/shops/$shopId/products/low-stock';
  static String productStock(String shopId, String productId) =>
      '/shops/$shopId/products/$productId/stock';
  static String productStockHistory(String shopId, String productId) =>
      '/shops/$shopId/products/$productId/stock-history';

  // ─── Reports ─────────────────────────────────────────────────
  static String dashboard(String shopId) => '/shops/$shopId/reports/dashboard';
  static String ledgerReport(String shopId) => '/shops/$shopId/reports/ledger';
  static String inventoryReport(String shopId) =>
      '/shops/$shopId/reports/inventory';
  static String customerReport(String shopId) =>
      '/shops/$shopId/reports/customers';
  static String exportReport(String shopId, String type) =>
      '/shops/$shopId/reports/export/$type';

  // ─── Reminders ───────────────────────────────────────────────
  static String reminders(String shopId) => '/shops/$shopId/reminders';
  static String reminder(String shopId, String reminderId) =>
      '/shops/$shopId/reminders/$reminderId';
  static String todayReminders(String shopId) =>
      '/shops/$shopId/reminders/today';

  // ─── Daily Notes ───────────────────────────────────────────────
  static String notes(String shopId) => '/shops/$shopId/notes';
  static String note(String shopId, String noteId) =>
      '/shops/$shopId/notes/$noteId';
  static String noteComplete(String shopId, String noteId) =>
      '/shops/$shopId/notes/$noteId/complete';
  static String notesBulkComplete(String shopId) =>
      '/shops/$shopId/notes/bulk-complete';
  static String notesBulkDelete(String shopId) =>
      '/shops/$shopId/notes/bulk-delete';
  static String notesToday(String shopId) => '/shops/$shopId/notes/today';
  static String notesSummary(String shopId) => '/shops/$shopId/notes/summary';

  // ─── Sync ────────────────────────────────────────────────────
  static String sync(String shopId) => '/shops/$shopId/sync';
  static String syncChanges(String shopId) => '/shops/$shopId/sync/changes';
  static String syncStatus(String shopId) => '/shops/$shopId/sync/status';
}
