import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// Department Enrollment Bar Chart Widget
class DepartmentBarChartCard extends StatelessWidget {
  const DepartmentBarChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final deptData = [
      {'name': 'Computer Science', 'count': 64, 'total': 148, 'color': AppTheme.primaryCyan},
      {'name': 'Telecommunications', 'count': 42, 'total': 148, 'color': AppTheme.primaryBlue},
      {'name': 'Software Engineering', 'count': 28, 'total': 148, 'color': AppTheme.accentEmerald},
      {'name': 'Cyber Security', 'count': 14, 'total': 148, 'color': const Color(0xFF8B5CF6)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, color: AppTheme.primaryCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'Student Enrollment by Department',
                style: TextStyle(color: AppTheme.textBright, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Distribution of enrolled students across academic faculties.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

          ...deptData.map((d) {
            final name = d['name'] as String;
            final count = d['count'] as int;
            final total = d['total'] as int;
            final color = d['color'] as Color;
            final ratio = count / total;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(color: AppTheme.textBright, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('$count students (${(ratio * 100).toStringAsFixed(0)}%)', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundMidnight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Lab Category Donut / Pie Chart Widget with Custom Painter
class LabCategoryPieChartCard extends StatelessWidget {
  const LabCategoryPieChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Routing Protocols', 'percentage': 35.0, 'color': AppTheme.primaryCyan},
      {'name': 'Switching & VLANs', 'percentage': 25.0, 'color': AppTheme.primaryBlue},
      {'name': 'Subnetting & VLSM', 'percentage': 25.0, 'color': AppTheme.accentEmerald},
      {'name': 'Network Security', 'percentage': 15.0, 'color': const Color(0xFF8B5CF6)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart, color: AppTheme.accentEmerald, size: 20),
              SizedBox(width: 8),
              Text(
                'Lab Curriculum Category Breakdown',
                style: TextStyle(color: AppTheme.textBright, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Proportion of practical exercises by networking domain.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Custom Donut / Pie Painter
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: PieChartPainter(categories: categories),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '42',
                          style: TextStyle(color: AppTheme.textBright, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total Labs',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categories.map((c) {
                    final name = c['name'] as String;
                    final pct = c['percentage'] as double;
                    final color = c['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(color: AppTheme.textBright, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${pct.toInt()}%',
                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom Donut / Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;

  PieChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double startAngle = -pi / 2;

    for (final cat in categories) {
      final percentage = cat['percentage'] as double;
      final color = cat['color'] as Color;
      final sweepAngle = (percentage / 100) * 2 * pi;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle + 0.05, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
