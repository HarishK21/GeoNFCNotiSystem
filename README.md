# GeoTap Guardian

GeoTap Guardian is an Android-first Flutter app for school pickup and dismissal workflows with role-based parent and staff experiences.

Core behaviors already scaffolded in this repo:

- Parent and staff role-based routing
- Firebase-auth-facing profile resolution with mock fallback
- Firestore-backed and mock repository layers
- Queue transitions for `pending`, `approaching`, `verified`, and `released`
- Android geofencing and NFC service abstractions with debug simulation paths
- Office approval, audit logging, reconciliation, and notification job scaffolding
- Firebase deployment artifacts for Firestore rules, indexes, and Cloud Functions

## Development modes

- Mock/dev mode is the default and does not require Firebase credentials.
- Live Firebase mode is opt-in and only starts when you run with `--dart-define=USE_FIREBASE=true`.
- If Firebase initialization fails, the app falls back to mock mode instead of crashing.

## Quick start

### Flutter app

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

### Firebase-backed live mode

Follow [`docs/firebase_setup.md`](docs/firebase_setup.md) first, then use:

```bash
flutter pub get
flutter run --dart-define=USE_FIREBASE=true
```

### Functions workspace

The `functions/` backend is pinned to Node 20 via [`functions/.nvmrc`](functions/.nvmrc).

```bash
cd functions
npm ci
npm run check
```

`npm run check` performs a syntax check on the Cloud Functions entrypoint without requiring deployment.

## CI validation

GitHub Actions validation lives in [`.github/workflows/ci.yml`](.github/workflows/ci.yml) and runs:

- Flutter dependency install
- `flutter analyze`
- `flutter test`
- `functions/` install on Node 20
- `npm run check`

## Key docs

- [`PLAN.md`](PLAN.md)
- [`AGENTS.md`](AGENTS.md)
- [`docs/firebase_setup.md`](docs/firebase_setup.md)
- [`docs/firestore_schema.md`](docs/firestore_schema.md)
- [`docs/live_validation_checklist.md`](docs/live_validation_checklist.md)
- [`docs/android_geofencing.md`](docs/android_geofencing.md)
- [`docs/android_nfc.md`](docs/android_nfc.md)
