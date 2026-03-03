# KhataSetu - State Management Strategy

## 🎯 Overview

KhataSetu uses **BLoC (Business Logic Component)** pattern for state management, providing:
- Clear separation of concerns
- Testability
- Scalability
- Predictable state changes

---

## 📊 BLoC Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        BLOC ARCHITECTURE FLOW                                │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────┐
    │                              UI LAYER                                │
    │                                                                      │
    │   ┌──────────────┐     Events      ┌──────────────┐                │
    │   │    Widget    │ ───────────────▶ │     BLoC     │                │
    │   │              │                  │              │                │
    │   │              │ ◀─────────────── │              │                │
    │   └──────────────┘     States       └──────────────┘                │
    │                                            │                         │
    └────────────────────────────────────────────┼─────────────────────────┘
                                                 │
                                                 │ Uses
                                                 ▼
    ┌─────────────────────────────────────────────────────────────────────┐
    │                           DOMAIN LAYER                               │
    │                                                                      │
    │                       ┌──────────────┐                              │
    │                       │   UseCase    │                              │
    │                       └──────────────┘                              │
    │                              │                                       │
    └──────────────────────────────┼───────────────────────────────────────┘
                                   │
                                   │ Uses
                                   ▼
    ┌─────────────────────────────────────────────────────────────────────┐
    │                            DATA LAYER                                │
    │                                                                      │
    │   ┌──────────────┐         ┌──────────────┐                         │
    │   │  Repository  │ ───────▶│  DataSource  │                         │
    │   └──────────────┘         └──────────────┘                         │
    │                                                                      │
    └─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 BLoCs Directory Structure

```
lib/presentation/blocs/
├── auth/
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
│
├── customer/
│   ├── customer_list/
│   │   ├── customer_list_bloc.dart
│   │   ├── customer_list_event.dart
│   │   └── customer_list_state.dart
│   │
│   └── customer_detail/
│       ├── customer_detail_bloc.dart
│       ├── customer_detail_event.dart
│       └── customer_detail_state.dart
│
├── ledger/
│   ├── ledger_bloc.dart
│   ├── ledger_event.dart
│   └── ledger_state.dart
│
├── product/
│   ├── product_list_bloc.dart
│   └── ...
│
├── dashboard/
│   ├── dashboard_bloc.dart
│   └── ...
│
├── reminder/
│   ├── reminder_bloc.dart
│   └── ...
│
├── theme/
│   └── theme_cubit.dart          # Simple state, use Cubit
│
├── locale/
│   └── locale_cubit.dart         # Language selection
│
└── sync/
    └── sync_cubit.dart           # Offline sync status
```

---

## 📝 BLoC Implementation Examples

### 1. Auth BLoC

```dart
// auth_event.dart
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String phone;
  final String password;
  
  const AuthLoginRequested({
    required this.phone,
    required this.password,
  });
  
  @override
  List<Object?> get props => [phone, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String phone;
  final String password;
  
  const AuthRegisterRequested({
    required this.name,
    required this.phone,
    required this.password,
  });
  
  @override
  List<Object?> get props => [name, phone, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthRefreshToken extends AuthEvent {}
```

```dart
// auth_state.dart
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String accessToken;
  
  const AuthAuthenticated({
    required this.user,
    required this.accessToken,
  });
  
  @override
  List<Object?> get props => [user, accessToken];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}
```

```dart
// auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  
  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.refreshTokenUseCase,
  }) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthRefreshToken>(_onRefreshToken);
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await loginUseCase(
      LoginParams(phone: event.phone, password: event.password),
    );
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authData) => emit(AuthAuthenticated(
        user: authData.user,
        accessToken: authData.accessToken,
      )),
    );
  }
  
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await registerUseCase(
      RegisterParams(
        name: event.name,
        phone: event.phone,
        password: event.password,
      ),
    );
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authData) => emit(AuthAuthenticated(
        user: authData.user,
        accessToken: authData.accessToken,
      )),
    );
  }
  
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await logoutUseCase(NoParams());
    emit(AuthUnauthenticated());
  }
  
  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    // Check for stored tokens and validate
    // Emit AuthAuthenticated or AuthUnauthenticated
  }
  
  Future<void> _onRefreshToken(
    AuthRefreshToken event,
    Emitter<AuthState> emit,
  ) async {
    final result = await refreshTokenUseCase(NoParams());
    
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (newToken) {
        if (state is AuthAuthenticated) {
          emit(AuthAuthenticated(
            user: (state as AuthAuthenticated).user,
            accessToken: newToken,
          ));
        }
      },
    );
  }
}
```

---

### 2. Customer List BLoC

```dart
// customer_list_event.dart
abstract class CustomerListEvent extends Equatable {
  const CustomerListEvent();
}

class CustomerListFetched extends CustomerListEvent {
  final String? searchQuery;
  final String? filter;  // 'all', 'due', 'clear', 'risky'
  final int page;
  
  const CustomerListFetched({
    this.searchQuery,
    this.filter,
    this.page = 1,
  });
  
  @override
  List<Object?> get props => [searchQuery, filter, page];
}

class CustomerListRefreshed extends CustomerListEvent {
  @override
  List<Object?> get props => [];
}

class CustomerDeleted extends CustomerListEvent {
  final String customerId;
  
  const CustomerDeleted(this.customerId);
  
  @override
  List<Object?> get props => [customerId];
}
```

