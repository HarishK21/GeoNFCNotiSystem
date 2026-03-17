import '../../core/models/app_role.dart';
import '../../domain/models/user_profile.dart';

enum AuthGateStatus { loading, signedOut, profileUnavailable, authenticated }

class AuthGateState {
  const AuthGateState._({required this.status, this.profile, this.message});

  const AuthGateState.loading()
    : this._(status: AuthGateStatus.loading, message: 'Resolving session...');

  const AuthGateState.signedOut()
    : this._(status: AuthGateStatus.signedOut, message: 'Sign in to continue.');

  const AuthGateState.profileUnavailable({String? message})
    : this._(
        status: AuthGateStatus.profileUnavailable,
        message: message ?? 'No profile document was found for this account.',
      );

  const AuthGateState.authenticated(UserProfile profile)
    : this._(status: AuthGateStatus.authenticated, profile: profile);

  final AuthGateStatus status;
  final UserProfile? profile;
  final String? message;

  bool get isLoading => status == AuthGateStatus.loading;
  bool get isSignedOut => status == AuthGateStatus.signedOut;
  bool get isAuthenticated => status == AuthGateStatus.authenticated;
  AppRole? get role => profile?.role;
}
