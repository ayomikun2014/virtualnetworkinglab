import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';

/// Admin Provisioning & System Service for VirtuaNetLab
class AdminProvisionService {
  final FirebaseFirestore _firestore;

  AdminProvisionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Root Namespace Path: /virtuanetlab/app
  ///
  /// `AppConstants.usersCollection` already includes `rootPath` — prefixing
  /// it again pointed every write here at a phantom
  /// `virtuanetlab/app/virtuanetlab/app/users` collection that the real
  /// login flow (AuthService, AuthRepository) never reads, so a
  /// provisioned lecturer's profile silently went nowhere useful. Now
  /// matches the collection auth actually reads.
  String get _usersPath => AppConstants.usersCollection;
  String get _logsPath => AppConstants.currentActivityLogsCollection;

  /// Approves a self-registered lecturer and assigns their courses in one
  /// step — an unapproved lecturer has no courses, so "approve" without a
  /// course list would just be a different kind of unusable account.
  Future<bool> approveLecturer({
    required String uid,
    required String displayName,
    required List<Map<String, String>> assignedCourses,
  }) async {
    try {
      await _firestore.collection(_usersPath).doc(uid).set({
        'approvalStatus': 'approved',
        'assignedCourses': assignedCourses,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      await logActivity(
        action: 'APPROVE_LECTURER',
        description:
            'Approved lecturer $displayName with '
            '${assignedCourses.length} course'
            '${assignedCourses.length == 1 ? '' : 's'} assigned',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Root Admin',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Edits an already-approved lecturer's department and course list.
  Future<bool> updateLecturerAssignment({
    required String uid,
    required String displayName,
    required String departmentId,
    required List<Map<String, String>> assignedCourses,
  }) async {
    try {
      await _firestore.collection(_usersPath).doc(uid).set({
        'departmentId': departmentId,
        'assignedCourses': assignedCourses,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      await logActivity(
        action: 'UPDATE_LECTURER',
        description: 'Updated course assignment for $displayName',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Root Admin',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Suspends or reactivates any account. Firestore-only: this flips the
  /// `isActive` flag `FirebaseAuthRepository.login` checks, which is enough
  /// to lock a suspended user out on their next sign-in. It does not touch
  /// their Firebase Auth credentials — revoking those needs the Admin SDK,
  /// which means a Cloud Function this project doesn't have. A currently
  /// signed-in session on the suspended device also isn't force-ended; it
  /// only takes effect at the next login.
  Future<bool> setUserActive({
    required String uid,
    required String displayName,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection(_usersPath).doc(uid).set({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      await logActivity(
        action: isActive ? 'REACTIVATE_ACCOUNT' : 'SUSPEND_ACCOUNT',
        description:
            '${isActive ? 'Reactivated' : 'Suspended'} account for '
            '$displayName',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Root Admin',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes a user's profile — used for deleting a student or lecturer,
  /// and for rejecting a pending lecturer application.
  ///
  /// Firestore-only, same limitation as [setUserActive]: their Firebase
  /// Auth account is not deleted, so the email/password still work. What
  /// removing the profile actually does is send them through
  /// `FirebaseAuthRepository._fetchUserProfile`'s no-profile branch on
  /// their next login, which re-provisions them as a brand-new Level 1
  /// student with none of what was just deleted — for a rejected lecturer
  /// application, landing back at "ordinary student" is a reasonable
  /// outcome, not a security hole.
  Future<bool> deleteUserProfile({
    required String uid,
    required String displayName,
  }) async {
    try {
      await _firestore.collection(_usersPath).doc(uid).delete();

      await logActivity(
        action: 'DELETE_PROFILE',
        description: 'Deleted profile for $displayName',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Root Admin',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Log Activity & Audit Event
  Future<void> logActivity({
    required String action,
    required String description,
    required String performedBy,
  }) async {
    try {
      final now = DateTime.now();
      final logDoc = _firestore.collection(_logsPath).doc();

      await logDoc.set({
        'id': logDoc.id,
        'action': action,
        'description': description,
        'performedBy': performedBy,
        'timestamp': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
      });
    } catch (_) {
      // Fail-safe
    }
  }
}
