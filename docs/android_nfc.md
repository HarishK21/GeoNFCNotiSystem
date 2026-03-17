# Android NFC

## What it does

- GeoTap Guardian treats Android NFC verification as `verified`.
- Staff release stays locked until the queue item has reached the verified state.
- The Flutter UI reads NFC capability through `NfcService`.

## Flutter and Android wiring

- Flutter-facing contract: `lib/domain/services/nfc_service.dart`
- Android implementation: `lib/data/platform/method_channel_nfc_service.dart`
- Android channel host: `android/app/src/main/kotlin/com/geotap/guardian/geo_tap_guardian/MainActivity.kt`
- NFC session manager: `android/app/src/main/kotlin/com/geotap/guardian/geo_tap_guardian/GeoTapNfcSessionManager.kt`

## Event mapping

- Staff selects a student in the verification flow and starts an NFC verification session.
- An Android tag scan emits an `NfcVerificationEvent`.
- The app maps that event to a queue transition from `approaching` to `verified`.
- The transition is persisted through the workflow controller and writes pickup-event and audit-trail entries with an NFC source.
- Once verified, the release action becomes available from the staff queue flow.

## Permissions and UX

- The Android manifest declares NFC support as optional so the app remains installable on devices without NFC hardware.
- The staff verification screen surfaces whether NFC is supported, enabled, and currently listening for a selected student.
- If the device does not support NFC, or NFC is turned off, the app remains usable in debug/mock mode.
- iOS remains compile-safe through a stub implementation that reports NFC as unsupported for now.

## Debug and dev simulation

- Staff debug controls can simulate `verified` without a physical tag.
- Reset controls can move a queue entry back to `pending`.
- Test fakes and non-Android stubs keep the verification flow runnable even when real NFC hardware is unavailable.

## Manual phone-testing steps

1. Open the app on an Android phone and sign in as staff or use mock/demo staff mode.
2. Open the student lookup flow and choose a queue item that is already `approaching`.
3. Tap `Start NFC scan` and confirm the NFC status card reports that reader mode is listening.
4. Scan a supported NFC tag and verify the queue state changes to `verified`.
5. Return to the live queue and confirm the release button is now available.
6. Use `Simulate verified` first if you need to confirm the app-side state transition before testing a real tag.

## Current limitations

- Tag content is not yet matched against a stored guardian/device registry; this milestone treats any scanned tag as proof of on-site verification for the selected student session.
- Reader mode is Android-only for now.
- Full production hardening should add stronger server-side release validation and a tag enrollment strategy.
