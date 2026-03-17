import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/app/router/app_route_guard.dart';
import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/core/models/auth_gate_state.dart';
import 'package:geo_tap_guardian/domain/models/user_profile.dart';

void main() {
  test('signed-out users are redirected to sign-in', () {
    final redirect = AppRouteGuard.redirect(
      authGate: const AuthGateState.signedOut(),
      location: '/parent/plan',
    );

    expect(redirect, '/sign-in');
  });

  test('parent users cannot enter staff routes', () {
    final redirect = AppRouteGuard.redirect(
      authGate: AuthGateState.authenticated(_profile(AppRole.parent)),
      location: '/staff/queue',
    );

    expect(redirect, '/parent/plan');
  });

  test('staff users are routed away from sign-in after auth', () {
    final redirect = AppRouteGuard.redirect(
      authGate: AuthGateState.authenticated(_profile(AppRole.staff)),
      location: '/sign-in',
    );

    expect(redirect, '/staff/queue');
  });

  test('missing profiles route to profile unavailable', () {
    final redirect = AppRouteGuard.redirect(
      authGate: const AuthGateState.profileUnavailable(),
      location: '/parent/plan',
    );

    expect(redirect, '/profile-unavailable');
  });
}

UserProfile _profile(AppRole role) {
  return UserProfile(
    uid: 'user_1',
    role: role,
    schoolId: 'school_1',
    displayName: 'Demo User',
    email: 'demo@example.com',
  );
}
