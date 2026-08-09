import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:virtuanetlab/app/app_routes.dart';
import 'package:virtuanetlab/core/enums/app_enums.dart';
import 'package:virtuanetlab/core/errors/failures.dart';
import 'package:virtuanetlab/core/services/practice_level_seed_service.dart';
import 'package:virtuanetlab/data/models/exercise_model.dart';
import 'package:virtuanetlab/data/models/topology_model.dart';
import 'package:virtuanetlab/data/models/user_model.dart';
import 'package:virtuanetlab/data/repositories/auth_repository.dart';
import 'package:virtuanetlab/data/repositories/exercise_repository.dart';
import 'package:virtuanetlab/data/repositories/grading_repository.dart';
import 'package:virtuanetlab/data/repositories/topology_repository.dart';
import 'package:virtuanetlab/features/auth/providers/auth_provider.dart';
import 'package:virtuanetlab/features/exercises/providers/exercise_provider.dart';
import 'package:virtuanetlab/features/exercises/providers/progress_provider.dart';
import 'package:virtuanetlab/features/exercises/providers/save_history_provider.dart';
import 'package:virtuanetlab/features/topology/providers/grading_provider.dart';
import 'package:virtuanetlab/features/topology/providers/topology_provider.dart';
import 'package:virtuanetlab/features/topology/services/topology_grader.dart';

/// A genuinely "logged in" AuthProvider with no real Firebase User — see the
/// note in canvas_gorouter_navigation_test.dart for why `currentUser` can
/// safely stay null here.
class _FakeLoginAuthRepository implements IAuthRepository {
  final UserModel user;
  _FakeLoginAuthRepository(this.user);

  @override
  Stream<User?> get authStateChanges => Stream<User?>.fromIterable([null]);

  @override
  User? get currentUser => null;

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async => user;

  @override
  Future<UserModel> registerStudent({
    required String email,
    required String password,
    required String displayName,
    required String studentIdNumber,
    required String departmentId,
    List<String> enrolledCourseIds = const [],
  }) async => user;

  @override
  Future<UserModel> registerLecturer({
    required String email,
    required String password,
    required String displayName,
    required String departmentId,
  }) async => user;

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel?> getCurrentUserProfile() async => user;
}

ExerciseModel _practiceLevel({
  required String exerciseId,
  required int level,
  required String title,
}) {
  final now = DateTime.now();
  return ExerciseModel(
    exerciseId: exerciseId,
    title: title,
    description: 'Brief for $title.',
    categoryId: 'free_practice',
    courseTitle: 'Free Practice',
    exerciseType: ExerciseType.switching,
    difficulty: DifficultyLevel.beginner,
    authorUid: 'system_seed',
    initialTopologyId: '',
    practiceLevel: level,
    createdAt: now,
    updatedAt: now,
  );
}

class _TwoLevelExerciseRepository implements IExerciseRepository {
  @override
  Future<List<ExerciseModel>> getPracticeLevels() async => [
    _practiceLevel(
      exerciseId: 'practice_seed_level_1',
      level: 1,
      title: 'Connect Two PCs',
    ),
    _practiceLevel(
      exerciseId: 'practice_seed_level_2',
      level: 2,
      title: 'Build a Star Network',
    ),
  ];

  @override
  Future<List<ExerciseModel>> getCourseAssessments(List<String> ids) async =>
      [];

  @override
  Future<ExerciseModel> getExercise(String id) async =>
      throw const ServerFailure('not used in this test');
}

class _NoopSeedService implements IPracticeLevelSeedService {
  @override
  Future<PracticeSeedOutcome> bootstrapPracticeLevels() async =>
      const PracticeSeedOutcome();
}

class _NoopGradingRepository implements IGradingRepository {
  @override
  Future<ExerciseSolutionKey?> getSolutionKey(String exerciseId) async => null;
  @override
  Future<ExerciseProgress?> getProgress({
    required String uid,
    required String exerciseId,
  }) async => null;
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
  }) async => ExerciseProgress(exerciseId: exerciseId);
  @override
  Future<void> recordSave({
    required String uid,
    required String title,
    required String topologyId,
    String? exerciseId,
  }) async {}
  @override
  Future<({int before, int after})> applyPointsDelta({
    required String uid,
    required int delta,
  }) async => (before: 0, after: delta > 0 ? delta : 0);
  @override
  Future<int> demotePracticeLevel({required String uid}) async => 1;
  @override
  Future<void> resetExerciseProgress({
    required String uid,
    required String exerciseId,
  }) async {}
  @override
  Future<void> advancePracticeLevel({
    required String uid,
    required int practiceLevel,
  }) async {}
  @override
  Stream<Map<String, ExerciseProgress>> watchProgress(String uid) =>
      const Stream.empty();
  @override
  Stream<List<SaveRecord>> watchSaveHistory(String uid) =>
      const Stream.empty();
}

