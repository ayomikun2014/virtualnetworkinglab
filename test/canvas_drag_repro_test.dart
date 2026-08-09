import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:virtuanetlab/core/enums/app_enums.dart';
import 'package:virtuanetlab/data/models/topology_model.dart';
import 'package:virtuanetlab/data/repositories/topology_repository.dart';
import 'package:virtuanetlab/features/topology/providers/topology_provider.dart';
import 'package:virtuanetlab/features/topology/screens/canvas_builder_screen.dart';

class FakeTopologyRepository implements ITopologyRepository {
  // Single-subscription: events added before `.listen()` are buffered, so the
  // seeded initial value survives until CanvasBuilderScreen subscribes in its
  // post-frame callback (a broadcast controller would drop it instead).
  final _controller = StreamController<TopologyModel?>();
  TopologyModel? _saved;

  FakeTopologyRepository(TopologyModel initial) {
    _saved = initial;
    _controller.add(initial);
  }

  @override
  Stream<TopologyModel?> watchTopology(String topologyId) => _controller.stream;

  @override
  Future<TopologyModel> getTopology(String topologyId) async => _saved!;

  @override
  Future<void> saveTopology(TopologyModel topology) async {
    _saved = topology;
  }
}

void main() {
  testWidgets('dragging a device node on the canvas updates its position', (
    tester,
  ) async {
    final initial = TopologyModel(
      topologyId: 't1',
      ownerUid: 'u1',
      name: 'Test Topology',
      nodes: [
        DeviceNode(
          nodeId: 'node_pc1',
          label: 'PC1',
          type: DeviceType.pc,
          model: 'Ubuntu Host',
          position: const Position(x: 120, y: 120),
          interfaces: const [InterfaceConfig(name: 'eth0')],
        ),
      ],
      edges: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = FakeTopologyRepository(initial);
    final provider = TopologyProvider(repository: repo);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<TopologyProvider>.value(
          value: provider,
          child: const CanvasBuilderScreen(topologyId: 't1'),
        ),
      ),
    );

    // Let watchTopology's postFrameCallback + stream delivery settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PC1'), findsOneWidget);

    final nodeFinder = find.text('PC1');
    final startCenter = tester.getCenter(nodeFinder);

    final transformBefore = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .clone();

    // Drag the node 150px right and 100px down.
    final gesture = await tester.startGesture(startCenter);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(150, 100));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    final node = provider.activeTopology!.nodes.first;
    // Original position was (120, 120); a real drag should move it roughly
    // by the drag delta. If InteractiveViewer's pan gesture ate the drag
    // instead of the node's own GestureDetector, the node position here
    // will still be (120, 120) even though the *canvas* panned instead.
    expect(
      node.position.x,
      greaterThan(200),
      reason:
          'Node did not move with the drag gesture — position stayed at ${node.position.x},${node.position.y}',
    );

    final transformAfter = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value;

    // A Listener observes pointer events without claiming them in the
    // gesture arena, so it does nothing to stop InteractiveViewer's own
    // recognizer from also treating the same drag as a canvas pan. The node
    // moving (checked above) is not enough on its own to prove the canvas
    // didn't ALSO move underneath it.
    expect(
      transformAfter,
      equals(transformBefore),
      reason:
          'Canvas panned during a node drag — only the node should move, not the background',
    );
  });
}
