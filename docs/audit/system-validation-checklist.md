# KhataSetu — System Validation Checklist

> Complete testing guide for 5–10 user deployment.  
> Generated: March 2026 | 54 API endpoints · 5 BLoCs · 49 event handlers · 20 screens

---

## Prerequisites

```
Backend running:  cd backend && npm run dev   (port 3000)
Flutter running:  cd khata_setu_app && flutter run -d chrome
MongoDB:          mongod or Atlas cluster connected
```

**Test accounts:** Create 2 accounts (Owner A, Owner B) with separate shops to validate shop-scoped data isolation.

---

# SECTION 1 — API Endpoint Test Matrix

> For each entity: verify the Flutter UI triggers the correct API call, handles success, and gracefully handles failure (network off, 4xx, 5xx).

## 1.1 Authentication (6 endpoints)

| # | Operation | API | Flutter Trigger | Expected UI Behavior | Error Case |
|---|-----------|-----|-----------------|---------------------|------------|
| 1 | Register | `POST /auth/register` | RegisterPage → `RegisterRequested` event | AuthLoading spinner → navigate to Dashboard | Show "Phone already registered" / validation errors in SnackBar |
| 2 | Login | `POST /auth/login` | LoginPage → `LoginRequested` event | AuthLoading spinner → navigate to Dashboard | Show "Invalid credentials" in SnackBar |
| 3 | Token Refresh | `POST /auth/refresh` | AuthInterceptor auto-triggers on 401 | Transparent — user doesn't see anything | If refresh fails → clear tokens → redirect to LoginPage |
| 4 | Logout | `POST /auth/logout` | SettingsPage → `LogoutRequested` event | Navigate to LoginPage, clear all stored data | Should still logout locally even if API fails |
| 5 | Forgot Password | `POST /auth/forgot-password` | Not wired (stubbed) | Shows "Not available yet" error | N/A |
| 6 | Reset Password | `POST /auth/reset-password` | Not wired (stubbed) | Shows "Not available yet" error | N/A |

**How to test token refresh:**
1. Login successfully
2. Wait for access token to expire (or manually clear it from SecureStorage via DevTools)
3. Perform any action (load customers, etc.)
4. **Expected:** Interceptor auto-refreshes, action completes without user seeing error
5. If refresh token is also expired → should redirect to LoginPage

## 1.2 Customers (6 endpoints)

| # | Operation | API | Flutter Trigger | Expected UI Behavior | Error Case |
|---|-----------|-----|-----------------|---------------------|------------|
| 1 | Create | `POST /shops/:shopId/customers` | AddCustomerPage form submit → `AddCustomer` event | Loading → success SnackBar → navigate back to list | Validation error shown, duplicate phone error |
| 2 | List | `GET /shops/:shopId/customers` | CustomersPage init → `LoadCustomers` event | Loading shimmer → customer cards | Error widget with retry button |
| 3 | Detail | `GET /shops/:shopId/customers/:id` | CustomerDetailsPage → direct API call | Loading → full customer profile | Error with retry |
| 4 | Update | `PUT /shops/:shopId/customers/:id` | EditCustomerPage → `UpdateCustomer` event | Loading → success SnackBar → navigate back | Validation error shown |
| 5 | Delete | `DELETE /shops/:shopId/customers/:id` | CustomerDetailsPage delete → `DeleteCustomer` event | Confirmation dialog → success → navigate to list | Error SnackBar |
| 6 | Search | `GET /shops/:shopId/customers?search=` | CustomersPage search field → `SearchCustomers` event (debounced 300ms) | Debounce → filtered results | Empty state if no matches |

**Step-by-step CRUD test:**
1. Open Customers tab → verify list loads (or empty state if first time)
2. Tap "+" → fill name (required), phone (10 digits, starts 6-9) → submit
3. Verify customer appears in list
4. Tap customer → verify details page loads with correct data
5. Tap edit → change name → save → verify update reflected
6. Go back to list → type in search → verify debounce (wait ~300ms before API fires)
7. Open customer → delete → confirm → verify removed from list

## 1.3 Ledger/Transactions (6 endpoints)

| # | Operation | API | Flutter Trigger | Expected UI Behavior | Error Case |
|---|-----------|-----|-----------------|---------------------|------------|
| 1 | Add Credit | `POST /shops/:shopId/ledger` (type: credit) | AddTransactionPage → `AddCredit` event | Loading → success → navigate back | Error SnackBar |
| 2 | Add Payment | `POST /shops/:shopId/ledger` (type: payment) | AddTransactionPage → `AddPayment` event | Loading → success → navigate back | Error SnackBar |
| 3 | List All | `GET /shops/:shopId/ledger` | LedgerPage init → `LoadAllTransactions` event | Loading → transaction cards | Error widget with retry |
| 4 | Customer Ledger | `GET /shops/:shopId/customers/:id/ledger` | CustomerTimelinePage → `LoadTransactions` event | Loading → timeline view | Error with retry |
| 5 | Delete Entry | `DELETE /shops/:shopId/ledger/:id` | CustomerDetailsPage → `UndoLastTransaction` event | Confirmation → success → recalculate balance | Error SnackBar |
| 6 | Refresh | Pull-to-refresh | LedgerPage pull → `RefreshTransactions` event | Refresh indicator → updated data | Error SnackBar |

