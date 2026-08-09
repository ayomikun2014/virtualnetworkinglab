import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

/// Lecturer Tab 2: Grading Center — real, per-student results.
///
/// Course assessments are graded automatically the moment a student
/// submits (percentage of correct devices/cables, see `TopologyGrader` and
/// `GradingProvider.checkTopology`), so there is nothing left for a
/// lecturer to manually score here. This is a read-only view of what every
/// student actually scored on every course exercise this lecturer
/// authored — sourced from `exercise_results`, the denormalised record
/// `FirebaseGradingRepository.recordAttempt` writes for exactly that
/// purpose. Free Practice attempts never appear here: they're a separate
/// system with no lecturer attached.
class GradingCenterTab extends StatefulWidget {
  const GradingCenterTab({super.key});

  @override
  State<GradingCenterTab> createState() => _GradingCenterTabState();
}

class _GradingCenterTabState extends State<GradingCenterTab> {
  /// Filters the list to one course code, or null for every course this
  /// lecturer teaches.
  String? _courseFilter;

  @override
  Widget build(BuildContext context) {
    final lecturerUid = Provider.of<AuthProvider>(
      context,
    ).currentUser?.uid;

    if (lecturerUid == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryCyan),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Student Results',
          style: TextStyle(
            color: AppTheme.textBright,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Every course assessment submission, graded automatically the '
          'moment a student submits — nothing here needs manual scoring.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 20),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.exerciseResultsCollection)
              .where('authorUid', isEqualTo: lecturerUid)
              .orderBy('attemptedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.primaryCyan),
                ),
              );
            }

            if (snapshot.hasError) {
              // Also to the console: a missing composite index error embeds
              // a direct "create this index" link, and the console
              // auto-links URLs where the wrapped Text widget below can't —
              // same reasoning as ExerciseProvider.fetchCourseAssessments.
              debugPrint('GradingCenterTab: failed to load results: '
                  '${snapshot.error}');
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentCrimson.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.accentCrimson,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Could not load results: ${snapshot.error}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final allDocs = snapshot.data?.docs ?? [];
            if (allDocs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 48,
                        color: AppTheme.textMuted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No submissions yet',
                        style: TextStyle(
                          color: AppTheme.textBright,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Results appear here the moment a student submits '
                        'one of your course assessments.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final courseCodes = allDocs
                .map((d) => (d.data() as Map<String, dynamic>)['exerciseId'])
                .toSet();
            // Course code isn't stored directly on the result — it comes
            // along with exerciseTitle from the exercise itself, which
            // doesn't carry categoryId either. Filtering by exercise title
            // prefix would be fragile, so the filter chips key on
            // exerciseId instead: precise, even if the label is the title
            // rather than a course code.
            final exerciseTitles = <String, String>{
              for (final doc in allDocs)
                (doc.data() as Map<String, dynamic>)['exerciseId']
                        as String? ??
                    '':
                    (doc.data() as Map<String, dynamic>)['exerciseTitle']
                            as String? ??
                        'Untitled',
            };

            final docs = _courseFilter == null
                ? allDocs
                : allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['exerciseId'] == _courseFilter;
                  }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (courseCodes.length > 1) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _courseFilter == null,
                        onSelected: (_) =>
                            setState(() => _courseFilter = null),
                      ),
                      for (final exerciseId in exerciseTitles.keys)
                        ChoiceChip(
                          label: Text(exerciseTitles[exerciseId]!),
                          selected: _courseFilter == exerciseId,
                          onSelected: (_) =>
                              setState(() => _courseFilter = exerciseId),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildResultCard(data);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    final studentName = data['studentName'] as String? ?? 'Student';
    final studentEmail = data['studentEmail'] as String? ?? '';
    final exerciseTitle = data['exerciseTitle'] as String? ?? 'Assessment';
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
                    style: const TextStyle(
                      color: AppTheme.textBright,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '$studentEmail • $exerciseTitle',
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
