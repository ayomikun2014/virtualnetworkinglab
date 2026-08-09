import 'package:flutter/material.dart';
import '../../../data/models/topology_model.dart';

/// The colour a cable of [cableType] renders in — shared between
/// [CablePainter] and anywhere a student picks a cable type (e.g. the
/// canvas toolbar's cable-type selector), so the colour they pick is
/// guaranteed to be the colour that actually gets drawn.
Color cableColorForType(String cableType) {
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
      final start = Offset(
        sourceNode.position.x + 40,
        sourceNode.position.y + 40,
      );
      final end = Offset(
        targetNode.position.x + 40,
        targetNode.position.y + 40,
      );

      final isHighlight =
          edge.sourceNodeId == selectedNodeId ||
          edge.targetNodeId == selectedNodeId;
      final cableColor = cableColorForType(edge.cableType);

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
        ..cubicTo(
          control1.dx,
          control1.dy,
          control2.dx,
          control2.dy,
          end.dx,
          end.dy,
        );

      canvas.drawPath(path, paint);

      // Label the link with what it actually is: which two devices, over
      // which medium — "PC1 — Ethernet — PC2" — rather than leaving a bare
      // coloured line a student has to hover a port to identify.
      _drawLinkLabel(
        canvas,
        midpoint: _cubicBezierPointAt(start, control1, control2, end, 0.5),
        text: '${sourceNode.label} — ${edge.cableType} — ${targetNode.label}',
        accentColor: isHighlight ? Colors.white : cableColor,
      );
    }
  }

  /// Point at parameter [t] along a cubic bezier — used to anchor the link
  /// label at the curve's true midpoint (t=0.5), not at the midpoint of the
  /// straight line between endpoints, which drifts off a curved cable.
  Offset _cubicBezierPointAt(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    final x =
        mt * mt * mt * p0.dx +
        3 * mt * mt * t * p1.dx +
        3 * mt * t * t * p2.dx +
        t * t * t * p3.dx;
    final y =
        mt * mt * mt * p0.dy +
        3 * mt * mt * t * p1.dy +
        3 * mt * t * t * p2.dy +
        t * t * t * p3.dy;
    return Offset(x, y);
  }

  void _drawLinkLabel(
    Canvas canvas, {
    required Offset midpoint,
    required String text,
    required Color accentColor,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = Rect.fromCenter(
      center: midpoint,
      width: textPainter.width + 14,
      height: textPainter.height + 6,
    );
    final pill = RRect.fromRectAndRadius(pillRect, const Radius.circular(6));

    canvas.drawRRect(
      pill,
      Paint()..color = const Color(0xFF0B1220).withValues(alpha: 0.92),
    );
    canvas.drawRRect(
      pill,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    textPainter.paint(
      canvas,
      Offset(
        midpoint.dx - textPainter.width / 2,
        midpoint.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CablePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.nodes != nodes ||
        oldDelegate.selectedNodeId != selectedNodeId;
  }
}