**Step-by-step test:**
1. From customer details → tap "Give Credit" → enter ₹500 → submit
2. Verify: balance increases by ₹500 on customer card
3. Tap "Receive Payment" → enter ₹200 → submit
4. Verify: balance decreases by ₹200
5. Go to Ledger tab → verify both transactions appear with correct amounts/types
6. Go to customer timeline → verify chronological order
7. Undo last transaction → verify balance recalculates

## 1.4 Products/Inventory (8 endpoints)

| # | Operation | API | Flutter Trigger | Expected UI Behavior | Error Case |
|---|-----------|-----|-----------------|---------------------|------------|
| 1 | Create | `POST /shops/:shopId/products` | AddProductPage → `AddProduct` event | Loading → success → navigate back | Validation error |
| 2 | List | `GET /shops/:shopId/products` | InventoryPage init → `LoadProducts` event | Loading → product cards | Error widget with retry |
| 3 | Detail | `GET /shops/:shopId/products/:id` | Not wired (route exists but no page) | N/A | N/A |
| 4 | Update | `PATCH /shops/:shopId/products/:id` | InventoryPage edit → `UpdateProduct` event | Loading → success SnackBar | Error SnackBar |
| 5 | Delete | `DELETE /shops/:shopId/products/:id` | InventoryPage delete → `DeleteProduct` event | Confirmation → remove from list | Error SnackBar |
| 6 | Adjust Stock | `POST /shops/:shopId/products/:id/stock` | InventoryPage → `AdjustStock` event | Dialog → success → updated quantity | Error SnackBar |
| 7 | Search | `GET /shops/:shopId/products?search=` | InventoryPage search → `SearchProducts` event (debounced 300ms) | Filtered results | Empty state |
| 8 | Filter Category | `GET /shops/:shopId/products?category=` | InventoryPage dropdown → `FilterByCategory` event | Filtered results | Empty state |

**Step-by-step test:**
1. Open Inventory tab → verify empty state or product list
2. Tap "+" → fill product name, price, stock quantity, category → submit
3. Verify product appears in list with correct info
4. Search by name → verify debounce works
5. Filter by category → verify filtering
6. Adjust stock (add 10 → subtract 5 → verify correct count)
7. Delete product → confirm → verify removed

## 1.5 Daily Notes (10+ endpoints)

| # | Operation | API | Flutter Trigger | Expected UI Behavior | Error Case |
|---|-----------|-----|-----------------|---------------------|------------|
| 1 | Create | `POST /shops/:shopId/notes` | DailyNoteEditorPage → `SaveNote` event | Loading → success → navigate back | Validation error |
| 2 | List | `GET /shops/:shopId/notes` | DailyNotebookPage → `LoadNotes` event | Loading → note cards | Error with retry |
| 3 | Detail | `GET /shops/:shopId/notes/:id` | Editor → `LoadNoteForEdit` event | Loading → populated form | Error |
| 4 | Update | `PATCH /shops/:shopId/notes/:id` | Editor → `SaveNote` event (with existing ID) | Loading → success | Error |
| 5 | Delete | `DELETE /shops/:shopId/notes/:id` | Notebook → `DeleteNote` event | Confirmation → remove | Error |
| 6 | Complete | `POST /shops/:shopId/notes/:id/complete` | Notebook → `CompleteNote` event | Status changes to completed | Error |
| 7 | Bulk Complete | `POST /shops/:shopId/notes/bulk-complete` | Select mode → `BulkCompleteSelected` | All selected marked complete | Error |
| 8 | Bulk Delete | `POST /shops/:shopId/notes/bulk-delete` | Select mode → `BulkDeleteSelected` | All selected removed | Error |
| 9 | Search | `GET /shops/:shopId/notes?search=` | Search → `SearchNotes` event (debounced) | Filtered results | Empty state |
| 10 | Summary | `GET /shops/:shopId/notes/summary` | Notebook → `LoadSummary` event | Summary stats displayed | Error |
| 11 | Load More | `GET /shops/:shopId/notes?page=N` | Scroll → `LoadMoreNotes` event | Appends to list | Error SnackBar |

## 1.6 Dashboard & Reports

| # | Operation | API | Flutter Trigger | Expected UI Behavior |
|---|-----------|-----|-----------------|---------------------|
| 1 | Dashboard Stats | `GET /shops/:shopId/dashboard` | DashboardPage → loads customer + transaction data | Stat cards with totals |
| 2 | Shop Info | `GET /shops` | DashboardCubit → `loadShopInfo()` | Shop name in header |
| 3 | Reports | `GET /shops/:shopId/reports/*` | ReportsPage → direct API calls | Charts and data tables |
| 4 | Ledger PDF | `GET /shops/:shopId/reports/ledger-pdf` | ReportsPage export button | PDF downloads/opens |

