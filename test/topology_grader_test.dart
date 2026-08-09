import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/enums/app_enums.dart';
import 'package:virtuanetlab/data/models/topology_model.dart';
import 'package:virtuanetlab/features/topology/services/topology_grader.dart';

DeviceNode _pc(String nodeId, {String? label}) => DeviceNode(
  nodeId: nodeId,
  label: label ?? nodeId,
  type: DeviceType.pc,
  model: 'Ubuntu Host',
  position: const Position(x: 0, y: 0),
  interfaces: const [InterfaceConfig(name: 'eth0')],
);

DeviceNode _switch(String nodeId, {String? label}) => DeviceNode(
  nodeId: nodeId,
  label: label ?? nodeId,
  type: DeviceType.switchDevice,
  model: 'Catalyst 2960',
  position: const Position(x: 0, y: 0),
  interfaces: const [
    InterfaceConfig(name: 'eth0'),
    InterfaceConfig(name: 'eth1'),
  ],
);

TopologyModel _topology({
  required List<DeviceNode> nodes,
  List<CableEdge> edges = const [],
}) {
  final now = DateTime.now();
  return TopologyModel(
    topologyId: 't',
    ownerUid: 'u',
    name: 'Topology',
    nodes: nodes,
    edges: edges,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('TopologyGrader.gradeCabling', () {
    test('passes when devices and cabling match the solution', () {
      final solution = _topology(
        nodes: [
          _pc('s_pc1', label: 'PC1'),
          _pc('s_pc2', label: 'PC2'),
        ],
        edges: const [
          CableEdge(
            edgeId: 's_edge1',
            sourceNodeId: 's_pc1',
            sourceInterface: 'eth0',
            targetNodeId: 's_pc2',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      final student = _topology(
        nodes: [
          _pc('n1', label: 'PC1'),
          _pc('n2', label: 'PC2'),
        ],
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

      final result = TopologyGrader.gradeCabling(
        student: student,
        solution: solution,
      );

      expect(result.passed, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails with a specific message when a required device is missing', () {
      final solution = _topology(
        nodes: [
          _pc('s_pc1', label: 'PC1'),
          _switch('s_sw1', label: 'Switch1'),
        ],
      );

      final student = _topology(nodes: [_pc('n1', label: 'PC1')]);

      final result = TopologyGrader.gradeCabling(
        student: student,
        solution: solution,
      );

      expect(result.passed, isFalse);
      expect(
        result.failures.map((c) => c.message),
        contains(contains('Switch')),
      );
    });

    test('fails when devices are present but not connected', () {
      final solution = _topology(
        nodes: [
          _pc('s_pc1', label: 'PC1'),
          _pc('s_pc2', label: 'PC2'),
        ],
        edges: const [
          CableEdge(
            edgeId: 's_edge1',
            sourceNodeId: 's_pc1',
            sourceInterface: 'eth0',
            targetNodeId: 's_pc2',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      final student = _topology(
        nodes: [
          _pc('n1', label: 'PC1'),
          _pc('n2', label: 'PC2'),
        ],
      );

      final result = TopologyGrader.gradeCabling(
        student: student,
        solution: solution,
      );

      expect(result.passed, isFalse);
      expect(result.failures.single.message, contains('Connect'));
    });

    test('fails when connected with the wrong cable type', () {
      final solution = _topology(
        nodes: [
          _pc('s_pc1', label: 'PC1'),
          _switch('s_sw1', label: 'Switch1'),
        ],
        edges: const [
          CableEdge(
            edgeId: 's_edge1',
            sourceNodeId: 's_pc1',
            sourceInterface: 'eth0',
            targetNodeId: 's_sw1',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      final student = _topology(
        nodes: [
          _pc('n1', label: 'PC1'),
          _switch('n2', label: 'Switch1'),
        ],
        edges: const [
          CableEdge(
            edgeId: 'e1',
            sourceNodeId: 'n1',
            sourceInterface: 'eth0',
            targetNodeId: 'n2',
            targetInterface: 'eth0',
            cableType: 'Fiber',
          ),
        ],
      );

      final result = TopologyGrader.gradeCabling(
        student: student,
        solution: solution,
      );

      expect(result.passed, isFalse);
      expect(result.failures.single.message, contains('Ethernet'));
    });

    test(
      'fails when the student adds devices the design does not call for',
      () {
        // This used to pass. Grading ignored anything beyond the solution,
        // so a student could leave a wrong half-built attempt on the canvas
        // next to a correct one and still be told they had succeeded.
        final solution = _topology(nodes: [_pc('s_pc1', label: 'PC1')]);

        final student = _topology(
          nodes: [
            _pc('n1', label: 'PC1'),
            _pc('n2', label: 'PC2'), // extra, unrequired
            _switch('n3', label: 'Switch1'), // extra, unrequired
          ],
          edges: const [
            CableEdge(
              edgeId: 'e1',
              sourceNodeId: 'n1',
              sourceInterface: 'eth0',
              targetNodeId: 'n3',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        final result = TopologyGrader.gradeCabling(
          student: student,
          solution: solution,
        );

        expect(result.passed, isFalse);
        expect(
          result.failures.map((c) => c.message).join(' '),
          contains('Switch'),
          reason: 'the student needs to be told what to remove',
        );
      },
    );

    test('fails when a correct build has an extra cable bolted onto it', () {
      // Every required link is present and correct — the only problem is a
      // connection that is not part of the design. The old grader only ever
      // asked "is each solution cable present?", so this passed.
      final solution = _topology(
        nodes: [
          _pc('s_pc1', label: 'PC1'),
          _pc('s_pc2', label: 'PC2'),
          _switch('s_sw1', label: 'Switch1'),
        ],
        edges: const [
          CableEdge(
            edgeId: 'se1',
            sourceNodeId: 's_pc1',
            sourceInterface: 'eth0',
            targetNodeId: 's_sw1',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
          CableEdge(
            edgeId: 'se2',
            sourceNodeId: 's_pc2',
            sourceInterface: 'eth0',
            targetNodeId: 's_sw1',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      final student = _topology(
        nodes: [
          _pc('n1', label: 'PC1'),
          _pc('n2', label: 'PC2'),
          _switch('n3', label: 'Switch1'),
        ],
        edges: const [
          CableEdge(
            edgeId: 'e1',
            sourceNodeId: 'n1',
            sourceInterface: 'eth0',
            targetNodeId: 'n3',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
          CableEdge(
            edgeId: 'e2',
            sourceNodeId: 'n2',
            sourceInterface: 'eth0',
            targetNodeId: 'n3',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
          // Not in the design: the two PCs also wired directly together.
          CableEdge(
            edgeId: 'e3',
            sourceNodeId: 'n1',
            sourceInterface: 'eth0',
            targetNodeId: 'n2',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
      );

      final result = TopologyGrader.gradeCabling(
        student: student,
        solution: solution,
      );

      expect(result.passed, isFalse);
      expect(
        result.failures.map((c) => c.message).join(' '),
        contains('Remove the cable'),
      );
    });

    test('an answer key with no devices fails instead of passing', () {
      // checks.every() on an empty list is true in Dart, so a solution
      // topology that was never populated would otherwise mark every
      // submission — including an empty canvas — correct.
      final result = TopologyGrader.gradeCabling(
        student: _topology(nodes: [_pc('n1', label: 'PC1')]),
        solution: _topology(nodes: const []),
      );

      expect(result.passed, isFalse);
      expect(result.failures, isNotEmpty);
    });

    test(
      'matches devices by type and creation order, not by the (renamable) label',
      () {
        final solution = _topology(
          nodes: [
            _pc('s_pc1', label: 'PC1'),
            _pc('s_pc2', label: 'PC2'),
          ],
          edges: const [
            CableEdge(
              edgeId: 's_edge1',
              sourceNodeId: 's_pc1',
              sourceInterface: 'eth0',
              targetNodeId: 's_pc2',
              targetInterface: 'eth0',
              cableType: 'Ethernet',
            ),
          ],
        );

        // Student renamed both PCs via the property inspector — grading
        // must still key off creation order, not this text.
        final student = _topology(
          nodes: [
            _pc('n1', label: "Dad's Computer"),
            _pc('n2', label: 'Gaming Rig'),
          ],
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

        final result = TopologyGrader.gradeCabling(
          student: student,
          solution: solution,
        );

        expect(result.passed, isTrue);
      },
    );
  });
}
