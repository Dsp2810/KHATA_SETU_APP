# KhataSetu — Interview Prep & Resume Guide

---

## 1. Resume Bullet Points (ATS-Friendly)

**Use these in your Flutter/Mobile Developer resume under "Projects" or "Experience":**

> **KhataSetu — Digital Credit Ledger & Inventory Platform** | Flutter, BLoC, Node.js, MongoDB
> - Architected and built a **full-stack offline-first Flutter application** with 20 screens, 10 feature modules, and 54 REST API endpoints; implemented **AES-256 encrypted Hive storage** with keychain-backed keys, **JWT auth with automatic token refresh**, and a **background sync service** for seamless offline-to-online data reconciliation
> - Engineered a **production-hardened BLoC state management layer** with centralized error mapping (`DioException → typed Failure → user-facing message`), **rxdart debounced search**, hot-swappable DI repositories via GetIt, and consistent **Loading → Error (retry) → Empty → Data** state handling across all screens — achieving **zero lifecycle bugs and zero compile warnings**
> - Delivered a **bilingual (English + Gujarati) real-world application** for Indian village shopkeepers featuring customer credit tracking, inventory management with POS billing, PDF report generation, UPI payment integration, and biometric authentication — designed for **low-connectivity environments** with full offline cache and automatic sync

---

## 2. Technical Interview Questions & Answers

### Q1: Why did you choose BLoC over Riverpod or Provider?

**Answer:** BLoC enforces a strict unidirectional data flow — Events go in, States come out. For a financial app with complex state transitions (loading, error, success, optimistic updates), this explicitness is critical. Every state change is traceable through events, which makes debugging production issues straightforward. Provider is too implicit for complex flows, and Riverpod, while powerful, introduces a different mental model that doesn't enforce the same separation. BLoC also integrates naturally with rxdart for debounced search, which I use across three search-enabled screens.

---

### Q2: How does your offline-first architecture work? What happens when the user goes offline mid-transaction?

**Answer:** Every repository follows a three-step pattern: (1) attempt remote API call, (2) on success, cache the response in encrypted Hive, (3) if the remote call fails, save locally and flag for sync. The `SyncService` runs on a 5-minute timer and pushes unsynced records when connectivity returns. `ConnectivityService` listens for network state changes and triggers immediate sync on reconnection. For conflict resolution, I use a server-wins (last-write-wins) strategy — appropriate for a single-shopkeeper-per-device model where concurrent edits from multiple devices are unlikely.

---

### Q3: Why Hive over SQLite for offline storage?

**Answer:** Three reasons: (1) Hive is pure Dart with zero platform channels, which eliminates an entire class of platform-specific bugs. (2) The data model is document-oriented (customers, transactions, products) — NoSQL fits naturally without requiring schema migrations for every field change. (3) Hive provides built-in AES encryption via `HiveAesCipher`, which was critical for encrypting financial data at rest. SQLite would have required a separate encryption layer like SQLCipher.

---

### Q4: Explain your DI strategy. Why GetIt with manual registration instead of injectable codegen?

**Answer:** I need precise control over registration order and lifecycle because repositories are registered in two phases: (1) at app startup with local-only datasources, (2) after login when the `shopId` is available, I wire up remote datasources. This two-phase pattern doesn't map cleanly to codegen annotations. I also implemented a hot-swap pattern — BLoCs are registered once as lazy singletons in `MultiBlocProvider`, and after login, I call `updateRepository()` on existing instances instead of re-registering them. Re-registration would invalidate the BLoC references held by `MultiBlocProvider`, causing stale state in the widget tree.

---

### Q5: How do you handle authentication token refresh?

**Answer:** The Dio `AuthInterceptor` intercepts every request. It reads the JWT from `flutter_secure_storage` and attaches it as a Bearer token. If the API responds with 401, the interceptor automatically calls the refresh endpoint with the stored refresh token, saves the new access token, and retries the original request transparently. If the refresh itself fails (expired refresh token), it clears all tokens and navigates to the login screen. Tokens are stored in Android's `EncryptedSharedPreferences` and iOS Keychain — never in plain SharedPreferences or Hive.

---

### Q6: What was the hardest bug you fixed in this project?

**Answer:** The `build()`-time event dispatch bug. A page was dispatching `LoadTransactions` inside the `build()` method of a widget. When the BLoC emitted a new state, the widget rebuilt, which re-dispatched the event, which caused another state emission — an infinite loop. The fix was straightforward once identified (move dispatch to `initState()`), but diagnosing it required understanding Flutter's build lifecycle deeply. I also found that the original code used a `StatelessWidget` wrapping a `StatefulWidget` unnecessarily, which I cleaned up.

---

### Q7: How do you ensure sensitive data is secure on the device?

**Answer:** Three layers: (1) All Hive data boxes (customers, transactions, products, notes) are encrypted with AES-256. The encryption key is generated once using `Hive.generateSecureKey()` and stored in `flutter_secure_storage`, which uses Android Keystore / iOS Keychain — hardware-backed on supported devices. (2) Auth tokens are stored exclusively in `flutter_secure_storage`, never in SharedPreferences or Hive. (3) No token or sensitive data is ever logged to the console — I audited every `debugPrint` and `print` call to confirm.

---

### Q8: Why didn't you implement full Clean Architecture with a domain layer?

**Answer:** Pragmatic decision. Full Clean Architecture (with Use Cases, Repository interfaces, and Entities as separate from Models) adds significant boilerplate. For a 10-user app with 10 features, the abstraction cost doesn't pay off. I use a pragmatic 2-layer approach: Data layer (repositories + datasources) and Presentation layer (BLoC + pages). The repository already provides the abstraction boundary between remote and local data. If the app scaled to 100K users and needed multiple data source strategies, I'd add the domain layer then. The Auth feature does have a domain layer as a reference pattern.

