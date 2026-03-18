import '../models/pickup_event.dart';
import '../models/pickup_exception_code.dart';
import '../models/pickup_permission.dart';
import '../models/pickup_queue_entry.dart';
import '../models/release_event.dart';
import '../models/student.dart';
import 'pickup_authorization_service.dart';

class QueueReconciliationChange {
  const QueueReconciliationChange({
    required this.previousEntry,
    required this.updatedEntry,
    required this.notes,
  });

  final PickupQueueEntry previousEntry;
  final PickupQueueEntry updatedEntry;
  final String notes;
}

class QueueReconciliationService {
  const QueueReconciliationService(this._authorizationService);

  final PickupAuthorizationService _authorizationService;

  List<QueueReconciliationChange> reconcileSchoolQueue({
    required List<PickupQueueEntry> queueEntries,
    required List<Student> students,
    required List<PickupPermission> permissions,
    required List<PickupEvent> pickupEvents,
    required List<ReleaseEvent> releaseEvents,
    required DateTime at,
  }) {
    final studentById = {for (final student in students) student.id: student};
    return queueEntries
        .map(
          (entry) => reconcileEntry(
            entry: entry,
            student: studentById[entry.studentId],
            permissions: permissions,
            pickupEvents: pickupEvents,
            releaseEvents: releaseEvents,
            at: at,
          ),
        )
        .whereType<QueueReconciliationChange>()
        .toList(growable: false);
  }

  QueueReconciliationChange? reconcileEntry({
    required PickupQueueEntry entry,
    required Student? student,
    required List<PickupPermission> permissions,
    required List<PickupEvent> pickupEvents,
    required List<ReleaseEvent> releaseEvents,
    required DateTime at,
  }) {
    var updatedEntry = entry;
    final notes = <String>[];

    final latestPickup = _latestPickupEvent(entry, pickupEvents);
    final latestRelease = _latestReleaseEvent(entry, releaseEvents);
    final canonicalStatus = _canonicalStatus(
      current: updatedEntry.eventType,
      latestPickup: latestPickup,
      latestRelease: latestRelease,
    );
    if (canonicalStatus != updatedEntry.eventType) {
      updatedEntry = updatedEntry.copyWith(
        eventType: canonicalStatus,
        isNfcVerified: _isVerified(canonicalStatus),
        etaLabel: _etaLabelFor(canonicalStatus),
      );
      notes.add(
        'Queue state reconciled from ${entry.eventType.name} to ${canonicalStatus.name} using newer event history.',
      );
    } else if (updatedEntry.isNfcVerified != _isVerified(canonicalStatus) ||
        updatedEntry.etaLabel != _etaLabelFor(canonicalStatus)) {
      updatedEntry = updatedEntry.copyWith(
        isNfcVerified: _isVerified(canonicalStatus),
        etaLabel: _etaLabelFor(canonicalStatus),
      );
      notes.add(
        'Queue verification metadata was repaired to match the queue state.',
      );
    }

    final decision = _authorizationService.evaluate(
      entry: updatedEntry,
      student: student,
      permissions: permissions,
      at: at,
    );
    if (decision.isAuthorized) {
      if (isSystemManagedPickupException(updatedEntry.exceptionCode) ||
          updatedEntry.officeApprovalRequired) {
        updatedEntry = updatedEntry.copyWith(clearExceptionFlag: true);
        notes.add(
          'Cleared system-generated release block after authorization re-check.',
        );
      }
    } else {
      final issueMessage =
          decision.message ??
          'Office approval is required before this student can be released.';
      if (updatedEntry.exceptionFlag != issueMessage ||
          updatedEntry.exceptionCode != decision.exceptionCode?.name ||
          updatedEntry.officeApprovalRequired !=
              decision.requiresOfficeApproval) {
        updatedEntry = updatedEntry.copyWith(
          exceptionFlag: issueMessage,
          exceptionCode: decision.exceptionCode?.name,
          officeApprovalRequired: decision.requiresOfficeApproval,
        );
        notes.add(issueMessage);
      }
    }

    if (_isEquivalent(entry, updatedEntry)) {
      return null;
    }

    return QueueReconciliationChange(
      previousEntry: entry,
      updatedEntry: updatedEntry,
      notes: notes.join(' '),
    );
  }
}

PickupEvent? _latestPickupEvent(
  PickupQueueEntry entry,
  List<PickupEvent> pickupEvents,
) {
  return _latestByTime<PickupEvent>(
    pickupEvents.where((event) => event.studentId == entry.studentId),
    (event) => event.occurredAt,
  );
}

ReleaseEvent? _latestReleaseEvent(
  PickupQueueEntry entry,
  List<ReleaseEvent> releaseEvents,
) {
  return _latestByTime<ReleaseEvent>(
    releaseEvents.where((event) => event.studentId == entry.studentId),
    (event) => event.releasedAt,
  );
}

T? _latestByTime<T>(Iterable<T> items, DateTime Function(T item) selector) {
  T? latest;
  for (final item in items) {
    if (latest == null || selector(item).isAfter(selector(latest))) {
      latest = item;
    }
  }
  return latest;
}

PickupEventType _canonicalStatus({
  required PickupEventType current,
  required PickupEvent? latestPickup,
  required ReleaseEvent? latestRelease,
}) {
  if (latestRelease != null) {
    if (latestPickup == null ||
        !latestPickup.occurredAt.isAfter(latestRelease.releasedAt)) {
      return PickupEventType.released;
    }
    return latestPickup.type;
  }

  if (latestPickup != null &&
      _statusRank(latestPickup.type) > _statusRank(current)) {
    return latestPickup.type;
  }

  return current;
}

bool _isVerified(PickupEventType type) {
  return type == PickupEventType.verified || type == PickupEventType.released;
}

int _statusRank(PickupEventType type) {
  return switch (type) {
    PickupEventType.pending => 0,
    PickupEventType.approaching => 1,
    PickupEventType.verified => 2,
    PickupEventType.released => 3,
  };
}

String _etaLabelFor(PickupEventType status) {
  return switch (status) {
    PickupEventType.pending => 'Pending',
    PickupEventType.approaching => 'Approaching',
    PickupEventType.verified => 'Ready',
    PickupEventType.released => 'Released',
  };
}

bool _isEquivalent(PickupQueueEntry left, PickupQueueEntry right) {
  return left.toMap().toString() == right.toMap().toString();
}