## 1.7 Settings & Other

| # | Operation | API | Flutter Trigger | Expected UI Behavior |
|---|-----------|-----|-----------------|---------------------|
| 1 | UPI Setup | `PUT /shops/:shopId/upi-settings` | UpiSetupPage form submit | Success SnackBar |
| 2 | User Profile | `GET /users/me` | AuthBloc → `CheckAuthStatus` | User data in settings |
| 3 | Sync | `POST /sync` | SyncService → `syncAll()` | Background sync, status in settings |

---

# SECTION 2 — Offline Mode Testing Plan

## 2.1 How to Simulate Offline

**Method 1 — Chrome DevTools (easiest for web):**
1. Open Chrome DevTools → Network tab → check "Offline"
2. All Dio calls will throw `DioExceptionType.connectionError`

**Method 2 — Kill backend (tests actual server down):**
```bash
kill $(lsof -t -i:3000)
```

**Method 3 — Android device:**
1. Turn on Airplane mode
2. Or disconnect WiFi/mobile data

## 2.2 Offline → CRUD Test Sequence

### Test A: Create data while offline

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Go offline (Method 1 or 2) | ConnectivityService detects change, `debugPrint: OFFLINE` |
| 2 | Add a new customer "Offline Kumar" | Saves to Hive with `synced = false`, no error shown to user |
| 3 | Add a credit transaction ₹300 | Saves locally, balance updates in UI |
| 4 | Add a new product "Test Item" | Saves locally with `synced = false` |
| 5 | Verify all 3 items appear in their lists | UI reads from Hive, should show normally |
| 6 | Go back online | ConnectivityService detects change |
| 7 | Wait for periodic sync (5 min) OR trigger manual sync from Settings | SyncService pushes all unsynced data |
| 8 | Verify in backend (`curl /shops/:id/customers`) | "Offline Kumar" now exists on server |

### Test B: Read cached data while offline

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | While online, load all customers, transactions, products | Data cached in Hive |
| 2 | Go offline | |
| 3 | Navigate to each tab | Lists load from Hive cache — no spinner, no error |
| 4 | Search customers | Local search works |
| 5 | View customer details | Loads from local cache |

### Test C: App restart while offline

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | While online, login and browse (cache data) | |
| 2 | Go offline | |
| 3 | Kill and restart the app | |
| 4 | Expected: App should restart with `CheckAuthStatus` | Token exists in SecureStorage → ConnectivityService detects offline → emits `AuthenticatedOffline` from cached profile |
| 5 | **FIXED:** Offline-aware auth check | AuthBloc checks `ConnectivityService.isOnline` before API call. If offline, builds `User` from cached SecureStorage data and emits `AuthenticatedOffline` |
| 6 | Verify: user stays logged in and can use local data | Dashboard loads from Hive cache, all CRUD works offline |

## 2.3 Sync Edge Cases

| # | Scenario | How to Test | Expected Behavior |
|---|----------|-------------|-------------------|
| 1 | Duplicate customer created online+offline | Create "Ram" online, create "Ram" (same phone) offline, go online | Sync should fail for duplicate — `errors++` in SyncResult |
| 2 | Edit conflict | Edit customer name offline, edit same customer on another device | Server-wins (last write) — no conflict resolution UI exists |
| 3 | Delete while unsynced | Create customer offline, delete before going online | Local delete succeeds, nothing to sync |
| 4 | Large batch sync | Create 20 items offline, go online | SyncService iterates all, should complete without timeout |
| 5 | Sync interrupted | Go offline mid-sync | `_isSyncing` flag prevents duplicate runs. Remaining items sync next cycle |
| 6 | Token expired during sync | Access token expires while syncing 10 items | AuthInterceptor refreshes token, sync continues |

## 2.4 Network Reconnection Flow

```
OFFLINE → ONLINE reconnection sequence:
1. ConnectivityService._updateStatus() detects wifi/mobile back
2. Emits `true` on onConnectivityChanged stream
3. SyncService.startPeriodicSync() should trigger syncAll()
4. SyncAll() pushes: unsynced customers → unsynced transactions → pulls remote data
5. UI updates via BLoC state changes
```

**Manual verification:**
1. Go offline → make 3 changes → go online
2. Open Settings → check Sync Status → should show "Syncing..." then "Synced"
3. Verify changes appear on backend

---

# SECTION 3 — BLoC State Validation

## 3.1 No Event Dispatched in `build()`

**Rule:** Never call `bloc.add(Event)` inside `build()`. Always use `initState`, `didChangeDependencies`, or `addPostFrameCallback`.

**How to verify:**

```bash
# From khata_setu_app/ directory, search for event dispatch patterns in build methods:
grep -n "\.add(" lib/features/*/presentation/pages/*.dart | grep -v "initState\|dispose\|onTap\|onPressed\|onRefresh\|_on\|callback\|listener\|PostFrame"
```

