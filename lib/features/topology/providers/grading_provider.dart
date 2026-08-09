import 'package:flutter/foundation.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/topology_model.dart';
import '../../../data/repositories/grading_repository.dart';
import '../../../data/repositories/topology_repository.dart';
import '../services/topology_grader.dart';

/// State Management Provider for checking a student's canvas against a
/// level's answer key and recording the result.
class GradingProvider extends ChangeNotifier {
  final IGradingRepository _gradingRepository;
  final ITopologyRepository _topologyRepository;

  GradingProvider({
    IGradingRepository? gradingRepository,
    ITopologyRepository? topologyRepository,
  }) : _gradingRepository = gradingRepository ?? FirebaseGradingRepository(),
       _topologyRepository = topologyRepository ?? FirebaseTopologyRepository();

  /// What a working build is worth.
  static const int pointsForPass = 4;

  /// What a failed Check Connection costs. Smaller than [pointsForPass], so
  /// a student who gets there after a couple of wrong attempts still comes
  /// out ahead and keeps moving.
  static const int pointsForFail = 2;

  /// What it costs to open any level past the first.
  static const int pointsToUnlockLevel = 2;

  bool _isChecking = false;
  GradeResult? _lastResult;
  ExerciseProgress? _lastProgress;
  String? _errorMessage;

  /// Points gained (positive) or spent (negative) by the most recent check.
  int _lastPointsDelta = 0;

  /// The student's score after the most recent check.
  int? _lastPointsTotal;

  /// Set when the most recent failure cost the student a level because they
  /// had no points left to lose. Null when nothing was demoted.
  int? _lastDemotedToLevel;

  int get lastPointsDelta => _lastPointsDelta;
  int? get lastPointsTotal => _lastPointsTotal;
  int? get lastDemotedToLevel => _lastDemotedToLevel;

  bool get isChecking => _isChecking;
  GradeResult? get lastResult => _lastResult;

  /// The student's standing on the exercise after the most recent check —
  /// used to tell them how many attempts it took.
  ExerciseProgress? get lastProgress => _lastProgress;
  String? get errorMessage => _errorMessage;