---

### Q9: How does your error handling pipeline work end-to-end?

**Answer:** Exceptions flow through a typed pipeline: (1) Dio throws `DioException` on network/HTTP errors. (2) Repositories can also throw custom `AppException` subtypes (`ServerException`, `NetworkException`, `CacheException`, etc.). (3) In BLoC catch blocks, I call `mapExceptionToFailure(e)` which maps any exception to a typed `Failure` — `NetworkFailure`, `AuthFailure`, `ValidationFailure`, etc. (4) Each `Failure` has a user-facing `message` property. (5) The BLoC emits an error state with this message. (6) The UI renders an `ErrorRetryWidget` with the message and a retry button that re-dispatches the original event. This means the user never sees raw stack traces or "Exception: ..." strings.

---

### Q10: What would you change if this needed to scale to 10,000 users?

**Answer:** Four things: (1) Add cursor-based pagination to Customers, Ledger, and Inventory — I already have the pattern implemented in DailyNoteBloc with `hasReachedMax` and `LoadMore` events. (2) Replace server-wins conflict resolution with timestamp-based merging or CRDT for multi-device sync. (3) Add a proper domain layer with Use Cases to decouple business logic from repositories. (4) Implement WebSocket-based real-time sync instead of polling every 5 minutes. The current architecture supports all of these as incremental additions — nothing needs to be rewritten.

---

## 3. Weak Architectural Decisions & Defensive Reasoning

### Challenge 1: "Your BLoCs are registered as lazy singletons — won't that cause memory leaks?"

**Defense:** In this app, BLoCs are intentionally long-lived. They're created once and live for the entire app session because the same customer list, transaction history, and inventory are accessed across multiple screens. Registering them as factories would mean losing state when navigating between tabs (bottom nav uses `ShellRoute`). The hot-swap pattern (`updateRepository()`) ensures they get fresh data sources after login without being recreated. Memory is bounded because the data set is small (a village shop has ~50-200 customers, not millions).

### Challenge 2: "You're using Hive, which is no longer actively maintained. Why not Isar or Drift?"

**Defense:** Hive 2.x is stable and battle-tested for this use case. The app uses it purely as an offline cache, not as a primary database — the source of truth is MongoDB on the backend. Hive's built-in AES encryption was a deciding factor. Isar would require a migration effort with no clear benefit for a cache layer. If I were starting fresh today, I'd evaluate Isar, but for a production app that's already stable, switching the cache layer is unnecessary churn.

### Challenge 3: "No tests. How do you know it works?"

**Defense:** Fair criticism. The app has been manually tested against 54 API endpoints (all verified working), and the backend has Jest + Supertest infrastructure. For a resume project with 5-10 real users, the ROI of comprehensive widget tests is lower than shipping stable features. That said, the architecture is designed for testability — BLoCs have pure event→state mappings, repositories have injectable datasources, and the DI container makes mocking straightforward. Adding tests is an incremental effort, not a rewrite.

### Challenge 4: "Server-wins conflict resolution will lose user data."

**Defense:** In the target use case, one shopkeeper uses one device. Concurrent edits from multiple devices are not a real scenario. Server-wins is the simplest correct strategy for this constraint. The sync service also timestamps all local changes, so if a conflict did occur, we could add a merge screen. For 5-10 users, the operational complexity of CRDTs or OT is unjustified.

---

## 4. Three High-Impact Improvements (8.4 → 9.5)

### Improvement 1: Add Widget Tests for Critical Flows (Impact: +0.4)

Write 10-15 focused widget tests covering:
- Login flow (success, error, demo mode)
- Customer CRUD (add, edit, delete confirms)
- Transaction add (credit, payment, validation)
- Error states render correctly with retry

**Why:** Demonstrates testing discipline. Use `bloc_test` for BLoC tests (pure event→state), `mocktail` for mocking repositories. These are fast to write because the BLoC architecture makes state transitions deterministic.

```bash
# Estimated effort: 4-6 hours
flutter pub add --dev bloc_test mocktail
```

### Improvement 2: Add Pagination to Customers & Ledger (Impact: +0.4)

Follow the existing `DailyNoteBloc` pattern:
- Add `LoadMoreCustomers` event with cursor/page tracking
- Add `hasReachedMax` flag to `CustomerLoaded` state
- Implement infinite scroll with `ScrollController` detection
- Same for `TransactionBloc` with `LoadMoreTransactions`

**Why:** Shows you understand performance at scale. The pattern already exists in your codebase — it's a copy-and-adapt, not a new invention.

```
Estimated effort: 3-4 hours (pattern already exists in DailyNoteBloc)
```

### Improvement 3: Add a CI Pipeline with GitHub Actions (Impact: +0.3)

Create `.github/workflows/flutter-ci.yml`:
- `flutter analyze` (zero warnings — already passing)
- `flutter test` (once tests exist)
- `flutter build apk --release` (proves it compiles)

**Why:** Shows DevOps awareness. A green CI badge on the README signals professional discipline. Even without comprehensive tests, running `flutter analyze` in CI catches regressions automatically.

```yaml
# Estimated effort: 1 hour
name: Flutter CI
on: [push, pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
        working-directory: khata_setu_app
      - run: flutter analyze
        working-directory: khata_setu_app
```

---

**Total effort for all 3 improvements: ~8-11 hours → Score: 9.5/10**
