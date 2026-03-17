import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/pickup_request.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/pickup_request_card.dart';
import '../../../../domain/models/pickup_queue_entry.dart';
import '../../../../domain/models/student.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(appEnvironmentProvider);
    final workflowAction = ref.watch(workflowActionControllerProvider);
    final authGate = ref.watch(authGateStateProvider);
    final studentsState = ref.watch(studentsFutureProvider);
    final guardiansState = ref.watch(guardiansFutureProvider);
    final queueState = ref.watch(queueEntriesStreamProvider);
    final schoolState = ref.watch(activeSchoolProvider);
    final familyStudents = ref.watch(familyStudentsProvider);
    final familyQueueEntries = ref.watch(familyQueueEntriesProvider);
    final familyQueue = ref.watch(familyPickupQueueProvider);
    final activeDelegates = ref.watch(familyDelegatesProvider);
    final announcements = ref.watch(announcementsProvider);
    final latestAnnouncement = announcements.isNotEmpty
        ? announcements.first
        : null;
    final loadError = _firstError([
      studentsState,
      guardiansState,
      queueState,
      schoolState,
    ]);
    final isLoading =
        studentsState.isLoading ||
        guardiansState.isLoading ||
        queueState.isLoading ||
        schoolState.isLoading;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (workflowAction.isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        if (loadError != null) ...[
          ContentStateCard.error(
            title: 'Could not fully load today\'s pickup plan',
            message: '$loadError',
          ),
          const SizedBox(height: 16),
        ],
        if (!environment.firebaseConfigured) ...[
          DashboardCard(
            title: 'Running without Firebase',
            subtitle:
                'The app shell uses local mock data until Auth and Firestore are configured.',
            icon: Icons.cloud_off_rounded,
            child: const Text(
              'This milestone keeps the real workflow structure in place while mock repositories power the data and actions.',
            ),
          ),
          const SizedBox(height: 16),
        ],
        DashboardCard(
          title: authGate.profile?.displayName ?? 'Parent pickup overview',
          subtitle:
              schoolState.asData?.value?.name ?? 'Resolving school profile',
          icon: Icons.family_restroom_rounded,
          child: Text(
            activeDelegates.isEmpty
                ? 'Today\'s dismissal is tied to your primary guardian profile. Add a one-time delegate from the Guardians tab when someone else will handle pickup.'
                : '${activeDelegates.length} delegate'
                      '${activeDelegates.length == 1 ? ' is' : 's are'} active for today\'s pickup window.',
          ),
        ),
        const SizedBox(height: 16),
        const DashboardCard(
          title: 'Today\'s pickup rules',
          subtitle:
              'Approaching and verified stay separate states in app logic.',
          icon: Icons.rule_folder_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FlowStep(
                index: '1',
                text:
                    'Pending means a pickup plan exists, but the guardian has not started the handoff flow yet.',
              ),
              SizedBox(height: 10),
              _FlowStep(
                index: '2',
                text:
                    'Approaching marks that a guardian is on the way. In mock mode you can trigger this manually while geofencing is still deferred.',
              ),
              SizedBox(height: 10),
              _FlowStep(
                index: '3',
                text:
                    'Verified means on-site confirmation is complete. Staff release happens only after that state is visible.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading &&
            familyStudents.isEmpty &&
            familyQueueEntries.isEmpty) ...[
          const ContentStateCard.loading(
            title: 'Loading family pickup plan',
            message: 'Resolving students, queue state, and linked guardians.',
          ),
          const SizedBox(height: 16),
        ] else if (familyStudents.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No linked students',
            message:
                'This parent profile does not currently map to any student records.',
          ),
          const SizedBox(height: 16),
        ] else ...[
          for (final student in familyStudents) ...[
            _StudentPlanCard(
              student: student,
              queueEntry: familyQueueEntries
                  .where((entry) => entry.studentId == student.id)
                  .firstOrNull,
              request: familyQueue
                  .where((request) => request.studentId == student.id)
                  .firstOrNull,
            ),
            const SizedBox(height: 16),
          ],
        ],
        DashboardCard(
          title: latestAnnouncement?.title ?? 'Announcements will appear here',
          subtitle:
              latestAnnouncement?.sentAtLabel ??
              'Waiting for announcement feed data.',
          icon: Icons.campaign_rounded,
          child: Text(
            latestAnnouncement?.body ??
                'The repository layer is active, but no announcement documents have been emitted yet.',
          ),
        ),
      ],
    );
  }
}

class _StudentPlanCard extends ConsumerWidget {
  const _StudentPlanCard({
    required this.student,
    required this.queueEntry,
    required this.request,
  });

  final Student student;
  final PickupQueueEntry? queueEntry;
  final PickupRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardCard(
      title: student.displayName,
      subtitle:
          '${student.gradeLevel} | ${student.homeroom} | ${student.pickupZone}',
      icon: Icons.directions_walk_rounded,
      child: request == null
          ? const Text(
              'No active pickup request is in the queue for this student yet.',
            )
          : PickupRequestCard(
              request: request!,
              showReleaseState: true,
              footer: queueEntry != null && queueEntry!.canMarkApproaching
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => _markApproaching(
                          context,
                          ref,
                          queueEntry!,
                          student.displayName,
                        ),
                        icon: const Icon(Icons.near_me_rounded),
                        label: const Text('I\'m approaching'),
                      ),
                    )
                  : Text(
                      request!.presenceState.detail,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
            ),
    );
  }

  Future<void> _markApproaching(
    BuildContext context,
    WidgetRef ref,
    PickupQueueEntry entry,
    String studentName,
  ) async {
    try {
      await ref
          .read(workflowActionControllerProvider.notifier)
          .markApproaching(entry);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$studentName is now marked as approaching.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update pickup: $error')),
      );
    }
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 14, child: Text(index)),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
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
