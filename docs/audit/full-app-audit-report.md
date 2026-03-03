# KhataSetu Flutter App — Full Production Audit Report

> **Auditor**: GitHub Copilot (Claude Opus 4.6)  
> **Date**: 2025-07-13  
> **Scope**: 101 Dart files across `khata_setu_app/lib/`  
> **Target**: 5,000+ shop users, long-term maintainability  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Audit](#2-architecture-audit)
3. [Global Infrastructure Issues](#3-global-infrastructure-issues)
4. [Module-by-Module Checklist](#4-module-by-module-checklist)
5. [Performance Hardening](#5-performance-hardening)
6. [Security Audit](#6-security-audit)
7. [Release Readiness](#7-release-readiness)
8. [Stabilization Roadmap](#8-stabilization-roadmap)

---

## 1. Executive Summary

### Overall Health: 🟡 Fair — Solid foundation, needs targeted hardening

The app has a well-structured codebase with consistent Clean Architecture patterns, proper DI setup, offline-first repositories, and a rich UI. The **Daily Notes module** serves as the gold standard implementation. However, there are **2 critical bugs**, **8 high-severity issues**, and **20+ medium issues** that must be addressed before production.

### Critical Blockers (Must Fix Before Release)
| # | Issue | File | Impact |
|---|-------|------|--------|
| C1 | `LoadTransactions` dispatched inside `build()` | `customer_timeline_page.dart` | Infinite rebuild loop, redundant API calls |
| C2 | `AddProduct` dispatched via `getIt` with no listener, fake 800ms delay | `add_product_page.dart` | User sees success regardless of actual result |

### High Severity (Fix in Sprint 1)
| # | Issue | Files | Impact |
|---|-------|-------|--------|
| H1 | No pagination anywhere except Daily Notes | customers, ledger, inventory, dashboard | Memory bloat at 5k+ users |
| H2 | Dashboard has no loading/error states | `dashboard_page.dart` | Blank screen on slow network |
| H3 | Dashboard chart period selector is non-functional | `dashboard_page.dart` | Broken feature visible to all users |
| H4 | `getIt<>` used instead of `context.read<>` | inventory_page, add_product_page, smart_billing_page | Bypasses widget tree, state sync issues |
| H5 | No `fromJson`/`toJson` on 4 of 6 models | customer, transaction, product, daily_summary, shop_upi | Blocks full backend sync |
| H6 | No Equatable on any model | All 6 models | BLoC state diffing broken |
| H7 | No retry buttons on any error state | All 17 pages | Users stuck on errors |
| H8 | SyncService only syncs Customers+Transactions, not Products or Notes | `sync_service.dart` | Inventory and Notes data loss |

---

## 2. Architecture Audit

### 2.1 Layer Analysis

```
┌─────────────────────────────────────────────────────┐
│ PRESENTATION (features/{module}/presentation/)       │
│ ├── pages/ (17 pages)                                │
│ ├── bloc/ (7 BLoCs/Cubits)                          │
│ └── widgets/ (only daily_notebook has custom ones)    │
├─────────────────────────────────────────────────────┤
│ DOMAIN (features/{module}/domain/)                   │  ← MOSTLY EMPTY
│ ├── entities/ (auth/User, customers/Customer)        │
│ ├── repositories/ (auth/AuthRepository interface)    │
│ └── usecases/ (auth only: LoginUseCase, RegisterUC)  │
├─────────────────────────────────────────────────────┤
│ DATA (core/data/)                                    │
│ ├── models/ (6 Hive models)                         │
│ ├── datasources/ (7: 4 local + 3 remote)            │
│ └── repositories/ (4: udhar, product, shop_upi, note)│
└─────────────────────────────────────────────────────┘
```

### 2.2 Architecture Issues

#### Issue A1: Domain Layer Is Nearly Empty
- **Status**: Only `auth/` has domain entities/usecases/repositories
- **Impact**: BLoCs directly depend on data-layer repositories and models  
- **Recommendation**: For a project this size, this is acceptable. The "domain" folder exists but the app effectively uses a **pragmatic 2-layer architecture** (Data + Presentation). The existing pattern is consistent — don't force domain entities where they add overhead. **Keep as-is** unless adding complex business rules.

#### Issue A2: Flat Data Layer Under `core/data/`
- **Status**: All models, datasources, and repositories live under `core/data/` rather than per-feature
- **Impact**: As features grow, this directory becomes cluttered (already 19 files)
- **Recommendation**: Acceptable for now. If you add 3+ more modules, consider migrating to per-feature data directories:
  ```
  features/customers/data/
    ├── models/customer_model.dart
    ├── datasources/customer_local_datasource.dart
    └── repositories/customer_repository.dart
  ```

#### Issue A3: Inconsistent Feature Directory Structure
| Feature | domain/ | presentation/bloc/ | presentation/widgets/ | data/ |
|---------|---------|-------------------|----------------------|-------|
| auth | ✅ (entities, usecases, repos) | ✅ (AuthBloc, BiometricCubit) | ❌ | ❌ |
| customers | ✅ (entity only) | ✅ (CustomerBloc) | ❌ | In core/ |
| ledger | ❌ | ✅ (TransactionBloc) | ❌ | In core/ |
| inventory | ❌ | ✅ (InventoryBloc) | ❌ | In core/ |
| daily_notebook | ❌ | ✅ (DailyNoteBloc) | ✅ (3 widgets) | In core/ |
| billing | ❌ | ❌ (no BLoC!) | ❌ | ❌ |
| home | ❌ | ❌ | ❌ | ❌ |
| reports | ❌ | ❌ | ❌ | ❌ |
| settings | ❌ | ✅ (ThemeCubit, LanguageCubit) | ❌ | ❌ |
| upi | ❌ | ✅ (ShopUpiCubit) | ❌ | In core/ |

**Gaps**: Billing, Home/Dashboard, and Reports have **no dedicated BLoC** — they read state directly from other BLoCs, which is fragile.

#### Issue A4: DI Pattern (GetIt + registerRemoteDatasource)
- **Status**: Post-login dynamic registration pattern works but has risks
- **Risk**: If `registerRemoteDatasource(shopId)` fails or is called twice, `getIt.unregister` + `registerLazySingleton` can cause race conditions with existing BLocProvider references
- **Fix**: `main.dart` creates BLoCs via `getIt<>()` in `MultiBlocProvider` at app startup. When `registerRemoteDatasource()` replaces them, the old BLoC instances are orphaned but the `BlocProvider` still holds references to them. **The widget tree never gets the new BLoC instances.**
- **Impact**: **After login, all BLoCs in the widget tree are stale until a full app restart.** This is a fundamental architectural flaw.
- **Solution**: Either:
  1. Don't re-register BLoCs — instead pass the remote datasource to the existing BLoC instance via a method
  2. Or force a full app rebuild after `registerRemoteDatasource()` (e.g., navigate to splash and re-init)

---

## 3. Global Infrastructure Issues

### 3.1 Network Layer — ✅ Solid

| Component | Status | Notes |
|-----------|--------|-------|
| Dio configuration | ✅ | Proper timeouts (30s), JSON headers |
| AuthInterceptor | ✅ | Auto JWT + X-Shop-Id injection, skip for auth endpoints |
| Token refresh | ✅ | 401 → refresh → retry pattern implemented correctly |
| ErrorInterceptor | ✅ | Human-readable messages per status code |
| LoggingInterceptor | ✅ | Debug-only, sanitizes sensitive fields |
| Base URL per env | ✅ | `--dart-define=ENV` pattern |

**Minor Issues**:
- `LoggingInterceptor` logs full response data — may include sensitive customer data in debug builds. Add `_sanitizeData()` for response bodies too.
- `AuthInterceptor._refreshToken()` creates a new Dio without the `baseUrl` path context — URL is `/auth/refresh` (relative) which should work but is fragile.

### 3.2 Error Handling — ⚠️ Needs Work

| Component | Status | Notes |
|-----------|--------|-------|
| Exception hierarchy | ✅ | `AppException` base → 6 subtypes |
| Failure hierarchy | ✅ | `Failure` base (Equatable) → 7 subtypes |
| **Exception → Failure mapping** | ❌ Missing | No function that converts `DioException` → `AppException` → `Failure` |
| Repository error handling | ⚠️ | Repositories catch errors silently (`debugPrint`) and fall back to local — never surface the error type to BLoCs |
| BLoC error handling | ⚠️ | BLoCs emit raw `String` error messages — not `Failure` objects |

**Problem**: The exception/failure classes exist but are **never used**. Repositories catch `DioException` and fall back silently. BLoCs emit `CustomerError('Failed to load customers: $e')` with concatenated exception toString() — not a structured `Failure` object.

**Fix**: Create a `mapException` utility:
```dart
Failure mapException(dynamic e) {
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionError) return const NetworkFailure();
    if (e.response?.statusCode == 401) return AuthFailure.unauthorized();
    return ServerFailure(message: e.message ?? 'Server error');
  }
  return ServerFailure(message: e.toString());
}
```

### 3.3 Pagination — ❌ Missing Everywhere Except Daily Notes

| Pattern | Status |
|---------|--------|
| Pagination model class | ❌ No shared `PaginatedResponse<T>` model |
| Infinite scroll helper | ❌ Only Daily Notes has `ScrollController`-based pagination |
| API supports pagination | ✅ All list endpoints support `page` + `limit` |
| BLoC handles pagination | ❌ Only `DailyNoteBloc` has `LoadMoreNotes` |

**Impact at 5k users**: A shopkeeper with 500 customers and 10,000 transactions would load ALL data into memory on page open. This will cause ANRs and OOM on low-end Android devices.

### 3.4 Search Debounce — ⚠️ Inconsistent

| Module | Has Debounce? | Implementation |
|--------|--------------|----------------|
| Customers | ✅ | `rxdart` 300ms in `CustomerBloc` |
| Inventory | ❌ | Direct `SearchProducts` with no debounce |
| Daily Notes | ✅ | `rxdart` 300ms in `DailyNoteBloc` |
| Ledger | ❌ | Client-side filtering, no BLoC event |
| Billing | ❌ | Client-side filtering |

### 3.5 Connectivity Awareness — ⚠️ Partial

- `ConnectivityService` exists and works ✅
- Only `SyncService` listens to connectivity changes
- **No UI indicator** shows online/offline status to the user
- **No toast/snackbar** when going offline or coming back online
- **Repositories don't check connectivity** before attempting remote calls — they try and catch, which is wasteful

---

## 4. Module-by-Module Checklist

### Legend
✅ = Fully implemented | ⚠️ = Partial | ❌ = Missing | N/A = Not applicable

### 4.1 Auth Module

| Feature | Status | Notes |
|---------|--------|-------|
| Login with API | ✅ | Phone + password → JWT tokens |
| Register with API | ✅ | Name, phone, password, shopName |
| Token storage | ✅ | Secure storage for access + refresh tokens |
| Token refresh | ✅ | AuthInterceptor handles 401 |
| Session check at startup | ✅ | `CheckAuthStatus` in splash |
| Demo mode | ✅ | Offline, no tokens |
| Biometric lock | ✅ | Full implementation with toggle |
| OTP verification | ❌ | Stub handler: `emit(AuthError('OTP not available yet'))` |
| Forgot password | ❌ | Stub handler |
| Logout (API) | ✅ | Sends refresh token to invalidate |
| Post-login wiring | ⚠️ | `registerRemoteDatasource` called but stale BLoC issue (see A4) |

### 4.2 Customer Module

| Feature | Status | Notes |
|---------|--------|-------|
| List customers | ✅ | From local Hive |
| Search customers | ✅ | With rxdart debounce |
| Filter (owes/owed/settled) | ✅ | Client-side filtering |
| Sort (name/balance/recent) | ✅ | Client-side |
| Add customer (API) | ✅ | Remote-first, local fallback |
| Edit customer | ✅ | Remote-first, local fallback |
| Delete customer | ✅ | Soft delete |
| Customer details | ✅ | Rich UI with trust score, charts |
| **Pagination** | ❌ | All customers loaded at once |
| **Bulk operations** | ❌ | No multi-select, no bulk delete |
| **Remote search** | ⚠️ | `searchCustomersAsync()` exists in repo but BLoC uses local `searchCustomers()` |
| **Error retry** | ❌ | No retry buttons |
| **Loading states** | ⚠️ | Initial load only, no loading during remote fetch |
| **RefreshIndicator** | ✅ | Pull to refresh on list |

### 4.3 Ledger Module

| Feature | Status | Notes |
|---------|--------|-------|
| All transactions list | ✅ | Grouped by date |
| Customer transactions | ✅ | Timeline view |
| Add credit entry | ✅ | Remote-first, local fallback |
| Add payment entry | ✅ | Remote-first, local fallback |
| Undo last transaction | ✅ | Local + remote delete |
| Search transactions | ⚠️ | Client-side only in `ledger_page.dart`, not through BLoC |
| Filter by type | ✅ | Credit/Debit chips |
| Date range filter | ⚠️ | UI exists but filtering may be client-side only |
| **Pagination** | ❌ | All transactions loaded |
| **Bulk operations** | ❌ | No multi-select |
| **Remote sync** | ⚠️ | Via SyncService only |
| **Error retry** | ❌ | SnackBar only |
| **BUG: build() dispatch** | 🔴 | `customer_timeline_page.dart` dispatches event in `build()` |

### 4.4 Inventory Module

| Feature | Status | Notes |
|---------|--------|-------|
| List products | ✅ | Grid + list views |
| Search products | ✅ | But no debounce in BLoC |
| Filter by category | ✅ | Category chips |
| Add product | ⚠️ | Works but **no BLoC listener for result** |
| Edit product | ✅ | Bottom sheet in inventory_page |
| Delete product | ✅ | Soft delete |
| Stock adjustment | ✅ | Add/remove via BLoC |
| Barcode lookup | ⚠️ | `getProductByBarcode()` in repo but not wired to UI |
| Low stock filter | ⚠️ | `getLowStockProducts()` exists but no UI filter |
| **Pagination** | ❌ | All products loaded |
| **Bulk operations** | ❌ | No multi-select |
| **BUG: getIt instead of context.read** | 🔴 | Both inventory_page and add_product_page |
| **BUG: Fake 800ms delay** | 🔴 | add_product_page shows success regardless |

### 4.5 Daily Notebook Module — ✅ Gold Standard

| Feature | Status | Notes |
|---------|--------|-------|
| List notes with pagination | ✅ | Infinite scroll, 20 per page |
| Search with debounce | ✅ | 300ms rxdart debounce |
| Filter (status/priority/date/sort) | ✅ | Bottom sheet |
| Create note (API) | ✅ | Remote-first, local fallback |
| Edit note | ✅ | Rich editor |
| Delete note | ✅ | Soft delete |
| Complete note | ✅ | Toggle status |
| Multi-select + bulk ops | ✅ | Bulk complete, bulk delete |
| Summary metrics | ✅ | From /summary endpoint |
| Today's notes | ✅ | Dedicated endpoint |
| Repeat yesterday | ✅ | Clone pattern |
| Error handling | ✅ | Proper error states |
| Loading states | ✅ | Shimmer loaders |
| Offline-first | ✅ | Full offline support |

### 4.6 Billing Module

| Feature | Status | Notes |
|---------|--------|-------|
| Product grid | ✅ | With search + categories |
| Cart management | ✅ | `CartManager` ChangeNotifier |
| Customer selection | ✅ | From CustomerBloc |
| Bill generation | ✅ | Creates ledger entry |
| PDF bill | ⚠️ | Via `PdfReportService` but not directly wired |
| **No dedicated BLoC** | ⚠️ | Uses CartManager + direct repo calls |
| **Recursive customer loading** | 🔴 | `Future.delayed` retry — fragile |
| **Dark mode colors** | ⚠️ | Hardcoded grey values |

### 4.7 Reports Module

| Feature | Status | Notes |
|---------|--------|-------|
| Report generation | ✅ | PDF via `PdfReportService` |
| Multiple report types | ✅ | Daily, Weekly, Monthly, Custom |
| Customer statement | ✅ | Per-customer report |
| Print/Share/Save | ✅ | Full export options |
| **No dedicated BLoC** | ⚠️ | Reads state directly from other BLoCs |
| **No remote dashboard API** | ❌ | `getDashboard()` exists in ApiService but unused |
| **Non-reactive state** | ⚠️ | `context.read<>().state` instead of BlocBuilder |

### 4.8 Settings Module

| Feature | Status | Notes |
|---------|--------|-------|
| Theme switching | ✅ | Light/Dark/System with persistence |
| Language switching | ✅ | EN/GU/HI with auto-detection |
| Biometric toggle | ✅ | With auth verification on enable |
| Manual sync | ✅ | Triggers SyncService |
| Data export | ✅ | JSON backup |
| Clear data | ✅ | Hive box clearing |
| Profile info | ✅ | From SecureStorage |
| **App version display** | ⚠️ | Hardcoded `'1.0.0'` instead of package_info |

### 4.9 UPI Module

| Feature | Status | Notes |
|---------|--------|-------|
| UPI ID setup | ✅ | Local Hive storage |
| QR image upload | ✅ | File storage |
| QR display | ✅ | With amount customization |
| **No remote sync** | ❌ | UPI config is local-only |
| **No backend endpoint** | ❌ | No UPI endpoints in API |

### 4.10 Home/Dashboard

| Feature | Status | Notes |
|---------|--------|-------|
| Summary stats | ✅ | Customer count, balances |
| Activity chart | ✅ | fl_chart integration |
| Recent transactions | ✅ | From TransactionBloc |
| Quick actions | ✅ | Navigation buttons |
| **No loading state** | 🔴 | Shows stale/empty data while loading |
| **No error state** | 🔴 | Silently fails |
| **Chart selector broken** | 🔴 | Week/Month/Year selector non-functional |
| **No remote dashboard** | ❌ | Doesn't use `/reports/dashboard` API |

---

## 5. Performance Hardening

### 5.1 Unnecessary Rebuilds

| Issue | Location | Fix |
|-------|----------|-----|
| All BLoCs are global singletons via MultiBlocProvider in main.dart | `main.dart` | This is fine for shared state. Ensure per-page BLoCs use `BlocProvider` locally. |
| `InventoryLoaded.props` uses `products.length` instead of list identity | `inventory_state.dart` | Use `products` directly or `products.hashCode` — current impl may miss updates within same-length list |
| No `const` constructors on many state classes | Various | Add `const` where possible |
| No `Equatable` on models means BLoC emits "new" states that are identical | All models | Add Equatable mixin or override `==`/`hashCode` properly |

### 5.2 Memory Concerns

| Issue | Impact | Fix |
|-------|--------|-----|
| All customers loaded into memory | OOM at 500+ customers | Add pagination with `page`/`limit` |
| All transactions loaded into memory | OOM at 10k+ transactions | Add pagination |
| All products loaded into memory | OOM at 5k+ products | Add pagination |
| Hive boxes stay open for app lifetime | Memory baseline grows | Acceptable for mobile apps |
| `PdfReportService` generates full PDF in memory | Spike on large reports | Stream-based generation or limit data |
| `CartManager` uses `ChangeNotifier` + `List<CartItem>` | Fine for cart sizes | Acceptable |

### 5.3 Network Optimization

| Issue | Fix |
|-------|-----|
| `getAllCustomersAsync()` fetches `limit=100` per page — may need multiple calls | Implement proper pagination loop or increase to `limit=1000` for initial sync |
| Search hits API on every keystroke (where debounce is missing) | Add debounce to Inventory search |
| No request cancellation — previous search results can arrive after newer ones | Use `CancelToken` in Dio for search requests |
| No image caching strategy | Use `cached_network_image` when product images are added |
| SyncService fetches ALL remote customers on every sync cycle | Use `sync/changes` endpoint for delta sync |

### 5.4 Hive Optimization

| Issue | Fix |
|-------|-----|
| `getAllCustomers()` iterates all values with `.where()` | For 500+ records, create an index box or use `LazyBox` |
| `searchProducts()` does full-text scan of all products | Add search index box or use `sqflite` for searchable data |
| `getTransactionsForCustomer()` scans all transactions | Use compound key index: `customerId_timestamp` |
| No Hive compaction strategy | Add periodic `compact()` calls or on app backgrounding |

---

## 6. Security Audit

### 6.1 Token Management — ✅ Solid

| Check | Status |
|-------|--------|
| Tokens in FlutterSecureStorage | ✅ |
| Android encrypted SharedPreferences | ✅ |
| iOS Keychain with first_unlock_this_device | ✅ |
| Tokens cleared on logout | ✅ |
| Token refresh on 401 | ✅ |
| No tokens in logs | ✅ (LoggingInterceptor sanitizes Authorization header) |

### 6.2 Sensitive Data Logging — ⚠️ Needs Attention

| Issue | Severity | Location |
|-------|----------|----------|
| `LoggingInterceptor` logs full response body in debug | Medium | `dio_client.dart:71` — may include customer phone numbers, balances |
| 40+ `debugPrint()` calls in production code | Low | All repositories, BLoCs, services — stripped in release builds but adds noise |
| `_sanitizeData()` only sanitizes request body, not response | Medium | `dio_client.dart:91` |
| Customer phone numbers stored in plain Hive (not encrypted) | Medium | `customer_model.dart` — Hive data is unencrypted on disk |

### 6.3 Input Validation — ⚠️ Client-Side Only

| Check | Status |
|-------|--------|
| Phone validation (regex `^[6-9]\d{9}$`) | ✅ in UI forms |
| Password min length | ✅ in UI forms |
| Amount validation | ✅ in UI forms |
| **Server-side validation** | ✅ (Joi validators on backend) |
| **Double-submit prevention** | ⚠️ Some forms disable button during loading, but not all |
| **XSS in customer names** | ✅ (Flutter renders text safely, no HTML injection) |

### 6.4 Biometric Security — ✅ Complete

| Check | Status |
|-------|--------|
| Device capability check | ✅ |
| Enrollment check | ✅ |
| Auto-disable on enrollment removal | ✅ |
| Verify before enabling | ✅ |
| Lock-out handling | ✅ |
| Preference persisted in SharedPreferences | ✅ |

### 6.5 Data at Rest

| Check | Status | Notes |
|-------|--------|-------|
| Hive encryption | ❌ | Hive boxes are not encrypted — customer data readable on rooted devices |
| Secure storage for tokens | ✅ | FlutterSecureStorage with platform-specific encryption |
| Backup files | ⚠️ | JSON backup written to app documents — not encrypted |

**Recommendation**: For sensitive Indian financial data (udhar records), consider using `Hive.openBox(encryptionCipher: HiveAesCipher(key))` with a key stored in FlutterSecureStorage.

---

## 7. Release Readiness

### 7.1 Crash Protection

| Check | Status | Notes |
|-------|--------|-------|
| Global error handler | ❌ | No `FlutterError.onError` or `runZonedGuarded` in `main.dart` |
| Crash reporting (Sentry/Crashlytics) | ❌ | Not integrated |
| Uncaught exception UI | ❌ | App will show red error screen on unhandled exceptions |
| Router error page | ✅ | `_ErrorPage` widget for navigation errors |

### 7.2 Timeout & Edge Cases

| Check | Status |
|-------|--------|
| Network timeout handling | ✅ (ErrorInterceptor) |
| Empty state UI | ✅ (PremiumEmptyState widget used) |
| No internet banner | ❌ Missing |
| Retry on failure | ❌ No retry buttons anywhere |
| Back button handling | ✅ (GoRouter handles it) |
| Deep link handling | ❌ Not configured |

### 7.3 Debug Artifacts

| Issue | Count | Action |
|-------|-------|--------|
| `debugPrint()` calls | 40+ | Acceptable (stripped in release) but noisy |
| `print()` calls | 0 | ✅ Clean |
| `TODO` comments | 1 | `login_page.dart:330` — "Implement forgot password" |
| Hardcoded debug URLs | 0 | ✅ Uses `--dart-define` pattern |
| `debugShowCheckedModeBanner` | ✅ | Set to `false` |

### 7.4 Compile Warnings

| File | Warning | Fix |
|------|---------|-----|
| `sync_service.dart:6` | Unused import `transaction_model.dart` | Remove import |
| `biometric_cubit.dart:2` | Unused import `foundation.dart` | Remove import |
| `login_page.dart:16` | Unused import `biometric_service.dart` | Remove import |
| `edit_customer_page.dart:8` | Unused import `animations.dart` | Remove import |
| `customer_details_page.dart:189` | Always-true null check | Remove `if (customer != null)` |

### 7.5 Localization Completeness

| Check | Status | Notes |
|-------|--------|-------|
| l10n setup | ✅ | EN, GU, HI with `gen_l10n` |
| Pages using l10n | ⚠️ 85% | Most pages use `context.l10n` |
| Hardcoded strings found | ⚠️ | `'Yesterday'`, `'Xm ago'`, `'Xh ago'`, `'Txns'`, `'Day Total: ₹X'`, `'My Shop'`, business type names |
| Date/number formatting | ⚠️ | Uses `intl` package but relative dates are hardcoded English |
| Currency formatting | ✅ | `AppConstants.currencySymbol` used consistently |

---

## 8. Stabilization Roadmap

### Phase 1: Critical Bug Fixes (1-2 days)

| Priority | Task | Effort |
|----------|------|--------|
| P0 | Fix `customer_timeline_page.dart` — move `LoadTransactions` from `build()` to `initState()` | 10 min |
| P0 | Fix `add_product_page.dart` — add `BlocListener<InventoryBloc>` for result, remove fake delay | 30 min |
| P0 | Fix stale BLoC issue — either inject remote datasource into existing BLoC instances or force app rebuild after login | 2 hrs |
| P0 | Fix dashboard loading/error states — wrap with BlocBuilder, add loading shimmer | 1 hr |
| P0 | Fix dashboard chart period selector — actually filter data by period | 1 hr |

### Phase 2: Infrastructure Hardening (3-5 days)

| Priority | Task | Effort |
|----------|------|--------|
| P1 | Add shared `PaginatedList<T>` model and infinite scroll mixin | 2 hrs |
| P1 | Add pagination to CustomerBloc, TransactionBloc, InventoryBloc | 4 hrs |
| P1 | Add `fromJson`/`toJson` to all 4 remaining models | 2 hrs |
| P1 | Add Equatable to all models (or proper `==`/`hashCode`) | 1 hr |
| P1 | Add search debounce to InventoryBloc | 30 min |
| P1 | Create `mapException()` utility and use in repositories | 1 hr |
| P1 | Add retry buttons to all error states | 2 hrs |
| P1 | Replace `getIt<>` with `context.read<>` in inventory/billing pages | 1 hr |
| P1 | Extend SyncService to sync Products and DailyNotes | 2 hrs |
| P1 | Add global error handler in `main.dart` (runZonedGuarded) | 30 min |
| P1 | Fix all 5 compile warnings | 10 min |

### Phase 3: Production Polish (3-5 days)

| Priority | Task | Effort |
|----------|------|--------|
| P2 | Add offline indicator banner (global) | 1 hr |
| P2 | Wire dashboard to `/reports/dashboard` API | 2 hrs |
| P2 | Localize all hardcoded strings | 1 hr |
| P2 | Add Hive box encryption for sensitive data | 2 hrs |
| P2 | Integrate crash reporting (Sentry or Firebase Crashlytics) | 2 hrs |
| P2 | Add request cancellation for search (CancelToken) | 1 hr |
| P2 | Use delta sync via `/sync/changes` instead of full pull | 3 hrs |
| P2 | Add `copyWith` to TransactionModel and DailySummaryModel | 30 min |
| P2 | Create BillingBloc to replace direct repo calls | 2 hrs |
| P2 | Create DashboardBloc to replace nested BlocBuilders | 2 hrs |

### Phase 4: Scale & Optimize (ongoing)

| Priority | Task | Effort |
|----------|------|--------|
| P3 | Add Hive compaction strategy | 1 hr |
| P3 | Add search indexes for large datasets | 3 hrs |
| P3 | Profile with Flutter DevTools, fix jank | 2 hrs |
| P3 | Add integration tests for critical flows | 5 hrs |
| P3 | Add deep link support | 2 hrs |
| P3 | Implement OTP verification flow | 3 hrs |
| P3 | Implement forgot password flow | 2 hrs |

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Dart files | 101 |
| Feature modules | 10 |
| BLoCs/Cubits | 7 |
| Hive models | 6 |
| API endpoints defined | 52 |
| API service methods | 35 |
| Critical bugs | 2 |
| High-severity issues | 8 |
| Medium-severity issues | 20+ |
| Low-severity issues | 10+ |
| Compile warnings | 5 |
| TODOs in code | 1 |
| Debug prints | 40 |
| Estimated fix effort (P0+P1) | ~20 hours |
| Estimated full stabilization | ~40 hours |

---

*Report generated by analyzing 101 files across the complete Flutter codebase. Daily Notes module serves as the reference "gold standard" implementation that other modules should be aligned to.*
