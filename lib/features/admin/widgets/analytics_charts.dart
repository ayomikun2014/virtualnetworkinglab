import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// One bar's worth of real data — a department's share of the student body.
class DepartmentCount {
  final String name;
  final int count;
  final Color color;

  const DepartmentCount({
    required this.name,
    required this.count,
    required this.color,
  });
}

/// Department Enrollment Bar Chart Widget
///
/// Takes real counts rather than owning any data itself — this used to
/// hardcode four departments and a class of 148 regardless of how many
/// students actually existed, which is exactly the "admin shows default
/// data" complaint this was rebuilt to fix.
class DepartmentBarChartCard extends StatelessWidget {
  final List<DepartmentCount> departments;

  const DepartmentBarChartCard({super.key, required this.departments});

  @override
  Widget build(BuildContext context) {
    final total = departments.fold<int>(0, (sum, d) => sum + d.count);

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
                style: TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Distribution of enrolled students across academic departments.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No students registered yet.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            )
          else
            ...departments
                .where((d) => d.count > 0)
                .map((d) {
                  final ratio = d.count / total;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              d.name,
                              style: const TextStyle(
                                color: AppTheme.textBright,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${d.count} student${d.count == 1 ? '' : 's'} '
                              '(${(ratio * 100).toStringAsFixed(0)}%)',
                              style: TextStyle(
                                color: d.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                  color: d.color,
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: d.color.withValues(alpha: 0.4),
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

/// One slice's worth of real data — an exercise type's share of the
/// published catalogue.
class CategoryShare {
  final String name;
  final int count;
  final Color color;

  const CategoryShare({
    required this.name,
    required this.count,
    required this.color,
  });
}

/// Lab Category Donut / Pie Chart Widget with Custom Painter
///
/// Same fix as the bar chart above: real per-category exercise counts
/// instead of a fixed 35/25/25/15 split and a hardcoded "42 Total Labs"
/// that never matched what had actually been published.
class LabCategoryPieChartCard extends StatelessWidget {
  final List<CategoryShare> categories;

  const LabCategoryPieChartCard({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(0, (sum, c) => sum + c.count);
    final slices = categories.where((c) => c.count > 0).toList();

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
                style: TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Published exercises by networking domain.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No exercises published yet.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CustomPaint(
                    painter: PieChartPainter(slices: slices, total: total),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              color: AppTheme.textBright,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total Labs',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: slices.map((c) {
                      final pct = (c.count / total) * 100;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  color: AppTheme.textBright,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: c.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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
  final List<CategoryShare> slices;
  final int total;

  PieChartPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.count / total) * 2 * pi;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle + 0.05, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.total != total;
}
