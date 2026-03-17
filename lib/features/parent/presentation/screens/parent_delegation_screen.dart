import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../domain/models/student.dart';

class ParentDelegationScreen extends ConsumerWidget {
  const ParentDelegationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowAction = ref.watch(workflowActionControllerProvider);
    final guardiansState = ref.watch(guardiansFutureProvider);
    final studentsState = ref.watch(studentsFutureProvider);
    final permissionsState = ref.watch(pickupPermissionsStreamProvider);
    final familyStudents = ref.watch(familyStudentsProvider);
    final familyGuardians = ref.watch(familyGuardiansProvider);
    final delegates = ref.watch(familyDelegatesProvider);
    final loadError = _firstError([
      guardiansState,
      studentsState,
      permissionsState,
    ]);
    final isLoading =
        guardiansState.isLoading ||
        studentsState.isLoading ||
        permissionsState.isLoading;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (workflowAction.isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        if (loadError != null) ...[
          ContentStateCard.error(
            title: 'Guardians could not be fully loaded',
            message: '$loadError',
          ),
          const SizedBox(height: 16),
        ],
        DashboardCard(
          title: 'Manage guardians',
          subtitle:
              'Create one-time pickup permissions without sharing the main account.',
          icon: Icons.how_to_reg_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delegates appear in the same repository-backed pickup flow as primary guardians. Staff still releases only after the queue reaches verified.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: familyStudents.isEmpty
                      ? null
                      : () => _openDelegateDialog(context, ref, familyStudents),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Create one-time permission'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading && familyGuardians.isEmpty && delegates.isEmpty) ...[
          const ContentStateCard.loading(
            title: 'Loading guardians and delegates',
            message: 'Resolving linked guardians and temporary permissions.',
          ),
          const SizedBox(height: 16),
        ],
        if (familyGuardians.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No linked guardians',
            message:
                'This parent profile is not currently connected to any guardian records.',
          ),
          const SizedBox(height: 16),
        ] else ...[
          for (final guardian in familyGuardians) ...[
            DashboardCard(
              title: guardian.displayName,
              subtitle: guardian.email,
              icon: Icons.badge_outlined,
              trailing: Chip(label: Text(guardian.phone)),
              child: Text(
                'Linked to ${guardian.studentIds.length} student'
                '${guardian.studentIds.length == 1 ? '' : 's'} in the current school.',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
        if (delegates.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No temporary delegates yet',
            message:
                'Create a one-time permission so another approved adult can appear in the pickup queue.',
          ),
        ] else ...[
          for (final delegate in delegates) ...[
            DashboardCard(
              title: delegate.name,
              subtitle: '${delegate.relationship} | ${delegate.windowLabel}',
              icon: delegate.isActive
                  ? Icons.verified_user_outlined
                  : Icons.history_toggle_off_rounded,
              trailing: Chip(
                label: Text(delegate.isActive ? 'Active' : 'Scheduled'),
              ),
              child: Text(
                delegate.isActive
                    ? 'This delegate can appear in the live pickup queue during the approved window.'
                    : 'This delegate will remain inactive until the approved window begins.',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }

  Future<void> _openDelegateDialog(
    BuildContext context,
    WidgetRef ref,
    List<Student> students,
  ) async {
    final draft = await showDialog<_TemporaryPermissionDraft>(
      context: context,
      builder: (context) => _TemporaryPermissionDialog(students: students),
    );
    if (draft == null) {
      return;
    }

    try {
      await ref
          .read(workflowActionControllerProvider.notifier)
          .createTemporaryPermission(
            studentId: draft.studentId,
            delegateName: draft.delegateName,
            delegatePhone: draft.delegatePhone,
            relationship: draft.relationship,
            startsAt: draft.startsAt,
            endsAt: draft.endsAt,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Temporary pickup permission created for ${draft.delegateName}.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create permission: $error')),
      );
    }
  }
}

class _TemporaryPermissionDialog extends StatefulWidget {
  const _TemporaryPermissionDialog({required this.students});

  final List<Student> students;

  @override
  State<_TemporaryPermissionDialog> createState() =>
      _TemporaryPermissionDialogState();
}

class _TemporaryPermissionDialogState
    extends State<_TemporaryPermissionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationshipController;
  late String _selectedStudentId;
  int _durationMinutes = 90;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _relationshipController = TextEditingController(text: 'Trusted adult');
    _selectedStudentId = widget.students.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create one-time permission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedStudentId,
              decoration: const InputDecoration(labelText: 'Student'),
              items: [
                for (final student in widget.students)
                  DropdownMenuItem<String>(
                    value: student.id,
                    child: Text(student.displayName),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStudentId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Delegate name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Delegate phone'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _relationshipController,
              decoration: const InputDecoration(labelText: 'Relationship'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _durationMinutes,
              decoration: const InputDecoration(labelText: 'Valid for'),
              items: const [
                DropdownMenuItem(value: 60, child: Text('60 minutes')),
                DropdownMenuItem(value: 90, child: Text('90 minutes')),
                DropdownMenuItem(value: 120, child: Text('120 minutes')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _durationMinutes = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit
              ? () {
                  final startsAt = DateTime.now();
                  Navigator.of(context).pop(
                    _TemporaryPermissionDraft(
                      studentId: _selectedStudentId,
                      delegateName: _nameController.text.trim(),
                      delegatePhone: _phoneController.text.trim(),
                      relationship: _relationshipController.text.trim(),
                      startsAt: startsAt,
                      endsAt: startsAt.add(Duration(minutes: _durationMinutes)),
                    ),
                  );
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  bool get _canSubmit {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _relationshipController.text.trim().isNotEmpty;
  }
}

class _TemporaryPermissionDraft {
  const _TemporaryPermissionDraft({
    required this.studentId,
    required this.delegateName,
    required this.delegatePhone,
    required this.relationship,
    required this.startsAt,
    required this.endsAt,
  });

  final String studentId;
  final String delegateName;
  final String delegatePhone;
  final String relationship;
  final DateTime startsAt;
  final DateTime endsAt;
}

Object? _firstError(Iterable<AsyncValue<dynamic>> values) {
  for (final value in values) {
    if (value.hasError) {
      return value.error;
    }
  }
  return null;
}
