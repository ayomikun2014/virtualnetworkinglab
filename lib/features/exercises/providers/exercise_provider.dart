import 'package:flutter/foundation.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/repositories/exercise_repository.dart';

/// State Management Provider for Free Practice Mode & Course Assessments
class ExerciseProvider extends ChangeNotifier {
  final IExerciseRepository _repository;

  List<ExerciseModel> _practiceLevels = [];
  List<ExerciseModel> _courseAssessments = [];
  ExerciseModel? _activeExercise;

  bool _isLoading = false;
  String? _errorMessage;

  ExerciseProvider({IExerciseRepository? repository})
      : _repository = repository ?? FirebaseExerciseRepository();

  // Getters
  List<ExerciseModel> get practiceLevels => _practiceLevels;
  List<ExerciseModel> get courseAssessments => _courseAssessments;
  ExerciseModel? get activeExercise => _activeExercise;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches published Free Practice levels (Level 1: IP -> Level 2: Subnetting -> Level 3: VLANs -> Level 4: OSPF)
  Future<void> fetchPracticeLevels() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _practiceLevels = await _repository.getPracticeLevels();
    } on Failure catch (f) {
      _errorMessage = f.message;
    } catch (e) {
      _errorMessage = 'Failed to load practice levels: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches class-scoped course assessments for student's enrolled courses
  Future<void> fetchCourseAssessments(List<String> enrolledCourseIds) async {
    if (enrolledCourseIds.isEmpty) {
      _courseAssessments = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _courseAssessments = await _repository.getCourseAssessments(enrolledCourseIds);
    } on Failure catch (f) {
      _errorMessage = f.message;
    } catch (e) {
      _errorMessage = 'Failed to load course assessments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects active exercise for canvas or lab execution
  void selectActiveExercise(ExerciseModel exercise) {
    _activeExercise = exercise;
    notifyListeners();
  }

  /// Clears active exercise selection
  void clearActiveExercise() {
    _activeExercise = null;
    notifyListeners();
  }
}