**Files already fixed in production hardening:**
- `customer_timeline_page.dart` — moved from build → initState ✅
- `add_product_page.dart` — moved to BlocListener ✅
- `inventory_page.dart` — moved to `addPostFrameCallback` ✅

**Check these files still have correct patterns:**

| File | Where Event Should Fire | Correct? |
|------|------------------------|----------|
| `customers_page.dart` | `initState` or `addPostFrameCallback` | Check |
| `ledger_page.dart` | `initState` or `addPostFrameCallback` | Check |
| `inventory_page.dart` | `addPostFrameCallback` | ✅ Fixed |
| `dashboard_page.dart` | `BlocListener<DashboardCubit>` | ✅ Fixed |
| `daily_notebook_page.dart` | `initState` | Check |
| `customer_timeline_page.dart` | `initState` | ✅ Fixed |

## 3.2 Detecting Duplicate API Calls

**Symptom:** Same API endpoint called 2+ times on a single user action.

**How to detect:**

1. **Backend logging:** Add request logger middleware:
   ```javascript
   // In app.js, temporarily:
   app.use((req, res, next) => {
     console.log(`${req.method} ${req.originalUrl} at ${Date.now()}`);
     next();
   });
   ```

2. **Dio logging:** Enable `LogInterceptor` in ApiService (already available):
   ```dart
   // Temporarily in api_service.dart constructor:
   _dio.interceptors.add(LogInterceptor(requestBody: true));
   ```

3. **BLoC event stream:** Add `onTransition` override:
   ```dart
   @override
   void onTransition(Transition<Event, State> transition) {
     super.onTransition(transition);
     debugPrint('${transition.event} → ${transition.nextState}');
   }
   ```

**Known risk areas for duplicate calls:**

| Area | Risk | Status |
|------|------|--------|
| `initState` + `BlocProvider.create` both fire events | Medium | Check each page |
| Pull-to-refresh while initial load still running | Low | BLoCs handle state overwrite |
| Search with each keystroke (no debounce) | Fixed | InventoryBloc + CustomerBloc have debounce ✅ |
| `didChangeDependencies` called multiple times | Medium | Only dashboard_page uses it |

## 3.3 State Transition Verification

For each BLoC, verify these transitions work:

### AuthBloc
```
AuthInitial → AuthLoading → Authenticated(user)     ← Login success
AuthInitial → AuthLoading → Unauthenticated          ← No token found
AuthInitial → AuthLoading → AuthError(msg)            ← Login failed
Authenticated → AuthLoading → Unauthenticated         ← Logout
```

### CustomerBloc
```
CustomerInitial → CustomerLoading → CustomerLoaded(list)    ← Load success
CustomerLoaded → CustomerLoading → CustomerLoaded(list)     ← Refresh
CustomerLoaded → CustomerLoaded(filtered)                    ← Search
Any → CustomerError(msg)                                     ← API failure
CustomerError → CustomerLoading → CustomerLoaded(list)       ← Retry
```

### TransactionBloc
```
TransactionInitial → TransactionLoading → TransactionLoaded(list)  ← Load
TransactionLoaded → TransactionLoading → TransactionLoaded(list)   ← Add credit/payment
Any → TransactionError(msg)                                         ← Failure
TransactionError → TransactionLoading → TransactionLoaded(list)     ← Retry
```

### InventoryBloc
```
InventoryInitial → InventoryLoading → InventoryLoaded(list)  ← Load
InventoryLoaded → InventoryLoaded(filtered)                    ← Search (debounced)
InventoryLoaded → InventoryLoaded(filtered)                    ← Filter category
Any → InventoryError(msg)                                      ← Failure
InventoryError → InventoryLoading → InventoryLoaded            ← Retry
```

### DailyNoteBloc
```
DailyNoteInitial → DailyNoteLoading → DailyNoteLoaded(list, page, hasMore)  ← Load
DailyNoteLoaded → DailyNoteLoaded(appended, page+1)                          ← LoadMore
DailyNoteLoaded → DailyNoteLoaded(filtered)                                   ← Search/Filter
Any → DailyNoteError(msg)                                                      ← Failure
```

**How to verify:** Use Flutter DevTools → Select the BLoC tab → Watch state transitions in real-time as you interact with the app.

---

# SECTION 4 — Security Validation

## 4.1 Hive Encryption Verification

**What was implemented:** AES-256 encryption using `HiveAesCipher`, with the encryption key stored in `flutter_secure_storage` (Android Keystore / iOS Keychain).

**Test steps:**

| # | Step | Expected |
|---|------|----------|
| 1 | Login and add some data (customers, transactions) | Data stored in Hive boxes |
| 2 | Find Hive file location on device | Android: `/data/data/com.khatasetu.app/app_flutter/` |
| 3 | Try to read `.hive` files with a hex editor | **Expected:** Data is encrypted, no readable strings visible |
| 4 | Uninstall + reinstall the app | New encryption key generated → old data unreadable (fresh start) |
| 5 | Verify `appMeta` box is unencrypted | This box stores non-sensitive metadata (app version, migration flags) |

