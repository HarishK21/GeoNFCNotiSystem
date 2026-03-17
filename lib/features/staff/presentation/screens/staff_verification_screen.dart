import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../domain/models/guardian.dart';
import '../../../../domain/models/pickup_queue_entry.dart';
import '../../../../domain/models/student.dart';
import '../widgets/workflow_action_feedback.dart';

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
        DashboardCard(
          title: 'Student lookup',
          subtitle:
              'Search students, review queue state, and jump into verification-ready records.',
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
                'NFC is still deferred, but staff can already search students, inspect queue state, and use the repository-backed workflow actions.',
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
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

class _StudentLookupCard extends ConsumerWidget {
  const _StudentLookupCard({
    required this.student,
    required this.guardians,
    required this.queueEntry,
  });

  final Student student;
  final List<Guardian> guardians;
  final PickupQueueEntry? queueEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardianSummary = guardians.isEmpty
        ? 'No guardians linked'
        : guardians.map((guardian) => guardian.displayName).join(', ');

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
          if (queueEntry != null && queueEntry!.canVerify) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => runWorkflowAction(
                context,
                ref,
                successMessage: '${student.displayName} verified on-site.',
                action: () => ref
                    .read(workflowActionControllerProvider.notifier)
                    .verifyPickup(queueEntry!),
              ),
              icon: const Icon(Icons.verified_user_rounded),
              label: const Text('Verify from lookup'),
            ),
          ],
        ],
      ),
    );
  }
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
