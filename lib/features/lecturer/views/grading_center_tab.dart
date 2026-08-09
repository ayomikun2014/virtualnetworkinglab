import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/lecturer_drilldown_widgets.dart';

/// Lecturer Tab 2: Grading Center — real, per-student results.
///
/// Course assessments are graded automatically the moment a student
/// submits (percentage of correct devices/cables, see `TopologyGrader` and
/// `GradingProvider.checkTopology`), so there is nothing left for a
/// lecturer to manually score here. This is a read-only, three-level
/// drill-down: courses this lecturer teaches → assessments published under
/// the selected course → students who submitted the selected assessment.
///
/// Two streams cover all three levels — `exercises` and `exercise_results`,
/// both scoped to `authorUid == this lecturer` — with course/exercise
/// selection filtering client-side rather than re-querying Firestore on
/// every tap. Free Practice attempts never appear here: they're a separate
/// system with no lecturer attached.
class GradingCenterTab extends StatefulWidget {
  const GradingCenterTab({super.key});

  @override
  State<GradingCenterTab> createState() => _GradingCenterTabState();
}

class _GradingCenterTabState extends State<GradingCenterTab> {
  /// Drill-down position. Both null: the course grid. Course set, exercise
  /// null: that course's assessment list. Both set: the selected
  /// assessment's student results.
  String? _selectedCourseCode;
  String? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final lecturerUid = user?.uid;
    final assignedCourses = user?.assignedCourses ?? const [];

