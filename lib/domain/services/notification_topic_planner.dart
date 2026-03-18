import '../../core/models/app_role.dart';
import '../models/user_profile.dart';

class NotificationTopicPlanner {
  const NotificationTopicPlanner();

  Set<String> topicsForProfile(UserProfile profile) {
    final topics = <String>{_emergencyTopic(profile.schoolId)};

    switch (profile.role) {
      case AppRole.staff:
        topics.add(_staffTopic(profile.schoolId));
      case AppRole.parent:
        final guardianId = profile.linkedGuardianId;
        if (guardianId != null && guardianId.isNotEmpty) {
          topics.add(_guardianTopic(profile.schoolId, guardianId));
        }
    }

    return topics;
  }
}

String _staffTopic(String schoolId) => 'school_${schoolId}_staff';

String _guardianTopic(String schoolId, String guardianId) {
  return 'school_${schoolId}_guardian_$guardianId';
}

String _emergencyTopic(String schoolId) => 'school_${schoolId}_emergency';
