<div align="center">

# KhataSetu

**Digital Credit Ledger & Inventory Platform for Indian Village Shopkeepers**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?logo=nodedotjs)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-6+-47A248?logo=mongodb)](https://mongodb.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)]()

A production-hardened Flutter + Node.js application that digitizes the traditional paper-based credit system (udhar khata) for India's 12M+ small retailers. Built with offline-first architecture, AES-256 encrypted local storage, and real-time sync.

</div>

---

## The Problem

75%+ of India's small retailers still track credit on paper. Lost pages = lost money. KhataSetu replaces that with a secure, offline-capable mobile app designed for low connectivity, bilingual users, and real-world reliability.

**Target:** 5-10 real shopkeepers | **Focus:** Stability over scale | **Goal:** Production-grade engineering

---

## Features

| Module | Capabilities |
|--------|-------------|
| **Auth** | Login, register, biometric unlock, demo mode, multi-shop |
| **Dashboard** | Revenue cards, credit/payment charts, top defaulters, quick actions |
| **Customers** | CRUD, debounced search, trust scoring, credit limits, color-coded risk |
| **Ledger** | Credit/payment entries, date-grouped timeline, undo, auto-balance |
| **Inventory** | Product CRUD, stock adjustment, category filter, barcode-ready, POS billing |
| **Daily Notebook** | Notes with pagination, search, bulk ops, date filter, summary stats |
| **Reports** | Gujarati PDF generation, branded exports, share via WhatsApp/Email |
| **UPI** | QR display, deep links, payment confirmation |
| **Reminders** | Manual + smart suggestions, push notification ready |
| **Settings** | Theme (dark/light), language (EN/GU), biometric toggle |

---

## Architecture

```
+------------------------------------------------------------------+
|                     FLUTTER APPLICATION                           |
|                                                                   |
|  +-------------------------------------------------------------+ |
|  |  PRESENTATION     Pages -> BLoC/Cubit -> States              | |
|  |                   20 screens | 9 BLoCs | Equatable           | |
|  +----------------------------+--------------------------------+ |
|  +----------------------------v--------------------------------+ |
|  |  DATA              Repositories -> Remote (Dio) + Local      | |
|  |                    Offline-First: API -> Cache -> Fallback   | |
|  +-------------------------------------------------------------+ |
|  +-------------------------------------------------------------+ |
|  |  CORE              DI (GetIt) | GoRouter | Theme | Auth      | |
|  |                    Interceptors | Connectivity | Sync        | |
|  +-------------------------------------------------------------+ |
+-------------------------------+----------------------------------+
                                | REST API (JWT + X-Shop-Id)
+-------------------------------v----------------------------------+
|  NODE.JS BACKEND      Routes -> Middleware -> Controllers        |
|                       -> Services -> Mongoose -> MongoDB         |
|                       54 endpoints | RBAC | Refresh tokens       |
+------------------------------------------------------------------+
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **BLoC over Riverpod** | Explicit event-driven state -- easier to debug, test, and trace |
| **GetIt (manual DI)** | Full control over registration order; hot-swap for post-login updates |
| **Hive + AES-256** | NoSQL fits document model; financial data encrypted at rest |
| **Repository pattern** | Pragmatic 2-layer (Data + Presentation) -- avoids over-abstraction |

---

## Offline-First Design

```
Online:    API Request -> Cache in Hive -> Return Data
Offline:   Read Hive Cache -> Queue Writes -> Sync When Online
Sync:      Background sync every 5 min | Server-wins conflict resolution
```

Every repository: remote fetch -> cache locally -> fallback to Hive on failure -> queue for sync.

---

## Security

| Layer | Implementation |
|-------|----------------|
| **Auth** | JWT access + refresh tokens; auto-refresh on 401 via Dio interceptor |
| **Storage** | AES-256 encrypted Hive boxes; key in platform keychain |
| **API** | X-Shop-Id header scoping, Helmet.js, rate limiting (100 req/min) |
| **Passwords** | bcrypt hashing (10 rounds) |
| **Input** | Joi validation (backend), Indian phone format validation |
| **Tokens** | Never logged; stored in EncryptedSharedPreferences / Keychain |

---

## Tech Stack

### Frontend -- Flutter | 117 Dart files | 20 screens | 10 modules

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.x (Dart SDK ^3.11.0) |
| State | flutter_bloc, equatable |
| DI | get_it |
| Network | dio, connectivity_plus |
| Storage | hive (AES), flutter_secure_storage |
| Navigation | go_router (ShellRoute) |
| Charts | fl_chart |
| PDF | pdf, printing |
| i18n | flutter_localizations (EN + GU) |

### Backend -- Node.js | 55 JS files | 54 endpoints

| Category | Technology |
|----------|-----------|
| Runtime | Node.js 18+ |
| Framework | Express.js |
| Database | MongoDB (Mongoose) |
| Auth | JWT, bcryptjs |
| Validation | Joi |
| Security | Helmet, express-rate-limit |
| Logging | Winston, Morgan |
| Testing | Jest, Supertest |

---

## Project Structure

```
KhataSetu/
|-- khata_setu_app/              # Flutter frontend
|   +-- lib/
|       |-- core/
|       |   |-- data/            # Models, datasources, repositories
|       |   |-- di/              # GetIt dependency injection
|       |   |-- error/           # Typed exceptions & failures
|       |   |-- network/         # Dio client, interceptors
|       |   |-- router/          # GoRouter config
|       |   |-- services/        # Sync, connectivity, biometric
|       |   |-- storage/         # Secure & local storage wrappers
|       |   +-- theme/           # Design system (colors, spacing, typography)
|       |-- features/            # 10 feature modules
|       |-- shared/widgets/      # 15+ reusable UI components
|       +-- l10n/                # ARB localization files
|
|-- backend/                     # Node.js REST API
|   +-- src/
|       |-- controllers/         # Thin controllers -> services
|       |-- middleware/          # Auth, validation, rate-limit, errors
|       |-- models/              # Mongoose schemas (indexes, virtuals)
|       |-- routes/              # RESTful endpoints
|       |-- services/            # Business logic
|       +-- validators/          # Joi schemas
|
+-- docs/                        # Architecture & audit documentation
    |-- api/                     # API endpoint docs
    |-- architecture/            # System diagrams & flows
    |-- audit/                   # Production hardening reports
    +-- database/                # Schema design
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Node.js 18+
- MongoDB 6+ (local or Atlas)

### Backend

```bash
cd backend
cp .env.example .env          # Fill in MongoDB URI, JWT secret
npm install
npm run dev                    # http://localhost:3000
```

### Flutter App

```bash
cd khata_setu_app
flutter pub get
flutter run -d chrome          # Web
flutter run -d <device_id>     # Mobile / Desktop
```

> Update API base URL in `lib/core/network/dio_client.dart` to match your backend.

### Resume / Live Demo Build (Web + APK)

Use demo mode for frictionless showcase (no real account needed):

```bash
cd khata_setu_app
flutter run -d chrome \
  --dart-define=ENV=prod \
  --dart-define=DEMO_MODE=true \
  --dart-define=APK_DOWNLOAD_URL=https://your-domain.com/khatasetu-demo.apk
```

Build production web demo:

```bash
cd khata_setu_app
flutter build web --release \
  --dart-define=ENV=prod \
  --dart-define=DEMO_MODE=true \
  --dart-define=APK_DOWNLOAD_URL=https://your-domain.com/khatasetu-demo.apk
```

Build Android APK for sharing:

```bash
cd khata_setu_app
flutter build apk --release --dart-define=ENV=prod --dart-define=DEMO_MODE=true
```

Output artifacts:
- Web: `khata_setu_app/build/web/`
- APK: `khata_setu_app/build/app/outputs/flutter-apk/app-release.apk`

---

## Engineering Highlights

- **Zero lifecycle bugs** -- No build()-time event dispatches; hot-swap DI eliminates stale references
- **Typed error pipeline** -- DioException -> mapExceptionToFailure() -> Failure -> user message with retry
- **Encrypted offline cache** -- AES-256 Hive boxes with keychain-backed keys; full offline CRUD
- **Hot-swap DI** -- BLoCs registered once globally; repositories swapped at runtime
- **Consistent UX** -- Every screen handles Loading -> Error (retry) -> Empty -> Data
- **Bilingual** -- Full English + Gujarati localization via ARB files
- **0 errors, 0 warnings** -- Clean compile across the entire codebase

---

## Documentation

| Document | Description |
|----------|-------------|
| [System Architecture](docs/architecture/system-architecture.md) | High-level system design |
| [API Endpoints](docs/api/api-endpoints.md) | Full REST API reference |
| [Schema Design](docs/database/schema-design.md) | MongoDB collection schemas |
| [App Flow](docs/architecture/app-flow.md) | Screen navigation & user flows |
| [Production Hardening](docs/audit/production-hardening-report.md) | Audit trail of hardening changes |
| [Design System](docs/ui-ux/design-system.md) | Colors, typography, spacing |

---

## License

This project is proprietary software. All rights reserved.

---

<div align="center">
  <sub>Built with care for India's village shopkeepers.</sub>
</div>
