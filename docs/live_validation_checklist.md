# Live Validation Checklist

Use this checklist for the final production-style validation pass after Firebase is configured.

## Before testing

1. Install Firebase CLI on the validation machine.
2. Use Node.js 20.x for the `functions/` workspace. The repo includes `functions/.nvmrc`.
3. Place `google-services.json` in `android/app/`.
4. If you want iOS smoke coverage, place `GoogleService-Info.plist` in `ios/Runner/`.
5. Keep both native Firebase config files out of version control.
6. Run `flutter pub get`.
7. Run `cd functions && npm ci`.
8. Run `node -c index.js` inside `functions/`.
9. Run `npm run check` inside `functions/`.
10. Deploy backend config:
   - `firebase deploy --only firestore:rules,firestore:indexes`
   - `firebase deploy --only functions`
11. Launch the app in live mode with `flutter run --dart-define=USE_FIREBASE=true`.

## App and backend flow checks

1. Sign in as a parent and confirm the profile resolves to the correct school and guardian.
2. Confirm the device receives or is subscribed for:
   - `school_{schoolId}_guardian_{guardianId}`
   - `school_{schoolId}_emergency`
3. Trigger an approaching event and confirm:
   - queue entry moves to `approaching`
   - a `guardianApproaching` notification job is written
4. Sign in as staff on a separate device and confirm the device receives or is subscribed for:
   - `school_{schoolId}_staff`
   - `school_{schoolId}_emergency`
5. Trigger NFC verification and confirm:
   - queue entry moves to `verified`
   - a `guardianVerified` notification job is written
6. Attempt a release with an unauthorized or expired guardian and confirm:
   - release is blocked
   - `officeApprovals/{queueEntryId}` is created with `pending`
   - queue remains blocked with an exception
7. Approve the office approval from the staff workflow and confirm:
   - queue exception clears
   - office approval status becomes `approved`
8. Complete release and confirm:
   - `releaseEvents/{releaseEventId}` contains `queueEntryId`
   - office approval status becomes `resolved`
   - a `releaseCompleted` notification job is processed by the backend worker
9. Send an emergency notice and confirm:
   - the notice appears in the app
   - an `emergencyNotice` job is queued and processed
10. Inspect any failed notification job and confirm:
   - `status` becomes `failed`
   - `attemptCount` increments
   - `lastError` is populated

## Expected backend collections to inspect

- `userProfiles`
- `schools/{schoolId}/queue`
- `schools/{schoolId}/pickupEvents`
- `schools/{schoolId}/releaseEvents`
- `schools/{schoolId}/officeApprovals`
- `schools/{schoolId}/notificationJobs`
- `schools/{schoolId}/auditTrail`