```dart
// customer_list_state.dart
abstract class CustomerListState extends Equatable {
  const CustomerListState();
}

class CustomerListInitial extends CustomerListState {
  @override
  List<Object?> get props => [];
}

class CustomerListLoading extends CustomerListState {
  @override
  List<Object?> get props => [];
}

class CustomerListLoaded extends CustomerListState {
  final List<Customer> customers;
  final bool hasReachedMax;
  final int currentPage;
  final String? activeFilter;
  
  const CustomerListLoaded({
    required this.customers,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.activeFilter,
  });
  
  CustomerListLoaded copyWith({
    List<Customer>? customers,
    bool? hasReachedMax,
    int? currentPage,
    String? activeFilter,
  }) {
    return CustomerListLoaded(
      customers: customers ?? this.customers,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
  
  @override
  List<Object?> get props => [customers, hasReachedMax, currentPage, activeFilter];
}

class CustomerListError extends CustomerListState {
  final String message;
  
  const CustomerListError(this.message);
  
  @override
  List<Object?> get props => [message];
}
```

```dart
// customer_list_bloc.dart
class CustomerListBloc extends Bloc<CustomerListEvent, CustomerListState> {
  final GetCustomersUseCase getCustomersUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;
  
  CustomerListBloc({
    required this.getCustomersUseCase,
    required this.deleteCustomerUseCase,
  }) : super(CustomerListInitial()) {
    on<CustomerListFetched>(_onFetched);
    on<CustomerListRefreshed>(_onRefreshed);
    on<CustomerDeleted>(_onDeleted);
  }
  
  Future<void> _onFetched(
    CustomerListFetched event,
    Emitter<CustomerListState> emit,
  ) async {
    if (state is CustomerListLoaded && event.page > 1) {
      // Pagination - append to existing list
      final currentState = state as CustomerListLoaded;
      if (currentState.hasReachedMax) return;
      
      final result = await getCustomersUseCase(
        GetCustomersParams(
          page: event.page,
          filter: event.filter,
          search: event.searchQuery,
        ),
      );
      
      result.fold(
        (failure) => emit(CustomerListError(failure.message)),
        (newCustomers) => emit(currentState.copyWith(
          customers: [...currentState.customers, ...newCustomers.items],
          hasReachedMax: newCustomers.items.isEmpty,
          currentPage: event.page,
        )),
      );
    } else {
      // Initial load or filter change
      emit(CustomerListLoading());
      
      final result = await getCustomersUseCase(
        GetCustomersParams(
          page: 1,
          filter: event.filter,
          search: event.searchQuery,
        ),
      );
      
      result.fold(
        (failure) => emit(CustomerListError(failure.message)),
        (customers) => emit(CustomerListLoaded(
          customers: customers.items,
          hasReachedMax: customers.items.isEmpty,
          currentPage: 1,
          activeFilter: event.filter,
        )),
      );
    }
  }
  
  Future<void> _onRefreshed(
    CustomerListRefreshed event,
    Emitter<CustomerListState> emit,
  ) async {
    final currentFilter = state is CustomerListLoaded
        ? (state as CustomerListLoaded).activeFilter
        : null;
    
    add(CustomerListFetched(filter: currentFilter, page: 1));
  }
  
  Future<void> _onDeleted(
    CustomerDeleted event,
    Emitter<CustomerListState> emit,
  ) async {
    if (state is CustomerListLoaded) {
      final currentState = state as CustomerListLoaded;
      
      final result = await deleteCustomerUseCase(
        DeleteCustomerParams(customerId: event.customerId),
      );
      
      result.fold(
        (failure) => emit(CustomerListError(failure.message)),
        (_) {
          final updatedList = currentState.customers
              .where((c) => c.id != event.customerId)
              .toList();
          emit(currentState.copyWith(customers: updatedList));
        },
      );
    }
  }
}
```

---

### 3. Theme Cubit (Simple State)

```dart
// theme_cubit.dart
class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;
  
  ThemeCubit(this._prefs) : super(_loadInitialTheme(_prefs));
  
  static ThemeMode _loadInitialTheme(SharedPreferences prefs) {
    final isDark = prefs.getBool('darkMode') ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }
  
  void toggleTheme() {
    final newMode = state == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    _prefs.setBool('darkMode', newMode == ThemeMode.dark);
    emit(newMode);
  }
  
  void setTheme(ThemeMode mode) {
    _prefs.setBool('darkMode', mode == ThemeMode.dark);
    emit(mode);
  }
}
```

---

### 4. Sync Cubit (Offline Status)

