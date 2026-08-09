import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';

/// Lecturer Management & Grading Service for VirtuaNetLab
class LecturerManagementService {
  final FirebaseFirestore _firestore;

  LecturerManagementService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore Namespace Getters (/virtuanetlab/app/...)
  String get _exercisesPath => AppConstants.exercisesCollection;
  String get _logsPath => AppConstants.currentActivityLogsCollection;

  /// Reserves the Firestore document id for an exercise the lecturer is about
  /// to author.
  ///
  /// The id has to exist *before* publishing because the lecturer designs the
  /// solution canvas first, and that canvas is saved under
  /// `{exerciseId}_solution`. Reserving up front is what lets the answer key
  /// point at the canvas they actually built.
  String reserveExerciseId() => _firestore.collection(_exercisesPath).doc().id;

  /// Topology id holding the lecturer's worked solution for [exerciseId].
  static String solutionTopologyIdFor(String exerciseId) =>
      '${exerciseId}_solution';

  /// This course's next assessment number — one more than however many
  /// exercises already exist under [categoryId], published or not.
  /// Deliberately counts unpublished/deleted ones too were there any: the
  /// number marks *when* an assessment was created relative to the others,
  /// not a live position in a re-orderable list, so it must never be
  /// reused even if an earlier assessment is later removed.
  Future<int> _nextAssessmentNumber(String categoryId) async {
    final existing = await _firestore
        .collection(_exercisesPath)
        .where('categoryId', isEqualTo: categoryId)
        .count()
        .get();
    return (existing.count ?? 0) + 1;
  }

  /// Publish a New Practical Exercise with Private Solution Key
  ///
  /// [exerciseId] should come from [reserveExerciseId] so it matches the
  /// solution canvas the lecturer already designed. This wizard only
  /// publishes course exercises now — [practiceLevel] stays null; Free
  /// Practice levels are a separate, seeded curriculum
  /// (`PracticeLevelSeedService`), not something authored ad hoc here.
  Future<bool> createExercise({
    required String exerciseId,
    required String title,
    required String instructions,
    required String exerciseType,
    required String categoryId,
    required String courseTitle,
    required String difficulty,
    required double maxScore,
    required String initialTopologyId,
    String? solutionTopologyId,
    int? timeLimitMinutes,
    Map<String, dynamic>? targetCriteria,
  }) async {
    try {
      final docRef = _firestore.collection(_exercisesPath).doc(exerciseId);
      final now = DateTime.now();
      final assessmentNumber = await _nextAssessmentNumber(categoryId);

      // 1. Write Public Exercise Metadata.
      //
      // Field names here MUST match ExerciseModel's @freezed schema
      // (lib/data/models/exercise_model.dart) exactly — ExerciseModel.fromJson
      // does unchecked `as String` casts on `exerciseId`/`description`/
      // `categoryId`/`exerciseType`, so a mismatched key here doesn't fail
      // quietly, it throws the first time any student reads this exercise
      // back (getExercise / getPracticeLevels / getCourseAssessments all go
      // through ExerciseModel.fromJson unguarded).
      await docRef.set({
        'exerciseId': docRef.id,
        'title': title,
        'description': instructions,
        'categoryId': categoryId,
        'courseTitle': courseTitle,
        'exerciseType': exerciseType,
        'difficulty': difficulty,
        'maxScore': maxScore,
        'initialTopologyId': initialTopologyId,
        'practiceLevel': null,
        'assessmentNumber': assessmentNumber,
        'timeLimitMinutes': timeLimitMinutes,
        'authorUid': FirebaseAuth.instance.currentUser?.uid ?? 'lecturer',
        'isPublished': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      // 2. Write Private Solution Key Sub-Collection Document.
      //
      // Defaults to `{exerciseId}_solution` — a per-exercise id — rather than
      // reusing initialTopologyId or a fixed constant, so every published
      // exercise doesn't silently end up grading student work against the
      // same shared answer key.
      await docRef.collection('private').doc('solution_key').set({
        'solutionTopologyId':
            solutionTopologyId ?? solutionTopologyIdFor(exerciseId),
        'targetCriteria':
            targetCriteria ??
            {
              'icmpPingSuccess': true,
              'ospfAdjacencyVerified': true,
              'vlanTaggingCorrect': true,
            },
        'updatedAt': now.toIso8601String(),
      });

      await _logActivity(
        action: 'PUBLISH_EXERCISE',
        description:
            'Published exercise: $title ($exerciseType, Max: $maxScore)',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Lecturer',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Locks or unlocks [exerciseId] against new submissions.
  ///
  /// Deliberately a separate flag from [ExerciseModel.isPublished] rather
  /// than reusing it: unpublishing removes the assessment from every
  /// student's list outright (including anyone who already submitted),
  /// while locking only closes it to students who have not attempted it
  /// yet — the assessment and any existing results stay visible.
  Future<bool> setExerciseLocked({
    required String exerciseId,
    required bool locked,
  }) async {
    try {
      await _firestore.collection(_exercisesPath).doc(exerciseId).update({
        'isLocked': locked,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await _logActivity(
        action: locked ? 'LOCK_EXERCISE' : 'UNLOCK_EXERCISE',
        description: '${locked ? 'Locked' : 'Unlocked'} exercise $exerciseId',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Lecturer',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates the editable metadata of an already-published exercise.
  ///
  /// Course, exercise type, solution canvas and assessment number are not
  /// editable here — changing course/type would break the drill-down a
  /// student already relies on, and the assessment number marks publish
  /// order rather than being a display label a lecturer can rename.
  Future<bool> updateExercise({
    required String exerciseId,
    required String title,
    required String instructions,
    required String difficulty,
    required double maxScore,
    int? timeLimitMinutes,
  }) async {
    try {
      await _firestore.collection(_exercisesPath).doc(exerciseId).update({
        'title': title,
        'description': instructions,
        'difficulty': difficulty,
        'maxScore': maxScore,
        'timeLimitMinutes': timeLimitMinutes,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await _logActivity(
        action: 'EDIT_EXERCISE',
        description: 'Edited exercise: $title',
        performedBy: FirebaseAuth.instance.currentUser?.email ?? 'Lecturer',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes an exercise outright.
  ///
  /// Only the exercise document itself is removed — the private solution
  /// key, the solution topology and any student `exercise_results`/progress
  /// records referencing this [exerciseId] are left in place. They become
  /// unreachable orphans (nothing queries an exercise by id once its own
  /// document is gone), which is harmless and keeps this a single write
  /// instead of a multi-collection fan-out delete.
  Future<bool> deleteExercise({
    required String exerciseId,
    required String title,
  }) async {
    try {
      await _firestore.collection(_exercisesPath).doc(exerciseId).delete();
      await _logActivity(
        action: 'DELETE_EXERCISE',
        description: 'Deleted exercise: $title',
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
