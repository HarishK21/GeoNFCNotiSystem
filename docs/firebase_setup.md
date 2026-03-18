# Firebase Setup

Use this checklist when turning on live Firebase mode for GeoTap Guardian.

## Required project setup

1. Create or select a Firebase project.
2. Enable Firebase Authentication and choose the sign-in providers you want to support.
3. Create a Firestore database in the same project.
4. Add the Android app in Firebase and download `google-services.json` into `android/app/`.
5. If you plan to test on iOS, also add the iOS app and download `GoogleService-Info.plist` into `ios/Runner/`.
6. Generate FlutterFire configuration if you want platform-specific Firebase options files.
7. Deploy `firestore.rules` before connecting production users.
8. Create a delivery path for `schools/{schoolId}/notificationJobs` such as a Cloud Function or trusted server that turns queued jobs into FCM sends.

## Suggested local commands

```bash
flutter pub get
firebase login
firebase use <your-project-id>
firebase deploy --only firestore:rules
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

## Mode switch

- Mock mode stays the default development path.
- Set `USE_FIREBASE=true` only after Firebase has been configured.
- If Firebase bootstrap fails, the app falls back to mock mode instead of crashing.

## Operational notes

- Keep `userProfiles/{uid}` aligned with the Firebase Auth UID.
- Ensure each profile has the correct `role`, `schoolId`, and optional `linkedGuardianId`.
- Decide how `notificationJobs` will be drained in production. The app currently writes queued jobs, but a backend worker or Cloud Function still needs to send them through Firebase Cloud Messaging.
- Revisit the Firestore rules whenever the schema or queue transition rules change.
