import 'package:flutter/material.dart';
import '../../../data/models/topology_model.dart';

/// CustomPainter rendering Cubic Bezier curves for physical network cable links
class CablePainter extends CustomPainter {
  final List<CableEdge> edges;
  final List<DeviceNode> nodes;
  final String? selectedNodeId;

  const CablePainter({
    required this.edges,
    required this.nodes,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty || nodes.isEmpty) return;

    final nodeMap = {for (var n in nodes) n.nodeId: n};

    for (final edge in edges) {
      final sourceNode = nodeMap[edge.sourceNodeId];
      final targetNode = nodeMap[edge.targetNodeId];

      if (sourceNode == null || targetNode == null) continue;

      // Node card center offset adjustment (assume 80x80 node dimensions)
      final start = Offset(sourceNode.position.x + 40, sourceNode.position.y + 40);
      final end = Offset(targetNode.position.x + 40, targetNode.position.y + 40);

      final isHighlight = edge.sourceNodeId == selectedNodeId || edge.targetNodeId == selectedNodeId;
      final cableColor = _getCableColor(edge.cableType);

      final paint = Paint()
        ..color = isHighlight ? Colors.white : cableColor
        ..strokeWidth = isHighlight ? 3.5 : 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Calculate smooth Cubic Bezier control points
      final dx = (end.dx - start.dx).abs() * 0.5;

      final control1 = Offset(start.dx + dx, start.dy);
      final control2 = Offset(end.dx - dx, end.dy);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, end.dx, end.dy);

      canvas.drawPath(path, paint);
    }
  }

  Color _getCableColor(String cableType) {
    switch (cableType.toLowerCase()) {
      case 'ethernet':
      case 'copper':
        return const Color(0xFF00F2FE); // Cyan Neon
      case 'fiber':
      case 'optical':
        return const Color(0xFFF59E0B); // Amber Gold
      case 'serial':
      case 'wan':
        return const Color(0xFFEF4444); // Crimson Red
      default:
        return const Color(0xFF8B949E); // Slate Grey
    }
  }

  @override
  bool shouldRepaint(covariant CablePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.nodes != nodes ||
        oldDelegate.selectedNodeId != selectedNodeId;
  }
}
