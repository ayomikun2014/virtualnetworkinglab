import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

/// Lecturer Tab 0: Class Analytics & Pending Submissions Overview
class LecturerOverviewTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const LecturerOverviewTab({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 16 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Faculty Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  child: const Icon(Icons.school, color: AppTheme.primaryBlue, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Lecturer Faculty',
                        style: const TextStyle(color: AppTheme.textBright, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Department: ${user?.departmentId ?? "Networking & Telecommunications"}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                  _buildStatCard('Enrolled Students', '42', Icons.groups, AppTheme.primaryCyan),
                  _buildStatCard('Active Classes', '3', Icons.class_outlined, AppTheme.accentEmerald),
                  _buildStatCard('Lab Completion Rate', '88%', Icons.task_alt, AppTheme.primaryBlue),
                  _buildStatCard('Pending Reviews', '5', Icons.pending_actions, Colors.amber),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // 3. Quick Action Buttons
          const Text(
            'Quick Faculty Actions',
            style: TextStyle(color: AppTheme.textBright, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('Create New Class & Join Code'),
                onPressed: () => onNavigateTab(1), // Go to Classes
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_task, color: AppTheme.primaryCyan, size: 18),
                label: const Text('Author Lab Exercise', style: TextStyle(color: AppTheme.primaryCyan)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryCyan)),
                onPressed: () => onNavigateTab(2), // Go to Authoring
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.grade, color: AppTheme.textBright, size: 18),
                label: const Text('Grading Center (5 Pending)', style: TextStyle(color: AppTheme.textBright)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.borderSubtle)),
                onPressed: () => onNavigateTab(3), // Go to Grading
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 4. Active Classes Stream Grid
          const Text(
            'Active Taught Class Cohorts',
            style: TextStyle(color: AppTheme.textBright, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('${AppConstants.rootPath}/${AppConstants.classesCollection}')
                .where('lecturerUid', isEqualTo: user?.uid ?? 'lecturer')
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
                    child: Text('No active class cohorts created yet. Use "Classes & Roster" to generate a join code.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final section = data['sectionName'] ?? 'Section A';
                  final course = data['courseId'] ?? 'NET201';
                  final code = data['joinCode'] ?? 'NET2026A';
                  final count = data['studentCount'] ?? 18;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
                        child: const Icon(Icons.hub, color: AppTheme.primaryCyan),
                      ),
                      title: Text('$course — $section', style: const TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('Join Code: $code • Enrolled: $count Students', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      trailing: ElevatedButton(
                        onPressed: () => onNavigateTab(1),
                        child: const Text('View Roster'),
                      ),
                    ),
                  );
                },
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
