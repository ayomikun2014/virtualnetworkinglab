import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/services/practice_level_seed_service.dart';
import 'package:virtuanetlab/features/topology/services/topology_grader.dart';

void main() {
  group('PracticeLevelSeedService starter data', () {
    final topologies = PracticeLevelSeedService.starterSolutionTopologiesForTest();

    test('seeds at least one level', () {
      expect(topologies, isNotEmpty);
    });

    test('every level has a unique, non-empty name', () {
      final names = topologies.map((t) => t.name).toSet();
      expect(names.length, topologies.length);
      expect(names.every((n) => n.trim().isNotEmpty), isTrue);
    });

    test('every level has at least one device and one cable', () {
      for (final topology in topologies) {
        expect(
          topology.nodes,
          isNotEmpty,
          reason: '${topology.name} has no devices',
        );
        expect(
          topology.edges,
          isNotEmpty,
          reason: '${topology.name} has no cables',
        );
      }
    });

    test('every cable connects two nodes that actually exist', () {
      for (final topology in topologies) {
        final nodeIds = topology.nodes.map((n) => n.nodeId).toSet();
        for (final edge in topology.edges) {
          expect(
            nodeIds.contains(edge.sourceNodeId),
            isTrue,
            reason:
                '${topology.name}: edge ${edge.edgeId} sources a node id '
                '(${edge.sourceNodeId}) not present in this level',
          );
          expect(
            nodeIds.contains(edge.targetNodeId),
            isTrue,
            reason:
                '${topology.name}: edge ${edge.edgeId} targets a node id '
                '(${edge.targetNodeId}) not present in this level',
          );
        }
      }
    });

    test('the curriculum is 20 contiguous levels starting at 1', () {
      final levels = PracticeLevelSeedService.starterLevelSummariesForTest()
          .map((l) => l.level)
          .toList();

      expect(levels, List.generate(20, (i) => i + 1));
    });

    test('the original four starter levels are still levels 1-4', () {
      // These shipped first and students have progress against them, so an
      // expansion must extend the curriculum rather than renumber or rename
      // the levels underneath anyone partway through it.
      final firstFour = PracticeLevelSeedService.starterLevelSummariesForTest()
          .take(4)
          .map((l) => l.title)
          .toList();

      expect(firstFour, [
        'Connect Two PCs',
        'Build a Star Network',
        'Switch to Router',
        'Add a Server',
      ]);
    });

    test('no title re-states the level number', () {
      // The level number is rendered as its own "LEVEL N" badge on the
      // dashboard card and the Free Practice tile. A title of "Level 1:
      // Connect Two PCs" made every card show the word "Level" twice.
      for (final summary
          in PracticeLevelSeedService.starterLevelSummariesForTest()) {
        expect(
          summary.title.toLowerCase(),
          isNot(startsWith('level ')),
          reason: '"${summary.title}" repeats the level number in the title',
        );
      }
    });

    test(
      'a canvas built exactly to the solution passes TopologyGrader',
      () {
        // The strongest end-to-end check: if a student reproduced the
        // solution device-for-device and cable-for-cable, grading it against
        // itself must pass. This is what would actually catch a typo'd node
        // id, not just its presence.
        for (final topology in topologies) {
          final result = TopologyGrader.gradeCabling(
            student: topology,
            solution: topology,
          );
          expect(
            result.passed,
            isTrue,
            reason:
                '${topology.name} does not pass grading against its own '
                'solution: ${result.failures.map((c) => c.message).join('; ')}',
          );
        }
      },
    );
  });

  group('PracticeLevelSeedService upgrade rules', () {
    Map<String, dynamic> seededDoc({int? seedVersion}) => {
      'authorUid': PracticeLevelSeedService.seedAuthorUid,
      // Null-aware element: the whole entry drops out when seedVersion is
      // null, which is how a pre-versioning document is modelled.
      'seedVersion': ?seedVersion,
    };

    test('rewrites a level seeded before versioning existed', () {
      // The original four levels were written with no seedVersion field at
      // all. Those are exactly the documents that need the renamed titles,
      // so treating a missing field as "current" would strand every project
      // that had already run the old seeder.
      expect(
        PracticeLevelSeedService.shouldRewriteExistingLevel(seededDoc()),
        isTrue,
      );
    });

    test('leaves a level already at the current version alone', () {
      expect(
        PracticeLevelSeedService.shouldRewriteExistingLevel(
          seededDoc(seedVersion: PracticeLevelSeedService.seedVersion),
        ),
        isFalse,
      );
    });

    test("never overwrites a level a lecturer has taken over", () {
      // Ownership beats version: once a lecturer edits a level through the
      // authoring tab it stops being starter data, and a future version bump
      // silently reverting their work would be far worse than a stale title.
      expect(
        PracticeLevelSeedService.shouldRewriteExistingLevel({
          'authorUid': 'lecturer_uid_123',
        }),
        isFalse,
      );
    });
  });
}
