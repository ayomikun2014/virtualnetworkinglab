import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/exercise_model.dart';

/// Contract interface for Exercise & Practice Level Repository
abstract class IExerciseRepository {
  Future<List<ExerciseModel>> getPracticeLevels();
  Future<List<ExerciseModel>> getCourseAssessments(
    List<String> enrolledCourseIds,
  );
  Future<ExerciseModel> getExercise(String exerciseId);
}

/// Firebase & Cloud Firestore implementation of Exercise Repository
class FirebaseExerciseRepository implements IExerciseRepository {
  final FirebaseFirestore _firestore;

  FirebaseExerciseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ExerciseModel>> getPracticeLevels() async {
    try {
      final snap = await _firestore
          .collection(AppConstants.exercisesCollection)
          .where('isPublished', isEqualTo: true)
          .where('practiceLevel', isGreaterThan: 0)
          .orderBy('practiceLevel', descending: false)
          .get();

      return snap.docs
          .map((doc) => ExerciseModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to load free practice levels: $e');
    }
  }

  @override
  Future<List<ExerciseModel>> getCourseAssessments(
    List<String> enrolledCourseIds,
  ) async {
    if (enrolledCourseIds.isEmpty) return [];
    try {
      final snap = await _firestore
          .collection(AppConstants.exercisesCollection)
          .where('isPublished', isEqualTo: true)
          .where('categoryId', whereIn: enrolledCourseIds.take(10).toList())
          .get();

      return snap.docs
          .map((doc) => ExerciseModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to load course assessments: $e');
    }
  }

  @override
  Future<ExerciseModel> getExercise(String exerciseId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.exercisesCollection)
          .doc(exerciseId)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw const ServerFailure('Exercise not found.');
      }

      return ExerciseModel.fromJson(doc.data()!);
    } catch (e) {
      throw ServerFailure('Failed to load exercise details: $e');
    }
  }
}
