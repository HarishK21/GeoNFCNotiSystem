import '../models/pickup_permission.dart';

abstract class PickupPermissionRepository {
  Stream<List<PickupPermission>> watchPermissions(String schoolId);
  Future<void> createPermission(PickupPermission permission);
}
