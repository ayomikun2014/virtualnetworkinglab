import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/analytics_charts.dart';

/// Admin Tab 0: Overview Hub with System Metrics, Analytics Charts & Activity Feed
class OverviewTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const OverviewTab({
    super.key,
    required this.onNavigateTab,
  });

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
              border: Border.all(color: AppTheme.accentEmerald.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentEmerald,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: AppTheme.backgroundMidnight, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Virtual Network Lab Active',
                        style: TextStyle(
                          color: AppTheme.textBright,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Central Laboratory Network & Automated Simulation Engine operational.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. 4 Mini Stat Cards Grid
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
                  _buildStatCard('Total Students', '148', Icons.school, AppTheme.primaryCyan),
                  _buildStatCard('Active Lecturers', '12', Icons.badge, AppTheme.accentEmerald),
                  _buildStatCard('Active Courses', '8', Icons.menu_book, AppTheme.primaryBlue),
                  _buildStatCard('System Health', '100%', Icons.shield, Colors.amber),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. Visual Analytics Charts Section (Bar Chart & Donut/Pie Chart)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 850) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(child: DepartmentBarChartCard()),
                    SizedBox(width: 16),
                    Expanded(child: LabCategoryPieChartCard()),
                  ],
                );
              } else {
                return Column(
                  children: const [
                    DepartmentBarChartCard(),
                    SizedBox(height: 16),
                    LabCategoryPieChartCard(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 28),

          // 4. Quick Actions Bar
          const Text(
            'Quick Administrative Actions',
            style: TextStyle(color: AppTheme.textBright, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Provision Lecturer Account'),
                onPressed: () => onNavigateTab(1), // Jump to Lecturers Tab
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_card, color: AppTheme.primaryCyan, size: 18),
                label: const Text('Add Course / Curriculum', style: TextStyle(color: AppTheme.primaryCyan)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryCyan)),
                onPressed: () => onNavigateTab(2), // Jump to Courses Tab
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long, color: AppTheme.textBright, size: 18),
                label: const Text('View Audit Logs', style: TextStyle(color: AppTheme.textBright)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.borderSubtle)),
                onPressed: () => onNavigateTab(4), // Jump to Audit Logs
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 5. Real-time Audit Stream Activity Feed
          const Text(
            'Recent System Audit Feed',
            style: TextStyle(color: AppTheme.textBright, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('${AppConstants.rootPath}/${AppConstants.activityLogsCollection}')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppTheme.primaryCyan),
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
                    child: Text('No audit events logged yet.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final action = data['action'] ?? 'EVENT';
                  final description = data['description'] ?? 'System activity logged';
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
                          child: const Icon(Icons.bolt, color: AppTheme.primaryCyan, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryCyan.withValues(alpha: 0.15),
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
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(color: AppTheme.textBright, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timestamp.length > 10 ? timestamp.substring(0, 10) : timestamp,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
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
                Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: AppTheme.textBright, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
