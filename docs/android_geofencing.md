# Android Geofencing

## What it does

- GeoTap Guardian treats Android geofence entry as `approaching`.
- Geofence events never release a student by themselves.
- The Flutter UI reads geofencing capability through `GeofencingService`.

## Flutter and Android wiring

- Flutter-facing contract: `lib/domain/services/geofencing_service.dart`
- Android implementation: `lib/data/platform/method_channel_geofencing_service.dart`
- Android channel host: `android/app/src/main/kotlin/com/geotap/guardian/geo_tap_guardian/MainActivity.kt`
- Geofence manager: `android/app/src/main/kotlin/com/geotap/guardian/geo_tap_guardian/GeoTapGeofenceManager.kt`
- Broadcast receiver: `android/app/src/main/kotlin/com/geotap/guardian/geo_tap_guardian/GeofenceBroadcastReceiver.kt`

## Event mapping

- Registered geofence targets are derived from the signed-in parent profile and linked students.
- When Android reports a geofence enter event, the app maps it to a queue transition from `pending` to `approaching`.
- The queue mutation is written through the existing repository-backed workflow controller.
- The same transition also writes pickup-event and audit-trail records with a geofence source.

## Permissions and UX

- Manifest permissions are declared for fine, coarse, and background location.
- The current UI asks for Android location access from the parent home screen.
- For real-world background monitoring on Android 10+, testers should also allow `Allow all the time` in system settings.
- If the platform is not Android, the app falls back to a compile-safe stub service and shows a not-supported status.

## Debug and dev simulation

- Parent debug controls can simulate `approaching` without physical movement.
- Reset controls can move a queue entry back to `pending`.
- Non-Android platforms use stub services so the debug path stays available in development and tests.

## Manual phone-testing steps

1. Open the app on an Android phone and sign in as a parent or use mock/demo parent mode.
2. From the parent plan screen, grant location access when prompted.
3. Confirm the geofencing status card shows active targets for the linked student profile.
4. Use `Simulate approaching` first to verify the app-level state transition and audit flow.
5. With a real Android device, move into the configured geofence area and confirm the queue state changes to `approaching`.
6. Open the staff flow and confirm the same student now appears in the live queue awaiting verification.

## Current limitations

- Background location runtime handling is intentionally lightweight in this milestone and may need refinement for production-grade always-on behavior.
- School geofence coordinates currently come from `lib/core/config/device_geofence_defaults.dart`.
- This repo milestone validates Dart tests and analysis; full device behavior still needs on-phone verification.
