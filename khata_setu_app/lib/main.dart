import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/di/injection.dart';
import 'core/data/hive_initializer.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/settings/presentation/bloc/theme_cubit.dart';
import 'features/settings/presentation/bloc/language_cubit.dart';
import 'features/customers/presentation/bloc/customer_bloc.dart';
import 'features/ledger/presentation/bloc/transaction_bloc.dart';
import 'features/inventory/presentation/bloc/inventory_bloc.dart';
import 'features/upi/presentation/bloc/shop_upi_cubit.dart';
import 'features/daily_notebook/presentation/bloc/daily_note_bloc.dart';
import 'features/home/presentation/bloc/dashboard_cubit.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_event.dart';
import 'features/sync/presentation/bloc/sync_cubit.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Create FlutterSecureStorage instance for Hive encryption key
  FlutterSecureStorage secureStorage;
  if (kIsWeb) {
    secureStorage = const FlutterSecureStorage();
  } else {
    secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    );
  }

  // Register Hive adapters and open encrypted boxes
  await HiveInitializer.init(secureStorage);

  // Initialize dependency injection
  await configureDependencies();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const KhataSetuApp());
}

class KhataSetuApp extends StatelessWidget {
  const KhataSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<ThemeCubit>()),
        BlocProvider(create: (_) => getIt<LanguageCubit>()),
        BlocProvider(create: (_) => getIt<CustomerBloc>()),
        BlocProvider(create: (_) => getIt<TransactionBloc>()),
        BlocProvider(create: (_) => getIt<InventoryBloc>()),
        BlocProvider(create: (_) => getIt<ShopUpiCubit>()),
        BlocProvider(create: (_) => getIt<DailyNoteBloc>()),
        BlocProvider(create: (_) => getIt<DashboardCubit>()),
        BlocProvider(create: (_) => getIt<NotificationBloc>()..add(const LoadNotifications())),
        BlocProvider(create: (_) => getIt<SyncCubit>()),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp.router(
                title: 'KhataSetu',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                themeAnimationDuration: const Duration(milliseconds: 400),
                themeAnimationCurve: Curves.easeInOut,
                locale: locale,
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                routerConfig: AppRouter.router,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.noScaling,
                    ),
                    child: child!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
