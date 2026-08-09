import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_notification.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/lecturer_management_service.dart';
import '../widgets/lecturer_drilldown_widgets.dart';

/// Lecturer Tab 3: Manage Exercises — lock, edit or delete a published
/// assessment.
///
/// Same two-level drill-down as Grading Center (courses this lecturer
/// teaches → assessments under the selected course), but the assessment
/// level here is a management list instead of a read-only one: every row
/// carries Lock/Unlock, Edit and Delete actions. All three write straight
/// to the `exercises` document, and because the student-facing queries
/// (`FirebaseExerciseRepository.getCourseAssessments`) read the exact same
/// document, a lecturer's action here reaches the student panel the next
/// time that student's exercise list is fetched — no separate sync step.
class ManageExercisesTab extends StatefulWidget {
  const ManageExercisesTab({super.key});

  @override
  State<ManageExercisesTab> createState() => _ManageExercisesTabState();
}

class _ManageExercisesTabState extends State<ManageExercisesTab> {
  String? _selectedCourseCode;
  final _service = LecturerManagementService();

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
            'ManageExercisesTab: exercises query failed: '
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
              debugPrint(
                'ManageExercisesTab: results query failed: '
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
                _buildHeader(),
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
                else
                  _buildAssessmentList(exerciseDocs, resultDocs),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    if (_selectedCourseCode == null) {
      return const SectionHeader(
        title: 'Manage Exercises',
        subtitle:
            'Lock an assessment to stop new submissions, edit its details, '
            'or delete it — changes apply to students immediately.',
      );
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textBright),
          onPressed: () => setState(() => _selectedCourseCode = null),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SectionHeader(
            title: _selectedCourseCode!,
            subtitle: 'Assessments published for this course.',
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
            'least one course before there is anything to manage.',
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

  // ── Level 2: manage assessments for the selected course ─────────────

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
        final submissionCount = resultDocs.where((r) {
          final rData = r.data() as Map<String, dynamic>;
          return rData['exerciseId'] == doc.id;
        }).length;
        return _AssessmentManagementCard(
          exerciseId: doc.id,
          data: data,
          submissionCount: submissionCount,
          onToggleLock: () => _handleToggleLock(doc.id, data),
          onEdit: () => _handleEdit(doc.id, data),
          onDelete: () => _handleDelete(doc.id, data),
        );
      }).toList(),
    );
  }

  Future<void> _handleToggleLock(
    String exerciseId,
    Map<String, dynamic> data,
  ) async {
    final locked = data['isLocked'] == true;
    final success = await _service.setExerciseLocked(
      exerciseId: exerciseId,
      locked: !locked,
    );
    if (!mounted) return;
    AppNotifier.show(
      context,
      success
          ? (locked ? 'Assessment unlocked.' : 'Assessment locked.')
          : 'Could not update the lock state.',
      type: success
          ? AppNotificationType.success
          : AppNotificationType.error,
    );
  }

  Future<void> _handleEdit(
    String exerciseId,
    Map<String, dynamic> data,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _EditExerciseDialog(exerciseId: exerciseId, data: data),
    );
    if (result == true && mounted) {
      AppNotifier.show(
        context,
        'Assessment updated.',
        type: AppNotificationType.success,
      );
    }
  }

  Future<void> _handleDelete(
    String exerciseId,
    Map<String, dynamic> data,
  ) async {
    final title = data['title'] as String? ?? 'this assessment';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGlass,
        title: const Text(
          'Delete assessment?',
          style: TextStyle(color: AppTheme.textBright),
        ),
        content: Text(
          'This permanently removes "$title". Students will no longer see '
          'it, but existing submission records are kept for your records. '
          'This cannot be undone.',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCrimson,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await _service.deleteExercise(
      exerciseId: exerciseId,
      title: title,
    );
    if (!mounted) return;
    AppNotifier.show(
      context,
      success ? 'Assessment deleted.' : 'Could not delete the assessment.',
      type: success ? AppNotificationType.success : AppNotificationType.error,
    );
  }
}

