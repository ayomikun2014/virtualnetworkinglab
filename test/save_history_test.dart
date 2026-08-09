import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/data/repositories/grading_repository.dart';
import 'package:virtuanetlab/features/topology/screens/canvas_builder_screen.dart';

void main() {
  group('SaveRecord.fromJson', () {
    test('parses a passing check-type record with no failures', () {
      final record = SaveRecord.fromJson('doc1', {
        'type': 'check',
        'title': 'Level 1: Connect Two PCs',
        'exerciseId': 'ex1',
        'passed': true,
        'checks': [
          {'passed': true, 'message': 'PC1 is on the canvas.'},
        ],
        'attemptedAt': '2026-08-20T15:45:00.000',
      });

      expect(record.type, 'check');
      expect(record.title, 'Level 1: Connect Two PCs');
      expect(record.passed, isTrue);
      expect(record.failureMessages, isEmpty);
    });

    test('extracts only the failing checks as failureMessages', () {
      final record = SaveRecord.fromJson('doc1', {
        'type': 'check',
        'title': 'Level 2',
        'passed': false,
        'checks': [
          {'passed': true, 'message': 'PC1 is on the canvas.'},
          {'passed': false, 'message': 'Connect PC1 to Switch1.'},
          {'passed': false, 'message': 'Add a Switch.'},
        ],
        'attemptedAt': '2026-08-20T15:45:00.000',
      });

      expect(record.passed, isFalse);
      expect(record.failureMessages, [
        'Connect PC1 to Switch1.',
        'Add a Switch.',
      ]);
    });

    test('parses a save-type record with no checks/passed fields', () {
      final record = SaveRecord.fromJson('doc2', {
        'type': 'save',
        'title': 'Sandbox Canvas',
        'topologyId': 'sandbox_u1',
        'attemptedAt': '2026-08-20T09:00:00.000',
      });

      expect(record.type, 'save');
      expect(record.title, 'Sandbox Canvas');
      expect(record.passed, isNull);
      expect(record.failureMessages, isEmpty);
      // Carried through so a history row can reopen the canvas it points at.
      expect(record.topologyId, 'sandbox_u1');
    });

    test('a sandbox save is not reported as coming from a level', () {
      final record = SaveRecord.fromJson('doc6', {
        'type': 'save',
        'title': 'My scratch lab',
        'topologyId': 'sandbox_u1',
        'attemptedAt': '2026-08-20T09:00:00.000',
      });

      expect(record.isFromExercise, isFalse);
    });

    test('a save made on a level is reported as coming from one', () {
      final record = SaveRecord.fromJson('doc7', {
        'type': 'save',
        'title': 'Build a Star Network',
        'topologyId': 'practice_level_2_u1',
        'exerciseId': 'practice_seed_level_2',
        'attemptedAt': '2026-08-20T09:00:00.000',
      });

      expect(record.isFromExercise, isTrue);
    });

    test(
      'defaults to type "check" for records written before this field existed',
      () {
        // Every attempt document written by the original recordAttempt()
        // has no `type` field at all — they must still read as checks, not
        // silently vanish or misrender as saves.
        final record = SaveRecord.fromJson('doc3', {
          'title': 'Old Attempt',
          'passed': true,
          'attemptedAt': '2026-01-01T00:00:00.000',
        });

        expect(record.type, 'check');
      },
    );

    test('falls back to a generic title rather than a blank one', () {
      final record = SaveRecord.fromJson('doc4', {
        'attemptedAt': '2026-01-01T00:00:00.000',
      });

      expect(record.title, 'Untitled canvas');
    });

    test('an unparseable timestamp does not throw', () {
      expect(
        () => SaveRecord.fromJson('doc5', {
          'title': 'Bad timestamp',
          'attemptedAt': 'not-a-date',
        }),
        returnsNormally,
      );
    });
  });

  group('CanvasBuilderScreen.friendlySaveTitle', () {
    test('prefers the exercise title when one is set', () {
      expect(
        CanvasBuilderScreen.friendlySaveTitle(
          exerciseTitle: 'Level 3: Switch to Router',
          topologyId: 'practice_level_3_u1',
        ),
        'Level 3: Switch to Router',
      );
    });

    test('never shows a blank title, even if exerciseTitle is just whitespace', () {
      final title = CanvasBuilderScreen.friendlySaveTitle(
        exerciseTitle: '   ',
        topologyId: 'sandbox_u1',
      );
      expect(title, isNotEmpty);
      expect(title, 'Sandbox Canvas');
    });

    test('labels a sandbox canvas without a raw uid in the name', () {
      final title = CanvasBuilderScreen.friendlySaveTitle(
        exerciseTitle: null,
        topologyId: 'sandbox_abc123uid',
      );
      expect(title, 'Sandbox Canvas');
      expect(title, isNot(contains('abc123uid')));
    });

    test('labels an assessment canvas without a raw exerciseId in the name', () {
      final title = CanvasBuilderScreen.friendlySaveTitle(
        exerciseTitle: null,
        topologyId: 'assessment_ex99_u1',
      );
      expect(title, 'Course Assessment');
      expect(title, isNot(contains('ex99')));
    });

    test('falls back to a generic name for anything else', () {
      expect(
        CanvasBuilderScreen.friendlySaveTitle(
          exerciseTitle: null,
          topologyId: 'default_canvas',
        ),
        'Topology Canvas',
      );
    });
  });
}
