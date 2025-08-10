# My Areas App

A personal offline product tracking app. Fixed areas (Area A, Area B, Area C), with per-area stores and per-store, per-date product lists. 100% offline using Hive. State management with Riverpod.

## Requirements
- Flutter (latest stable)
- Dart SDK (bundled with Flutter)

## Setup
```bash
# Get Flutter if you don't have it
# https://docs.flutter.dev/get-started/install

# Clone or copy this folder
cd my_areas_app

# Create platform folders (android/ios/web) if missing
flutter create .

# Fetch packages
flutter pub get

# Run on a connected Android device or emulator
flutter run -d android
```

## Build APK (sideload)
```bash
# Build a release APK
flutter build apk --release

# The APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

## Notes
- Data is stored locally via Hive in the app sandbox.
- No login, no network required.
- Uninstalling the app will remove local data.