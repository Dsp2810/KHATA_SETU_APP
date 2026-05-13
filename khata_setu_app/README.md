# KhataSetu Flutter App

Flutter frontend for KhataSetu (digital udhar/ledger + inventory app).

## Run Locally

```bash
flutter pub get
flutter run -d chrome
```

## Live Demo Mode (Resume Ready)

This mode enables smooth showcase login and optional APK download CTA on web.

```bash
flutter run -d chrome \
	--dart-define=ENV=prod \
	--dart-define=DEMO_MODE=true \
	--dart-define=APK_DOWNLOAD_URL=https://your-domain.com/khatasetu-demo.apk
```

## Build for Deployment

### Web (Release)

```bash
flutter build web --release \
	--dart-define=ENV=prod \
	--dart-define=DEMO_MODE=true \
	--dart-define=APK_DOWNLOAD_URL=https://your-domain.com/khatasetu-demo.apk
```

Output: `build/web/`

### Android APK (Release)

```bash
flutter build apk --release --dart-define=ENV=prod --dart-define=DEMO_MODE=true
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Demo Flags

- `ENV=prod` → Uses production backend URL
- `DEMO_MODE=true` → Enables demo login flow
- `APK_DOWNLOAD_URL=<https-url>` → Shows “Download APK” button on web login page
