import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell_scaffold.dart';

class StaffShellScreen extends StatelessWidget {
  const StaffShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = [
    'Staff Queue',
    'Verification',
    'Announcements',
    'Audit Trail',
  ];

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      roleLabel: 'Teacher/Staff',
      currentIndex: navigationShell.currentIndex,
      title: _titles[navigationShell.currentIndex],
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups_2_rounded),
          label: 'Queue',
        ),
        NavigationDestination(
          icon: Icon(Icons.nfc_outlined),
          selectedIcon: Icon(Icons.nfc_rounded),
          label: 'Verify',
        ),
        NavigationDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign_rounded),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Audit',
        ),
      ],
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      body: navigationShell,
    );
  }
}
