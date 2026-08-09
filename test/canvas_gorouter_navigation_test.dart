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

/// A "logged in" AuthProvider without a real Firebase User.
///
/// `AuthProvider.loginWithIdentifierAndPassword` does
/// `await _authRepository.currentUser?.getIdTokenResult(true);` — the `?.`
/// makes that a safe no-op when `currentUser` is null, so `login()` can
/// return a plain fake UserModel and `currentUser` can just stay null. That
/// leaves `AuthProvider.currentUser` genuinely populated afterwards, which
/// is what the router's redirect guard and every screen actually check.
class FakeLoginAuthRepository implements IAuthRepository {
  final UserModel user;
  FakeLoginAuthRepository(this.user);

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

class SpyTopologyRepository implements ITopologyRepository {
  final Map<String, StreamController<TopologyModel?>> _controllers = {};
  final List<String> watchedIds = [];

  void seed(String topologyId, TopologyModel model) {
    (_controllers[topologyId] ??= StreamController<TopologyModel?>()).add(
      model,
    );
  }

  @override
  Stream<TopologyModel?> watchTopology(String topologyId) {
    watchedIds.add(topologyId);
    return (_controllers[topologyId] ??= StreamController<TopologyModel?>())
        .stream;
  }

  @override
  Future<TopologyModel> getTopology(String topologyId) async =>
      throw UnimplementedError('not used in this test');

  @override
  Future<void> saveTopology(TopologyModel topology) async {}
}

class _EmptyExerciseRepository implements IExerciseRepository {
  @override
  Future<List<ExerciseModel>> getPracticeLevels() async => [];
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
  Future<ExerciseSolutionKey?> getSolutionKey(String exerciseId) async =>
      null;
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

TopologyModel _topologyWithNodes({
  required String topologyId,
  required List<String> nodeLabels,
}) {
  final now = DateTime.now();
  return TopologyModel(
    topologyId: topologyId,
    ownerUid: 'u1',
    name: 'Topology $topologyId',
    nodes: [
      for (var i = 0; i < nodeLabels.length; i++)
        DeviceNode(
          nodeId: 'node$i',
          label: nodeLabels[i],
          type: DeviceType.pc,
          model: 'Ubuntu Host',
          position: Position(x: 100.0 * i, y: 100),
          interfaces: const [InterfaceConfig(name: 'eth0')],
        ),
    ],
    edges: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets(
    'the real app router: navigating from level 1 to level 2 loads level '
    "2's own topology, not level 1's — the exact production path a "
    'student follows',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final user = UserModel(
        uid: 'u1',
        email: 'student@test.edu',
        displayName: 'Test Student',
        departmentId: 'dept_net',
        freePracticeLevel: 3,
        lastLoginAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(
        authRepository: FakeLoginAuthRepository(user),
      );
      addTearDown(authProvider.dispose);

      final topologyRepo = SpyTopologyRepository();
      topologyRepo.seed(
        'practice_level_1_u1',
        _topologyWithNodes(
          topologyId: 'practice_level_1_u1',
          nodeLabels: ['PC1', 'PC2'],
        ),
      );
      topologyRepo.seed(
        'practice_level_2_u1',
        _topologyWithNodes(
          topologyId: 'practice_level_2_u1',
          nodeLabels: [],
        ),
      );
      final topologyProvider = TopologyProvider(repository: topologyRepo);

      final router = AppRouter.createRouter(authProvider);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: topologyProvider),
            ChangeNotifierProvider(
              create: (_) => ExerciseProvider(
                repository: _EmptyExerciseRepository(),
                seedService: _NoopSeedService(),
              ),
            ),
            // Default-constructing ProgressProvider() reaches for a real
            // FirebaseGradingRepository, which needs Firebase.initializeApp()
            // — never called in this widget test. Inject the noop repo.
            ChangeNotifierProvider(
              create: (_) =>
                  ProgressProvider(repository: _NoopGradingRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  GradingProvider(gradingRepository: _NoopGradingRepository()),
            ),
            // The router briefly renders DashboardHomeView (student
            // dashboard) as part of the post-login redirect, and that view
            // reads this provider in didChangeDependencies — without it
            // registered here the test crashes before it ever reaches the
            // canvas navigation this test is actually about.
            ChangeNotifierProvider(
              create: (_) => SaveHistoryProvider(
                repository: _NoopGradingRepository(),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Log in explicitly — matches how a real session reaches the app
      // (mirrors AuthProvider's own login flow rather than pre-seeding
      // private state), which is what actually triggers the router's
      // redirect out of /login.
      await authProvider.loginWithIdentifierAndPassword(
        identifier: 'student@test.edu',
        password: 'irrelevant',
      );
      await tester.pumpAndSettle();

      // Navigate exactly the way _openLevel() does for Level 1 (omitting
      // exerciseId so this doesn't also require faking the exercise-brief
      // fetch that CanvasBuilderScreen makes directly, unrelated to the
      // question this test is checking).
      router.go('/canvas-builder/practice_level_1_u1');
      await tester.pumpAndSettle();

      expect(find.text('PC1'), findsOneWidget);
      expect(find.text('PC2'), findsOneWidget);

      // Now the real navigation this bug report is about: from level 1's
      // canvas straight to level 2's, same session, same running app.
      router.go('/canvas-builder/practice_level_2_u1');
      await tester.pumpAndSettle();

      expect(
        topologyRepo.watchedIds,
        ['practice_level_1_u1', 'practice_level_2_u1'],
        reason:
            "go_router must mount a fresh CanvasBuilderScreen for level 2's "
            'URL, which is what makes it call watchTopology again for the '
            'new id.',
      );

      expect(
        find.text('PC1'),
        findsNothing,
        reason:
            "level 1's PC1 must not still be on screen once level 2's "
            "(empty) canvas has loaded through the real app router.",
      );
      expect(find.text('PC2'), findsNothing);
    },
  );
}
