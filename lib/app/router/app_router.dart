import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../features/auth/presentation/screens/auth_loading_screen.dart';
import '../../features/auth/presentation/screens/profile_unavailable_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/parent/presentation/parent_shell_screen.dart';
import '../../features/parent/presentation/screens/parent_announcements_screen.dart';
import '../../features/parent/presentation/screens/parent_delegation_screen.dart';
import '../../features/parent/presentation/screens/parent_home_screen.dart';
import '../../features/parent/presentation/screens/parent_queue_screen.dart';
import '../../features/staff/presentation/screens/staff_announcements_screen.dart';
import '../../features/staff/presentation/screens/staff_audit_screen.dart';
import '../../features/staff/presentation/screens/staff_queue_screen.dart';
import '../../features/staff/presentation/screens/staff_verification_screen.dart';
import '../../features/staff/presentation/staff_shell_screen.dart';
import 'app_route_guard.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authGate = ref.watch(authGateStateProvider);

  return GoRouter(
    initialLocation: '/loading',
    redirect: (context, state) {
      return AppRouteGuard.redirect(
        authGate: authGate,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: '/loading',
        name: 'auth-loading',
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/profile-unavailable',
        name: 'profile-unavailable',
        builder: (context, state) => const ProfileUnavailableScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ParentShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/plan',
                name: 'parent-plan',
                builder: (context, state) => const ParentHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/guardians',
                name: 'parent-guardians',
                builder: (context, state) => const ParentDelegationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/history',
                name: 'parent-history',
                builder: (context, state) => const ParentQueueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/announcements',
                name: 'parent-announcements',
                builder: (context, state) => const ParentAnnouncementsScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StaffShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff/queue',
                name: 'staff-queue',
                builder: (context, state) => const StaffQueueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff/students',
                name: 'staff-students',
                builder: (context, state) => const StaffVerificationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff/exceptions',
                name: 'staff-exceptions',
                builder: (context, state) => const StaffAnnouncementsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff/audit',
                name: 'staff-audit',
                builder: (context, state) => const StaffAuditScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
