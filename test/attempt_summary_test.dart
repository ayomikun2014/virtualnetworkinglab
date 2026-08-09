import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/data/repositories/grading_repository.dart';
import 'package:virtuanetlab/features/exercises/screens/practice_levels_screen.dart';

void main() {
  group('PracticeLevelsScreen.attemptSummary', () {
    String summaryFor({
      int attemptCount = 0,
      bool passed = false,
      int? attemptsUsed,
    }) => PracticeLevelsScreen.attemptSummary(
      ExerciseProgress(
        exerciseId: 'ex1',
        attemptCount: attemptCount,
        passed: passed,
        attemptsUsed: attemptsUsed,
      ),
    );

    test('reads as untouched before any attempt', () {
      expect(summaryFor(), 'Not attempted yet');
    });

    test('counts attempts in progress, with correct pluralisation', () {
      expect(summaryFor(attemptCount: 1), '1 attempt so far');
      expect(summaryFor(attemptCount: 4), '4 attempts so far');
    });

    test('celebrates a first-try solve without saying "1 attempts"', () {
      expect(
        summaryFor(attemptCount: 1, passed: true, attemptsUsed: 1),
        'Solved on the first try',
      );
    });

    test('reports the attempts the student actually used to pass', () {
      expect(
        summaryFor(attemptCount: 3, passed: true, attemptsUsed: 3),
        'Solved in 3 attempts',
      );
    });

    test(
      'keeps reporting the earned figure after re-opening a solved level',
      () {
        // attemptCount has since climbed to 7, but the level was solved on
        // the 3rd try and that is what the student earned.
        expect(
          summaryFor(attemptCount: 7, passed: true, attemptsUsed: 3),
          'Solved in 3 attempts',
        );
      },
    );
  });
}