  /// Loads the exercise's solution key and reference topology, grades
  /// [studentTopology] against it, records the attempt, and — on a pass —
  /// marks the exercise passed and advances [practiceLevel] if given.
  ///
  /// Returns null (with [errorMessage] set) if the level has no solution
  /// configured or the check couldn't be completed; callers should treat
  /// that as "try again later", not as a failed attempt, and it is
  /// deliberately NOT recorded as one.
  Future<GradeResult?> checkTopology({
    required String uid,
    required String exerciseId,
    required String exerciseTitle,
    required TopologyModel studentTopology,
    int? practiceLevel,
    // Only used for a course assessment's denormalised lecturer-facing
    // result — see IGradingRepository.recordAttempt's field doc.
    String? authorUid,
    String? studentName,
    String? studentEmail,
  }) async {
    _isChecking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Course assessments (practiceLevel == null) get exactly one
      // attempt, pass or fail — unlike Free Practice, where re-attempting
      // is the whole point of the points economy. The assignment card
      // already disables re-opening after one attempt, but this is the
      // check that actually can't be bypassed by a second browser tab
      // opened before the first attempt's result lands.
      if (practiceLevel == null) {
        final existing = await _gradingRepository.getProgress(
          uid: uid,
          exerciseId: exerciseId,
        );
        if (existing != null && existing.attemptCount > 0) {
          _errorMessage =
              "You've already submitted this assessment — only one "
              'attempt is allowed.';
          return null;
        }
      }

      final solutionKey = await _gradingRepository.getSolutionKey(exerciseId);
      if (solutionKey == null) {
        _errorMessage = "This level's answer key isn't set up yet.";
        return null;
      }

      final solutionTopology = await _topologyRepository.getTopology(
        solutionKey.solutionTopologyId,
      );

      final result = TopologyGrader.gradeCabling(
        student: studentTopology,
        solution: solutionTopology,
      );
      _lastResult = result;

      final progress = await _gradingRepository.recordAttempt(
        uid: uid,
        exerciseId: exerciseId,
        title: exerciseTitle,
        result: result,
        practiceLevel: practiceLevel,
        authorUid: authorUid,
        studentName: studentName,
        studentEmail: studentEmail,
      );
      _lastProgress = progress;

      // Points, demotion and level-advancement are a Free Practice-only
      // economy — practiceLevel == null is a course assessment, which has
      // its own scoring (correctChecks/totalChecks, see ExerciseProgress)
      // and must not touch the student's points at all. This used to run
      // unconditionally, which meant submitting a lecturer's course
      // assessment could cost Free Practice points or even demote a Free
      // Practice level — visibly wrong, and exactly the cross-contamination
      // course assessments were supposed to be free of.
      if (practiceLevel != null) {
        // A re-check of a level already passed is worth nothing: without
        // that, pressing Check Connection repeatedly on a solved canvas is
        // free points forever, which makes the unlock threshold meaningless.
        // Failing it still costs, so there is no reason to keep pressing.
        // Keyed on "did THIS attempt solve it", not on the attempt count.
        // Using `attemptCount > 1` meant anyone who failed once before
        // getting it right was told they had "already solved this one" and
        // paid nothing — the exact opposite of the intent, since struggling
        // to a correct answer is the case most worth rewarding.
        final delta = result.passed
            ? (progress.solvedOnThisAttempt ? pointsForPass : 0)
            : -pointsForFail;

        _lastPointsDelta = delta;
        _lastDemotedToLevel = null;

        if (delta != 0) {
          final score = await _gradingRepository.applyPointsDelta(
            uid: uid,
            delta: delta,
          );
          _lastPointsTotal = score.after;

          // Nothing left to take. The score alone can't punish a student who
          // is already on zero — without this, failing costs them nothing
          // once they hit the floor. Dropping a level does cost something,
          // and it points them back at the easier builds where they can
          // rebuild a score.
          if (delta < 0 && score.before < pointsForFail) {
            _lastDemotedToLevel = await _gradingRepository
                .demotePracticeLevel(uid: uid);
          }
        }

        if (result.passed) {
          await _gradingRepository.advancePracticeLevel(
            uid: uid,
            practiceLevel: practiceLevel,
          );
        }
      } else {
        _lastPointsDelta = 0;
        _lastPointsTotal = null;
        _lastDemotedToLevel = null;
      }

      return result;
    } on Failure catch (f) {
      _errorMessage = f.message;
      debugPrint('checkTopology failed: ${f.message}');
      return null;
    } catch (e) {
      _errorMessage = 'Failed to check topology: $e';
      debugPrint('checkTopology failed: $e');
      return null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Wipes a level so the student can play it again for points.
  ///
  /// Both halves matter. Clearing the progress is what makes the next solve
  /// pay out — a re-check of a level still marked passed is worth nothing,
  /// which is what stops a finished canvas being an infinite point tap.
  /// Emptying the canvas is what makes that payout earned: the student has
  /// to actually rebuild the network, not just press Check again.
  ///
  /// Destructive, so callers must confirm with the student first.
  Future<bool> resetLevel({
    required String uid,
    required String exerciseId,
    required String topologyId,
    required String ownerUid,
  }) async {
    try {
      await _gradingRepository.resetExerciseProgress(
        uid: uid,
        exerciseId: exerciseId,
      );

      final now = DateTime.now();
      await _topologyRepository.saveTopology(
        TopologyModel(
          topologyId: topologyId,
          ownerUid: ownerUid,
          name: 'Network Topology',
          nodes: const [],
          edges: const [],
          createdAt: now,
          updatedAt: now,
        ),
      );

      _errorMessage = null;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      debugPrint('resetLevel failed: ${f.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reset this level: $e';
      debugPrint('resetLevel failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// Logs a plain "Save Canvas" press to the student's activity history.
  /// Deliberately fire-and-forget from the caller's perspective — a save
  /// that succeeded but failed to log itself should never look like the
  /// save itself failed, so this only surfaces failures to the console.
  Future<void> recordCanvasSave({
    required String uid,
    required String title,
    required String topologyId,
    String? exerciseId,
  }) async {
    try {
      await _gradingRepository.recordSave(
        uid: uid,
        title: title,
        topologyId: topologyId,
        exerciseId: exerciseId,
      );
    } catch (e) {
      debugPrint('recordCanvasSave failed: $e');
    }
  }

  void clearResult() {
    _lastResult = null;
    _lastProgress = null;
    _lastPointsDelta = 0;
    _lastPointsTotal = null;
    _lastDemotedToLevel = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Whether [level] can be opened by a student on [points] with progression
  /// up to [freePracticeLevel].
  ///
  /// Level 1 is always open — it is where points come from, so locking it
  /// behind points would strand anyone who spent theirs on failed checks
  /// with no way to earn more.
  static bool canEnterLevel({
    required int level,
    required int freePracticeLevel,
    required int points,
  }) {
    if (level <= 1) return true;
    if (freePracticeLevel < level) return false;
    return points >= pointsToUnlockLevel;
  }
}
