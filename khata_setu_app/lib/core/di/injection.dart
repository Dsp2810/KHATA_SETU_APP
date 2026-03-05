import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../network/dio_client.dart';
import '../network/api_service.dart';
import '../storage/secure_storage.dart';
import '../storage/local_storage.dart';
import '../services/cart_manager.dart';
import '../data/datasources/udhar_local_datasource.dart';
import '../data/datasources/udhar_remote_datasource.dart';
import '../data/repositories/udhar_repository.dart';
import '../../features/settings/presentation/bloc/theme_cubit.dart';
import '../../features/customers/presentation/bloc/customer_bloc.dart';
import '../../features/ledger/presentation/bloc/transaction_bloc.dart';
import '../data/datasources/product_local_datasource.dart';
import '../data/datasources/product_remote_datasource.dart';
import '../data/repositories/product_repository.dart';
import '../../features/inventory/presentation/bloc/inventory_bloc.dart';
import '../data/datasources/shop_upi_local_datasource.dart';
import '../data/repositories/shop_upi_repository.dart';
import '../../features/upi/presentation/bloc/shop_upi_cubit.dart';
import '../../features/settings/presentation/bloc/language_cubit.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../services/sync_service.dart';
import '../services/sync_service_v2.dart' as v2;
import '../services/connectivity_service.dart';
import '../data/datasources/sync_queue_local_datasource.dart';
import '../data/datasources/daily_note_local_datasource.dart';
import '../data/datasources/daily_note_remote_datasource.dart';
import '../data/repositories/daily_note_repository.dart';
import '../../features/daily_notebook/presentation/bloc/daily_note_bloc.dart';
import '../../features/home/presentation/bloc/dashboard_cubit.dart';
import '../data/datasources/notification_local_datasource.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/sync/presentation/bloc/sync_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // FlutterSecureStorage - handle web platform
  FlutterSecureStorage flutterSecureStorage;
  if (kIsWeb) {
    flutterSecureStorage = const FlutterSecureStorage();
  } else {
    flutterSecureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    );
  }
  getIt.registerSingleton<FlutterSecureStorage>(flutterSecureStorage);

  // Storage
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(getIt<FlutterSecureStorage>()),
  );
  getIt.registerLazySingleton<LocalStorageService>(
    () => LocalStorageService(getIt<SharedPreferences>()),
  );

  // Theme Cubit - Register early since it's needed at app start
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<LocalStorageService>()),
  );

  // Language Cubit - Register early for locale at app start
  getIt.registerLazySingleton<LanguageCubit>(
    () => LanguageCubit(getIt<LocalStorageService>()),
  );

  // Cart Manager - Singleton for POS/Billing
  getIt.registerLazySingleton<CartManager>(() => CartManager());

  // Connectivity
  final connectivityService = ConnectivityService();
  await connectivityService.init();
  getIt.registerSingleton<ConnectivityService>(connectivityService);

  // Sync Queue (Hive-backed)
  getIt.registerLazySingleton<SyncQueueLocalDataSource>(
    () => SyncQueueLocalDataSource(),
  );

  // Sync Service v2 (queue-based)
  getIt.registerLazySingleton<v2.SyncService>(
    () => v2.SyncService(
      queue: getIt<SyncQueueLocalDataSource>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  // Sync Cubit — UI state for sync banner
  getIt.registerLazySingleton<SyncCubit>(
    () => SyncCubit(getIt<v2.SyncService>()),
  );

  // Network
  getIt.registerLazySingleton<Dio>(() => DioClient.createDio(getIt<SecureStorageService>()));

  // Register feature-specific dependencies
  await _registerFeatureDependencies();
}

Future<void> _registerFeatureDependencies() async {
  // Auth
  await _registerAuthDependencies();

  // Customer
  await _registerCustomerDependencies();

  // Ledger
  await _registerLedgerDependencies();

  // Inventory
  await _registerInventoryDependencies();

  // UPI
  await _registerUpiDependencies();

  // Settings
  await _registerSettingsDependencies();

  // Daily Notebook
  await _registerDailyNoteDependencies();

  // Notifications
  await _registerNotificationDependencies();
}

Future<void> _registerAuthDependencies() async {
  // API Service (depends on Dio)
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(getIt<Dio>()),
  );

  // Auth BLoC (singleton — shared across splash, login, register)
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      apiService: getIt<ApiService>(),
      secureStorage: getIt<SecureStorageService>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  // Dashboard Cubit — loads shop info for dashboard page
  getIt.registerLazySingleton<DashboardCubit>(
    () => DashboardCubit(
      secureStorage: getIt<SecureStorageService>(),
      apiService: getIt<ApiService>(),
    ),
  );
}

