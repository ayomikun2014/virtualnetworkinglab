import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/enums/app_enums.dart';
import 'package:virtuanetlab/data/models/topology_model.dart';
import 'package:virtuanetlab/features/topology/widgets/cable_painter.dart';

DeviceNode _pc(String id, String label, double x, double y) => DeviceNode(
  nodeId: id,
  label: label,
  type: DeviceType.pc,
  model: 'Ubuntu',
  position: Position(x: x, y: y),
  interfaces: const [InterfaceConfig(name: 'eth0')],
);

void main() {
  group('cableColorForType', () {
    test('each medium maps to a distinct colour', () {
      final ethernet = cableColorForType('Ethernet');
      final fiber = cableColorForType('Fiber');
      final serial = cableColorForType('Serial');

      expect(ethernet, isNot(equals(fiber)));
      expect(fiber, isNot(equals(serial)));
      expect(ethernet, isNot(equals(serial)));
    });

    test('is case-insensitive, since stored cableType casing may vary', () {
      expect(cableColorForType('ethernet'), cableColorForType('ETHERNET'));
      expect(cableColorForType('Fiber'), cableColorForType('fiber'));
    });

    test('an unrecognised type falls back to a colour rather than throwing', () {
      expect(() => cableColorForType('carrier-pigeon'), returnsNormally);
    });
  });

  group('CablePainter.paint', () {
    test(
      'draws a populated topology — including the new midpoint link label — without throwing',
      () {
        final nodes = [
          _pc('n1', 'PC1', 100, 100),
          _pc('n2', 'PC2', 400, 250),
        ];
        const edges = [
          CableEdge(
            edgeId: 'e1',
            sourceNodeId: 'n1',
            sourceInterface: 'eth0',
            targetNodeId: 'n2',
            targetInterface: 'eth0',
            cableType: 'Fiber',
          ),
        ];

        final painter = CablePainter(
          edges: edges,
          nodes: nodes,
          selectedNodeId: 'n1',
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // The label draw path (bezier midpoint math + TextPainter layout +
        // RRect) is new; a sign error or a TextPainter used before layout()
        // would throw here rather than just rendering wrong.
        expect(
          () => painter.paint(canvas, const Size(1000, 800)),
          returnsNormally,
        );

        recorder.endRecording().dispose();
      },
    );

    test(
      'skips an edge whose node was deleted rather than crashing the canvas',
      () {
        final nodes = [_pc('n1', 'PC1', 0, 0)];
        const edges = [
          CableEdge(
            edgeId: 'e1',
            sourceNodeId: 'n1',
            sourceInterface: 'eth0',
            targetNodeId: 'deleted_node',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ];

        final painter = CablePainter(edges: edges, nodes: nodes);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(500, 500)),
          returnsNormally,
        );
        recorder.endRecording().dispose();
      },
    );

    test('handles two nodes stacked at the same position (zero-length cable)', () {
      // A degenerate case worth checking explicitly: start == end collapses
      // the bezier to a point, which is exactly the kind of input that
      // trips up hand-rolled curve-point math with a division or an
      // assumption baked in.
      final nodes = [_pc('n1', 'PC1', 50, 50), _pc('n2', 'PC2', 50, 50)];
      const edges = [
        CableEdge(
          edgeId: 'e1',
          sourceNodeId: 'n1',
          sourceInterface: 'eth0',
          targetNodeId: 'n2',
          targetInterface: 'eth0',
          cableType: 'Serial',
        ),
      ];

      final painter = CablePainter(edges: edges, nodes: nodes);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(200, 200)),
        returnsNormally,
      );
      recorder.endRecording().dispose();
    });
  });
}
