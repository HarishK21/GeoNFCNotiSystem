# Firestore Schema

GeoTap Guardian uses a dual-mode data strategy:

- Default development mode uses mock repositories and does not require Firebase files.
- Firebase mode is opt-in with `--dart-define=USE_FIREBASE=true`.
- If Firebase startup fails, the app falls back to mock repositories instead of crashing.

## Top-Level Collections

### `userProfiles/{uid}`

Stores the app-facing profile resolved after Firebase Auth.

Fields:
- `uid`: string
- `role`: `parent` or `staff`
- `schoolId`: string
- `displayName`: string
- `email`: string
- `phone`: string or null
- `linkedGuardianId`: string or null

## School Root

### `schools/{schoolId}`

Fields:
- `name`: string
- `timezone`: string
- `pickupZones`: string[]

Subcollections:
- `students`
- `guardians`
- `pickupPermissions`
- `pickupEvents`
- `releaseEvents`
- `announcements`
- `emergencyNotices`
- `queue`
- `auditTrail`
- `notificationJobs`

## Core Domain Collections

### `schools/{schoolId}/students/{studentId}`

Fields:
- `schoolId`: string
- `displayName`: string
- `gradeLevel`: string
- `homeroom`: string
- `pickupZone`: string
- `guardianIds`: string[]

### `schools/{schoolId}/guardians/{guardianId}`

Fields:
- `schoolId`: string
- `displayName`: string
- `email`: string
- `phone`: string
- `studentIds`: string[]

### `schools/{schoolId}/pickupPermissions/{permissionId}`

Fields:
- `schoolId`: string
- `studentId`: string
- `guardianId`: string
- `delegateName`: string
- `delegatePhone`: string
- `relationship`: string
- `approvedBy`: string
- `startsAt`: timestamp
- `endsAt`: timestamp
- `isActive`: bool

### `schools/{schoolId}/pickupEvents/{pickupEventId}`

Fields:
- `schoolId`: string
- `studentId`: string
- `guardianId`: string
- `type`: `pending`, `approaching`, `verified`, or `released`
- `source`: `manual`, `geofence`, or `nfc`
- `pickupZone`: string
- `occurredAt`: timestamp
- `actorName`: string or null
- `notes`: string or null

### `schools/{schoolId}/releaseEvents/{releaseEventId}`

Fields:
- `schoolId`: string
- `studentId`: string
- `guardianId`: string
- `staffId`: string
- `staffName`: string
- `releasedAt`: timestamp
- `verificationMethod`: string
- `notes`: string or null

### `schools/{schoolId}/announcements/{announcementId}`

Fields:
- `schoolId`: string
- `title`: string
- `body`: string
- `audience`: string
- `sentAt`: timestamp
- `requiresAcknowledgement`: bool

### `schools/{schoolId}/emergencyNotices/{noticeId}`

Fields:
- `schoolId`: string
- `title`: string
- `body`: string
- `severity`: `advisory`, `warning`, or `critical`
- `sentAt`: timestamp
- `isActive`: bool

## Projection Collections

These collections are denormalized read models intended to keep the Flutter UI simple and efficient.

### `schools/{schoolId}/queue/{queueEntryId}`

Fields:
- `schoolId`: string
- `studentId`: string
- `studentName`: string
- `guardianId`: string
- `guardianName`: string
- `homeroom`: string
- `pickupZone`: string
- `etaLabel`: string
- `eventType`: `pending`, `approaching`, `verified`, or `released`
- `isNfcVerified`: bool
- `exceptionFlag`: string or null
- `exceptionCode`: string or null
- `officeApprovalRequired`: bool

### `schools/{schoolId}/auditTrail/{auditEntryId}`

Fields:
- `schoolId`: string
- `studentName`: string
- `action`: string
- `actorName`: string
- `occurredAt`: timestamp
- `notes`: string

### `schools/{schoolId}/notificationJobs/{jobId}`

Queued push-notification scaffolding for later Cloud Functions or server delivery.

Fields:
- `schoolId`: string
- `type`: `guardianApproaching`, `guardianVerified`, `releaseCompleted`, or `emergencyNotice`
- `audienceTopic`: string
- `title`: string
- `body`: string
- `createdAt`: timestamp
- `status`: `queued`, `sent`, or `failed`
- `payload`: map<string, dynamic>

## Repository Mapping Notes

- Firebase Auth resolves the UID only.
- `userProfiles/{uid}` resolves the app role, `schoolId`, and optional linked guardian record.
- Role-specific screens share one router while provider guards enforce role access from the resolved profile.
- `queue` and `auditTrail` are projection collections so the UI does not need to join multiple collections just to paint the queue or event history.
- `notificationJobs` is an integration collection for FCM or Cloud Functions fan-out and is safe to keep optional in mock mode.
- Queue mutations should be written through app logic that preserves the allowed progression: `pending -> approaching -> verified -> released`.

## Security Assumptions

- `userProfiles/{uid}` is expected to use the Firebase Auth UID as its document ID.
- Parent access is limited to the linked guardian family record in the same school.
- Staff access is limited to the same school and is expected to be the only path that can complete release and administrative audit actions.
- Firestore rules should treat queue, pickup events, release events, and audit entries as school-scoped projection data.
- Temporary pickup permissions should be validated against the linked guardian and their active time window.
- Release should only be possible when the queue entry is already verified on-site, `isNfcVerified` is true, and no office-approval block is active.
- Queue reconciliation may repair stale queue projections from newer pickup or release events and should leave an audit entry when it does so.
