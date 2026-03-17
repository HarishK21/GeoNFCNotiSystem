import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/parent/presentation/parent_shell_screen.dart';
import '../../features/parent/presentation/screens/parent_announcements_screen.dart';
import '../../features/parent/presentation/screens/parent_delegation_screen.dart';
import '../../features/parent/presentation/screens/parent_home_screen.dart';
import '../../features/parent/presentation/screens/parent_queue_screen.dart';
import '../../features/role_selection/presentation/role_selection_screen.dart';
import '../../features/staff/presentation/screens/staff_announcements_screen.dart';
import '../../features/staff/presentation/screens/staff_audit_screen.dart';
import '../../features/staff/presentation/screens/staff_queue_screen.dart';
import '../../features/staff/presentation/screens/staff_verification_screen.dart';
import '../../features/staff/presentation/staff_shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ParentShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/home',
                name: 'parent-home',
                builder: (context, state) => const ParentHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/queue',
                name: 'parent-queue',
                builder: (context, state) => const ParentQueueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/delegation',
                name: 'parent-delegation',
                builder: (context, state) => const ParentDelegationScreen(),
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
                path: '/staff/verification',
                name: 'staff-verification',
                builder: (context, state) => const StaffVerificationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff/announcements',
                name: 'staff-announcements',
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