**Encrypted boxes (6):**
- `customers`, `transactions`, `products`, `dailySummary`, `dailyNotes`, `syncQueue`

**Unencrypted box (1):**
- `appMeta` (non-sensitive)

**Code verification:**
```bash
# Verify all data boxes use cipher:
grep -n "openBox\|openLazyBox" khata_setu_app/lib/core/data/hive_initializer.dart
# Each should have: encryptionCipher: HiveAesCipher(encryptionKey)
```

## 4.2 Token Handling Verification

| # | Check | How to Verify | Expected |
|---|-------|---------------|----------|
| 1 | Tokens stored in SecureStorage (not Hive/SharedPrefs) | `grep -rn "saveAccessToken\|saveRefreshToken" lib/` | Only `SecureStorageService` writes tokens |
| 2 | Tokens not logged to console | `grep -rn "debugPrint.*token\|print.*token" lib/` | **Zero matches** (already verified ✅) |
| 3 | Token attached via interceptor only | Check `api_interceptors.dart` | `Bearer $token` added in `onRequest` |
| 4 | Auth endpoints skip token injection | Check `isAuthEndpoint` logic | `/auth/login`, `/auth/register`, `/auth/refresh` excluded |
| 5 | Token refresh uses new Dio instance | Check `_refreshToken()` | Creates `Dio(BaseOptions(...))` without interceptors |
| 6 | Failed refresh clears all tokens | Check `onError` handler | `_secureStorage.clearTokens()` on refresh failure |
| 7 | Logout clears tokens | Check `_onLogoutRequested` | `_storage.clearTokens()` called |
| 8 | Shop ID header sent on all requests | Check interceptor | `X-Shop-Id` from SecureStorage |

## 4.3 Sensitive Data Logging Audit

```bash
# Run from khata_setu_app/ directory:

# 1. Check for password logging:
grep -rn "password\|passwd" lib/ --include="*.dart" | grep -i "print\|log\|debug"
# Expected: Zero matches

# 2. Check for token logging:
grep -rn "token" lib/ --include="*.dart" | grep -i "print\|log\|debug"
# Expected: Zero matches (already verified ✅)

# 3. Check for phone number logging:
grep -rn "phone" lib/ --include="*.dart" | grep -i "print\|log"
# Expected: Only error context, never user phone numbers

# 4. Check for creditCard/UPI ID logging:
grep -rn "upiId\|cardNumber\|cvv\|pin" lib/ --include="*.dart" | grep -i "print\|log"
# Expected: Zero matches

# 5. Review all debugPrint calls (should only be error context):
grep -rn "debugPrint" lib/ --include="*.dart" | wc -l
# Then spot-check: none should contain user PII
```

## 4.4 Backend Security Checks

| # | Check | How to Verify |
|---|-------|---------------|
| 1 | Passwords hashed with bcrypt | `grep "bcrypt" backend/src/ -rn` → `bcrypt.hash()` used |
| 2 | JWT secret not hardcoded | `grep "JWT_SECRET\|jwt.*secret" backend/src/ -rn` → reads from `process.env` |
| 3 | Rate limiting on auth endpoints | Check `rateLimit.middleware.js` applied to `/auth/*` |
| 4 | Input validation on all routes | Check each route file uses `validate.middleware.js` |
| 5 | Shop-scoped queries | All DB queries include `{ shopId: req.shop._id }` |

---

# SECTION 5 — Performance & Stability Checklist

## 5.1 Scroll Stress Test

| # | Test | Steps | Pass Criteria |
|---|------|-------|---------------|
| 1 | Fast scroll customer list | Add 50+ customers → scroll rapidly up/down | No jank, no errors, no duplicate cards |
| 2 | Fast scroll transaction list | Add 100+ transactions → scroll | Smooth animation, correct data |
| 3 | Fast scroll daily notes | Add 30+ notes → scroll + load more | Pagination appends without flicker |
| 4 | Search while scrolling | Start scrolling → immediately type search | Previous scroll cancelled, search results shown |
| 5 | Pull-to-refresh during scroll | Pull down while mid-scroll | Refresh indicator shows, data reloads correctly |

## 5.2 Large Dataset Simulation

```bash
# Backend: seed test data via API
for i in $(seq 1 50); do
  curl -X POST http://localhost:3000/api/v1/shops/SHOP_ID/customers \
    -H "Authorization: Bearer TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Customer $i\",\"phone\":\"9$(printf '%09d' $i)\"}"
done

for i in $(seq 1 100); do
  curl -X POST http://localhost:3000/api/v1/shops/SHOP_ID/ledger \
    -H "Authorization: Bearer TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"customerId\":\"CUSTOMER_ID\",\"type\":\"credit\",\"amount\":$((RANDOM % 1000 + 100))}"
done
```

