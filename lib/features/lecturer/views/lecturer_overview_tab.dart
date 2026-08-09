import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

/// Lecturer Tab 0: real-time teaching summary.
///
/// Every figure here is a live Firestore count scoped to the signed-in
/// lecturer — no "42 Enrolled Students" placeholder that stayed 42
/// regardless of who was actually enrolled. "My Courses" lists the courses
/// an admin assigned this lecturer (`UserModel.assignedCourses`), each
/// showing the code students actually enter with `InviteCodeService` and
/// how many exercises have been published under it.
class LecturerOverviewTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const LecturerOverviewTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final uid = user?.uid;
    final assignedCourses = user?.assignedCourses ?? const [];
    final courseCodes = assignedCourses
        .map((c) => c['code'])
        .whereType<String>()
        .toList();
    final screenWidth = MediaQuery.of(context).size.width;

    if (uid == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryCyan),
      );
    }

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
                  child: const Icon(
                    Icons.school,
                    color: AppTheme.primaryBlue,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Lecturer Faculty',
                        style: const TextStyle(
                          color: AppTheme.textBright,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Department: ${user?.departmentId ?? "Networking & Telecommunications"}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Stat Cards — exercises this lecturer authored drives both
          // the "Exercises Published" count and the per-course breakdown
          // below, so it's one stream instead of one per stat.
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.exercisesCollection)
                .where('authorUid', isEqualTo: uid)
                .snapshots(),
            builder: (context, exerciseSnapshot) {
              if (exerciseSnapshot.hasError) {
                debugPrint(
                  'LecturerOverviewTab: exercises query failed: '
                  '${exerciseSnapshot.error}',
                );
              }
              final exerciseDocs = exerciseSnapshot.data?.docs ?? [];

              return StreamBuilder<QuerySnapshot>(
                // Firestore caps whereIn/arrayContainsAny at 10 values —
                // the same limit FirebaseExerciseRepository.
                // getCourseAssessments already lives with for
                // enrolledCourseIds, so a lecturer with more than 10
                // assigned courses undercounts here rather than errors.
                stream: courseCodes.isEmpty
                    ? const Stream<QuerySnapshot>.empty()
                    : FirebaseFirestore.instance
                          .collection(AppConstants.usersCollection)
                          .where('role', isEqualTo: 'student')
                          .where(
                            'enrolledCourseIds',
                            arrayContainsAny: courseCodes.take(10).toList(),
                          )
                          .snapshots(),
                builder: (context, studentSnapshot) {
                  if (studentSnapshot.hasError) {
                    debugPrint(
                      'LecturerOverviewTab: enrolled-students query failed: '
                      '${studentSnapshot.error}',
                    );
                  }
                  final enrolledCount = studentSnapshot.data?.docs.length ?? 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(AppConstants.exerciseResultsCollection)
                        .where('authorUid', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, resultsSnapshot) {
                      if (resultsSnapshot.hasError) {
                        debugPrint(
                          'LecturerOverviewTab: results query failed: '
                          '${resultsSnapshot.error}',
                        );
                      }
                      final results = resultsSnapshot.data?.docs ?? [];
                      final passedCount = results.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['passed'] == true;
                      }).length;

                      return LayoutBuilder(
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
                                'My Courses',
                                '${assignedCourses.length}',
                                Icons.menu_book,
                                AppTheme.primaryBlue,
                              ),
                              _buildStatCard(
                                'Exercises Published',
                                '${exerciseDocs.length}',
                                Icons.edit_document,
                                AppTheme.primaryCyan,
                              ),
                              _buildStatCard(
                                'Enrolled Students',
                                '$enrolledCount',
                                Icons.groups,
                                AppTheme.accentEmerald,
                              ),
                              _buildStatCard(
                                'Submissions Passed',
                                '$passedCount / ${results.length}',
                                Icons.fact_check,
                                Colors.amber,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 28),

          // 3. Quick Action Buttons
          const Text(
            'Quick Faculty Actions',
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
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('Author Lab Exercise'),
                onPressed: () => onNavigateTab(1), // Go to Authoring
              ),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.grade,
                  color: AppTheme.primaryCyan,
                  size: 18,
                ),
                label: const Text(
                  'View Student Results',
                  style: TextStyle(color: AppTheme.primaryCyan),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryCyan),
                ),
                onPressed: () => onNavigateTab(2), // Go to Grading
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 4. My Courses — what an admin assigned, and the exercise count
          // per course, computed from the same exercises stream above.
          const Text(
            'My Courses',
            style: TextStyle(
              color: AppTheme.textBright,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (assignedCourses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGlass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Center(
                child: Text(
                  'No courses assigned yet. An admin needs to approve your '
                  'application and assign at least one course.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.exercisesCollection)
                  .where('authorUid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    'LecturerOverviewTab: my-courses query failed: '
                    '${snapshot.error}',
                  );
                }
                final exercisesByCourse = <String, int>{};
                for (final doc in snapshot.data?.docs ?? []) {
                  final data = doc.data() as Map<String, dynamic>;
                  final categoryId = data['categoryId'] as String? ?? '';
                  exercisesByCourse[categoryId] =
                      (exercisesByCourse[categoryId] ?? 0) + 1;
                }

                return Column(
                  children: assignedCourses.map((course) {
                    final code = course['code'] ?? '';
                    final title = course['title'] ?? '';
                    final count = exercisesByCourse[code] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryCyan.withValues(
                            alpha: 0.15,
                          ),
                          child: const Icon(
                            Icons.hub,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                        title: Text(
                          '$code — $title',
                          style: const TextStyle(
                            color: AppTheme.textBright,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '$count exercise${count == 1 ? '' : 's'} published '
                          '• students join with code "$code"',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => onNavigateTab(1),
                          child: const Text('Add Exercise'),
                        ),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
  }
}
