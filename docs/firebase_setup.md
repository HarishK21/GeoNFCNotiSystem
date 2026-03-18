# Firebase Setup

Use this checklist when turning on live Firebase mode for GeoTap Guardian.

## Required project setup

1. Create or select a Firebase project.
2. Enable Firebase Authentication and choose the sign-in providers you want to support.
3. Create a Firestore database in the same project.
4. Install Firebase CLI on the machine that will deploy backend config.
5. Use Node.js 20.x for `functions/` install and deployment work so it matches the configured Firebase runtime. The repo includes `functions/.nvmrc` for this workspace.
6. Add the Android app in Firebase and download `google-services.json` into `android/app/`.
7. If you plan to test on iOS, also add the iOS app and download `GoogleService-Info.plist` into `ios/Runner/`.
8. Generate FlutterFire configuration if you want platform-specific Firebase options files.
9. Install the Firebase backend worker dependencies in `functions/`.
10. Deploy Firestore indexes, rules, and the Cloud Functions delivery/approval scaffolding.
11. Keep the Firebase native config files local only; this repo ignores them by default and the Android Gradle project is already wired for the Google Services plugin.

## Suggested local commands

```bash
flutter pub get
flutter run --dart-define=USE_FIREBASE=true
firebase login
firebase use <your-project-id>
cd functions && npm ci
node -c index.js
npm run check
cd ..
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
```

## Firestore indexes to expect

The app orders a few live collections by timestamp or name. Create indexes if Firestore prompts for them while you exercise these queries:

- `pickupPermissions` ordered by `startsAt`
- `pickupEvents` ordered by `occurredAt`
- `releaseEvents` ordered by `releasedAt`
- `announcements` ordered by `sentAt`
- `emergencyNotices` ordered by `sentAt`
- `queue` ordered by `studentName`
- `auditTrail` ordered by `occurredAt`
- `officeApprovals` filtered by `status` and ordered by `requestedAt`
- `notificationJobs` filtered by `status` and ordered by `createdAt`

## Mode switch

- Mock mode stays the default development path.
- Run the app with `--dart-define=USE_FIREBASE=true` only after Firebase has been configured.
- If Firebase bootstrap fails, the app falls back to mock mode instead of crashing.

## Operational notes

- Keep `userProfiles/{uid}` aligned with the Firebase Auth UID.
- Ensure each profile has the correct `role`, `schoolId`, and optional `linkedGuardianId`.
- `releaseEvents` now include `queueEntryId` so backend rules and functions can verify the queue state that drove the release.
- `officeApprovals/{queueEntryId}` is the backend approval record keyed to the queue item that needed an override.
- `notificationJobs` are now shaped for Firebase Cloud Messaging delivery tracking with `attemptCount`, `lastAttemptAt`, `deliveredAt`, and `lastError`.
- In Firebase live mode the app now subscribes authenticated users to:
  - `school_{schoolId}_staff` for staff queue notifications
  - `school_{schoolId}_guardian_{guardianId}` for parent release notifications when `linkedGuardianId` exists
  - `school_{schoolId}_emergency` for emergency notices
- `functions/index.js` includes starter Firebase Cloud Functions for:
  - draining `notificationJobs` into FCM topic sends
  - syncing `officeApprovals` back into queue/audit projections
  - resolving approvals when a release event is written
- On Android 13+ you should expect the OS notification permission prompt when testing FCM delivery.
- Revisit the Firestore rules whenever the schema or queue transition rules change.

## Suggested live Firebase smoke checks

1. Sign in as staff and confirm `userProfiles/{uid}` resolves role and school.
2. Trigger an approaching and verified flow, then confirm `pickupEvents`, `queue`, and `notificationJobs` update.
3. Attempt an unauthorized or expired release and confirm `officeApprovals/{queueEntryId}` is created with `pending` status.
4. Approve the office approval from the staff workflow and confirm the queue block clears.
5. Release the student and confirm:
   - `releaseEvents/{releaseEventId}` contains `queueEntryId`
   - the approval record transitions to `resolved`
   - the release notification job is marked `sent` or `failed` by the function