    if (lecturerUid == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryCyan),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.exercisesCollection)
          .where('authorUid', isEqualTo: lecturerUid)
          .snapshots(),
      builder: (context, exerciseSnapshot) {
        if (exerciseSnapshot.hasError) {
          debugPrint(
            'GradingCenterTab: exercises query failed: '
            '${exerciseSnapshot.error}',
          );
        }
        final exerciseDocs = exerciseSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.exerciseResultsCollection)
              .where('authorUid', isEqualTo: lecturerUid)
              .snapshots(),
          builder: (context, resultSnapshot) {
            if (resultSnapshot.hasError) {
              // Also to the console: a missing composite index error embeds
              // a direct "create this index" link, and the console
              // auto-links URLs where a wrapped Text widget can't.
              debugPrint(
                'GradingCenterTab: results query failed: '
                '${resultSnapshot.error}',
              );
            }
            final resultDocs = resultSnapshot.data?.docs ?? [];
            final isLoading =
                exerciseSnapshot.connectionState == ConnectionState.waiting ||
                resultSnapshot.connectionState == ConnectionState.waiting;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildHeader(assignedCourses.length),
                const SizedBox(height: 20),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                  )
                else if (_selectedCourseCode == null)
                  _buildCourseGrid(assignedCourses, exerciseDocs, resultDocs)
                else if (_selectedExerciseId == null)
                  _buildAssessmentList(exerciseDocs, resultDocs)
                else
                  _buildSubmissionsList(exerciseDocs, resultDocs),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(int courseCount) {
    if (_selectedCourseCode == null) {
      return const SectionHeader(
        title: 'Student Results',
        subtitle:
            'Every course assessment submission, graded automatically the '
            'moment a student submits — nothing here needs manual scoring.',
      );
    }

    final backTarget = _selectedExerciseId == null
        // Back from the assessment list goes to the course grid.
        ? () => setState(() => _selectedCourseCode = null)
        // Back from the submission list goes to the assessment list, not
        // all the way to the grid — one tap back per level, not a jump.
        : () => setState(() => _selectedExerciseId = null);

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textBright),
          onPressed: backTarget,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SectionHeader(
            title: _selectedExerciseId == null
                ? _selectedCourseCode!
                : 'Submissions',
            subtitle: _selectedExerciseId == null
                ? 'Assessments you have published for this course.'
                : 'Everyone who has submitted this assessment.',
          ),
        ),
      ],
    );
  }

  // ── Level 1: course grid ──────────────────────────────────────────────

  Widget _buildCourseGrid(
    List<Map<String, String>> assignedCourses,
    List<QueryDocumentSnapshot> exerciseDocs,
    List<QueryDocumentSnapshot> resultDocs,
  ) {
    if (assignedCourses.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No courses assigned yet',
        message:
            'An admin needs to approve your application and assign at '
            'least one course before there is anything to grade.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: assignedCourses.map((course) {
            final code = course['code'] ?? '';
            final title = course['title'] ?? '';

            final courseExerciseIds = exerciseDocs
                .where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['categoryId'] == code;
                })
                .map((doc) => doc.id)
                .toSet();

            final submissionCount = resultDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return courseExerciseIds.contains(data['exerciseId']);
            }).length;

            return CourseCard(
              code: code,
              title: title,
              exerciseCount: courseExerciseIds.length,
              submissionCount: submissionCount,
              onTap: () => setState(() => _selectedCourseCode = code),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Level 2: assessment list for the selected course ────────────────

  Widget _buildAssessmentList(
    List<QueryDocumentSnapshot> exerciseDocs,
    List<QueryDocumentSnapshot> resultDocs,
  ) {
    final courseExercises = exerciseDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['categoryId'] == _selectedCourseCode;
    }).toList()..sort((a, b) {
      final an = (a.data() as Map<String, dynamic>)['assessmentNumber'] as num?;
      final bn = (b.data() as Map<String, dynamic>)['assessmentNumber'] as num?;
      return (an ?? 0).compareTo(bn ?? 0);
    });

    if (courseExercises.isEmpty) {
      return const EmptyState(
        icon: Icons.edit_document,
        title: 'No assessments published yet',
        message: 'Publish one from Exercise Authoring for this course.',
      );
    }

    return Column(
      children: courseExercises.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = data['title'] as String? ?? 'Untitled';
        final assessmentNumber = (data['assessmentNumber'] as num?)?.toInt();
        final submissions = resultDocs.where((r) {
          final rData = r.data() as Map<String, dynamic>;
          return rData['exerciseId'] == doc.id;
        }).toList();
        final passedCount = submissions.where((r) {
          final rData = r.data() as Map<String, dynamic>;
          return rData['passed'] == true;
        }).length;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppTheme.primaryCyan,
              ),
            ),
            title: Text(
              assessmentNumber == null
                  ? title
                  : 'Assessment $assessmentNumber — $title',
              style: const TextStyle(
                color: AppTheme.textBright,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              submissions.isEmpty
                  ? 'No submissions yet'
                  : '${submissions.length} submission'
                        '${submissions.length == 1 ? '' : 's'} • '
                        '$passedCount passed',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textMuted,
              size: 14,
            ),
            onTap: () => setState(() => _selectedExerciseId = doc.id),
          ),
        );
      }).toList(),
    );
  }

  // ── Level 3: student submissions for the selected assessment ────────

  Widget _buildSubmissionsList(
    List<QueryDocumentSnapshot> exerciseDocs,
    List<QueryDocumentSnapshot> resultDocs,
  ) {
    final submissions = resultDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['exerciseId'] == _selectedExerciseId;
    }).toList()..sort((a, b) {
      final aTime = (a.data() as Map<String, dynamic>)['attemptedAt'] as String?;
      final bTime = (b.data() as Map<String, dynamic>)['attemptedAt'] as String?;
      return (bTime ?? '').compareTo(aTime ?? '');
    });

    if (submissions.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'No submissions yet',
        message:
            'Results appear here the moment a student submits this '
            'assessment.',
      );
    }

    return Column(
      children: submissions
          .map((doc) => _buildResultCard(doc.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    final studentName = data['studentName'] as String? ?? 'Student';
    final studentEmail = data['studentEmail'] as String? ?? '';
    final passed = data['passed'] as bool? ?? false;
    final correct = (data['correctChecks'] as num?)?.toInt() ?? 0;
    final total = (data['totalChecks'] as num?)?.toInt() ?? 0;
    final scorePercent = total == 0 ? 0.0 : (correct / total) * 100;
    final attemptedAt = DateTime.tryParse(
      data['attemptedAt'] as String? ?? '',
    );

    final statusColor = passed ? AppTheme.accentEmerald : AppTheme.accentCrimson;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(
                passed ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textBright,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    studentEmail,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (attemptedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(attemptedAt),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${scorePercent.round()}%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '$correct/$total correct',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0 && now.day == dt.day) return 'Today';
    if (diff.inDays <= 1 && now.day - dt.day == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
