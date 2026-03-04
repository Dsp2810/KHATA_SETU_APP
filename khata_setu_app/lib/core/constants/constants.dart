class ApiConstants {
  ApiConstants._();

  // Environment flag - pass via: flutter run --dart-define=ENV=prod
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  // Base URLs per environment
  static const String _devBaseUrl = 'http://192.168.0.122:3000/api/v1';
  static const String _dockerBaseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator → host Docker
  static const String _prodBaseUrl = 'https://khata-setu-app.onrender.com/api/v1';

  /// Active base URL - automatically selected by ENV:
  ///   flutter run --dart-define=ENV=dev       → local LAN IP (default)
  ///   flutter run --dart-define=ENV=docker    → 10.0.2.2 (emulator → host Docker)
  ///   flutter run --dart-define=ENV=prod      → production HTTPS
  static String get baseUrl {
    switch (_env) {
      case 'prod':
        return _prodBaseUrl;
      case 'docker':
        return _dockerBaseUrl;
      default:
        return _devBaseUrl;
    }
  }

  static bool get isProduction => _env == 'prod';

  // Timeouts — 60s to handle Render free-tier cold starts (~30-50s)
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  // Headers
  static const String contentType = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String shopIdHeader = 'X-Shop-Id';
}

class StorageKeys {
  StorageKeys._();

  // Auth
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userData = 'user_data';

  // User Profile
  static const String userName = 'user_name';
  static const String userPhone = 'user_phone';

  // Shop
  static const String activeShopId = 'active_shop_id';
  static const String activeShopName = 'shop_name';
  static const String shopsList = 'shops_list';

  // Settings
  static const String themeMode = 'theme_mode';
  static const String language = 'language';

  // Offline
  static const String pendingSyncQueue = 'pending_sync_queue';
  static const String lastSyncTime = 'last_sync_time';
}

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'KhataSetu';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int phoneLength = 10;

  // Timeouts
  static const Duration sessionTimeout = Duration(minutes: 15);
  static const Duration syncInterval = Duration(minutes: 5);

  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd/MM/yyyy hh:mm a';

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Limits
  static const double maxTransactionAmount = 10000000; // 1 Crore
  static const int maxCustomersPerShop = 10000;
  static const int maxProductsPerShop = 50000;
}

class RouteConstants {
  RouteConstants._();

  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Main Routes
  static const String dashboard = '/dashboard';

  // Customer Routes
  static const String customers = '/customers';
  static const String customerDetails = '/customers/:id';
  static const String addCustomer = '/customers/add';
  static const String editCustomer = '/customers/:id/edit';

  // Ledger Routes
  static const String ledger = '/ledger';
  static const String addTransaction = '/ledger/add';

  // Billing Routes
  static const String billing = '/billing';

  // Inventory Routes
  static const String inventory = '/inventory';
  static const String addProduct = '/inventory/add';

  // Reports Routes
  static const String reports = '/reports';

  // Settings Routes
  static const String settings = '/settings';

  // Notifications Route
  static const String notifications = '/notifications';

  // UPI Routes
  static const String upiSetup = '/settings/upi-setup';
  static const String upiQrDisplay = '/upi-qr';

  // Daily Notebook Routes
  static const String dailyNotebook = '/daily-notebook';
}
