import '../../../core/enums/app_enums.dart';
import '../../../data/models/topology_model.dart';

/// Result of checking one requirement from the solution topology against the
/// student's canvas — e.g. "is PC1 connected to Switch1 with an Ethernet
/// cable".
class GradeCheck {
  final bool passed;
  final String message;

  const GradeCheck({required this.passed, required this.message});
}

/// Outcome of grading a student's canvas against a level's solution
/// topology.
class GradeResult {
  final bool passed;
  final List<GradeCheck> checks;

  const GradeResult({required this.passed, required this.checks});

  /// Only the checks that failed — what the "Try Again" dialog shows.
  List<GradeCheck> get failures => checks.where((c) => !c.passed).toList();
}

/// Grades a student's topology against a lecturer-authored solution
/// topology by comparing device presence and cabling only — not exact IP,
/// subnet, VLAN or ACL configuration.
///
/// This is intentionally simpler than a full packet/route simulator: for a
/// teaching canvas, "did the student place the right devices and connect
/// them with the right cable" is the thing being taught for these levels,
/// and it can be checked directly from the graph the student built, with no
/// separate simulation engine.
///
/// Device identity is matched by (type, creation order) rather than by the
/// node's `label`. The property inspector lets a student rename a device
/// freely, so matching on the editable label would silently break grading
/// the moment a student renamed "PC1" to something else — matching by type
/// and the order devices were added mirrors how labels are auto-assigned in
/// the first place (`_defaultLabelFor` in canvas_builder_screen.dart) without
/// depending on the mutable text.
class TopologyGrader {
  TopologyGrader._();

  static GradeResult gradeCabling({
    required TopologyModel student,
    required TopologyModel solution,
  }) {
    // An answer key with no devices in it produces no checks at all, and
    // `[].every(...)` is true in Dart — so without this guard a level whose
    // solution topology was never populated would silently pass every
    // canvas submitted to it, including an empty one.
    if (solution.nodes.isEmpty) {
      return const GradeResult(
        passed: false,
        checks: [
          GradeCheck(
            passed: false,
            message:
                "This level's answer key has no devices in it yet — tell "
                'your lecturer.',
          ),
        ],
      );
    }

    final nodeMatch = _matchNodesByTypeAndOrder(
      solutionNodes: solution.nodes,
      studentNodes: student.nodes,
    );

    final checks = <GradeCheck>[
      ..._devicePresenceChecks(solution.nodes, nodeMatch),
      ..._extraDeviceChecks(
        solutionNodes: solution.nodes,
        studentNodes: student.nodes,
      ),
      ..._cablingChecks(
        solution: solution,
        studentEdges: student.edges,
        nodeMatch: nodeMatch,
      ),
      ..._extraCableChecks(
        solution: solution,
        studentEdges: student.edges,
        nodeMatch: nodeMatch,
      ),
    ];

    return GradeResult(passed: checks.every((c) => c.passed), checks: checks);
  }

  /// Maps each solution nodeId to the student's corresponding DeviceNode (or
  /// null if the student hasn't placed enough devices of that type yet).
  static Map<String, DeviceNode?> _matchNodesByTypeAndOrder({
    required List<DeviceNode> solutionNodes,
    required List<DeviceNode> studentNodes,
  }) {
    final studentByType = <DeviceType, List<DeviceNode>>{};
    for (final node in studentNodes) {
      studentByType.putIfAbsent(node.type, () => []).add(node);
    }

    final typeCursor = <DeviceType, int>{};
    final match = <String, DeviceNode?>{};

    for (final solutionNode in solutionNodes) {
      final pool = studentByType[solutionNode.type] ?? const [];
      final index = typeCursor[solutionNode.type] ?? 0;
      typeCursor[solutionNode.type] = index + 1;

      match[solutionNode.nodeId] = index < pool.length ? pool[index] : null;
    }

    return match;
  }

  static List<GradeCheck> _devicePresenceChecks(
    List<DeviceNode> solutionNodes,
    Map<String, DeviceNode?> nodeMatch,
  ) {
    return solutionNodes.map((solutionNode) {
      final matched = nodeMatch[solutionNode.nodeId];
      return GradeCheck(
        passed: matched != null,
        message: matched != null
            ? '${solutionNode.label} is on the canvas.'
            : 'Add a ${_typeName(solutionNode.type)} '
                  '(like ${solutionNode.label}) to the canvas.',
      );
    }).toList();
  }

  /// Flags devices the design doesn't call for.
  ///
  /// These levels teach a specific topology, so "the right shape plus three
  /// spare switches" is not the right shape. Grading used to ignore extras
  /// entirely, which meant a student could bolt anything onto a correct
  /// build — or leave a half-finished wrong attempt on the canvas beside a
  /// correct one — and still be told they had passed.
  static List<GradeCheck> _extraDeviceChecks({
    required List<DeviceNode> solutionNodes,
    required List<DeviceNode> studentNodes,
  }) {
    final solutionCounts = <DeviceType, int>{};
    for (final node in solutionNodes) {
      solutionCounts[node.type] = (solutionCounts[node.type] ?? 0) + 1;
    }

    final studentCounts = <DeviceType, int>{};
    for (final node in studentNodes) {
      studentCounts[node.type] = (studentCounts[node.type] ?? 0) + 1;
    }

    final checks = <GradeCheck>[];
    studentCounts.forEach((type, studentCount) {
      final wanted = solutionCounts[type] ?? 0;
      if (studentCount <= wanted) return;

      final name = _typeName(type);
      checks.add(
        GradeCheck(
          passed: false,
          message: wanted == 0
              ? 'Remove the $name — this level does not use one.'
              : 'This level uses $wanted $name'
                    '${wanted == 1 ? '' : 's'}, but you have placed '
                    '$studentCount. Remove the extra '
                    '${studentCount - wanted == 1 ? 'one' : 'ones'}.',
        ),
      );
    });

    return checks;
  }

