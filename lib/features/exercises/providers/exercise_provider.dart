import 'package:flutter/foundation.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/practice_level_seed_service.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/repositories/exercise_repository.dart';

/// State Management Provider for Free Practice Mode & Course Assessments
class ExerciseProvider extends ChangeNotifier {
  final IExerciseRepository _repository;
  final IPracticeLevelSeedService _seedService;

  List<ExerciseModel> _practiceLevels = [];
  List<ExerciseModel> _courseAssessments = [];
  ExerciseModel? _activeExercise;

  bool _isLoading = false;
  String? _errorMessage;

  /// Seeding is attempted at most once per session, so a deployment where
  /// writes are genuinely rejected doesn't retry on every screen visit.
  bool _hasAttemptedSeed = false;

  ExerciseProvider({
    IExerciseRepository? repository,
    IPracticeLevelSeedService? seedService,
  }) : _repository = repository ?? FirebaseExerciseRepository(),
       _seedService = seedService ?? PracticeLevelSeedService();

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

      // Bring the starter curriculum up to date.
      //
      // Seeding used to run in main() before runApp — i.e. before anyone
      // signs in. Any Firestore deployment whose rules require an
      // authenticated request rejects every one of those writes, silently,
      // leaving Free Practice permanently empty with no clue why. Doing it
      // here instead means it runs as a signed-in user (both callers of
      // this method sit behind the router's auth guard), and any remaining
      // failure is reported rather than swallowed.
      //
      // Deliberately NOT gated on `_practiceLevels.isEmpty`. That made the
      // starter set write-once: a database with the original four levels
      // was never empty, so the seeder was never called again and levels
      // 5–20 could not reach it no matter how many times the student
      // reloaded. bootstrapPracticeLevels is idempotent and version-aware,
      // so it is safe — and necessary — to ask it on every session.
      if (!_hasAttemptedSeed) {
        _hasAttemptedSeed = true;
        final outcome = await _seedService.bootstrapPracticeLevels();

        if (outcome.seededAnything) {
          _practiceLevels = await _repository.getPracticeLevels();
        } else if (outcome.error != null) {
          _errorMessage =
              'Could not create the starter practice levels: ${outcome.error}';
          debugPrint('practice level seeding failed: ${outcome.error}');
        }
      }
    } on Failure catch (f) {
      _errorMessage = f.message;
      // Also to the browser console: Firestore embeds a direct
      // "create this index" link in the message, and the console auto-links
      // URLs — the on-screen error banner doesn't render it as clickable.
      debugPrint('fetchPracticeLevels failed: ${f.message}');
    } catch (e) {
      _errorMessage = 'Failed to load practice levels: $e';
      debugPrint('fetchPracticeLevels failed: $e');
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
      _courseAssessments = await _repository.getCourseAssessments(
        enrolledCourseIds,
      );
    } on Failure catch (f) {
      _errorMessage = f.message;
      debugPrint('fetchCourseAssessments failed: ${f.message}');
    } catch (e) {
      _errorMessage = 'Failed to load course assessments: $e';
      debugPrint('fetchCourseAssessments failed: $e');
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
