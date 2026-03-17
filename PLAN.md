# GeoTap Guardian Plan

## Milestones

### 1. Foundation and runnable shell
- Create the Flutter project in the repository root.
- Add Material 3, Riverpod, and GoRouter.
- Build role-based parent and staff app shells with placeholder screens.
- Keep the app runnable without Firebase configuration.

Acceptance criteria:
- `flutter analyze` passes.
- `flutter test` passes.
- Both role entry points open and show production-style placeholder flows.

Validation commands:
- `puro -e geotap flutter pub get`
- `puro -e geotap dart format lib test`
- `puro -e geotap flutter analyze`
- `puro -e geotap flutter test`

### 2. Firebase-backed product wiring
- Add Firebase Auth bootstrap with a safe no-config fallback.
- Replace hardcoded UI data with repository-backed Firestore and mock implementations.
- Isolate Firebase wiring from the widgets behind repository providers.
- Document the Firestore schema and add tests for parsing and profile/data resolution.

Acceptance criteria:
- Parent/staff role state can resolve from Firebase Auth plus profile documents.
- Queue, delegates, announcements, and audit data can flow from either Firestore or mock repositories.
- Missing Firebase config produces a clear development-mode fallback instead of a crash.
- `docs/firestore_schema.md` documents the intended collection structure.

Validation commands:
- `puro -e geotap flutter pub get`
- `puro -e geotap flutter analyze`
- `puro -e geotap flutter test`

### 3. Auth-facing UX and real workflows
- Add sign-in and sign-out scaffolding that works in both Firebase mode and mock mode.
- Resolve auth to user profile to role-based routing with provider or route guards.
- Wire parent and staff screens to repository-backed queue, delegation, announcement, and audit workflows.
- Add queue transition actions for `pending`, `approaching`, `verified`, and `released`.
- Expand tests for routing, workflow mutations, and state transitions.

Acceptance criteria:
- The app opens to sign-in, supports demo auth in mock mode, and routes to the correct role shell after profile resolution.
- Parent screens show today's plan, guardians, one-time delegation, pickup history, and notices from repositories.
- Staff screens show live queue, student lookup, release confirmation, exception flags, and audit trail from repositories.
- Queue actions update repository-backed state without breaking mock mode.

Validation commands:
- `puro -e geotap flutter pub get`
- `puro -e geotap dart format lib test`
- `puro -e geotap flutter analyze`
- `puro -e geotap flutter test`

### 4. Android-first geofencing and NFC
- Add Android platform channels or plugins for geofence and NFC events.
- Map geofence to approaching status and NFC to verified status.
- Surface Android-only capability checks while keeping iOS compile-safe.
- Preserve mock and debug simulation flows so device-driven state changes remain testable without hardware.
- Document the manual Android phone-testing path for both integrations.

Acceptance criteria:
- Android approaching events move a guardian into the live queue.
- Android NFC verification unlocks staff release actions.
- Debug controls can simulate approaching, verified, and reset transitions without hardware.
- Device-triggered queue changes write pickup-event and audit-trail records through the repository layer.
- iOS builds remain compile-safe with graceful "not supported yet" messaging.

Validation commands:
- `puro -e geotap flutter pub get`
- `puro -e geotap dart format lib test`
- `puro -e geotap flutter analyze`
- `puro -e geotap flutter test`

### 5. Release hardening and readiness
- Add release confirmations, queue reconciliation, and audit filters.
- Expand tests for role routing, reducers/providers, and release rules.
- Prepare store-ready app metadata, backend validation, and deployment notes.

Acceptance criteria:
- Staff cannot release an unverified request.
- Audit trail captures queue, delegation, verification, release, and exception changes.
- Backend and device-hardening tasks are documented for a machine with full Android SDK and Firebase setup.

Validation commands:
- `puro -e geotap flutter analyze`
- `puro -e geotap flutter test`
- `puro -e geotap flutter build apk --debug`

## Current next milestone

Next up is Milestone 5: harden release rules, backend validation, and production readiness on top of the Android device-event flows.