  /// Flags cables the design doesn't call for.
  ///
  /// Only cables between two graded devices are considered: a cable running
  /// to a device that is itself already reported as an extra would just
  /// repeat that complaint in different words.
  static List<GradeCheck> _extraCableChecks({
    required TopologyModel solution,
    required List<CableEdge> studentEdges,
    required Map<String, DeviceNode?> nodeMatch,
  }) {
    // Student node id -> the solution node it stands in for.
    final solutionNodeById = {for (final n in solution.nodes) n.nodeId: n};
    final solutionIdByStudentId = <String, String>{};
    nodeMatch.forEach((solutionNodeId, studentNode) {
      if (studentNode != null) {
        solutionIdByStudentId[studentNode.nodeId] = solutionNodeId;
      }
    });

    // Unordered key per solution pair, so A↔B and B↔A collapse together.
    String pairKey(String a, String b) {
      final sorted = [a, b]..sort();
      return '${sorted[0]}|${sorted[1]}';
    }

    final wantedPairs = solution.edges
        .map((e) => pairKey(e.sourceNodeId, e.targetNodeId))
        .toSet();

    final reported = <String>{};
    final checks = <GradeCheck>[];

    for (final edge in studentEdges) {
      final sourceSolutionId = solutionIdByStudentId[edge.sourceNodeId];
      final targetSolutionId = solutionIdByStudentId[edge.targetNodeId];
      if (sourceSolutionId == null || targetSolutionId == null) continue;

      final key = pairKey(sourceSolutionId, targetSolutionId);
      if (wantedPairs.contains(key)) continue;
      // Two cables between the same wrong pair is one mistake, not two.
      if (!reported.add(key)) continue;

      final sourceLabel = solutionNodeById[sourceSolutionId]?.label ?? 'device';
      final targetLabel = solutionNodeById[targetSolutionId]?.label ?? 'device';

      checks.add(
        GradeCheck(
          passed: false,
          message:
              'Remove the cable between $sourceLabel and $targetLabel — it '
              'is not part of this design.',
        ),
      );
    }

    return checks;
  }

  static List<GradeCheck> _cablingChecks({
    required TopologyModel solution,
    required List<CableEdge> studentEdges,
    required Map<String, DeviceNode?> nodeMatch,
  }) {
    final solutionNodeById = {for (final n in solution.nodes) n.nodeId: n};

    return solution.edges.map((solutionEdge) {
      final sourceSolutionNode = solutionNodeById[solutionEdge.sourceNodeId];
      final targetSolutionNode = solutionNodeById[solutionEdge.targetNodeId];

      if (sourceSolutionNode == null || targetSolutionNode == null) {
        // Malformed solution data — shouldn't happen, but don't crash grading.
        return const GradeCheck(
          passed: false,
          message:
              "This level's solution data is incomplete — tell your lecturer.",
        );
      }

      final label = '${sourceSolutionNode.label} ↔ ${targetSolutionNode.label}';

      final studentSource = nodeMatch[sourceSolutionNode.nodeId];
      final studentTarget = nodeMatch[targetSolutionNode.nodeId];

      if (studentSource == null || studentTarget == null) {
        return GradeCheck(
          passed: false,
          message: 'Connect $label once both devices are on the canvas.',
        );
      }

      final existingEdge = _findEdgeBetween(
        studentEdges,
        studentSource.nodeId,
        studentTarget.nodeId,
      );

      if (existingEdge == null) {
        return GradeCheck(
          passed: false,
          message: 'Connect $label with a ${solutionEdge.cableType} cable.',
        );
      }

      final cableMatches =
          existingEdge.cableType.toLowerCase() ==
          solutionEdge.cableType.toLowerCase();

      return GradeCheck(
        passed: cableMatches,
        message: cableMatches
            ? '$label is connected correctly.'
            : '$label should use a ${solutionEdge.cableType} cable, '
                  'not ${existingEdge.cableType}.',
      );
    }).toList();
  }

  static CableEdge? _findEdgeBetween(
    List<CableEdge> edges,
    String nodeIdA,
    String nodeIdB,
  ) {
    for (final edge in edges) {
      final matchesForward =
          edge.sourceNodeId == nodeIdA && edge.targetNodeId == nodeIdB;
      final matchesReverse =
          edge.sourceNodeId == nodeIdB && edge.targetNodeId == nodeIdA;
      if (matchesForward || matchesReverse) return edge;
    }
    return null;
  }

  static String _typeName(DeviceType type) {
    switch (type) {
      case DeviceType.router:
        return 'Router';
      case DeviceType.switchDevice:
        return 'Switch';
      case DeviceType.firewall:
        return 'Firewall';
      case DeviceType.pc:
        return 'PC';
      case DeviceType.server:
        return 'Server';
      case DeviceType.cloud:
        return 'Cloud/WAN';
    }
  }
}
