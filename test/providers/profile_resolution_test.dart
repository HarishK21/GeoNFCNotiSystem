import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/core/providers/app_providers.dart';
import 'package:geo_tap_guardian/data/mock/mock_data_store.dart';
import 'package:geo_tap_guardian/domain/models/user_profile.dart';
import 'package:geo_tap_guardian/domain/repositories/auth_repository.dart';
import 'package:geo_tap_guardian/domain/repositories/user_profile_repository.dart';

void main() {
  test('default mock profile resolves to parent role', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final profileSubscription = container.listen(
      currentUserProfileStreamProvider,
      (previous, next) {},
    );
    final queueSubscription = container.listen(
      queueEntriesStreamProvider,
      (previous, next) {},
    );
    addTearDown(profileSubscription.close);
    addTearDown(queueSubscription.close);

    final profile = await container.read(
      currentUserProfileStreamProvider.future,
    );
    await container.read(queueEntriesStreamProvider.future);

    expect(profile?.uid, MockDataStore.currentUserId);
    expect(container.read(resolvedRoleProvider), AppRole.parent);
    expect(container.read(pickupQueueProvider), hasLength(3));
    expect(
      container.read(releaseReadyQueueProvider).single.studentName,
      'Noah Patel',
    );
  });

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

    final resolvedProfile = await container.read(
      currentUserProfileStreamProvider.future,
    );

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

      await container.read(schoolAnnouncementsStreamProvider.future);
      await container.read(emergencyNoticesStreamProvider.future);

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
