import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/enums/app_enums.dart';
import 'package:virtuanetlab/data/models/topology_model.dart';
import 'package:virtuanetlab/data/repositories/grading_repository.dart';
import 'package:virtuanetlab/data/repositories/topology_repository.dart';
import 'package:virtuanetlab/features/topology/providers/grading_provider.dart';
import 'package:virtuanetlab/features/topology/services/topology_grader.dart';

class FakeGradingRepository implements IGradingRepository {
  ExerciseSolutionKey? solutionKeyToReturn;

  final List<GradeResult> recordedAttempts = [];
  final List<int> advancedPracticeLevels = [];

  /// Mirrors the real repository's counter so tests can assert on it.
  int attemptCount = 0;
  bool passed = false;
  int? attemptsUsed;
  int? correctChecks;
  int? totalChecks;

  @override
  Future<ExerciseSolutionKey?> getSolutionKey(String exerciseId) async =>
      solutionKeyToReturn;

  @override
  Future<ExerciseProgress?> getProgress({
    required String uid,
    required String exerciseId,
  }) async {
    if (attemptCount == 0) return null;
    return ExerciseProgress(
      exerciseId: exerciseId,
      attemptCount: attemptCount,
      passed: passed,
      attemptsUsed: attemptsUsed,
      correctChecks: correctChecks,
      totalChecks: totalChecks,
    );
  }

  final List<String> recordedTitles = [];
  String? lastAuthorUid;
  String? lastStudentName;
  String? lastStudentEmail;
  int? lastPracticeLevel;

  @override
  Future<ExerciseProgress> recordAttempt({
    required String uid,
    required String exerciseId,
    required String title,
    required GradeResult result,
    int? practiceLevel,
    String? authorUid,
    String? studentName,
    String? studentEmail,
  }) async {
    recordedAttempts.add(result);
    recordedTitles.add(title);
    lastAuthorUid = authorUid;
    lastStudentName = studentName;
    lastStudentEmail = studentEmail;
    lastPracticeLevel = practiceLevel;
    attemptCount += 1;
    final firstPassNow = result.passed && !passed;
    passed = passed || result.passed;
    if (firstPassNow) attemptsUsed = attemptCount;
    correctChecks = result.checks.where((c) => c.passed).length;
    totalChecks = result.checks.length;

    return ExerciseProgress(
      exerciseId: exerciseId,
      attemptCount: attemptCount,
      passed: passed,
      attemptsUsed: attemptsUsed,
      correctChecks: correctChecks,
      totalChecks: totalChecks,
    );
  }

  final List<String> savedTitles = [];

  @override
  Future<void> recordSave({
    required String uid,
    required String title,
    required String topologyId,
    String? exerciseId,
  }) async {
    savedTitles.add(title);
  }

  @override
  Future<void> advancePracticeLevel({
    required String uid,
    required int practiceLevel,
  }) async {
    advancedPracticeLevels.add(practiceLevel);
  }

  /// Mirrors the real repository's running total, including its floor at
  /// zero, so tests see the same score a student would.
  int points = 0;
  final List<int> appliedDeltas = [];

  final List<String> resetExerciseIds = [];

  @override
  Future<void> resetExerciseProgress({
    required String uid,
    required String exerciseId,
  }) async {
    resetExerciseIds.add(exerciseId);
    // Mirrors the real reset: back to unsolved and unattempted, which is
    // what lets the next solve pay out again.
    attemptCount = 0;
    passed = false;
    attemptsUsed = null;
    correctChecks = null;
    totalChecks = null;
  }

  /// Where the student sits in the Free Practice progression, so a test can
  /// see a demotion actually land.
  int practiceLevel = 1;
  int demoteCalls = 0;

  @override
  Future<({int before, int after})> applyPointsDelta({
    required String uid,
    required int delta,
  }) async {
    appliedDeltas.add(delta);
    final before = points;
    points = (points + delta).clamp(0, 1 << 30);
    return (before: before, after: points);
  }

  @override
  Future<int> demotePracticeLevel({required String uid}) async {
    demoteCalls += 1;
    practiceLevel = practiceLevel <= 1 ? 1 : practiceLevel - 1;
    return practiceLevel;
  }

  @override
  Stream<Map<String, ExerciseProgress>> watchProgress(String uid) =>
      const Stream.empty();

  @override
  Stream<List<SaveRecord>> watchSaveHistory(String uid) =>
      const Stream.empty();
}

