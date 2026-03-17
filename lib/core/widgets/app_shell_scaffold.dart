import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({
    super.key,
    required this.roleLabel,
    required this.currentIndex,
    required this.title,
    required this.destinations,
    required this.onDestinationSelected,
    required this.body,
  });

  final String roleLabel;
  final int currentIndex;
  final String title;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final authAction = ref.watch(authActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (value) {
                  if (value == 'sign-out') {
                    ref.read(authActionControllerProvider.notifier).signOut();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    value: 'profile',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.displayName),
                        Text(
                          roleLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'sign-out',
                    enabled: !authAction.isLoading,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}