```dart
// sync_state.dart
class SyncState extends Equatable {
  final bool isOnline;
  final int pendingCount;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  
  const SyncState({
    this.isOnline = true,
    this.pendingCount = 0,
    this.isSyncing = false,
    this.lastSyncTime,
  });
  
  SyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    bool? isSyncing,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
  
  @override
  List<Object?> get props => [isOnline, pendingCount, isSyncing, lastSyncTime];
}

// sync_cubit.dart
class SyncCubit extends Cubit<SyncState> {
  final SyncDataUseCase syncDataUseCase;
  final GetSyncStatusUseCase getSyncStatusUseCase;
  final NetworkInfo networkInfo;
  
  StreamSubscription? _connectivitySubscription;
  
  SyncCubit({
    required this.syncDataUseCase,
    required this.getSyncStatusUseCase,
    required this.networkInfo,
  }) : super(const SyncState()) {
    _initConnectivityListener();
    _loadPendingCount();
  }
  
  void _initConnectivityListener() {
    _connectivitySubscription = networkInfo.onConnectivityChanged.listen(
      (isOnline) async {
        emit(state.copyWith(isOnline: isOnline));
        
        if (isOnline && state.pendingCount > 0) {
          await syncPendingData();
        }
      },
    );
  }
  
  Future<void> _loadPendingCount() async {
    final result = await getSyncStatusUseCase(NoParams());
    result.fold(
      (failure) => null,
      (status) => emit(state.copyWith(pendingCount: status.pendingCount)),
    );
  }
  
  Future<void> syncPendingData() async {
    if (!state.isOnline || state.isSyncing) return;
    
    emit(state.copyWith(isSyncing: true));
    
    final result = await syncDataUseCase(NoParams());
    
    result.fold(
      (failure) => emit(state.copyWith(isSyncing: false)),
      (syncResult) => emit(state.copyWith(
        isSyncing: false,
        pendingCount: syncResult.remaining,
        lastSyncTime: DateTime.now(),
      )),
    );
  }
  
  void incrementPendingCount() {
    emit(state.copyWith(pendingCount: state.pendingCount + 1));
  }
  
  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
```

---

## 🏗️ BLoC Provider Setup

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(const KhataSetuApp());
}

// app.dart
class KhataSetuApp extends StatelessWidget {
  const KhataSetuApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Global BLoCs
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(AuthCheckStatus()),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => getIt<ThemeCubit>(),
        ),
        BlocProvider<LocaleCubit>(
          create: (_) => getIt<LocaleCubit>(),
        ),
        BlocProvider<SyncCubit>(
          create: (_) => getIt<SyncCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp.router(
                title: 'KhataSetu',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                routerConfig: appRouter,
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 📋 State Management Best Practices

### 1. Event Naming Convention
```dart
// Good
class CustomerListFetched extends CustomerListEvent {}
class CustomerCreated extends CustomerEvent {}
class PaymentRecorded extends LedgerEvent {}

// Avoid
class LoadCustomers extends CustomerListEvent {}  // Use past tense
class ClickSubmit extends CustomerEvent {}        // Don't use UI terms
```

### 2. State Immutability
```dart
// Always use copyWith for state updates
class CustomerListLoaded extends CustomerListState {
  final List<Customer> customers;
  
  // Good - immutable update
  CustomerListLoaded copyWith({List<Customer>? customers}) {
    return CustomerListLoaded(
      customers: customers ?? this.customers,
    );
  }
}
```

### 3. Error Handling
```dart
// Use Either from dartz for error handling
Future<void> _onFetched(
  CustomerListFetched event,
  Emitter<CustomerListState> emit,
) async {
  final result = await getCustomersUseCase(params);
  
  result.fold(
    (failure) => emit(CustomerListError(failure.message)),
    (data) => emit(CustomerListLoaded(customers: data)),
  );
}
```

### 4. Bloc-to-Bloc Communication
```dart
// Use BlocListener for cross-bloc communication
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthUnauthenticated) {
      context.read<CustomerListBloc>().add(CustomerListReset());
      context.read<DashboardBloc>().add(DashboardReset());
    }
  },
  child: ...,
)
```

### 5. Testing BLoCs
```dart
// Use bloc_test package
blocTest<CustomerListBloc, CustomerListState>(
  'emits [Loading, Loaded] when CustomerListFetched is added',
  build: () {
    when(() => mockGetCustomersUseCase(any()))
        .thenAnswer((_) async => Right(mockCustomers));
    return CustomerListBloc(getCustomersUseCase: mockGetCustomersUseCase);
  },
  act: (bloc) => bloc.add(const CustomerListFetched()),
  expect: () => [
    CustomerListLoading(),
    CustomerListLoaded(customers: mockCustomers),
  ],
);
```

---

## 🎯 When to Use Cubit vs BLoC

| Use Case | Cubit | BLoC |
|----------|-------|------|
| Simple toggle (theme, locale) | ✅ | ❌ |
| Counter, simple state | ✅ | ❌ |
| Complex async operations | ❌ | ✅ |
| Multiple event types | ❌ | ✅ |
| Event transformations | ❌ | ✅ |
| Need event traceability | ❌ | ✅ |
