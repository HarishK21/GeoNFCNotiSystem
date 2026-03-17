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
- `type`: `queued`, `approaching`, or `verified`
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
- `eventType`: `queued`, `approaching`, or `verified`
- `isNfcVerified`: bool

### `schools/{schoolId}/auditTrail/{auditEntryId}`

Fields:
- `schoolId`: string
- `studentName`: string
- `action`: string
- `actorName`: string
- `occurredAt`: timestamp
- `notes`: string

## Repository Mapping Notes

- Firebase Auth resolves the UID only.
- `userProfiles/{uid}` resolves the app role and `schoolId`.
- Role-specific screens can continue to share one app shell while the backend controls the authenticated profile.
- `queue` and `auditTrail` are projection collections so the UI does not need to join multiple collections just to paint the queue or event history.
