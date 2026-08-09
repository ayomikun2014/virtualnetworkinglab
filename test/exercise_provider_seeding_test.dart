import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/enums/app_enums.dart';
import 'package:virtuanetlab/core/errors/failures.dart';
import 'package:virtuanetlab/core/services/practice_level_seed_service.dart';
import 'package:virtuanetlab/data/models/exercise_model.dart';
import 'package:virtuanetlab/data/repositories/exercise_repository.dart';
import 'package:virtuanetlab/features/exercises/providers/exercise_provider.dart';

ExerciseModel _level(int n) => ExerciseModel(
  exerciseId: 'lvl$n',
  title: 'Level $n',
  description: 'desc',
  categoryId: 'free_practice',
  exerciseType: ExerciseType.switching,
  difficulty: DifficultyLevel.beginner,
  authorUid: 'system_seed',
  initialTopologyId: '',
  practiceLevel: n,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

/// Returns whatever `queueOfResults` yields, one call at a time — lets a
/// test model "empty, then populated after seeding".
class FakeExerciseRepository implements IExerciseRepository {
  final List<List<ExerciseModel>> queuedResults;
  int getPracticeLevelsCalls = 0;
  Failure? throwOnFetch;

  FakeExerciseRepository(this.queuedResults);

  @override
  Future<List<ExerciseModel>> getPracticeLevels() async {
    if (throwOnFetch != null) throw throwOnFetch!;
    final result = queuedResults[getPracticeLevelsCalls.clamp(
      0,
      queuedResults.length - 1,
    )];
    getPracticeLevelsCalls++;
    return result;
  }

  @override
  Future<List<ExerciseModel>> getCourseAssessments(List<String> ids) async => [];

  @override
  Future<ExerciseModel> getExercise(String id) async => _level(1);
}

class FakeSeedService implements IPracticeLevelSeedService {
  final PracticeSeedOutcome outcome;
  int calls = 0;

  FakeSeedService(this.outcome);

  @override
  Future<PracticeSeedOutcome> bootstrapPracticeLevels() async {
    calls++;
    return outcome;
  }
}

void main() {
  group('ExerciseProvider.fetchPracticeLevels seeding', () {
    test('seeds and re-fetches when the database has no levels', () async {
      final repo = FakeExerciseRepository([
        [], // first read: empty database
        [_level(1), _level(2)], // after seeding
      ]);
      final seeder = FakeSeedService(
        const PracticeSeedOutcome(seededCount: 2),
      );

      final provider = ExerciseProvider(
        repository: repo,
        seedService: seeder,
      );
      await provider.fetchPracticeLevels();

      expect(seeder.calls, 1);
      expect(provider.practiceLevels, hasLength(2));
      expect(provider.errorMessage, isNull);
    });

    test(
      'still seeds when levels already exist, so an expanded curriculum '
      'reaches a database that is not empty',
      () async {
        // The regression this replaces: seeding was gated on the level list
        // being empty. A database holding the original four levels was
        // never empty, so growing the starter set to twenty could not
        // reach it — reloading the app did nothing, forever.
        final repo = FakeExerciseRepository([
          [_level(1), _level(2), _level(3), _level(4)],
          [for (var n = 1; n <= 20; n++) _level(n)],
        ]);
        final seeder = FakeSeedService(
          const PracticeSeedOutcome(seededCount: 16),
        );

        final provider = ExerciseProvider(
          repository: repo,
          seedService: seeder,
        );
        await provider.fetchPracticeLevels();

        expect(seeder.calls, 1);
        expect(provider.practiceLevels, hasLength(20));
      },
    );

    test('an up-to-date database is left exactly as it is', () async {
      // Seeding is asked every session now, so "nothing to do" has to stay
      // a genuine no-op rather than reporting an error or re-fetching.
      final repo = FakeExerciseRepository([
        [for (var n = 1; n <= 20; n++) _level(n)],
      ]);
      final seeder = FakeSeedService(const PracticeSeedOutcome());

      final provider = ExerciseProvider(
        repository: repo,
        seedService: seeder,
      );
      await provider.fetchPracticeLevels();

      expect(seeder.calls, 1);
      expect(repo.getPracticeLevelsCalls, 1, reason: 'no pointless re-fetch');
      expect(provider.practiceLevels, hasLength(20));
      expect(provider.errorMessage, isNull);
    });

    test(
      'surfaces the seed failure instead of showing an empty list',
      () async {
        // The whole point: a rules rejection previously looked identical to
        // "no levels published yet" — an empty screen with no explanation.
        final repo = FakeExerciseRepository([<ExerciseModel>[]]);
        final seeder = FakeSeedService(
          const PracticeSeedOutcome(
            error: '[cloud_firestore/permission-denied] Missing permissions',
          ),
        );

        final provider = ExerciseProvider(
          repository: repo,
          seedService: seeder,
        );
        await provider.fetchPracticeLevels();

        expect(seeder.calls, 1);
        expect(provider.practiceLevels, isEmpty);
        expect(provider.errorMessage, contains('permission-denied'));
      },
    );

    test('only attempts seeding once per session', () async {
      final repo = FakeExerciseRepository([<ExerciseModel>[]]);
      final seeder = FakeSeedService(
        const PracticeSeedOutcome(error: 'still failing'),
      );

      final provider = ExerciseProvider(
        repository: repo,
        seedService: seeder,
      );
      await provider.fetchPracticeLevels();
      await provider.fetchPracticeLevels();
      await provider.fetchPracticeLevels();

      expect(seeder.calls, 1);
    });

    test('a read failure is reported and does not trigger seeding', () async {
      final repo = FakeExerciseRepository([<ExerciseModel>[]])
        ..throwOnFetch = const ServerFailure('index required');
      final seeder = FakeSeedService(const PracticeSeedOutcome());

      final provider = ExerciseProvider(
        repository: repo,
        seedService: seeder,
      );
      await provider.fetchPracticeLevels();

      expect(seeder.calls, 0);
      expect(provider.errorMessage, contains('index required'));
    });
  });
}
