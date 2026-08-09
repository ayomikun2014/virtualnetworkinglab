import '../../../data/repositories/grading_repository.dart';

/// A student's headline figures, derived entirely from records the grader
/// actually wrote — no invented numbers.
///
/// The dashboard previously showed "Completed Labs: {enrolled course count}
/// / 12" and a hardcoded "Average Score: 92%". Neither reflected anything
/// the student had done; the first compared two unrelated quantities and the
/// second was a literal. Everything here is computed from
/// `users/{uid}/progress` documents, which only exist because a Check
/// Connection actually ran.
///
/// Note there is deliberately no "average score": grading is pass/fail per
/// level, so no score exists to average. [successRate] answers the question
/// that percentage was pretending to — of the labs you've tried, how many
/// have you finished.
class StudentStats {
  /// Every published exercise currently visible to this student (Free
  /// Practice levels plus assessments for their enrolled courses).
  final int totalExercises;

  final int completedExercises;

  /// Exercises with at least one recorded attempt, passed or not.
  final int attemptedExercises;

  /// Every Check Connection press across those exercises.
  final int totalAttempts;

  /// Exercises solved on the very first attempt.
  final int firstTrySolves;

  final int practiceLevel;

  const StudentStats({
    required this.totalExercises,
    required this.completedExercises,
    required this.attemptedExercises,
    required this.totalAttempts,
    required this.firstTrySolves,
    required this.practiceLevel,
  });

  factory StudentStats.from({
    required Iterable<String> exerciseIds,
    required Map<String, ExerciseProgress> progressByExerciseId,
    required int practiceLevel,
  }) {
    var completed = 0;
    var attempted = 0;
    var attempts = 0;
    var firstTry = 0;
    var total = 0;

    for (final id in exerciseIds) {
      total++;
      final progress = progressByExerciseId[id];
      if (progress == null) continue;

      attempts += progress.attemptCount;
      if (progress.attemptCount > 0) attempted++;
      if (progress.passed) {
        completed++;
        if ((progress.attemptsUsed ?? 0) == 1) firstTry++;
      }
    }

    return StudentStats(
      totalExercises: total,
      completedExercises: completed,
      attemptedExercises: attempted,
      totalAttempts: attempts,
      firstTrySolves: firstTry,
      practiceLevel: practiceLevel,
    );
  }

  /// 0..1 for the completion progress bar.
  double get completionRate =>
      totalExercises == 0 ? 0 : completedExercises / totalExercises;

  /// Of the labs started, the share finished — null when nothing has been
  /// attempted yet, so the UI can show "—" instead of a misleading 0%.
  double? get successRate =>
      attemptedExercises == 0 ? null : completedExercises / attemptedExercises;

  /// Average attempts per solved lab — null until something is solved.
  double? get averageAttemptsPerSolve =>
      completedExercises == 0 ? null : totalAttempts / completedExercises;
}
