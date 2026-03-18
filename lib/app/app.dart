import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class GeoTapGuardianApp extends ConsumerWidget {
  const GeoTapGuardianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(deviceIntegrationBootstrapProvider);
    ref.watch(workflowHardeningBootstrapProvider);
    ref.watch(notificationSubscriptionBootstrapProvider);

    return MaterialApp.router(
      title: 'GeoTap Guardian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
