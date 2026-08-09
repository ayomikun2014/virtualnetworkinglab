import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../enums/app_enums.dart';
import '../../data/models/user_model.dart';

/// Admin Bootstrapping Service for VirtuaNetLab
///
/// Executed during application launch in [main.dart]. Checks if an administrative
/// user exists in Cloud Firestore. If absent, creates the root admin profile document.
class AdminSeedService {
  final FirebaseFirestore _firestore;

  AdminSeedService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Seeding routine executed on app launch. Creates default Root Administrator if none exists.
  Future<void> bootstrapRootAdmin() async {
    try {
      final adminQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      // If an administrator already exists in Firestore, skip seeding
      if (adminQuery.docs.isNotEmpty) {
        return;
      }

      final now = DateTime.now();
      const adminUid = 'root_admin_seed';

      final rootAdmin = UserModel(
        uid: adminUid,
        email: 'adminlab@gmail.com',
        displayName: 'Root Administrator',
        role: UserRole.admin,
        departmentId: 'dept_admin',
        isActive: true,
        lastLoginAt: now,
        createdAt: now,
        updatedAt: now,
        stats: {'completedExercises': 0, 'totalScore': 0},
      );

      // Write default root admin profile to Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(adminUid)
          .set(rootAdmin.toJson(), SetOptions(merge: true));
    } catch (e) {
      // Log error safely without crashing application launch
      // In production, logged to Crashlytics / Monitoring
    }
  }
}
