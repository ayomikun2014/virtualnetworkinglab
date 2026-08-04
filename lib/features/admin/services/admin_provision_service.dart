import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';

/// Admin Provisioning & System Service for VirtuaNetLab
class AdminProvisionService {
  final FirebaseFirestore _firestore;

  AdminProvisionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Root Namespace Path: /virtuanetlab/app
  String get _usersPath => '${AppConstants.rootPath}/${AppConstants.usersCollection}';
  String get _coursesPath => '${AppConstants.rootPath}/${AppConstants.coursesCollection}';
  String get _logsPath => '${AppConstants.rootPath}/${AppConstants.activityLogsCollection}';

  /// Provision a New Faculty / Lecturer Account in Firestore
  Future<bool> provisionLecturer({
    required String email,
    required String password,
    required String displayName,
    required String departmentId,
    required List<String> taughtClassIds,
  }) async {
    try {
      // 1. Check if user with this email already exists
      final query = await _firestore
          .collection(_usersPath)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      String docUid;
      if (query.docs.isNotEmpty) {
        docUid = query.docs.first.id;
      } else {
        docUid = _firestore.collection(_usersPath).doc().id;
      }

      final now = DateTime.now();

      // 2. Write Lecturer Profile to Firestore Namespace /virtuanetlab/app/users/{uid}
      await _firestore.collection(_usersPath).doc(docUid).set({
        'uid': docUid,
        'email': email,
        'displayName': displayName,
        'photoURL': null,
        'studentIdNumber': null,
        'role': UserRole.lecturer.name,
        'departmentId': departmentId,
        'taughtClassIds': taughtClassIds,
        'enrolledCourseIds': [],
        'freePracticeLevel': 1,
        'isActive': true,
        'lastLoginAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'stats': {'provisionedByAdmin': true},
      }, SetOptions(merge: true));

      // 3. Log System Provisioning Event
      await logActivity(
        action: 'PROVISION_LECTURER',
        description: 'Provisioned lecturer account for $displayName ($email) in $departmentId',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Root Admin',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create a New Academic Department
  Future<bool> createDepartment({
    required String id,
    required String name,
    required String code,
  }) async {
    try {
      final deptPath = '${AppConstants.rootPath}/departments';
      final now = DateTime.now();

      await _firestore.collection(deptPath).doc(id).set({
        'id': id,
        'name': name,
        'code': code,
        'createdAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      await logActivity(
        action: 'CREATE_DEPARTMENT',
        description: 'Created department $name ($code)',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Root Admin',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Create a New Course / Curriculum Entry
  Future<bool> createCourse({
    required String id,
    required String title,
    required String code,
    required String departmentId,
  }) async {
    try {
      final now = DateTime.now();

      await _firestore.collection(_coursesPath).doc(id).set({
        'id': id,
        'title': title,
        'code': code,
        'departmentId': departmentId,
        'createdAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      await logActivity(
        action: 'CREATE_COURSE',
        description: 'Created course $title ($code) under $departmentId',
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
