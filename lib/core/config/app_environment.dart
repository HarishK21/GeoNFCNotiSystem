enum AppDataSource { mock, firebase }

class AppEnvironment {
  const AppEnvironment({
    required this.dataSource,
    required this.firebaseRequested,
    required this.firebaseConfigured,
    required this.bootstrapMessage,
    required this.androidFirst,
    required this.nfcEnabledFlows,
  });

  final AppDataSource dataSource;
  final bool firebaseRequested;
  final bool firebaseConfigured;
  final String bootstrapMessage;
  final bool androidFirst;
  final bool nfcEnabledFlows;

  bool get isMockMode => dataSource == AppDataSource.mock;
}
