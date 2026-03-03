# KhataSetu - Flutter Clean Architecture Folder Structure

## 📁 Complete Folder Structure

```
khatasetu_app/
├── android/                          # Android native code
├── ios/                              # iOS native code
├── lib/
│   ├── main.dart                     # App entry point
│   ├── app.dart                      # MaterialApp configuration
│   │
│   ├── core/                         # Core utilities & shared code
│   │   ├── constants/
│   │   │   ├── app_constants.dart    # App-wide constants
│   │   │   ├── api_constants.dart    # API endpoints
│   │   │   ├── storage_keys.dart     # Hive box keys
│   │   │   └── asset_paths.dart      # Asset file paths
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart        # ThemeData configuration
│   │   │   ├── app_colors.dart       # Color palette
│   │   │   ├── app_text_styles.dart  # Typography
│   │   │   └── app_dimensions.dart   # Spacing & sizing
│   │   │
│   │   ├── utils/
│   │   │   ├── validators.dart       # Input validation
│   │   │   ├── formatters.dart       # Date, currency formatters
│   │   │   ├── helpers.dart          # Utility functions
│   │   │   ├── extensions.dart       # Dart extensions
│   │   │   └── logger.dart           # Logging utility
│   │   │
│   │   ├── errors/
│   │   │   ├── exceptions.dart       # Custom exceptions
│   │   │   └── failures.dart         # Failure classes
│   │   │
│   │   ├── network/
│   │   │   ├── api_client.dart       # Dio client setup
│   │   │   ├── api_interceptors.dart # Auth, logging interceptors
│   │   │   └── network_info.dart     # Connectivity checker
│   │   │
│   │   └── usecases/
│   │       └── usecase.dart          # Base UseCase class
│   │
│   ├── config/
│   │   ├── routes/
│   │   │   ├── app_router.dart       # GoRouter configuration
│   │   │   └── route_names.dart      # Route name constants
│   │   │
│   │   ├── di/
│   │   │   └── injection_container.dart # GetIt dependency injection
│   │   │
│   │   └── env/
│   │       ├── env_config.dart       # Environment configuration
│   │       └── app_config.dart       # Build-specific config
│   │
│   ├── data/                         # Data Layer
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   ├── auth_local_datasource.dart
│   │   │   │   ├── customer_local_datasource.dart
│   │   │   │   ├── ledger_local_datasource.dart
│   │   │   │   ├── product_local_datasource.dart
│   │   │   │   └── sync_queue_datasource.dart
│   │   │   │
│   │   │   └── remote/
│   │   │       ├── auth_remote_datasource.dart
│   │   │       ├── customer_remote_datasource.dart
│   │   │       ├── ledger_remote_datasource.dart
│   │   │       ├── product_remote_datasource.dart
│   │   │       ├── shop_remote_datasource.dart
│   │   │       ├── reminder_remote_datasource.dart
│   │   │       └── report_remote_datasource.dart
│   │   │
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── shop_model.dart
│   │   │   ├── customer_model.dart
│   │   │   ├── ledger_entry_model.dart
│   │   │   ├── product_model.dart
│   │   │   ├── reminder_model.dart
│   │   │   ├── sync_queue_model.dart
│   │   │   └── api_response_model.dart
│   │   │
│   │   └── repositories/
│   │       ├── auth_repository_impl.dart
│   │       ├── customer_repository_impl.dart
│   │       ├── ledger_repository_impl.dart
│   │       ├── product_repository_impl.dart
│   │       ├── shop_repository_impl.dart
│   │       ├── reminder_repository_impl.dart
│   │       └── sync_repository_impl.dart
│   │
│   ├── domain/                       # Domain Layer
│   │   ├── entities/
│   │   │   ├── user.dart
│   │   │   ├── shop.dart
│   │   │   ├── customer.dart
│   │   │   ├── ledger_entry.dart
│   │   │   ├── product.dart
│   │   │   ├── reminder.dart
│   │   │   └── dashboard_stats.dart
│   │   │
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── customer_repository.dart
│   │   │   ├── ledger_repository.dart
│   │   │   ├── product_repository.dart
│   │   │   ├── shop_repository.dart
│   │   │   ├── reminder_repository.dart
│   │   │   └── sync_repository.dart
│   │   │
│   │   └── usecases/
│   │       ├── auth/
│   │       │   ├── login_usecase.dart
│   │       │   ├── register_usecase.dart
│   │       │   ├── logout_usecase.dart
│   │       │   └── refresh_token_usecase.dart
│   │       │
│   │       ├── customer/
│   │       │   ├── get_customers_usecase.dart
│   │       │   ├── get_customer_usecase.dart
│   │       │   ├── create_customer_usecase.dart
│   │       │   ├── update_customer_usecase.dart
│   │       │   └── delete_customer_usecase.dart
│   │       │
│   │       ├── ledger/
│   │       │   ├── get_ledger_entries_usecase.dart
│   │       │   ├── create_credit_entry_usecase.dart
│   │       │   ├── create_debit_entry_usecase.dart
│   │       │   └── delete_entry_usecase.dart
│   │       │
│   │       ├── product/
│   │       │   ├── get_products_usecase.dart
│   │       │   ├── create_product_usecase.dart
│   │       │   ├── update_product_usecase.dart
│   │       │   ├── adjust_stock_usecase.dart
│   │       │   └── search_by_barcode_usecase.dart
│   │       │
│   │       ├── shop/
│   │       │   ├── get_dashboard_stats_usecase.dart
│   │       │   ├── get_shops_usecase.dart
│   │       │   ├── create_shop_usecase.dart
│   │       │   └── update_shop_settings_usecase.dart
│   │       │
│   │       ├── reminder/
│   │       │   ├── get_reminders_usecase.dart
│   │       │   ├── send_reminder_usecase.dart
│   │       │   └── get_reminder_suggestions_usecase.dart
│   │       │
│   │       └── sync/
│   │           ├── sync_data_usecase.dart
│   │           └── get_sync_status_usecase.dart
│   │
│   ├── presentation/                 # Presentation Layer
│   │   ├── blocs/
│   │   │   ├── auth/
│   │   │   │   ├── auth_bloc.dart
│   │   │   │   ├── auth_event.dart
│   │   │   │   └── auth_state.dart
│   │   │   │
│   │   │   ├── customer/
│   │   │   │   ├── customer_bloc.dart
│   │   │   │   ├── customer_event.dart
│   │   │   │   └── customer_state.dart
│   │   │   │
│   │   │   ├── ledger/
│   │   │   │   ├── ledger_bloc.dart
│   │   │   │   ├── ledger_event.dart
│   │   │   │   └── ledger_state.dart
│   │   │   │
│   │   │   ├── product/
│   │   │   │   ├── product_bloc.dart
│   │   │   │   ├── product_event.dart
│   │   │   │   └── product_state.dart
│   │   │   │
│   │   │   ├── dashboard/
│   │   │   │   ├── dashboard_bloc.dart
│   │   │   │   ├── dashboard_event.dart
│   │   │   │   └── dashboard_state.dart
│   │   │   │
│   │   │   ├── reminder/
│   │   │   │   ├── reminder_bloc.dart
│   │   │   │   ├── reminder_event.dart
│   │   │   │   └── reminder_state.dart
│   │   │   │
│   │   │   ├── theme/
│   │   │   │   └── theme_cubit.dart
│   │   │   │
│   │   │   └── sync/
│   │   │       └── sync_cubit.dart
│   │   │
│   │   ├── pages/
│   │   │   ├── splash/
│   │   │   │   └── splash_page.dart
│   │   │   │
│   │   │   ├── onboarding/
│   │   │   │   └── onboarding_page.dart
│   │   │   │
│   │   │   ├── auth/
│   │   │   │   ├── login_page.dart
│   │   │   │   ├── register_page.dart
│   │   │   │   └── forgot_password_page.dart
│   │   │   │
│   │   │   ├── dashboard/
│   │   │   │   ├── dashboard_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── stat_card.dart
│   │   │   │       ├── revenue_chart.dart
│   │   │   │       ├── low_stock_alert.dart
│   │   │   │       └── top_defaulters.dart
│   │   │   │
│   │   │   ├── customers/
│   │   │   │   ├── customer_list_page.dart
│   │   │   │   ├── customer_detail_page.dart
│   │   │   │   ├── add_customer_page.dart
│   │   │   │   ├── edit_customer_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── customer_card.dart
│   │   │   │       └── customer_filter_chips.dart
│   │   │   │
│   │   │   ├── ledger/
│   │   │   │   ├── ledger_page.dart
│   │   │   │   ├── add_credit_page.dart
│   │   │   │   ├── add_payment_page.dart
│   │   │   │   ├── transaction_detail_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── transaction_card.dart
│   │   │   │       └── item_selector.dart
│   │   │   │
│   │   │   ├── payment/
│   │   │   │   ├── payment_collection_page.dart
│   │   │   │   ├── receipt_page.dart
│   │   │   │   └── upi_setup_page.dart
│   │   │   │
│   │   │   ├── inventory/
│   │   │   │   ├── inventory_list_page.dart
│   │   │   │   ├── product_detail_page.dart
│   │   │   │   ├── add_product_page.dart
│   │   │   │   ├── edit_product_page.dart
│   │   │   │   ├── stock_adjustment_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── product_card.dart
│   │   │   │       └── stock_indicator.dart
│   │   │   │
│   │   │   ├── reminders/
│   │   │   │   ├── reminder_dashboard_page.dart
│   │   │   │   ├── send_reminder_page.dart
│   │   │   │   └── reminder_settings_page.dart
│   │   │   │
│   │   │   ├── reports/
│   │   │   │   ├── reports_dashboard_page.dart
│   │   │   │   ├── customer_report_page.dart
│   │   │   │   ├── inventory_report_page.dart
│   │   │   │   ├── payment_heatmap_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── pie_chart_widget.dart
│   │   │   │       ├── line_chart_widget.dart
│   │   │   │       └── bar_chart_widget.dart
│   │   │   │
│   │   │   ├── settings/
│   │   │   │   ├── settings_page.dart
│   │   │   │   ├── profile_settings_page.dart
│   │   │   │   ├── shop_settings_page.dart
│   │   │   │   ├── language_settings_page.dart
│   │   │   │   └── backup_restore_page.dart
│   │   │   │
│   │   │   └── notifications/
│   │   │       └── notifications_page.dart
│   │   │
│   │   └── widgets/
│   │       ├── common/
│   │       │   ├── app_button.dart
│   │       │   ├── app_text_field.dart
│   │       │   ├── app_card.dart
│   │       │   ├── app_loading.dart
│   │       │   ├── app_error.dart
│   │       │   ├── app_empty_state.dart
│   │       │   ├── app_snackbar.dart
│   │       │   └── app_dialog.dart
│   │       │
│   │       ├── layout/
│   │       │   ├── app_scaffold.dart
│   │       │   ├── bottom_nav_bar.dart
│   │       │   ├── shop_switcher.dart
│   │       │   └── app_drawer.dart
│   │       │
│   │       └── inputs/
│   │           ├── amount_input.dart
│   │           ├── phone_input.dart
│   │           ├── date_picker.dart
│   │           └── dropdown_field.dart
│   │
│   ├── l10n/                         # Localization
│   │   ├── app_en.arb                # English strings
│   │   ├── app_gu.arb                # Gujarati strings
│   │   └── l10n.dart                 # Generated file
│   │
│   └── services/                     # App Services
│       ├── notification_service.dart
│       ├── biometric_service.dart
│       ├── pdf_service.dart
│       ├── share_service.dart
│       └── barcode_service.dart
│
├── test/                             # Tests
│   ├── unit/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── widget/
│   │   └── pages/
│   └── integration/
│
├── assets/                           # Assets
│   ├── images/
│   │   ├── logo.png
│   │   ├── onboarding/
│   │   └── empty_states/
│   ├── icons/
│   ├── fonts/
│   │   ├── Poppins/
│   │   └── NotoSansGujarati/
│   └── lottie/
│       ├── loading.json
│       └── success.json
│
├── pubspec.yaml                      # Dependencies
├── analysis_options.yaml             # Lint rules
└── README.md
```

---

## 📦 Key Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
    
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^7.6.4
  injectable: ^2.3.2
  
  # Navigation
  go_router: ^12.1.1
  
  # Network
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  
  # UI/UX
  fl_chart: ^0.65.0
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.9
  lottie: ^2.7.0
  
  # Utils
  intl: ^0.18.1
  uuid: ^4.2.1
  logger: ^2.0.2
  dartz: ^0.10.1
  
  # Services
  local_auth: ^2.1.8
  share_plus: ^7.2.1
  pdf: ^3.10.7
  printing: ^5.11.1
  barcode_scan2: ^4.3.0
  url_launcher: ^6.2.1
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.5
  mocktail: ^1.0.1
  build_runner: ^2.4.7
  injectable_generator: ^2.4.1
  hive_generator: ^2.0.1
  flutter_lints: ^3.0.1
```

---

## 🔧 Configuration Files

### analysis_options.yaml
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - prefer_single_quotes
    - sort_constructors_first
    - prefer_const_constructors
    - prefer_const_declarations
    - avoid_print
    - require_trailing_commas
```