class _AssessmentManagementCard extends StatelessWidget {
  final String exerciseId;
  final Map<String, dynamic> data;
  final int submissionCount;
  final VoidCallback onToggleLock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssessmentManagementCard({
    required this.exerciseId,
    required this.data,
    required this.submissionCount,
    required this.onToggleLock,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Untitled';
    final assessmentNumber = (data['assessmentNumber'] as num?)?.toInt();
    final locked = data['isLocked'] == true;
    final statusColor = locked ? Colors.amber : AppTheme.accentEmerald;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(
                    locked ? Icons.lock : Icons.assignment_outlined,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessmentNumber == null
                            ? title
                            : 'Assessment $assessmentNumber — $title',
                        style: const TextStyle(
                          color: AppTheme.textBright,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$submissionCount submission'
                        '${submissionCount == 1 ? '' : 's'}'
                        '${locked ? ' • Locked — closed to new attempts' : ''}',
                        style: TextStyle(
                          color: locked ? statusColor : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: locked ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: Icon(
                    locked ? Icons.lock_open : Icons.lock_outline,
                    size: 16,
                  ),
                  label: Text(locked ? 'Unlock' : 'Lock'),
                  onPressed: onToggleLock,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  onPressed: onEdit,
                ),
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppTheme.accentCrimson,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.accentCrimson),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accentCrimson),
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Edits title, instructions, difficulty, max score and time limit — not
/// course, type or the solution canvas, which the assessment list would
/// need to change navigation/grading behaviour around, not just this form.
class _EditExerciseDialog extends StatefulWidget {
  final String exerciseId;
  final Map<String, dynamic> data;

  const _EditExerciseDialog({required this.exerciseId, required this.data});

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _maxScoreController;
  late final TextEditingController _timeLimitController;
  late String _difficulty;
  bool _isSaving = false;

  final _service = LecturerManagementService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.data['title'] as String? ?? '',
    );
    _instructionsController = TextEditingController(
      text: widget.data['description'] as String? ?? '',
    );
    _maxScoreController = TextEditingController(
      text: '${(widget.data['maxScore'] as num?)?.toInt() ?? 100}',
    );
    _timeLimitController = TextEditingController(
      text: (widget.data['timeLimitMinutes'] as num?)?.toInt().toString() ?? '',
    );
    _difficulty = widget.data['difficulty'] as String? ?? 'intermediate';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _maxScoreController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final timeLimitMinutes = int.tryParse(_timeLimitController.text.trim());
    final success = await _service.updateExercise(
      exerciseId: widget.exerciseId,
      title: _titleController.text.trim(),
      instructions: _instructionsController.text.trim(),
      difficulty: _difficulty,
      maxScore: double.tryParse(_maxScoreController.text) ?? 100.0,
      timeLimitMinutes: (timeLimitMinutes != null && timeLimitMinutes > 0)
          ? timeLimitMinutes
          : null,
    );

    if (!mounted) return;
    Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceGlass,
      title: const Text(
        'Edit Assessment',
        style: TextStyle(color: AppTheme.textBright),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: AppTheme.textBright),
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructionsController,
                  maxLines: 4,
                  style: const TextStyle(color: AppTheme.textBright),
                  decoration: const InputDecoration(labelText: 'Instructions'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter instructions'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  dropdownColor: AppTheme.surfaceGlass,
                  style: const TextStyle(color: AppTheme.textBright),
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: const [
                    DropdownMenuItem(
                      value: 'beginner',
                      child: Text('Beginner'),
                    ),
                    DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('Intermediate'),
                    ),
                    DropdownMenuItem(
                      value: 'advanced',
                      child: Text('Advanced'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _difficulty = val!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxScoreController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Max Score',
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter score'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _timeLimitController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Time Limit (min)',
                          hintText: 'blank = no limit',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
