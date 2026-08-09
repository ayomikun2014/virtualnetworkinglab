import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/constants/app_constants.dart';

void main() {
  group('Firestore collection paths', () {
    test('collection getters already include the root namespace', () {
      // This is the property that makes '$rootPath/$xCollection' a bug: the
      // getters are absolute paths, not path fragments.
      expect(
        AppConstants.exercisesCollection.startsWith(AppConstants.rootPath),
        isTrue,
      );
      expect(
        AppConstants.usersCollection.startsWith(AppConstants.rootPath),
        isTrue,
      );
    });

    test(
      'the exercise solution key sits under the same collection students read',
      () {
        // The lecturer publishes an exercise to `exercisesCollection` and the
        // answer key to `exerciseSolutionKeyPath`. If those ever drift apart,
        // grading silently finds no solution and every check reports "answer
        // key isn't set up yet".
        const exerciseId = 'ex123';
        expect(
          AppConstants.exerciseSolutionKeyPath(exerciseId),
          '${AppConstants.exercisesCollection}/$exerciseId/private/solution_key',
        );
      },
    );

    test('per-user progress and attempts hang off the real user document', () {
      const uid = 'student1';
      expect(
        AppConstants.userProgressCollection(uid),
        '${AppConstants.usersCollection}/$uid/progress',
      );
      expect(
        AppConstants.userAttemptsCollection(uid),
        '${AppConstants.usersCollection}/$uid/attempts',
      );
    });

    test('every collection path has an odd segment count', () {
      // Firestore requires collections to sit at odd depths; an even count
      // means the path actually points at a document and the call will throw
      // at runtime rather than at compile time.
      for (final path in [
        AppConstants.exercisesCollection,
        AppConstants.usersCollection,
        AppConstants.topologiesCollection,
        AppConstants.userProgressCollection('u'),
        AppConstants.userAttemptsCollection('u'),
      ]) {
        expect(
          path.split('/').length.isOdd,
          isTrue,
          reason: '$path does not resolve to a collection',
        );
      }
    });
  });
}
