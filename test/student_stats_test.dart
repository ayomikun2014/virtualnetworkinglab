import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/data/repositories/grading_repository.dart';
import 'package:virtuanetlab/features/dashboard/models/student_stats.dart';

ExerciseProgress _p(
  String id, {
  int attemptCount = 0,
  bool passed = false,
  int? attemptsUsed,
}) => ExerciseProgress(
  exerciseId: id,
  attemptCount: attemptCount,
  passed: passed,
  attemptsUsed: attemptsUsed,
);

void main() {
  group('StudentStats', () {
    test('a brand-new student reads as all-zero, not as failure', () {
      final stats = StudentStats.from(
        exerciseIds: const ['a', 'b', 'c'],
        progressByExerciseId: const {},
        practiceLevel: 1,
      );

      expect(stats.totalExercises, 3);
      expect(stats.completedExercises, 0);
      expect(stats.attemptedExercises, 0);
      expect(stats.totalAttempts, 0);
      expect(stats.completionRate, 0);
      // Null, not 0.0 — nothing attempted means no rate to report, and a
      // literal 0% would read like the student had failed everything.
      expect(stats.successRate, isNull);
      expect(stats.averageAttemptsPerSolve, isNull);
    });

    test('counts completions, attempts and first-try solves', () {
      final stats = StudentStats.from(
        exerciseIds: const ['a', 'b', 'c', 'd'],
        progressByExerciseId: {
          'a': _p('a', attemptCount: 1, passed: true, attemptsUsed: 1),
          'b': _p('b', attemptCount: 3, passed: true, attemptsUsed: 3),
          'c': _p('c', attemptCount: 2), // tried, not solved
          // 'd' never touched
        },
        practiceLevel: 3,
      );

      expect(stats.totalExercises, 4);
      expect(stats.completedExercises, 2);
      expect(stats.attemptedExercises, 3);
      expect(stats.totalAttempts, 6);
      expect(stats.firstTrySolves, 1);
      expect(stats.practiceLevel, 3);
      expect(stats.completionRate, 0.5);
      // Of the 3 labs started, 2 are finished.
      expect(stats.successRate, closeTo(2 / 3, 1e-9));
      expect(stats.averageAttemptsPerSolve, closeTo(3.0, 1e-9));
    });

    test('ignores progress for exercises no longer available', () {
      // A student can hold progress for an assessment whose course they've
      // since left; counting it would make "X / Y" exceed Y.
      final stats = StudentStats.from(
        exerciseIds: const ['a'],
        progressByExerciseId: {
          'a': _p('a', attemptCount: 1, passed: true, attemptsUsed: 1),
          'stale': _p('stale', attemptCount: 9, passed: true, attemptsUsed: 2),
        },
        practiceLevel: 1,
      );

      expect(stats.totalExercises, 1);
      expect(stats.completedExercises, 1);
      expect(stats.totalAttempts, 1);
      expect(stats.completionRate, 1.0);
    });

    test('an empty catalogue does not divide by zero', () {
      final stats = StudentStats.from(
        exerciseIds: const [],
        progressByExerciseId: const {},
        practiceLevel: 1,
      );

      expect(stats.totalExercises, 0);
      expect(stats.completionRate, 0);
      expect(stats.successRate, isNull);
    });

    test('a lab attempted many times but never passed stays incomplete', () {
      final stats = StudentStats.from(
        exerciseIds: const ['a'],
        progressByExerciseId: {'a': _p('a', attemptCount: 12)},
        practiceLevel: 1,
      );

      expect(stats.completedExercises, 0);
      expect(stats.attemptedExercises, 1);
      expect(stats.totalAttempts, 12);
      expect(stats.successRate, 0.0);
      expect(stats.averageAttemptsPerSolve, isNull);
    });

    test('a re-solved lab does not count as a first-try solve', () {
      // attemptsUsed freezes at the first pass, so replaying a solved level
      // must not retroactively turn it into a first-try win.
      final stats = StudentStats.from(
        exerciseIds: const ['a'],
        progressByExerciseId: {
          'a': _p('a', attemptCount: 7, passed: true, attemptsUsed: 4),
        },
        practiceLevel: 2,
      );

      expect(stats.completedExercises, 1);
      expect(stats.firstTrySolves, 0);
    });
  });
}
