import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../data/firebase/firestore_repositories.dart';
import '../../data/mock/mock_data_store.dart';
import '../../data/mock/mock_repositories.dart';
import '../../domain/repositories/audit_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/guardian_repository.dart';
import '../../domain/repositories/notice_repository.dart';
import '../../domain/repositories/pickup_event_repository.dart';
import '../../domain/repositories/pickup_permission_repository.dart';
import '../../domain/repositories/queue_repository.dart';
import '../../domain/repositories/release_event_repository.dart';
import '../../domain/repositories/school_repository.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';

final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  return const AppEnvironment(
    dataSource: AppDataSource.mock,
    firebaseRequested: false,
    firebaseConfigured: false,
    bootstrapMessage:
        'Mock mode enabled. Pass --dart-define=USE_FIREBASE=true to attempt Firebase startup.',
    androidFirst: true,
    nfcEnabledFlows: true,
  );
});

final mockDataStoreProvider = Provider<MockDataStore>((ref) {
  final store = MockDataStore();
  ref.onDispose(store.dispose);
  return store;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestoreAuthRepository(FirebaseAuth.instance);
  }
  return MockAuthRepository(ref.watch(mockDataStoreProvider));
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestoreUserProfileRepository(FirebaseFirestore.instance);
  }
  return MockUserProfileRepository(ref.watch(mockDataStoreProvider));
});

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestoreSchoolRepository(FirebaseFirestore.instance);
  }
  return MockSchoolRepository(ref.watch(mockDataStoreProvider));
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestoreStudentRepository(FirebaseFirestore.instance);
  }
  return MockStudentRepository(ref.watch(mockDataStoreProvider));
});

final guardianRepositoryProvider = Provider<GuardianRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestoreGuardianRepository(FirebaseFirestore.instance);
  }
  return MockGuardianRepository(ref.watch(mockDataStoreProvider));
});

final pickupPermissionRepositoryProvider = Provider<PickupPermissionRepository>(
  (ref) {
    final environment = ref.watch(appEnvironmentProvider);
    if (environment.dataSource == AppDataSource.firebase) {
      return FirestorePickupPermissionRepository(FirebaseFirestore.instance);
    }
    return MockPickupPermissionRepository(ref.watch(mockDataStoreProvider));
  },
);

final pickupEventRepositoryProvider = Provider<PickupEventRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestorePickupEventRepository(FirebaseFirestore.instance);
  }
  return MockPickupEventRepository(ref.watch(mockDataStoreProvider));
});

final releaseEventRepositoryProvider = Provider<ReleaseEventRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestoreReleaseEventRepository(FirebaseFirestore.instance);
  }
  return MockReleaseEventRepository(ref.watch(mockDataStoreProvider));
});

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestoreNoticeRepository(FirebaseFirestore.instance);
  }
  return MockNoticeRepository(ref.watch(mockDataStoreProvider));
});

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestoreQueueRepository(FirebaseFirestore.instance);
  }
  return MockQueueRepository(ref.watch(mockDataStoreProvider));
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource == AppDataSource.firebase) {
    return FirestoreAuditRepository(FirebaseFirestore.instance);
  }
  return MockAuditRepository(ref.watch(mockDataStoreProvider));
});
