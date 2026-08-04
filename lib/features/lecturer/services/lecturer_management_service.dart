import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';

/// Lecturer Management & Grading Service for VirtuaNetLab
class LecturerManagementService {
  final FirebaseFirestore _firestore;

  LecturerManagementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore Namespace Getters (/virtuanetlab/app/...)
  String get _classesPath => '${AppConstants.rootPath}/${AppConstants.classesCollection}';
  String get _exercisesPath => '${AppConstants.rootPath}/${AppConstants.exercisesCollection}';
  String get _submissionsPath => '${AppConstants.rootPath}/submissions';
  String get _logsPath => '${AppConstants.rootPath}/${AppConstants.activityLogsCollection}';

  /// Generate Unique 8-Character Alphanumeric Join Code (e.g., NET2026A)
  String _generateJoinCode(String courseCode) {
    final cleanCode = courseCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final prefix = cleanCode.length >= 3 ? cleanCode.substring(0, 3) : 'NET';
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();

    return '$prefix$suffix';
  }

  /// Create a New Class Section & Generate Join Code
  Future<Map<String, dynamic>?> createClass({
    required String courseId,
    required String sectionName,
    required String lecturerUid,
    required String semester,
  }) async {
    try {
      final docRef = _firestore.collection(_classesPath).doc();
      final joinCode = _generateJoinCode(courseId);
      final now = DateTime.now();

      final classData = {
        'id': docRef.id,
        'courseId': courseId,
        'sectionName': sectionName,
        'lecturerUid': lecturerUid,
        'semester': semester,
        'joinCode': joinCode,
        'studentCount': 0,
        'isActive': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await docRef.set(classData);

      // Log class creation activity
      await _logActivity(
        action: 'CREATE_CLASS',
        description: 'Created class $sectionName for course $courseId with Join Code: $joinCode',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Lecturer',
      );

      return classData;
    } catch (_) {
      return null;
    }
  }

  /// Publish a New Practical Exercise with Private Solution Key
  Future<bool> createExercise({
    required String title,
    required String instructions,
    required String exerciseType,
    required String difficulty,
    required double maxScore,
    required String initialTopologyId,
    String? solutionTopologyId,
    Map<String, dynamic>? targetCriteria,
  }) async {
    try {
      final docRef = _firestore.collection(_exercisesPath).doc();
      final now = DateTime.now();

      // 1. Write Public Exercise Metadata
      await docRef.set({
        'id': docRef.id,
        'title': title,
        'instructions': instructions,
        'type': exerciseType,
        'difficulty': difficulty,
        'maxScore': maxScore,
        'initialTopologyId': initialTopologyId,
        'authorUid': FirebaseAuth.instance.currentUser?.uid ?? 'lecturer',
        'isPublished': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      // 2. Write Private Solution Key Sub-Collection Document
      await docRef.collection('private').doc('solution_key').set({
        'solutionTopologyId': solutionTopologyId ?? initialTopologyId,
        'targetCriteria': targetCriteria ?? {
          'icmpPingSuccess': true,
          'ospfAdjacencyVerified': true,
          'vlanTaggingCorrect': true,
        },
        'updatedAt': now.toIso8601String(),
      });

      await _logActivity(
        action: 'PUBLISH_EXERCISE',
        description: 'Published exercise: $title ($exerciseType, Max: $maxScore)',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Lecturer',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Submit Lecturer Manual Grade Override & Feedback
  Future<bool> submitGradeOverride({
    required String submissionId,
    required double finalScore,
    required String feedback,
    required String lecturerUid,
  }) async {
    try {
      final docRef = _firestore.collection(_submissionsPath).doc(submissionId);
      final now = DateTime.now();

      await docRef.set({
        'finalScore': finalScore,
        'lecturerFeedback': feedback,
        'gradedByUid': lecturerUid,
        'gradedAt': now.toIso8601String(),
        'status': 'graded',
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      await _logActivity(
        action: 'GRADE_SUBMISSION',
        description: 'Graded submission $submissionId with score $finalScore',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Lecturer',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Log Internal Activity Event
  Future<void> _logActivity({
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
    } catch (_) {}
  }
}
