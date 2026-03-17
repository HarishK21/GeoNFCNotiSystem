import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_role.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/dashboard_card.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final environment = ref.watch(appEnvironmentProvider);
    final authAction = ref.watch(authActionControllerProvider);
    final supportsDemo = ref.watch(authSupportsDemoSignInProvider);
    final supportsCredentials = ref.watch(authSupportsCredentialSignInProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GeoTap Guardian',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to continue to the role-specific pickup workflow.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  DashboardCard(
                    title: 'Environment',
                    subtitle: environment.bootstrapMessage,
                    icon: environment.isMockMode
                        ? Icons.developer_mode_rounded
                        : Icons.cloud_done_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            environment.isMockMode
                                ? 'Mock repository mode'
                                : 'Firebase repository mode',
                          ),
                        ),
                        Chip(
                          label: Text(
                            environment.firebaseRequested
                                ? 'Firebase requested'
                                : 'Firebase optional',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (supportsDemo) ...[
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'Demo sign-in',
                      subtitle:
                          'Mock mode stays fully runnable by signing in as a parent or staff user.',
                      icon: Icons.switch_account_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: authAction.isLoading
                                  ? null
                                  : () => ref
                                        .read(authActionControllerProvider.notifier)
                                        .signInAsDemoRole(AppRole.parent),
                              icon: const Icon(Icons.family_restroom_rounded),
                              label: const Text('Continue as Parent Demo'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: authAction.isLoading
                                  ? null
                                  : () => ref
                                        .read(authActionControllerProvider.notifier)
                                        .signInAsDemoRole(AppRole.staff),
                              icon: const Icon(Icons.badge_rounded),
                              label: const Text('Continue as Staff Demo'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (supportsCredentials) ...[
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'Firebase sign-in',
                      subtitle:
                          'This scaffold is ready for real email/password sign-in once Firebase Auth is configured.',
                      icon: Icons.lock_open_rounded,
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: authAction.isLoading
                                  ? null
                                  : () => ref
                                        .read(authActionControllerProvider.notifier)
                                        .signInWithEmailPassword(
                                          email: _emailController.text.trim(),
                                          password: _passwordController.text,
                                        ),
                              child: const Text('Sign in with Firebase Auth'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (authAction.hasError) ...[
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'Sign-in issue',
                      subtitle: 'The app is still safe to use in mock mode.',
                      icon: Icons.error_outline_rounded,
                      child: Text('${authAction.error}'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
