import '../../core/models/auth_gate_state.dart';
import '../../core/models/app_role.dart';

class AppRouteGuard {
  static String? redirect({
    required AuthGateState authGate,
    required String location,
  }) {
    final isAuthPath = location == '/sign-in';
    final isLoadingPath = location == '/loading';
    final isProfileErrorPath = location == '/profile-unavailable';

    if (authGate.isLoading) {
      return isLoadingPath ? null : '/loading';
    }

    if (authGate.isSignedOut) {
      return isAuthPath ? null : '/sign-in';
    }

    if (authGate.status == AuthGateStatus.profileUnavailable) {
      return isProfileErrorPath ? null : '/profile-unavailable';
    }

    final role = authGate.role;
    if (role == null) {
      return isProfileErrorPath ? null : '/profile-unavailable';
    }

    if (isAuthPath || isLoadingPath || isProfileErrorPath || location == '/') {
      return role.defaultRoute;
    }

    if (location.startsWith('/parent') && role != AppRole.parent) {
      return role.defaultRoute;
    }

    if (location.startsWith('/staff') && role != AppRole.staff) {
      return role.defaultRoute;
    }

    return null;
  }
}
