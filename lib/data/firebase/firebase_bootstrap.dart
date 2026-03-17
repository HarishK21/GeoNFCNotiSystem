import 'package:firebase_core/firebase_core.dart';

import '../../core/config/app_environment.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap();

  Future<AppEnvironment> initialize() async {
    const firebaseRequested = bool.fromEnvironment(
      'USE_FIREBASE',
      defaultValue: false,
    );

    if (!firebaseRequested) {
      return const AppEnvironment(
        dataSource: AppDataSource.mock,
        firebaseRequested: false,
        firebaseConfigured: false,
        bootstrapMessage:
            'Mock mode enabled. Pass --dart-define=USE_FIREBASE=true to attempt Firebase startup.',
        androidFirst: true,
        nfcEnabledFlows: true,
      );
    }

    try {
      await Firebase.initializeApp();
      return const AppEnvironment(
        dataSource: AppDataSource.firebase,
        firebaseRequested: true,
        firebaseConfigured: true,
        bootstrapMessage: 'Firebase initialized successfully.',
        androidFirst: true,
        nfcEnabledFlows: true,
      );
    } catch (error) {
      return AppEnvironment(
        dataSource: AppDataSource.mock,
        firebaseRequested: true,
        firebaseConfigured: false,
        bootstrapMessage:
            'Firebase startup failed, so the app fell back to mock mode: $error',
        androidFirst: true,
        nfcEnabledFlows: true,
      );
    }
  }
}
