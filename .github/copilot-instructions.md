# KhataSetu - Copilot Instructions

## Project Overview
KhataSetu is a digital credit ledger (udhar khata) and inventory management platform for Indian village shopkeepers. Monorepo with Flutter app (`khata_setu_app/`) and Node.js/Express backend (`backend/`).

## Architecture

### Flutter App (`khata_setu_app/lib/`)
- **Clean Architecture**: Presentation → Domain → Data layers
- **State Management**: BLoC/Cubit pattern with `flutter_bloc`
- **DI**: GetIt (`core/di/injection.dart`) - register dependencies here, BLoCs as `registerFactory`, services as `registerLazySingleton`
- **Navigation**: GoRouter with ShellRoute for bottom nav (`core/router/app_router.dart`)
- **Feature Structure**: `features/{feature}/presentation/{pages,bloc,widgets}/`

### Backend (`backend/src/`)
- Express.js with Routes → Middleware → Controllers → Services → Models flow
- MongoDB with Mongoose schemas (auto timestamps, virtuals for computed fields)
- JWT auth with refresh tokens, role-based access control
- API versioning: `/api/v1/{resource}`

## Key Conventions

### Flutter Code Style
```dart
// Use theme constants, not hardcoded values
color: AppColors.primary           // ✓ from core/theme/app_colors.dart  
color: Color(0xFF1E88E5)           // ✗ avoid

// Spacing/sizing from AppSpacing, AppRadius
padding: EdgeInsets.all(AppSpacing.md)  // ✓
borderRadius: BorderRadius.circular(AppRadius.sm)  // ✓

// Indian phone validation regex (starts with 6-9)
RegExp(r'^[6-9]\d{9}$')

// Currency display
'${AppConstants.currencySymbol}${amount}'  // ₹1,000
```

### BLoC Pattern
- Events in `*_event.dart`, States in `*_state.dart`, BLoC in `*_bloc.dart`
- Register BLoCs in `injection.dart`, provide via `BlocProvider` in UI
- Use `BlocConsumer` for side effects + rebuild, `BlocBuilder` for rebuild only

### Shared Widgets (`shared/widgets/`)
Export through barrel file `widgets.dart`. Key reusable components:
- `CustomButton`, `CustomTextField` - form elements
- `StatCard`, `CustomerCard`, `TransactionCard`, `ProductCard` - domain cards
- `LoadingStates` - shimmer loaders

### Backend API Pattern
```javascript
// Controller: thin, delegates to service
const createCustomer = async (req, res, next) => {
  const result = await customerService.create(req.body, req.shop._id);
  res.status(201).json({ success: true, data: result });
};

// Validate with Joi in validators/, apply via validate.middleware.js
// Error handling via error.middleware.js (throw, don't catch)
```

### Mongoose Models
- Use compound indexes for multi-tenant queries: `{ shopId: 1, phone: 1 }`
- Virtual fields for computed values (e.g., `balanceStatus`, `trustLevel`)
- Text indexes for search: `{ shopId: 1, name: 'text' }`

## Development Commands

### Flutter
```bash
cd khata_setu_app
flutter run -d chrome          # Web (avoids Linux snap linker issues)
flutter run -d linux           # Linux desktop (requires lld linker)
flutter pub get                # Install dependencies
flutter pub run build_runner build  # Generate code (Hive adapters)
```

### Backend
```bash
cd backend
npm run dev                    # Start with nodemon
npm test                       # Run Jest tests
npm run lint:fix               # ESLint autofix
```

## Critical Files
- `khata_setu_app/lib/core/di/injection.dart` - All service registrations
- `khata_setu_app/lib/core/router/app_router.dart` - All routes
- `khata_setu_app/lib/core/theme/app_colors.dart` - Design system colors, spacing, typography
- `backend/src/app.js` - Express middleware chain and route mounting
- `docs/architecture/` - System diagrams and detailed structure docs

## Domain-Specific Terms
- **Udhar/Khata**: Credit/ledger - customer owes shopkeeper
- **currentBalance > 0**: Customer owes shop (debit from customer perspective)
- **trustScore (0-100)**: Customer creditworthiness rating
- **ShopId context**: All data queries scoped to active shop via `X-Shop-Id` header

## Testing Notes
- Flutter: Demo mode bypasses auth - `_onLogin()` uses local state with `Future.delayed` navigation
- Backend: Use `supertest` for API integration tests
- MongoDB: Virtual fields require `{ virtuals: true }` in `toJSON` options
