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
- Enforce release rules around verified state, role, authorization, and office-approval blocks.
- Add queue reconciliation so stale queue projections recover from newer pickup or release events.
- Scaffold queued push notifications for approaching, verified, released, and emergency flows.
- Add Firestore rules, schema checks, and Firebase setup notes for production enablement.
- Expand tests for release rules, reconciliation, audit consistency, and notification scaffolding.

Acceptance criteria:
- Staff cannot release an unverified or unauthorized request.
- Queue reconciliation repairs stale queue state and records an audit entry.
- Push-notification jobs are queued for approaching, verified, release, and emergency events without breaking mock mode.
- Firestore rules and schema-contract checks exist alongside Firebase setup documentation.
- Backend and device-hardening tasks are documented for a machine with full Android SDK and Firebase setup.

Validation commands:
- `puro -e geotap flutter pub get`
- `puro -e geotap dart format lib test`
- `puro -e geotap flutter analyze`
- `puro -e geotap flutter test`

### 6. Backend approval and delivery infrastructure
- Add explicit `officeApprovals` workflow records with pending, approved, denied, and resolved states.
- Strengthen Firestore release enforcement so release writes reference the queue item and, when needed, a matching approved office-approval record.
- Add Firebase deployment scaffolding with Firestore indexes, Firebase config, and Cloud Functions or worker code for notification delivery and approval projection sync.
- Preserve mock mode while extending tests and docs to cover approval review, notification delivery boundaries, and final live-validation preparation.

Acceptance criteria:
- Unauthorized or expired release attempts create a persistent office-approval record instead of only a transient queue flag.
- Approved office-approval records clear the queue block and allow release, while denied records keep release blocked.
- `notificationJobs` include delivery-tracking fields suitable for a backend worker or Cloud Function, and backend scaffolding exists in the repo for FCM topic delivery.
- Firestore rules, indexes, deployment config, and Firebase setup docs reflect the approval and notification-delivery flow.
- A clear live-validation checklist exists for the next milestone.

Validation commands:
- `puro -e geotap flutter pub get`
- `puro -e geotap dart format lib test`
- `puro -e geotap flutter analyze`
- `puro -e geotap flutter test`

## Current next milestone

Next up is Milestone 7: execute final live validation against a configured Firebase project and Android device hardware, including end-to-end auth, approval, notification delivery, geofence, NFC, and release confirmation checks.