Future<void> _registerCustomerDependencies() async {
  // Data Sources
  getIt.registerLazySingleton<UdharLocalDataSource>(
    () => UdharLocalDataSource(),
  );

  // Remote datasource is registered dynamically after login
  // (once we have the shopId). See registerRemoteDatasource().

  // Repositories
  getIt.registerLazySingleton<UdharRepository>(
    () => UdharRepository(getIt<UdharLocalDataSource>()),
  );

  // BLoCs — Singleton so all pages share the same instance
  getIt.registerLazySingleton<CustomerBloc>(
    () => CustomerBloc(getIt<UdharRepository>()),
  );
}

/// Call after login to wire up the remote datasource with the shopId.
/// Updates existing BLoC instances with new remote-capable repositories.
/// This avoids re-registering BLoCs, which would break MultiBlocProvider
/// references in the widget tree.
Future<void> registerRemoteDatasource(String shopId) async {
  final api = getIt<ApiService>();

  // ── Udhar: Register or replace the remote datasource ──
  if (getIt.isRegistered<UdharRemoteDataSource>()) {
    getIt.unregister<UdharRemoteDataSource>();
  }
  getIt.registerLazySingleton<UdharRemoteDataSource>(
    () => UdharRemoteDataSource(api, shopId),
  );

  // Re-create the repository with remote + sync queue support
  if (getIt.isRegistered<UdharRepository>()) {
    getIt.unregister<UdharRepository>();
  }
  getIt.registerLazySingleton<UdharRepository>(
    () => UdharRepository(
      getIt<UdharLocalDataSource>(),
      getIt<UdharRemoteDataSource>(),
      getIt<SyncQueueLocalDataSource>(),
    )..setShopId(shopId),
  );

  // Hot-swap repository into existing BLoC instances (keeps widget tree intact)
  final udharRepo = getIt<UdharRepository>();
  getIt<CustomerBloc>().updateRepository(udharRepo);
  getIt<TransactionBloc>().updateRepository(udharRepo);

  // ── Old SyncService (udhar-only periodic) — dispose if exists ──
  if (getIt.isRegistered<SyncService>()) {
    getIt<SyncService>().dispose();
    getIt.unregister<SyncService>();
  }

  // ── New SyncService v2: wire datasources + start ──
  final syncServiceV2 = getIt<v2.SyncService>();
  syncServiceV2.setUdharDatasources(
    getIt<UdharLocalDataSource>(),
    getIt<UdharRemoteDataSource>(),
  );

  // ── Inventory: Register remote datasource & re-create repository ──
  if (getIt.isRegistered<ProductRemoteDataSource>()) {
    getIt.unregister<ProductRemoteDataSource>();
  }
  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSource(api, shopId),
  );

  if (getIt.isRegistered<ProductRepository>()) {
    getIt.unregister<ProductRepository>();
  }
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepository(
      getIt<ProductLocalDataSource>(),
      getIt<ProductRemoteDataSource>(),
      getIt<SyncQueueLocalDataSource>(),
    )..setShopId(shopId),
  );

  // Hot-swap repository into existing InventoryBloc
  getIt<InventoryBloc>().updateRepository(getIt<ProductRepository>());

  // Wire product datasources into SyncService v2
  syncServiceV2.setProductDatasources(
    getIt<ProductLocalDataSource>(),
    getIt<ProductRemoteDataSource>(),
  );

  // ── Daily Notes: Register remote datasource & re-create repository ──
  if (getIt.isRegistered<DailyNoteRemoteDataSource>()) {
    getIt.unregister<DailyNoteRemoteDataSource>();
  }
  getIt.registerLazySingleton<DailyNoteRemoteDataSource>(
    () => DailyNoteRemoteDataSource(api, shopId),
  );

  if (getIt.isRegistered<DailyNoteRepository>()) {
    getIt.unregister<DailyNoteRepository>();
  }
  getIt.registerLazySingleton<DailyNoteRepository>(
    () => DailyNoteRepository(
      getIt<DailyNoteLocalDataSource>(),
      getIt<DailyNoteRemoteDataSource>(),
      getIt<SyncQueueLocalDataSource>(),
    )..setShopId(shopId),
  );

  // Hot-swap repository into existing DailyNoteBloc
  getIt<DailyNoteBloc>().updateRepository(getIt<DailyNoteRepository>());

  // Wire daily note datasources into SyncService v2
  syncServiceV2.setDailyNoteDatasources(
    getIt<DailyNoteLocalDataSource>(),
    getIt<DailyNoteRemoteDataSource>(),
  );

  // ── Start SyncService v2 ──
  syncServiceV2.start();
}

