import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell_scaffold.dart';

class ParentShellScreen extends StatelessWidget {
  const ParentShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = [
    'Parent Overview',
    'Today\'s Pickup Queue',
    'Delegation',
    'Announcements',
  ];

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      roleLabel: 'Parent/Guardian',
      currentIndex: navigationShell.currentIndex,
      title: _titles[navigationShell.currentIndex],
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.queue_outlined),
          selectedIcon: Icon(Icons.queue_rounded),
          label: 'Queue',
        ),
        NavigationDestination(
          icon: Icon(Icons.group_add_outlined),
          selectedIcon: Icon(Icons.group_add_rounded),
          label: 'Delegation',
        ),
        NavigationDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign_rounded),
          label: 'Alerts',
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