**Then verify:**
- [ ] Customer list loads within 2 seconds
- [ ] Ledger list loads within 2 seconds
- [ ] Search responds within 500ms
- [ ] Dashboard stats calculate correctly with 100+ transactions
- [ ] Memory usage stays under 200MB (check DevTools Performance tab)

## 5.3 App Restart Persistence

| # | Test | Action | Expected |
|---|------|--------|----------|
| 1 | Hot restart | Press `r` in terminal | All state resets, `CheckAuthStatus` fires, user stays logged in |
| 2 | Full restart | Press `R` or kill + re-run | Same as above + Hive re-initializes, encrypted boxes open |
| 3 | Clear app data | Android Settings → clear data | All Hive data gone, new encryption key generated, redirected to login |
| 4 | Login persistence | Login → close browser tab → reopen | Token in SecureStorage → auto-login via `CheckAuthStatus` → dashboard loads |

## 5.4 Memory Profiling

**Flutter DevTools steps:**
1. Run app in profile mode: `flutter run --profile -d chrome`
2. Open DevTools → Memory tab
3. Perform these actions and check for leaks:
   - Navigate to each tab (5 tabs) — no spike without corresponding drop
   - Open/close 10 customer detail pages — memory should return to baseline
   - Add 20 transactions — gradual increase OK, spike = problem
   - Pull-to-refresh 5 times — no cumulative leak
   - Search 10 different terms rapidly — should plateau

**What to look for:**
- [ ] No unbounded list growth
- [ ] Stream subscriptions cleaned up in `dispose()`
- [ ] BLoC instances not duplicated (singleton via GetIt)
- [ ] Hive boxes not opened multiple times

**Check stream disposal:**
```bash
grep -rn "StreamSubscription\|listen(" khata_setu_app/lib/ --include="*.dart" | head -20
# Then verify corresponding dispose()/cancel() calls
```

## 5.5 Unnecessary Rebuild Detection

**Using Flutter DevTools:**
1. Open DevTools → Performance tab → enable "Track rebuilds"
2. Navigate between tabs
3. **Red flag:** If a widget rebuilds when its data hasn't changed

**Key areas to watch:**
| Widget | Should NOT rebuild when... |
|--------|--------------------------|
| `DashboardPage` | Navigating to other tabs and back |
| `CustomerCard` | Another customer is selected |
| `StatCard` | Unrelated data changes |
| `BottomNavigationBar` | Page content scrolls |

**BlocBuilder optimization check:**
```bash
# Verify buildWhen is used where appropriate:
grep -rn "buildWhen\|BlocBuilder\|BlocConsumer" khata_setu_app/lib/features/ --include="*.dart" | wc -l
```

---

# SECTION 6 — Final Release Checklist

## 6.1 Pre-APK Build Checklist

