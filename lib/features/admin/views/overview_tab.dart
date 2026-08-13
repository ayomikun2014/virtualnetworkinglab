import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/departments.dart';
import '../../../core/enums/app_enums.dart';
import '../widgets/analytics_charts.dart';

/// Admin Tab 0: Overview Hub with real System Metrics, Analytics Charts &
/// Activity Feed
///
/// Every figure on this screen is a live Firestore count, not a fixed
/// placeholder — a demo dataset with 3 students used to claim 148 of them.
class OverviewTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const OverviewTab({super.key, required this.onNavigateTab});

  static const List<Color> _departmentColors = [
    AppTheme.primaryCyan,
    AppTheme.primaryBlue,
    AppTheme.accentEmerald,
    Color(0xFF8B5CF6),
    Colors.amber,
  ];

  static const List<Color> _categoryColors = [
    AppTheme.primaryCyan,
    AppTheme.primaryBlue,
    AppTheme.accentEmerald,
    Color(0xFF8B5CF6),
    Colors.amber,
    AppTheme.accentCrimson,
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        screenWidth < 600 ? 16 : 24,
        16, // Top padding reduced to start first card right at the top
        screenWidth < 600 ? 16 : 24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. System Health Status Banner (Starts cleanly at top)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentEmerald.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentEmerald,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppTheme.backgroundMidnight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Virtual Networking Laboratory Active',
                        style: TextStyle(
                          color: AppTheme.textBright,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Central Laboratory Network & Automated Simulation Engine operational.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2 & 3. Everything derived from the users collection: the four
          // stat cards (except System Health, which lives in the banner
          // above) and the department distribution chart. One stream, so
          // an approval or a new registration updates all of it at once.
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.usersCollection)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              var studentCount = 0;
              var approvedLecturerCount = 0;
              var pendingLecturerCount = 0;
              final courseCodesSeen = <String>{};
              final studentsByDept = <String, int>{};

              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final role = data['role'] as String?;

                if (role == 'student') {
                  studentCount++;
                  final dept = data['departmentId'] as String? ?? 'dept_net';
                  studentsByDept[dept] = (studentsByDept[dept] ?? 0) + 1;
                } else if (role == 'lecturer') {
                  if (data['approvalStatus'] == 'pending') {
                    pendingLecturerCount++;
                  } else {
                    approvedLecturerCount++;
                    final courses =
                        (data['assignedCourses'] as List?)
                            ?.cast<Map<String, dynamic>>() ??
                        const [];
                    for (final c in courses) {
                      final code = c['code'] as String?;
                      if (code != null && code.isNotEmpty) {
                        courseCodesSeen.add(code);
                      }
                    }
                  }
                }
              }

              final departmentCounts = studentsByDept.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth > 1000) {
                        crossAxisCount = 4;
                      } else if (constraints.maxWidth > 600) {
                        crossAxisCount = 2;
                      }

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                        children: [
                          _buildStatCard(
                            'Total Students',
                            '$studentCount',
                            Icons.school,
                            AppTheme.primaryCyan,
                          ),
                          _buildStatCard(
                            'Active Lecturers',
                            '$approvedLecturerCount',
                            Icons.badge,
                            AppTheme.accentEmerald,
                          ),
                          _buildStatCard(
                            'Pending Approvals',
                            '$pendingLecturerCount',
                            Icons.pending_actions,
                            Colors.amber,
                            onTap: pendingLecturerCount > 0
                                ? () => onNavigateTab(1)
                                : null,
                          ),
                          _buildStatCard(
                            'Courses Offered',
                            '${courseCodesSeen.length}',
                            Icons.menu_book,
                            AppTheme.primaryBlue,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final barChart = DepartmentBarChartCard(
                        departments: [
                          for (var i = 0; i < departmentCounts.length; i++)
                            DepartmentCount(
                              name: departmentLabel(departmentCounts[i].key),
                              count: departmentCounts[i].value,
                              color:
                                  _departmentColors[i %
                                      _departmentColors.length],
                            ),
                        ],
                      );

                      final pieChart = StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(AppConstants.exercisesCollection)
                            .snapshots(),
                        builder: (context, exerciseSnapshot) {
                          final exerciseDocs =
                              exerciseSnapshot.data?.docs ?? [];
                          final byType = <String, int>{};

                          for (final doc in exerciseDocs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final type =
                                data['exerciseType'] as String? ?? 'unknown';
                            byType[type] = (byType[type] ?? 0) + 1;
                          }

                          final entries = byType.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));

                          return LabCategoryPieChartCard(
                            categories: [
                              for (var i = 0; i < entries.length; i++)
                                CategoryShare(
                                  name: _exerciseTypeLabel(entries[i].key),
                                  count: entries[i].value,
                                  color:
                                      _categoryColors[i %
                                          _categoryColors.length],
                                ),
                            ],
                          );
                        },
                      );

                      if (constraints.maxWidth > 850) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: barChart),
                            const SizedBox(width: 16),
                            Expanded(child: pieChart),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          barChart,
                          const SizedBox(height: 16),
                          pieChart,
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // 4. Quick Actions Bar
          const Text(
            'Quick Administrative Actions',
            style: TextStyle(
              color: AppTheme.textBright,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.how_to_reg, size: 18),
                label: const Text('Review Pending Lecturers'),
                onPressed: () => onNavigateTab(1), // Jump to Lecturers Tab
              ),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.groups,
                  color: AppTheme.primaryCyan,
                  size: 18,
                ),
                label: const Text(
                  'Student Directory',
                  style: TextStyle(color: AppTheme.primaryCyan),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryCyan),
                ),
                onPressed: () => onNavigateTab(2), // Jump to Students Tab
              ),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.receipt_long,
                  color: AppTheme.textBright,
                  size: 18,
                ),
                label: const Text(
                  'View Audit Logs',
                  style: TextStyle(color: AppTheme.textBright),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.borderSubtle),
                ),
                onPressed: () => onNavigateTab(3), // Jump to Audit Logs
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 5. Real-time Audit Stream Activity Feed
          const Text(
            'Recent System Audit Feed',
            style: TextStyle(
              color: AppTheme.textBright,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.currentActivityLogsCollection)
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryCyan,
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceGlass,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Center(
                    child: Text(
                      'No audit events logged yet.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final action = data['action'] ?? 'EVENT';
                  final description =
                      data['description'] ?? 'System activity logged';
                  final performedBy = data['performedBy'] ?? 'Admin';
                  final timestamp = data['timestamp'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceGlass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: AppTheme.primaryCyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryCyan.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      action,
                                      style: const TextStyle(
                                        color: AppTheme.primaryCyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'By $performedBy',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: AppTheme.textBright,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timestamp.length > 10
                              ? timestamp.substring(0, 10)
                              : timestamp,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _exerciseTypeLabel(String raw) {
    final type = ExerciseType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => ExerciseType.unknown,
    );
    return type.displayName;
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onTap != null
              ? color.withValues(alpha: 0.5)
              : AppTheme.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textBright,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Only the Pending Approvals card is tappable, and only once there's
    // something in the queue — jumping to an empty Lecturers tab to prove
    // there's nothing to do is a wasted click.
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }
}
