import 'package:flutter/material.dart';

/// CustomPainter rendering a subtle dot-matrix grid background for the canvas
class CanvasGridPainter extends CustomPainter {
  final double gridSize;
  final Color dotColor;

  const CanvasGridPainter({
    this.gridSize = 20.0,
    this.dotColor = AppConstantsTheme.borderSubtle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor.withOpacity(0.35)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasGridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize || oldDelegate.dotColor != dotColor;
  }
}

class AppConstantsTheme {
  static const Color borderSubtle = Color(0xFF30363D);
}
