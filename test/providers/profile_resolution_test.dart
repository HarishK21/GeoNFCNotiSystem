import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/core/models/auth_gate_state.dart';
import 'package:geo_tap_guardian/core/providers/app_providers.dart';
import 'package:geo_tap_guardian/data/mock/mock_data_store.dart';
import 'package:geo_tap_guardian/domain/models/user_profile.dart';
import 'package:geo_tap_guardian/domain/repositories/auth_repository.dart';
import 'package:geo_tap_guardian/domain/repositories/user_profile_repository.dart';

void main() {
  test(
    'mock mode starts signed out and resolves a parent demo profile',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authSubscription = container.listen(
        currentUserIdStreamProvider,
        (previous, next) {},
      );
      final profileSubscription = container.listen(
        currentUserProfileStreamProvider,
        (previous, next) {},
      );
      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      addTearDown(authSubscription.close);
      addTearDown(profileSubscription.close);
      addTearDown(queueSubscription.close);

      await _waitFor(
        () => container.read(currentUserIdStreamProvider).hasValue,
      );

      final initialUserId = container
          .read(currentUserIdStreamProvider)
          .asData
          ?.value;
      expect(initialUserId, isNull);
      expect(
        container.read(authGateStateProvider).status,
        AuthGateStatus.signedOut,
      );

      await container
          .read(authActionControllerProvider.notifier)
          .signInAsDemoRole(AppRole.parent);

      await _waitFor(() {
        return container.read(currentUserProfileStreamProvider).asData?.value !=
            null;
      });
      await container.read(guardiansFutureProvider.future);
      await container.read(studentsFutureProvider.future);
      await _waitFor(() => container.read(queueEntriesStreamProvider).hasValue);

      final profile = container
          .read(currentUserProfileStreamProvider)
          .asData
          ?.value;
      expect(profile?.uid, MockDataStore.parentUserId);
      expect(container.read(resolvedRoleProvider), AppRole.parent);
      expect(container.read(familyPickupQueueProvider), hasLength(1));
      expect(
        container.read(familyPickupQueueProvider).single.studentName,
        'Maya Brooks',
      );
    },
  );

  test('overridden repositories resolve a staff profile', () async {
    const profile = UserProfile(
      uid: 'staff_2',
      role: AppRole.staff,
      schoolId: MockDataStore.primarySchoolId,
      displayName: 'Coach Rivera',
      email: 'rivera@example.com',
      phone: '+1-555-0199',
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _TestAuthRepository(profile.uid),
        ),
        userProfileRepositoryProvider.overrideWithValue(
          _TestUserProfileRepository(profile),
        ),
      ],
    );
    addTearDown(container.dispose);

    final profileSubscription = container.listen(
      currentUserProfileStreamProvider,
      (previous, next) {},
    );
    addTearDown(profileSubscription.close);

    await _waitFor(() {
      return container.read(currentUserProfileStreamProvider).asData?.value !=
          null;
    });

    final resolvedProfile = container
        .read(currentUserProfileStreamProvider)
        .asData
        ?.value;

    expect(resolvedProfile?.displayName, 'Coach Rivera');
    expect(container.read(resolvedRoleProvider), AppRole.staff);
    expect(
      container.read(currentSchoolIdProvider),
      MockDataStore.primarySchoolId,
    );
  });

  test(
    'announcement feed merges school announcements and emergency notices',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final announcementsSubscription = container.listen(
        schoolAnnouncementsStreamProvider,
        (previous, next) {},
      );
      final emergencySubscription = container.listen(
        emergencyNoticesStreamProvider,
        (previous, next) {},
      );
      addTearDown(announcementsSubscription.close);
      addTearDown(emergencySubscription.close);

      await _waitFor(
        () => container.read(schoolAnnouncementsStreamProvider).hasValue,
      );
      await _waitFor(
        () => container.read(emergencyNoticesStreamProvider).hasValue,
      );

      final announcements = container.read(announcementsProvider);
      expect(announcements, hasLength(2));
      expect(announcements.first.title, 'Weather-adjusted dismissal today');
      expect(announcements.last.title, 'Emergency drill reminder');
    },
  );
}

class _TestAuthRepository implements AuthRepository {
  const _TestAuthRepository(this._uid);

  final String _uid;

  @override
  String? getCurrentUserId() => _uid;

  @override
  bool get supportsCredentialSignIn => false;

  @override
  bool get supportsDemoSignIn => false;

  @override
  Future<void> signInAsDemoRole(AppRole role) async {}

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Stream<String?> watchCurrentUserId() => Stream<String?>.value(_uid);
}

class _TestUserProfileRepository implements UserProfileRepository {
  const _TestUserProfileRepository(this._profile);

  final UserProfile _profile;

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return Stream<UserProfile?>.value(uid == _profile.uid ? _profile : null);
  }
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('Timed out while waiting for provider state.');
}