Future<void> _registerLedgerDependencies() async {
  // TransactionBloc — Singleton, shares the same UdharRepository
  getIt.registerLazySingleton<TransactionBloc>(
    () {
      final bloc = TransactionBloc(getIt<UdharRepository>());
      return bloc;
    },
  );
}

Future<void> _registerInventoryDependencies() async {
  // Data Sources
  getIt.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSource(),
  );

  // Repository (local-only until login provides shopId)
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepository(getIt<ProductLocalDataSource>()),
  );

  // BLoC — Singleton so all pages share the same instance
  getIt.registerLazySingleton<InventoryBloc>(
    () => InventoryBloc(getIt<ProductRepository>()),
  );
}

Future<void> _registerUpiDependencies() async {
  // Data Sources
  getIt.registerLazySingleton<ShopUpiLocalDataSource>(
    () => ShopUpiLocalDataSource(),
  );

  // Repositories
  getIt.registerLazySingleton<ShopUpiRepository>(
    () => ShopUpiRepository(getIt<ShopUpiLocalDataSource>()),
  );

  // Cubit — Singleton so all pages share the same instance
  getIt.registerLazySingleton<ShopUpiCubit>(
    () => ShopUpiCubit(getIt<ShopUpiRepository>()),
  );
}

Future<void> _registerDailyNoteDependencies() async {
  // Data Sources
  getIt.registerLazySingleton<DailyNoteLocalDataSource>(
    () => DailyNoteLocalDataSource(),
  );

  // Repository (local-only until login provides shopId)
  getIt.registerLazySingleton<DailyNoteRepository>(
    () => DailyNoteRepository(getIt<DailyNoteLocalDataSource>()),
  );

  // BLoC — Singleton so all pages share the same instance
  getIt.registerLazySingleton<DailyNoteBloc>(
    () => DailyNoteBloc(
      noteRepository: getIt<DailyNoteRepository>(),
    ),
  );
}

Future<void> _registerSettingsDependencies() async {
  // ThemeCubit is registered in configureDependencies() since it's needed at app start
}

Future<void> _registerNotificationDependencies() async {
  // Data Sources
  getIt.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSource(),
  );

  // BLoC — Singleton so badge count is shared across app
  getIt.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(
      dataSource: getIt<NotificationLocalDataSource>(),
    ),
  );
}