class FakeTopologyRepository implements ITopologyRepository {
  final Map<String, TopologyModel> topologiesById;

  FakeTopologyRepository(this.topologiesById);

  @override
  Stream<TopologyModel?> watchTopology(String topologyId) =>
      const Stream.empty();

  @override
  Future<TopologyModel> getTopology(String topologyId) async =>
      topologiesById[topologyId]!;

  /// Every topology written back, so a test can check that a reset wipes
  /// the right canvas and only that one.
  final List<TopologyModel> saved = [];

  @override
  Future<void> saveTopology(TopologyModel topology) async {
    saved.add(topology);
  }
}

TopologyModel _topology({
  required String id,
  List<DeviceNode> nodes = const [],
  List<CableEdge> edges = const [],
}) {
  final now = DateTime.now();
  return TopologyModel(
    topologyId: id,
    ownerUid: 'u',
    name: 'Topology',
    nodes: nodes,
    edges: edges,
    createdAt: now,
    updatedAt: now,
  );
}

DeviceNode _pc(String nodeId) => DeviceNode(
  nodeId: nodeId,
  label: nodeId,
  type: DeviceType.pc,
  model: 'Ubuntu Host',
  position: const Position(x: 0, y: 0),
  interfaces: const [InterfaceConfig(name: 'eth0')],
);