### Code Quality
- [ ] `flutter analyze` returns 0 errors, 0 warnings (info OK)
- [ ] No `print()` or `debugPrint()` with sensitive data
- [ ] No hardcoded API URLs (uses `ApiConstants.baseUrl` from config)
- [ ] No `TODO` or `FIXME` in production code (or they're non-critical)
- [ ] Demo mode login does NOT expose real data

### Configuration
- [ ] `ApiConstants.baseUrl` points to production server (not localhost)
- [ ] Android `minSdkVersion` is 21+ (in `android/app/build.gradle.kts`)
- [ ] App version bumped in `pubspec.yaml` (`version: X.Y.Z+buildNumber`)
- [ ] Android signing key configured (not debug key)
- [ ] Internet permission in `AndroidManifest.xml`

### Dependencies
- [ ] `flutter pub outdated` — no critical security updates pending
- [ ] `cd backend && npm audit` — no critical vulnerabilities

### Features
- [ ] Login flow works with real API (not just demo mode)
- [ ] All 5 main tabs load correctly: Dashboard, Customers, Ledger, Inventory, Settings
- [ ] Customer CRUD: Add, View, Edit, Delete all work
- [ ] Transaction CRUD: Credit, Payment, Undo all work
- [ ] Product CRUD: Add, Edit, Delete, Stock Adjust all work
- [ ] Daily Notes: Create, Edit, Complete, Delete all work
- [ ] Search works with debounce on Customers, Inventory, Notes
- [ ] Pull-to-refresh works on all list pages
- [ ] UPI QR display works from customer details
- [ ] Reports page loads without crash
- [ ] Billing page loads without crash
- [ ] Settings page: Theme, Language, Logout all work

### Offline
- [ ] App doesn't crash when offline
- [ ] Data created offline appears in lists
- [ ] Sync completes when back online

### Security
- [ ] Hive boxes encrypted (verify `.hive` files unreadable)
- [ ] Tokens in SecureStorage only
- [ ] No tokens in logs
- [ ] Backend has rate limiting on auth routes
- [ ] CORS configured correctly for production

## 6.2 Build Commands

```bash
# Analyze
cd khata_setu_app
flutter analyze

# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build Web
flutter build web --release
```

## 6.3 Post-Build Smoke Test (on real device)

Do this on an actual Android phone, NOT emulator:

| # | Test | Time | Pass? |
|---|------|------|-------|
| 1 | Install APK → opens without crash | 30s | |
| 2 | Splash → Login screen loads | 5s | |
| 3 | Register new account | 1min | |
| 4 | Dashboard loads with stats | 10s | |
| 5 | Add 1 customer | 30s | |
| 6 | Add 1 credit transaction | 30s | |
| 7 | Add 1 product | 30s | |
| 8 | Verify balance on dashboard | 10s | |
| 9 | Turn on airplane mode → add 1 customer | 30s | |
| 10 | Turn off airplane mode → verify sync | 1min | |
| 11 | Kill app → reopen → verify logged in | 10s | |
| 12 | Logout → verify redirected to login | 10s | |

**Total smoke test time: ~5 minutes**

## 6.4 Logs to Check Before Release

```bash
# Check backend logs for errors:
cd backend
grep -i "error\|fail\|exception" logs/*.log 2>/dev/null || echo "No log files"

# Check for any uncaught exceptions in Flutter:
# Run app, perform all actions, then check terminal output for:
# - Red error text
# - "Unhandled Exception"
# - "setState() called after dispose"
# - "Looking up a deregistered binding"
# - "A build function returned null"
```

## 6.5 Test Twice (Critical Paths)

These flows must be tested **twice** because they involve multi-step state changes:

1. **Login → Add customer → Add credit → Logout → Login → Verify customer + balance persists**
2. **Offline create → Online sync → Verify on backend → Logout → Login → Verify from server**
3. **Token expiry → Auto-refresh → Action completes without error**

---

# SECTION 7 — Manual Test Case Sheet

> Convert this table into your checklist document. Mark Pass/Fail/Skip for each.

## Module: Authentication

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| AUTH-01 | Valid login | Enter valid phone + password → tap Login | Dashboard loads, shop name displayed | |
| AUTH-02 | Invalid password | Enter valid phone + wrong password → tap Login | Error: "Invalid credentials" | |
| AUTH-03 | Empty fields | Tap Login with empty fields | Validation error shown | |
| AUTH-04 | Invalid phone format | Enter "12345" → tap Login | Validation: "Enter valid 10-digit number" | |
| AUTH-05 | Register new user | Fill name, phone, password, shop name → Register | Dashboard loads, new shop created | |
| AUTH-06 | Duplicate phone register | Register with already-used phone | Error: "Phone already registered" | |
| AUTH-07 | Demo login | Tap "Demo Mode" | Dashboard with demo data, no API calls | |
| AUTH-08 | Logout | Settings → Logout | Redirected to Login, tokens cleared | |
| AUTH-09 | Session persistence | Login → close app → reopen | Auto-login, dashboard loads | |
| AUTH-10 | Token auto-refresh | Wait for token expiry → perform action | Action completes without error | |

## Module: Customers

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| CUST-01 | Load customer list | Navigate to Customers tab | List loads or empty state shown | |
| CUST-02 | Add customer (valid) | Tap + → fill name + phone → Submit | Customer appears in list | |
| CUST-03 | Add customer (invalid phone) | Enter 5-digit phone → Submit | Validation error | |
| CUST-04 | Add customer (duplicate phone) | Add customer with existing phone | Error message shown | |
| CUST-05 | View customer details | Tap customer card | Detail page with name, phone, balance | |
| CUST-06 | Edit customer | Details → Edit → change name → Save | Updated name shown | |
| CUST-07 | Delete customer | Details → Delete → Confirm | Removed from list | |
| CUST-08 | Search customer | Type name in search bar | Filtered results after ~300ms debounce | |
| CUST-09 | Search no results | Search "ZZZXXX" | Empty state shown | |
| CUST-10 | Pull to refresh | Pull down on list | Refresh indicator → updated data | |
| CUST-11 | Load error → retry | Kill backend → load customers → tap Retry | Error shown → Retry works after backend restart | |

## Module: Ledger / Transactions

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| TXN-01 | Add credit | Customer details → Give Credit → ₹500 → Submit | Balance +₹500, transaction in timeline | |
| TXN-02 | Add payment | Customer details → Receive Payment → ₹200 → Submit | Balance -₹200, transaction in timeline | |
| TXN-03 | Zero amount | Try adding ₹0 transaction | Validation error | |
| TXN-04 | Large amount | Add ₹99,999 credit | Succeeds, balance updates correctly | |
| TXN-05 | View ledger list | Navigate to Ledger tab | All transactions across customers | |
| TXN-06 | View customer timeline | Customer details → Transaction history | Chronological list for that customer | |
| TXN-07 | Undo transaction | Customer details → Undo last | Balance recalculated, transaction removed | |
| TXN-08 | Pull to refresh | Pull down on ledger list | Updated data loads | |
| TXN-09 | Ledger error → retry | Kill backend → load ledger → Retry | Error widget → Retry works | |

## Module: Inventory / Products

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| INV-01 | Load products | Navigate to Inventory tab | Product list or empty state | |
| INV-02 | Add product | Tap + → fill name, price, stock → Submit | Product in list | |
| INV-03 | Search product | Type name in search | Filtered results (debounced 300ms) | |
| INV-04 | Filter by category | Select category dropdown | Filtered results | |
| INV-05 | Adjust stock (add) | Product → Adjust → Add 10 | Stock increases by 10 | |
| INV-06 | Adjust stock (subtract) | Product → Adjust → Remove 5 | Stock decreases by 5 | |
| INV-07 | Delete product | Product → Delete → Confirm | Removed from list | |
| INV-08 | Edit product | Product → Edit → change price → Save | Updated price shown | |
| INV-09 | Error → retry | Kill backend → load products → Retry | Error widget with retry works | |

## Module: Daily Notes

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| NOTE-01 | Load notes list | Navigate to Daily Notebook | Note list or empty state | |
| NOTE-02 | Create note | Tap + → fill title, content → Save | Note appears in list | |
| NOTE-03 | Edit note | Tap note → edit content → Save | Updated content | |
| NOTE-04 | Complete note | Tap checkmark on note | Status changes to completed | |
| NOTE-05 | Delete note | Swipe/long-press → Delete → Confirm | Removed from list | |
| NOTE-06 | Search notes | Type in search bar | Filtered results (debounced) | |
| NOTE-07 | Bulk select → complete | Select mode → select 3 → Bulk Complete | All 3 marked completed | |
| NOTE-08 | Bulk select → delete | Select mode → select 2 → Bulk Delete | Both removed | |
| NOTE-09 | Load more (pagination) | Scroll to bottom | Next page loads, appended to list | |
| NOTE-10 | Filter by tag/priority | Apply filter | Filtered results | |

## Module: Dashboard

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| DASH-01 | Load dashboard | App start → Dashboard tab | Shop name, stat cards (total customers, balance, transactions) | |
| DASH-02 | Stats accuracy | Add customer + transaction → return to dashboard | Stats updated correctly | |
| DASH-03 | Pull to refresh | Pull down on dashboard | All stats re-fetched | |
| DASH-04 | Dashboard loading state | Kill backend → restart → load dashboard | Loading spinner shown briefly | |
| DASH-05 | Dashboard error state | Kill backend → load dashboard | Error widget with retry button | |

## Module: Offline / Sync

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| SYNC-01 | Offline create customer | Go offline → add customer | Saved locally (synced=false) | |
| SYNC-02 | Offline create transaction | Go offline → add credit | Saved locally, balance updates | |
| SYNC-03 | Offline create product | Go offline → add product | Saved locally | |
| SYNC-04 | Auto-sync on reconnect | Go online after SYNC-01,02,03 | Data pushed to server | |
| SYNC-05 | Cached data offline | Load data online → go offline → navigate | Lists load from Hive cache | |
| SYNC-06 | Sync status display | Settings → Sync Status | Shows last sync time / status | |

## Module: Security

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| SEC-01 | Hive encrypted | Check `.hive` files with hex editor | No readable strings | |
| SEC-02 | Token in SecureStorage | Check SharedPreferences for tokens | Not found there | |
| SEC-03 | No token in logs | Run app with verbose logging → search output | No token values printed | |
| SEC-04 | Logout clears data | Logout → check SecureStorage | Tokens removed | |

## Module: Settings

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| SET-01 | Theme toggle | Settings → toggle dark/light | Theme changes immediately | |
| SET-02 | Language switch | Settings → change language | UI text updates | |
| SET-03 | UPI setup | Settings → UPI → enter UPI ID → Save | Saved, available in QR | |
| SET-04 | Manual sync trigger | Settings → Sync Now | Sync runs, status updates | |

## Module: Edge Cases

| TC# | Test Case | Steps | Expected Result | Status |
|-----|-----------|-------|-----------------|--------|
| EDGE-01 | Rapid tab switching | Tap all 5 tabs quickly 10 times | No crash, no duplicate loads | |
| EDGE-02 | Double-tap submit | Tap "Save" twice quickly on any form | Only one API call, no duplicate entry | |
| EDGE-03 | Back navigation | Add customer → press back → press back | Returns to correct previous screen | |
| EDGE-04 | Screen rotation | Rotate device mid-form | Form data preserved | |
| EDGE-05 | Long text input | Enter 500-char customer name | Handled gracefully (truncated or error) | |
| EDGE-06 | Special characters | Customer name: "रामू's Shop & Co." | Saved and displayed correctly (Hindi support) | |
| EDGE-07 | Negative amount | Try entering -100 as transaction amount | Validation rejects | |
| EDGE-08 | App kill during save | Kill app while "Saving..." spinner shows | No corrupt data, can retry on restart | |

---

**Total Test Cases: 76**  
**Estimated Manual Testing Time: 2–3 hours**  
**Recommended: Run full suite before each release APK build**