class _StubTopologyRepository implements ITopologyRepository {
  // Yields a real (empty) topology rather than null: on null,
  // TopologyProvider synthesises a blank one and stamps it with
  // FirebaseAuth.instance.currentUser?.uid, which needs a Firebase app this
  // test deliberately doesn't have.
  @override
  Stream<TopologyModel?> watchTopology(String topologyId) {
    final now = DateTime.now();
    return Stream<TopologyModel?>.value(
      TopologyModel(
        topologyId: topologyId,
        ownerUid: 'u1',
        name: 'Stub',
        nodes: const [],
        edges: const [],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<TopologyModel> getTopology(String topologyId) async =>
      throw UnimplementedError('not used in this test');

  @override
  Future<void> saveTopology(TopologyModel topology) async {}
}

void main() {
  testWidgets(
    "the Dashboard Hub's practice cards each open their own level's canvas, "
    'not the same dashboard URL for every level',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final user = UserModel(
        uid: 'u1',
        email: 'student@test.edu',
        displayName: 'Test Student',
        departmentId: 'dept_net',
        // Both seeded levels unlocked, so neither button is disabled:
        // progression reached, and enough points in hand to open one.
        freePracticeLevel: 4,
        points: 10,
        lastLoginAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(
        authRepository: _FakeLoginAuthRepository(user),
      );
      addTearDown(authProvider.dispose);

      final router = AppRouter.createRouter(authProvider);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(
              create: (_) =>
                  TopologyProvider(repository: _StubTopologyRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => ExerciseProvider(
                repository: _TwoLevelExerciseRepository(),
                seedService: _NoopSeedService(),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  ProgressProvider(repository: _NoopGradingRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => GradingProvider(
                gradingRepository: _NoopGradingRepository(),
                // Also stubbed: GradingProvider builds its own
                // FirebaseTopologyRepository otherwise, and the canvas this
                // test navigates into reads it during build.
                topologyRepository: _StubTopologyRepository(),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => SaveHistoryProvider(
                repository: _NoopGradingRepository(),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await authProvider.loginWithIdentifierAndPassword(
        identifier: 'student@test.edu',
        password: 'irrelevant',
      );
      await tester.pumpAndSettle();

      // Both levels render on the hub's Free Practice Progression grid, each
      // labelled by its own badge.
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.text('LEVEL 2'), findsOneWidget);

      // Tap Level 2's button specifically — the whole bug was that this did
      // the same thing as Level 1's.
      final level2Button = find.descendant(
        of: find.ancestor(
          of: find.text('LEVEL 2'),
          matching: find.byType(Column),
        ),
        matching: find.widgetWithText(OutlinedButton, 'Start Practice'),
      );

      await tester.ensureVisible(level2Button.first);
      await tester.pumpAndSettle();
      await tester.tap(level2Button.first);

      // pump, not pumpAndSettle: the destination canvas runs continuous
      // animations, so settling never completes. The route change itself is
      // synchronous, and the location is what this test is asserting on.
      await tester.pump();

      final location = router
          .routeInformationProvider
          .value
          .uri
          .toString();

      // Previously this was '/student-dashboard?tab=3' for every single
      // card: no canvas, no exerciseId, and identical for Level 1 and
      // Level 2 — which is exactly what "clicking level 1 and level 2 shows
      // the same data" looked like from the student's side.
      expect(
        location,
        startsWith('/canvas-builder/practice_level_2_u1'),
        reason: "Level 2's card must open level 2's own canvas",
      );
      expect(
        location,
        contains('exerciseId=practice_seed_level_2'),
        reason:
            'the exerciseId has to ride along, or the canvas opens as an '
            'ungraded sandbox with no Check Connection button',
      );
      expect(location, contains('practiceLevel=2'));
    },
  );

  testWidgets(
    'a student with no points can still open Level 1, but Level 2 asks '
    'them to earn some first',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final user = UserModel(
        uid: 'u1',
        email: 'student@test.edu',
        displayName: 'Broke Student',
        departmentId: 'dept_net',
        // Reached Level 2 by progression, but spent everything on failed
        // checks — the exact state the points gate exists to represent.
        freePracticeLevel: 4,
        points: 0,
        lastLoginAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(
        authRepository: _FakeLoginAuthRepository(user),
      );
      addTearDown(authProvider.dispose);

      final router = AppRouter.createRouter(authProvider);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(
              create: (_) =>
                  TopologyProvider(repository: _StubTopologyRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => ExerciseProvider(
                repository: _TwoLevelExerciseRepository(),
                seedService: _NoopSeedService(),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  ProgressProvider(repository: _NoopGradingRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => GradingProvider(
                gradingRepository: _NoopGradingRepository(),
                topologyRepository: _StubTopologyRepository(),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => SaveHistoryProvider(
                repository: _NoopGradingRepository(),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await authProvider.loginWithIdentifierAndPassword(
        identifier: 'student@test.edu',
        password: 'irrelevant',
      );
      await tester.pumpAndSettle();

      // Level 1 stays playable — it is the only way back to earning points.
      expect(find.text('Start Practice'), findsOneWidget);

      // Level 2 says why it is shut, rather than just "Locked", which would
      // read as "you haven't got here yet" when in fact they have.
      expect(
        find.text('Need ${GradingProvider.pointsToUnlockLevel} points'),
        findsOneWidget,
      );
    },
  );
}
