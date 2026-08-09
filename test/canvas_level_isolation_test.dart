import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:virtuanetlab/core/enums/app_enums.dart';
import 'package:virtuanetlab/data/models/topology_model.dart';
import 'package:virtuanetlab/data/repositories/topology_repository.dart';
import 'package:virtuanetlab/features/topology/providers/topology_provider.dart';
import 'package:virtuanetlab/features/topology/screens/canvas_builder_screen.dart';

/// One single-subscription controller per topologyId, seeded up front —
/// events added before `.listen()` are buffered, so it doesn't matter that
/// CanvasBuilderScreen only subscribes later, inside its post-frame
/// callback.
class SpyTopologyRepository implements ITopologyRepository {
  final Map<String, StreamController<TopologyModel?>> _controllers = {};
  final List<String> watchedIds = [];
  final List<TopologyModel> saved = [];

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
  Future<void> saveTopology(TopologyModel topology) async {
    saved.add(topology);
  }
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

Widget _canvasApp(TopologyProvider provider, String topologyId) {
  return MaterialApp(
    home: ChangeNotifierProvider<TopologyProvider>.value(
      value: provider,
      // Mirrors the key app_routes.dart now sets on the real route so this
      // pumpWidget-swap test matches production widget identity.
      child: CanvasBuilderScreen(
        key: ValueKey('canvas_$topologyId'),
        topologyId: topologyId,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'switching to a different level in the same app session loads that '
    "level's own topology, not the previous level's",
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = SpyTopologyRepository();
      repo.seed(
        'practice_level_1_u1',
        _topologyWithNodes(
          topologyId: 'practice_level_1_u1',
          nodeLabels: ['PC1', 'PC2'],
        ),
      );
      // Level 2 has never been touched — a real "not attempted yet" canvas.
      repo.seed(
        'practice_level_2_u1',
        _topologyWithNodes(topologyId: 'practice_level_2_u1', nodeLabels: []),
      );

      // The SAME provider instance for both — this is what actually matters:
      // app.dart registers exactly one TopologyProvider for the whole app
      // session, shared across every canvas the student opens.
      final provider = TopologyProvider(repository: repo);

      await tester.pumpWidget(_canvasApp(provider, 'practice_level_1_u1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('PC1'), findsOneWidget);
      expect(find.text('PC2'), findsOneWidget);
      expect(provider.activeTopology?.topologyId, 'practice_level_1_u1');

      // Now open level 2 — same session, same provider, no reload. This is
      // exactly what tapping "Start Practice" on Level 2 right after
      // visiting Level 1 does.
      await tester.pumpWidget(_canvasApp(provider, 'practice_level_2_u1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        repo.watchedIds,
        ['practice_level_1_u1', 'practice_level_2_u1'],
        reason:
            'a fresh subscription must be started for level 2 — if the old '
            "one just kept running, level 2 would show level 1's live "
            'updates forever',
      );

      expect(
        provider.activeTopology?.topologyId,
        'practice_level_2_u1',
        reason: "the provider's active topology must switch over, not keep "
            "pointing at level 1's document",
      );

      expect(
        find.text('PC1'),
        findsNothing,
        reason:
            "level 1's PC1 must not still be showing once level 2's "
            '(empty) canvas has loaded — this is the exact bug being '
            'checked for.',
      );
      expect(find.text('PC2'), findsNothing);
    },
  );

  testWidgets(
    'a pending debounced save from level 1 does not get written to level '
    "2's document after switching levels",
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = SpyTopologyRepository();
      final level1 = _topologyWithNodes(
        topologyId: 'practice_level_1_u1',
        nodeLabels: ['PC1'],
      );
      repo.seed('practice_level_1_u1', level1);
      repo.seed(
        'practice_level_2_u1',
        _topologyWithNodes(topologyId: 'practice_level_2_u1', nodeLabels: []),
      );

      final provider = TopologyProvider(repository: repo);

      await tester.pumpWidget(_canvasApp(provider, 'practice_level_1_u1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Simulate the student editing a field on level 1 right before
      // navigating away — this schedules TopologyProvider's 600ms debounced
      // save (_scheduleSave), exactly like committing an IP address edit in
      // the property inspector does.
      provider.updateNode(level1.nodes.first.copyWith(label: 'PC1-edited'));

      // Navigate away immediately — well within the 600ms debounce window.
      await tester.pumpWidget(_canvasApp(provider, 'practice_level_2_u1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Let the leftover debounce timer fire, if it's still pending.
      await tester.pump(const Duration(milliseconds: 700));

      for (final saved in repo.saved) {
        expect(
          saved.topologyId,
          isNot('practice_level_2_u1'),
          reason:
              "a save queued while editing level 1 must never land on "
              "level 2's document, however the timing works out",
        );
      }
    },
  );
}
