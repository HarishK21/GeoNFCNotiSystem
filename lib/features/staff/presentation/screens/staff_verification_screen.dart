import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../domain/models/guardian.dart';
import '../../../../domain/models/nfc_status.dart';
import '../../../../domain/models/nfc_verification_target.dart';
import '../../../../domain/models/pickup_queue_entry.dart';
import '../../../../domain/models/student.dart';

class StaffVerificationScreen extends ConsumerStatefulWidget {
  const StaffVerificationScreen({super.key});

  @override
  ConsumerState<StaffVerificationScreen> createState() =>
      _StaffVerificationScreenState();
}

class _StaffVerificationScreenState
    extends ConsumerState<StaffVerificationScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentsFutureProvider);
    final guardiansState = ref.watch(guardiansFutureProvider);
    final queueState = ref.watch(queueEntriesStreamProvider);
    final nfcStatus = ref.watch(nfcStatusProvider);
    final deviceAction = ref.watch(deviceActionControllerProvider);
    final debugEnabled = ref.watch(deviceDebugEnabledProvider);
    final students = studentsState.asData?.value ?? const <Student>[];
    final guardians = guardiansState.asData?.value ?? const <Guardian>[];
    final queueEntries = queueState.asData?.value ?? const <PickupQueueEntry>[];
    final query = _searchController.text.trim().toLowerCase();
    final filteredStudents = students
        .where((student) {
          if (query.isEmpty) {
            return true;
          }
          return student.displayName.toLowerCase().contains(query) ||
              student.homeroom.toLowerCase().contains(query) ||
              student.gradeLevel.toLowerCase().contains(query);
        })
        .toList(growable: false);
    final loadError = _firstError([studentsState, guardiansState, queueState]);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (deviceAction.isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        _NfcStatusCard(status: nfcStatus),
        const SizedBox(height: 16),
        DashboardCard(
          title: 'Student lookup',
          subtitle:
              'Search students, review queue state, and arm NFC verification for the correct student.',
          icon: Icons.search_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search by student, grade, or homeroom',
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => setState(() {
                            _searchController.clear();
                          }),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              const Text(
                'On Android, staff can arm an NFC verification session for a selected student and then scan a tag on-site. Debug mode can simulate the same verified event path.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (loadError != null) ...[
          ContentStateCard.error(
            title: 'Could not load student lookup',
            message: '$loadError',
          ),
          const SizedBox(height: 16),
        ],
        if ((studentsState.isLoading ||
                guardiansState.isLoading ||
                queueState.isLoading) &&
            filteredStudents.isEmpty) ...[
          const ContentStateCard.loading(
            title: 'Loading students',
            message: 'Resolving student roster, guardians, and queue state.',
          ),
        ] else if (filteredStudents.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No students match this search',
            message: 'Try a different student name, homeroom, or grade filter.',
          ),
        ] else ...[
          for (final student in filteredStudents) ...[
            _StudentLookupCard(
              student: student,
              guardians: guardians
                  .where(
                    (guardian) => student.guardianIds.contains(guardian.id),
                  )
                  .toList(growable: false),
              queueEntry: queueEntries
                  .where((entry) => entry.studentId == student.id)
                  .firstOrNull,
              debugEnabled: debugEnabled,
              nfcStatus:
                  nfcStatus.asData?.value ?? const NfcStatus.unsupported(),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

class _NfcStatusCard extends ConsumerWidget {
  const _NfcStatusCard({required this.status});

  final AsyncValue<NfcStatus> status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listening = status.asData?.value.listening == true;

    return DashboardCard(
      title: 'Android NFC verification',
      subtitle:
          'Verified is driven by an Android NFC scan or debug simulation.',
      icon: Icons.nfc_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.when(
              data: (value) {
                if (!value.supported) {
                  return value.detail;
                }
                if (!value.enabled) {
                  return value.detail;
                }
                if (value.listening) {
                  return 'Reader mode is active for ${value.targetLabel ?? 'the selected student'}.';
                }
                return value.detail;
              },
              error: (error, stackTrace) =>
                  'Could not read Android NFC status: $error',
              loading: () => 'Checking Android NFC support and reader state.',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  status.asData?.value.supported == true
                      ? 'Android supported'
                      : 'Stubbed elsewhere',
                ),
              ),
              if (status.asData?.value.targetLabel != null)
                Chip(label: Text(status.asData!.value.targetLabel!)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(deviceActionControllerProvider.notifier)
                    .refreshNfcStatus(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh NFC'),
              ),
              if (listening)
                FilledButton.icon(
                  onPressed: () => _runDeviceAction(
                    context,
                    ref,
                    successMessage: 'Stopped NFC verification.',
                    action: () => ref
                        .read(deviceActionControllerProvider.notifier)
                        .stopNfcVerificationSession(),
                  ),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Stop NFC scan'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentLookupCard extends ConsumerWidget {
  const _StudentLookupCard({
    required this.student,
    required this.guardians,
    required this.queueEntry,
    required this.debugEnabled,
    required this.nfcStatus,
  });

  final Student student;
  final List<Guardian> guardians;
  final PickupQueueEntry? queueEntry;
  final bool debugEnabled;
  final NfcStatus nfcStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardianSummary = guardians.isEmpty
        ? 'No guardians linked'
        : guardians.map((guardian) => guardian.displayName).join(', ');
    final target = queueEntry == null
        ? null
        : NfcVerificationTarget(
            schoolId: queueEntry!.schoolId,
            studentId: queueEntry!.studentId,
            guardianId: queueEntry!.guardianId,
            studentName: queueEntry!.studentName,
            guardianName: queueEntry!.guardianName,
          );
    final buttons = <Widget>[];

    if (queueEntry != null && queueEntry!.canVerify && target != null) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _runDeviceAction(
            context,
            ref,
            successMessage:
                'NFC verification armed for ${student.displayName}.',
            action: () => ref
                .read(deviceActionControllerProvider.notifier)
                .startNfcVerificationSession(target),
          ),
          icon: const Icon(Icons.nfc_rounded),
          label: const Text('Start NFC scan'),
        ),
      );
    }

    if (debugEnabled &&
        queueEntry != null &&
        queueEntry!.canVerify &&
        target != null) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _runDeviceAction(
            context,
            ref,
            successMessage:
                '${student.displayName} verified from debug simulation.',
            action: () => ref
                .read(deviceActionControllerProvider.notifier)
                .simulateVerified(target),
          ),
          icon: const Icon(Icons.bolt_rounded),
          label: const Text('Simulate verified'),
        ),
      );
    }

    if (debugEnabled && queueEntry != null && !queueEntry!.canMarkApproaching) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _runDeviceAction(
            context,
            ref,
            successMessage: '${student.displayName} reset to pending.',
            action: () => ref
                .read(deviceActionControllerProvider.notifier)
                .resetQueueState(student.id),
          ),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Reset queue'),
        ),
      );
    }

    final isListeningForStudent =
        nfcStatus.listening && nfcStatus.targetStudentId == student.id;

    return DashboardCard(
      title: student.displayName,
      subtitle:
          '${student.gradeLevel} | ${student.homeroom} | ${student.pickupZone}',
      icon: Icons.person_search_rounded,
      trailing: Chip(
        label: Text(
          queueEntry == null ? 'No queue' : queueEntry!.eventType.name,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guardians: $guardianSummary'),
          const SizedBox(height: 12),
          Text(
            queueEntry == null
                ? 'No active queue entry is open for this student.'
                : 'Current queue state: ${queueEntry!.eventType.name}.',
          ),
          if (isListeningForStudent) ...[
            const SizedBox(height: 12),
            const Chip(
              avatar: Icon(Icons.nfc_rounded),
              label: Text('Waiting for a tag scan'),
            ),
          ],
          if (buttons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: buttons),
          ],
        ],
      ),
    );
  }
}

Future<void> _runDeviceAction(
  BuildContext context,
  WidgetRef ref, {
  required String successMessage,
  required Future<void> Function() action,
}) async {
  await action();
  if (!context.mounted) {
    return;
  }

  final state = ref.read(deviceActionControllerProvider);
  final messenger = ScaffoldMessenger.of(context);
  if (state.hasError) {
    messenger.showSnackBar(
      SnackBar(content: Text('Device action failed: ${state.error}')),
    );
    return;
  }

  messenger.showSnackBar(SnackBar(content: Text(successMessage)));
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

Object? _firstError(Iterable<AsyncValue<dynamic>> values) {
  for (final value in values) {
    if (value.hasError) {
      return value.error;
    }
  }
  return null;
}
