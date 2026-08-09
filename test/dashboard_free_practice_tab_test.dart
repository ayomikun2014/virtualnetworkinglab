import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:virtuanetlab/core/errors/failures.dart';
import 'package:virtuanetlab/core/services/practice_level_seed_service.dart';
import 'package:virtuanetlab/data/models/exercise_model.dart';
import 'package:virtuanetlab/data/models/user_model.dart';
import 'package:virtuanetlab/data/repositories/auth_repository.dart';
import 'package:virtuanetlab/data/repositories/exercise_repository.dart';
import 'package:virtuanetlab/data/repositories/grading_repository.dart';
import 'package:virtuanetlab/features/auth/providers/auth_provider.dart';
import 'package:virtuanetlab/features/dashboard/screens/student_dashboard.dart';
import 'package:virtuanetlab/features/dashboard/widgets/dashboard_layout.dart';
import 'package:virtuanetlab/features/exercises/providers/exercise_provider.dart';
import 'package:virtuanetlab/features/exercises/providers/progress_provider.dart';
import 'package:virtuanetlab/features/exercises/screens/practice_levels_screen.dart';
import 'package:virtuanetlab/features/topology/providers/grading_provider.dart';
import 'package:virtuanetlab/features/topology/providers/topology_provider.dart';
import 'package:virtuanetlab/features/topology/services/topology_grader.dart';

/// Emits a single `null` so AuthProvider's initial isLoading flips to false
/// and the widget tree settles, without needing a real Firebase User.
class _LoggedOutAuthRepository implements IAuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream<User?>.fromIterable([null]);

  @override
  User? get currentUser => null;

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) {
    throw const AuthFailure('not used in this test');
  }

  @override
  Future<UserModel> registerStudent({
    required String email,
    required String password,
    required String displayName,
    required String studentIdNumber,
    required String departmentId,
    List<String> enrolledCourseIds = const [],
  }) {
    throw const AuthFailure('not used in this test');
  }

  @override
  Future<UserModel> registerLecturer({
    required String email,
    required String password,
    required String displayName,
    required String departmentId,
  }) {
    throw const AuthFailure('not used in this test');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel?> getCurrentUserProfile() async => null;
}

class _EmptyExerciseRepository implements IExerciseRepository {
  @override
  Future<List<ExerciseModel>> getPracticeLevels() async => [];

  @override
  Future<List<ExerciseModel>> getCourseAssessments(List<String> ids) async =>
      [];

  @override
  Future<ExerciseModel> getExercise(String id) async {
    throw const ServerFailure('not used in this test');
  }
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

void main() {
  testWidgets(
    'opening the Free Practice tab shows the dashboard shell (sidebar + '
    'nav), not the old bare standalone page',
    (tester) async {
      // tester.view.physicalSize, not tester.binding.setSurfaceSize: the
      // latter controls the rendering surface but doesn't reliably drive
      // MediaQuery.of(context).size, which is what DashboardLayout's
      // isMobile check reads to decide whether to show the sidebar at all.
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  AuthProvider(authRepository: _LoggedOutAuthRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  ExerciseProvider(
                    repository: _EmptyExerciseRepository(),
                    seedService: _NoopSeedService(),
                  ),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  ProgressProvider(repository: _NoopGradingRepository()),
            ),
            ChangeNotifierProvider(create: (_) => TopologyProvider()),
            ChangeNotifierProvider(create: (_) => GradingProvider()),
          ],
          child: const MaterialApp(
            home: StudentDashboard(
              initialTabIndex: DashboardLayout.freePracticeTabIndex,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The actual bug: the old /practice-levels route had a bare Scaffold
      // with just an AppBar — none of this sidebar, and no working back
      // button, existed at all.
      expect(find.text('Dashboard Hub'), findsOneWidget);
      expect(find.text('Courses Lab'), findsOneWidget);
      expect(find.text('Save History'), findsOneWidget);
      expect(find.text('Sandbox Canvas'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // And it's actually showing Free Practice content, not Dashboard Hub.
      expect(find.byType(PracticeLevelsScreen), findsOneWidget);
    },
  );

  testWidgets('the Free Practice nav item is highlighted as selected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(authRepository: _LoggedOutAuthRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                ExerciseProvider(
                    repository: _EmptyExerciseRepository(),
                    seedService: _NoopSeedService(),
                  ),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                ProgressProvider(repository: _NoopGradingRepository()),
          ),
          ChangeNotifierProvider(create: (_) => TopologyProvider()),
          ChangeNotifierProvider(create: (_) => GradingProvider()),
        ],
        child: const MaterialApp(
          home: StudentDashboard(
            initialTabIndex: DashboardLayout.freePracticeTabIndex,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Free Practice'),
    );
    expect(tile.selected, isTrue);
  });
}
