import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/constants.dart';
import '../utils/app_formatter.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/dashboard_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/customers/presentation/pages/customer_details_page.dart';
import '../../features/customers/presentation/pages/add_customer_page.dart';
import '../../features/customers/presentation/pages/edit_customer_page.dart';
import '../../features/ledger/presentation/pages/ledger_page.dart';
import '../../features/ledger/presentation/pages/add_transaction_page.dart';
import '../../features/ledger/presentation/pages/customer_timeline_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/inventory/presentation/pages/add_product_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/billing/presentation/pages/smart_billing_page.dart';
import '../../features/upi/presentation/pages/upi_setup_page.dart';
import '../../features/upi/presentation/pages/upi_qr_display_page.dart';
import '../../features/daily_notebook/presentation/pages/daily_notebook_page.dart';
import '../../features/daily_notebook/presentation/pages/daily_note_editor_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: false,
    routes: [
      // Splash
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // Auth Routes
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (context, state) => const RegisterPage(),
      ),

      // Shell Route for Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomePage(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: RouteConstants.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),

          // Customers
          GoRoute(
            path: RouteConstants.customers,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const CustomersPage(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AddCustomerPage(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CustomerDetailsPage(customerId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final customer = state.extra as dynamic;
                      return EditCustomerPage(customer: customer);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Ledger
          GoRoute(
            path: RouteConstants.ledger,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const LedgerPage(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  // Handle both Map extras (from bottom sheet) and String (backward compat)
                  String? customerId;
                  String? initialType;
                  
                  final extra = state.extra;
                  if (extra is Map<String, dynamic>) {
                    customerId = extra['customerId'] as String?;
                    initialType = extra['type'] as String?;
                  } else if (extra is String) {
                    customerId = extra;
                  }
                  
                  return AddTransactionPage(
                    customerId: customerId,
                    initialType: initialType,
                  );
                },
              ),
              GoRoute(
                path: 'customer/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CustomerTimelinePage(customerId: id);
                },
              ),
            ],
          ),

          // Inventory
          GoRoute(
            path: RouteConstants.inventory,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const InventoryPage(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AddProductPage(),
              ),
            ],
          ),

          // Settings
          GoRoute(
            path: RouteConstants.settings,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SettingsPage(),
            ),
            routes: [
              GoRoute(
                path: 'upi-setup',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const UpiSetupPage(),
              ),
            ],
          ),

          // Reports
          GoRoute(
            path: RouteConstants.reports,
            builder: (context, state) => const ReportsPage(),
          ),

          // Billing
          GoRoute(
            path: RouteConstants.billing,
            builder: (context, state) => const SmartBillingPage(),
          ),

          // Daily Notebook
          GoRoute(
            path: RouteConstants.dailyNotebook,
            builder: (context, state) => const DailyNotebookPage(),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return DailyNoteEditorPage(
                    noteId: extra?['noteId'] as String?,
                    customerId: extra?['customerId'] as String?,
                    customerName: extra?['customerName'] as String?,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // UPI QR Display (standalone, outside shell)
      GoRoute(
        path: RouteConstants.upiQrDisplay,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return UpiQrDisplayPage(
            customerId: extra?['customerId'] as String?,
            customerName: extra?['customerName'] as String?,
            amount: extra?['amount'] as double?,
          );
        },
      ),

      // Notifications (standalone, outside shell)
      GoRoute(
        path: RouteConstants.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
}

class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.l10n.errorNotFound,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? context.l10n.errorNotFoundSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteConstants.dashboard),
              child: Text(context.l10n.goToDashboard),
            ),
          ],
        ),
      ),
    );
  }
}