void main() {
  group('GradingProvider.canEnterLevel', () {
    test('level 1 is always open, whatever the score', () {
      // Level 1 is where points come from. Locking it behind points would
      // strand a student who spent theirs on failed checks with no way to
      // ever earn more.
      expect(
        GradingProvider.canEnterLevel(
          level: 1,
          freePracticeLevel: 1,
          points: 0,
        ),
        isTrue,
      );
    });

    test('a reached level still needs points in hand', () {
      expect(
        GradingProvider.canEnterLevel(
          level: 2,
          freePracticeLevel: 5,
          points: GradingProvider.pointsToUnlockLevel - 1,
        ),
        isFalse,
      );
      expect(
        GradingProvider.canEnterLevel(
          level: 2,
          freePracticeLevel: 5,
          points: GradingProvider.pointsToUnlockLevel,
        ),
        isTrue,
      );
    });

    test('points alone do not skip the progression', () {
      expect(
        GradingProvider.canEnterLevel(
          level: 7,
          freePracticeLevel: 3,
          points: 500,
        ),
        isFalse,
      );
    });
  });

  group('GradingProvider.checkTopology', () {
    test(
      'returns null without recording an attempt when no solution key exists',
      () async {
        final gradingRepo = FakeGradingRepository()..solutionKeyToReturn = null;
        final topologyRepo = FakeTopologyRepository({});
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: topologyRepo,
        );

        final result = await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Test Exercise',
          studentTopology: _topology(id: 'student_canvas'),
        );

        expect(result, isNull);
        expect(provider.errorMessage, isNotNull);
        expect(gradingRepo.recordedAttempts, isEmpty);
        expect(gradingRepo.advancedPracticeLevels, isEmpty);
        expect(provider.isChecking, isFalse);
      },
    );

    test(
      'records the attempt and marks the exercise passed on a correct build',
      () async {
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2')],
          edges: const [
            CableEdge(
              edgeId: 'se1',
              sourceNodeId: 's1',
              sourceInterface: 'eth0',
              targetNodeId: 's2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          );
        final topologyRepo = FakeTopologyRepository({'solution1': solution});
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: topologyRepo,
        );

        final studentTopology = _topology(
          id: 'student_canvas',
          nodes: [_pc('n1'), _pc('n2')],
          edges: const [
            CableEdge(
              edgeId: 'e1',
              sourceNodeId: 'n1',
              sourceInterface: 'eth0',
              targetNodeId: 'n2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final result = await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Test Exercise',
          studentTopology: studentTopology,
          practiceLevel: 1,
        );

        expect(result, isNotNull);
        expect(result!.passed, isTrue);
        expect(gradingRepo.recordedAttempts, hasLength(1));
        expect(gradingRepo.recordedAttempts.single.passed, isTrue);
        expect(gradingRepo.advancedPracticeLevels, [1]);
        expect(provider.lastResult, same(result));
        expect(provider.lastProgress?.attemptsUsed, 1);

        // Solving it is what pays for the next level.
        expect(gradingRepo.appliedDeltas, [GradingProvider.pointsForPass]);
        expect(provider.lastPointsDelta, GradingProvider.pointsForPass);
        expect(provider.lastPointsTotal, GradingProvider.pointsForPass);
      },
    );

    test('a failed check spends points instead of earning them', () async {
      final solution = _topology(
        id: 'solution1',
        nodes: [_pc('s1'), _pc('s2')],
        edges: const [
          CableEdge(
            edgeId: 'se1',
            sourceNodeId: 's1',
            sourceInterface: 'eth0',
            targetNodeId: 's2',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      final gradingRepo = FakeGradingRepository()
        ..solutionKeyToReturn = const ExerciseSolutionKey(
          solutionTopologyId: 'solution1',
        )
        ..points = 10;
      final provider = GradingProvider(
        gradingRepository: gradingRepo,
        topologyRepository: FakeTopologyRepository({'solution1': solution}),
      );

      // Both PCs placed but never cabled together.
      final result = await provider.checkTopology(
        uid: 'student1',
        exerciseId: 'ex1',
        exerciseTitle: 'Test Exercise',
        studentTopology: _topology(
          id: 'student_canvas',
          nodes: [_pc('n1'), _pc('n2')],
        ),
        practiceLevel: 1,
      );

      expect(result!.passed, isFalse);
      expect(gradingRepo.appliedDeltas, [-GradingProvider.pointsForFail]);
      expect(provider.lastPointsDelta, -GradingProvider.pointsForFail);
      expect(provider.lastPointsTotal, 10 - GradingProvider.pointsForFail);
    });

    test(
      'struggling to a correct answer still earns the full points',
      () async {
        // The regression: the payout was keyed on `attemptCount > 1`, read
        // from the progress AFTER the attempt was recorded. Anyone who
        // failed even once before getting it right was therefore told
        // "you had already solved this one" and paid nothing — punishing
        // exactly the students the points are meant to encourage.
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2')],
          edges: const [
            CableEdge(
              edgeId: 'se1',
              sourceNodeId: 's1',
              sourceInterface: 'eth0',
              targetNodeId: 's2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          )
          // Enough to absorb the two failures without a demotion muddying
          // what this test is about.
          ..points = 20;
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: FakeTopologyRepository({'solution1': solution}),
        );

        Future<void> check(TopologyModel canvas) => provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Connect Two PCs',
          studentTopology: canvas,
          practiceLevel: 1,
        );

        // Two failed attempts: both PCs down, no cable between them.
        final incomplete = _topology(
          id: 'student_canvas',
          nodes: [_pc('n1'), _pc('n2')],
        );
        await check(incomplete);
        await check(incomplete);

        // Third attempt gets it right.
        await check(
          _topology(
            id: 'student_canvas',
            nodes: [_pc('n1'), _pc('n2')],
            edges: const [
              CableEdge(
                edgeId: 'e1',
                sourceNodeId: 'n1',
                sourceInterface: 'eth0',
                targetNodeId: 'n2',
                targetInterface: 'eth0',
                cableType: 'Ethernet',
              ),
            ],
          ),
        );

        expect(
          provider.lastPointsDelta,
          GradingProvider.pointsForPass,
          reason: 'solving on the third try is still solving it',
        );
        expect(provider.lastProgress?.attemptsUsed, 3);
      },
    );

    test(
      'failing with no points left costs a level instead of points',
      () async {
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2')],
          edges: const [
            CableEdge(
              edgeId: 'se1',
              sourceNodeId: 's1',
              sourceInterface: 'eth0',
              targetNodeId: 's2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          )
          ..points = 0
          ..practiceLevel = 4;
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: FakeTopologyRepository({'solution1': solution}),
        );

        await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Connect Two PCs',
          studentTopology: _topology(
            id: 'student_canvas',
            nodes: [_pc('n1'), _pc('n2')],
          ),
          practiceLevel: 4,
        );

        expect(gradingRepo.demoteCalls, 1);
        expect(provider.lastDemotedToLevel, 3);
        expect(gradingRepo.points, 0, reason: 'the score never goes negative');
      },
    );

    test('failing with points to spare does not cost a level', () async {
      final solution = _topology(
        id: 'solution1',
        nodes: [_pc('s1'), _pc('s2')],
        edges: const [
          CableEdge(
            edgeId: 'se1',
            sourceNodeId: 's1',
            sourceInterface: 'eth0',
            targetNodeId: 's2',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      final gradingRepo = FakeGradingRepository()
        ..solutionKeyToReturn = const ExerciseSolutionKey(
          solutionTopologyId: 'solution1',
        )
        ..points = GradingProvider.pointsForFail
        ..practiceLevel = 4;
      final provider = GradingProvider(
        gradingRepository: gradingRepo,
        topologyRepository: FakeTopologyRepository({'solution1': solution}),
      );

      await provider.checkTopology(
        uid: 'student1',
        exerciseId: 'ex1',
        exerciseTitle: 'Connect Two PCs',
        studentTopology: _topology(
          id: 'student_canvas',
          nodes: [_pc('n1'), _pc('n2')],
        ),
        practiceLevel: 4,
      );

      expect(gradingRepo.demoteCalls, 0);
      expect(provider.lastDemotedToLevel, isNull);
      expect(gradingRepo.points, 0);
      expect(gradingRepo.practiceLevel, 4);
    });

    test('re-checking a level already solved does not farm points', () async {
      // Without this, holding a finished canvas and pressing Check
      // Connection repeatedly is unlimited free points, which makes the
      // unlock threshold meaningless.
      final solution = _topology(
        id: 'solution1',
        nodes: [_pc('s1'), _pc('s2')],
        edges: const [
          CableEdge(
            edgeId: 'se1',
            sourceNodeId: 's1',
            sourceInterface: 'eth0',
            targetNodeId: 's2',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      final gradingRepo = FakeGradingRepository()
        ..solutionKeyToReturn = const ExerciseSolutionKey(
          solutionTopologyId: 'solution1',
        );
      final provider = GradingProvider(
        gradingRepository: gradingRepo,
        topologyRepository: FakeTopologyRepository({'solution1': solution}),
      );

      final winning = _topology(
        id: 'student_canvas',
        nodes: [_pc('n1'), _pc('n2')],
        edges: const [
          CableEdge(
            edgeId: 'e1',
            sourceNodeId: 'n1',
            sourceInterface: 'eth0',
            targetNodeId: 'n2',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      for (var i = 0; i < 3; i++) {
        await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Test Exercise',
          studentTopology: winning,
          practiceLevel: 1,
        );
      }

      expect(
        gradingRepo.points,
        GradingProvider.pointsForPass,
        reason: 'only the first solve pays out',
      );
      expect(provider.lastPointsDelta, 0);
    });

    test(
      'resetting a solved level lets it be earned again, and clears the '
      'canvas so the points have to be re-worked for',
      () async {
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2')],
          edges: const [
            CableEdge(
              edgeId: 'se1',
              sourceNodeId: 's1',
              sourceInterface: 'eth0',
              targetNodeId: 's2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          );
        final topologyRepo = FakeTopologyRepository({'solution1': solution});
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: topologyRepo,
        );

        final winning = _topology(
          id: 'practice_level_1_student1',
          nodes: [_pc('n1'), _pc('n2')],
          edges: const [
            CableEdge(
              edgeId: 'e1',
              sourceNodeId: 'n1',
              sourceInterface: 'eth0',
              targetNodeId: 'n2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        Future<void> solve() => provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Connect Two PCs',
          studentTopology: winning,
          practiceLevel: 1,
        );

        await solve();
        expect(gradingRepo.points, GradingProvider.pointsForPass);

        // Re-checking without resetting is worth nothing.
        await solve();
        expect(gradingRepo.points, GradingProvider.pointsForPass);

        final reset = await provider.resetLevel(
          uid: 'student1',
          exerciseId: 'ex1',
          topologyId: 'practice_level_1_student1',
          ownerUid: 'student1',
        );

        expect(reset, isTrue);
        expect(gradingRepo.resetExerciseIds, ['ex1']);
        expect(
          topologyRepo.saved.single.nodes,
          isEmpty,
          reason: 'the student has to rebuild it, not just press Check again',
        );
        expect(topologyRepo.saved.single.edges, isEmpty);
        expect(
          topologyRepo.saved.single.topologyId,
          'practice_level_1_student1',
          reason: "only this level's canvas may be wiped",
        );

        // Building it again now pays out again — the loop a student with no
        // points relies on to get back into the game.
        await solve();
        expect(gradingRepo.points, GradingProvider.pointsForPass * 2);
        expect(provider.lastPointsDelta, GradingProvider.pointsForPass);
      },
    );

    test(
      'records the attempt but does NOT mark passed on an incorrect build',
      () async {
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2')],
          edges: const [
            CableEdge(
              edgeId: 'se1',
              sourceNodeId: 's1',
              sourceInterface: 'eth0',
              targetNodeId: 's2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          );
        final topologyRepo = FakeTopologyRepository({'solution1': solution});
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: topologyRepo,
        );

        // Student placed both PCs but never cabled them together.
        final studentTopology = _topology(
          id: 'student_canvas',
          nodes: [_pc('n1'), _pc('n2')],
        );

        final result = await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Test Exercise',
          studentTopology: studentTopology,
          practiceLevel: 1,
        );

        expect(result, isNotNull);
        expect(result!.passed, isFalse);
        expect(result.failures, isNotEmpty);
        expect(gradingRepo.recordedAttempts, hasLength(1));
        expect(gradingRepo.recordedAttempts.single.passed, isFalse);
        expect(
          gradingRepo.advancedPracticeLevels,
          isEmpty,
          reason: 'a failed attempt must never unlock the next level',
        );
      },
    );

    test(
      'counts every attempt and reports how many it took to succeed',
      () async {
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2')],
          edges: const [
            CableEdge(
              edgeId: 'se1',
              sourceNodeId: 's1',
              sourceInterface: 'eth0',
              targetNodeId: 's2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          );
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: FakeTopologyRepository({'solution1': solution}),
        );

        final wrong = _topology(
          id: 'student_canvas',
          nodes: [_pc('n1'), _pc('n2')],
        );
        final right = _topology(
          id: 'student_canvas',
          nodes: [_pc('n1'), _pc('n2')],
          edges: const [
            CableEdge(
              edgeId: 'e1',
              sourceNodeId: 'n1',
              sourceInterface: 'eth0',
              targetNodeId: 'n2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        // Two failed tries, then the student gets it right.
        for (final attempt in [wrong, wrong, right]) {
          await provider.checkTopology(
            uid: 'student1',
            exerciseId: 'ex1',
            exerciseTitle: 'Test Exercise',
            studentTopology: attempt,
            practiceLevel: 1,
          );
        }

        expect(provider.lastProgress?.attemptCount, 3);
        expect(provider.lastProgress?.attemptsUsed, 3);

        // Re-opening a solved level must not inflate the "solved in N" figure.
        await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Test Exercise',
          studentTopology: right,
          practiceLevel: 1,
        );

        expect(provider.lastProgress?.attemptCount, 4);
        expect(
          provider.lastProgress?.attemptsUsed,
          3,
          reason: 'attemptsUsed must freeze at the first pass',
        );
      },
    );
  });

  group('GradingProvider course-assessment one-attempt rule', () {
    // practiceLevel is deliberately omitted (null) in every checkTopology
    // call in this group — that null is exactly what marks a check as a
    // course assessment rather than a Free Practice attempt, which is what
    // the one-attempt rule keys off of.

    test('a second check on a course assessment is refused', () async {
      final solution = _topology(
        id: 'solution1',
        nodes: [_pc('s1'), _pc('s2')],
        edges: const [
          CableEdge(
            edgeId: 'se1',
            sourceNodeId: 's1',
            sourceInterface: 'eth0',
            targetNodeId: 's2',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      final gradingRepo = FakeGradingRepository()
        ..solutionKeyToReturn = const ExerciseSolutionKey(
          solutionTopologyId: 'solution1',
        );
      final provider = GradingProvider(
        gradingRepository: gradingRepo,
        topologyRepository: FakeTopologyRepository({'solution1': solution}),
      );

      final incomplete = _topology(
        id: 'student_canvas',
        nodes: [_pc('n1'), _pc('n2')],
      );

      final first = await provider.checkTopology(
        uid: 'student1',
        exerciseId: 'ex1',
        exerciseTitle: 'Assessment 1',
        studentTopology: incomplete,
      );
      expect(first, isNotNull, reason: 'the first attempt must go through');
      expect(gradingRepo.attemptCount, 1);

      final second = await provider.checkTopology(
        uid: 'student1',
        exerciseId: 'ex1',
        exerciseTitle: 'Assessment 1',
        studentTopology: incomplete,
      );

      expect(
        second,
        isNull,
        reason: 'a course assessment allows exactly one attempt',
      );
      expect(
        gradingRepo.attemptCount,
        1,
        reason: 'the refused second try must not be recorded as an attempt',
      );
      expect(provider.errorMessage, contains('already submitted'));
    });

    test(
      'a Free Practice level (practiceLevel set) is NOT limited to one try',
      () async {
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2')],
          edges: const [
            CableEdge(
              edgeId: 'se1',
              sourceNodeId: 's1',
              sourceInterface: 'eth0',
              targetNodeId: 's2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          );
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: FakeTopologyRepository({'solution1': solution}),
        );

        final incomplete = _topology(
          id: 'student_canvas',
          nodes: [_pc('n1'), _pc('n2')],
        );

        await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Level 1',
          studentTopology: incomplete,
          practiceLevel: 1,
        );
        final second = await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Level 1',
          studentTopology: incomplete,
          practiceLevel: 1,
        );

        expect(
          second,
          isNotNull,
          reason: 'Free Practice keeps its own re-attempt/points economy',
        );
        expect(gradingRepo.attemptCount, 2);
      },
    );

    test(
      'the score on a course assessment reflects checks correct out of total',
      () async {
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2'), _pc('s3'), _pc('s4')],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          );
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: FakeTopologyRepository({'solution1': solution}),
        );

        // Two of the four required devices present, none cabled — the
        // grader emits one presence check per required device.
        final result = await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Assessment 1',
          studentTopology: _topology(
            id: 'student_canvas',
            nodes: [_pc('n1'), _pc('n2')],
          ),
        );

        expect(result, isNotNull);
        expect(provider.lastProgress?.correctChecks, 2);
        expect(provider.lastProgress?.totalChecks, 4);
        expect(provider.lastProgress?.scorePercent, 50.0);
      },
    );

    test(
      'a course assessment never touches points, even on a fail',
      () async {
        // Regression: checkTopology used to run the whole points/demotion
        // block unconditionally. A student opening a lecturer's course
        // assessment — completely unrelated to Free Practice — watched it
        // silently deduct Free Practice points and could even get demoted a
        // Free Practice level, despite the explicit requirement that course
        // assessments stay separate from Free Practice grades.
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2')],
          edges: const [
            CableEdge(
              edgeId: 'se1',
              sourceNodeId: 's1',
              sourceInterface: 'eth0',
              targetNodeId: 's2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          )
          // Low enough that the old bug would have demoted a Free Practice
          // level on this very fail.
          ..points = 0
          ..practiceLevel = 4;
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: FakeTopologyRepository({'solution1': solution}),
        );

        await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Assessment 1',
          studentTopology: _topology(
            id: 'student_canvas',
            nodes: [_pc('n1'), _pc('n2')],
          ),
          // practiceLevel omitted — this is the course-assessment case.
        );

        expect(
          gradingRepo.appliedDeltas,
          isEmpty,
          reason: 'no points call at all for a course assessment',
        );
        expect(gradingRepo.points, 0, reason: 'score must be untouched');
        expect(
          gradingRepo.demoteCalls,
          0,
          reason: 'nothing to demote — Free Practice level is unrelated',
        );
        expect(gradingRepo.practiceLevel, 4);
        expect(provider.lastPointsDelta, 0);
        expect(provider.lastPointsTotal, isNull);
        expect(provider.lastDemotedToLevel, isNull);
      },
    );

    test(
      'a course assessment pass never advances the Free Practice level',
      () async {
        final solution = _topology(
          id: 'solution1',
          nodes: [_pc('s1'), _pc('s2')],
          edges: const [
            CableEdge(
              edgeId: 'se1',
              sourceNodeId: 's1',
              sourceInterface: 'eth0',
              targetNodeId: 's2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final gradingRepo = FakeGradingRepository()
          ..solutionKeyToReturn = const ExerciseSolutionKey(
            solutionTopologyId: 'solution1',
          );
        final provider = GradingProvider(
          gradingRepository: gradingRepo,
          topologyRepository: FakeTopologyRepository({'solution1': solution}),
        );

        await provider.checkTopology(
          uid: 'student1',
          exerciseId: 'ex1',
          exerciseTitle: 'Assessment 1',
          studentTopology: _topology(
            id: 'student_canvas',
            nodes: [_pc('n1'), _pc('n2')],
            edges: const [
              CableEdge(
                edgeId: 'e1',
                sourceNodeId: 'n1',
                sourceInterface: 'eth0',
                targetNodeId: 'n2',
                targetInterface: 'eth0',
                cableType: 'Ethernet',
              ),
            ],
          ),
        );

        expect(gradingRepo.advancedPracticeLevels, isEmpty);
        expect(gradingRepo.appliedDeltas, isEmpty);
      },
    );
  });
}
