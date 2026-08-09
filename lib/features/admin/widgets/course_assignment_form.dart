import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// One course-title/course-code row, plus the "Add Another Course" button
/// that reveals more of them — the form a lecturer's teaching load is built
/// from, whether that's the Approve dialog assigning it for the first time
/// or the Edit dialog changing it later.
///
/// Read the current, validated list via [CourseAssignmentFormState.courses]
/// through a `GlobalKey<CourseAssignmentFormState>`, the same pattern
/// `Form`/`FormState` uses — there's no `onChanged` because nothing here
/// needs to react to every keystroke, only to read the final list once the
/// admin presses Save.
class CourseAssignmentForm extends StatefulWidget {
  /// Pre-filled rows — non-empty when editing an already-assigned lecturer,
  /// empty for a fresh approval.
  final List<Map<String, String>> initialCourses;

  const CourseAssignmentForm({super.key, this.initialCourses = const []});

  @override
  State<CourseAssignmentForm> createState() => CourseAssignmentFormState();
}

class _CourseRow {
  final TextEditingController titleController;
  final TextEditingController codeController;

  _CourseRow({String title = '', String code = ''})
    : titleController = TextEditingController(text: title),
      codeController = TextEditingController(text: code);

  void dispose() {
    titleController.dispose();
    codeController.dispose();
  }
}

class CourseAssignmentFormState extends State<CourseAssignmentForm> {
  late final List<_CourseRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialCourses.isEmpty
        ? [_CourseRow()]
        : widget.initialCourses
              .map(
                (c) => _CourseRow(title: c['title'] ?? '', code: c['code'] ?? ''),
              )
              .toList();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// Every row with both a title and a code filled in. A row left entirely
  /// blank (the common case: the admin clicked "Add Another Course" once
  /// too many) is silently dropped rather than treated as a validation
  /// error — a half-filled row IS an error and stays, since that's more
  /// likely a typo than an intentionally empty course.
  List<Map<String, String>> courses() {
    return _rows
        .map(
          (row) => {
            'title': row.titleController.text.trim(),
            'code': row.codeController.text.trim().toUpperCase(),
          },
        )
        .where((c) => c['title']!.isNotEmpty || c['code']!.isNotEmpty)
        .toList();
  }

  /// True if every non-blank row has both fields filled. Call before
  /// accepting [build]'s result — a course with a title and no code (or
  /// vice versa) is exactly the half-filled-row case [build] doesn't catch
  /// on its own.
  bool get isValid => _rows.every((row) {
    final title = row.titleController.text.trim();
    final code = row.codeController.text.trim();
    return (title.isEmpty && code.isEmpty) || (title.isNotEmpty && code.isNotEmpty);
  });

  void _addRow() => setState(() => _rows.add(_CourseRow()));

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _rows[i].titleController,
                    style: const TextStyle(color: AppTheme.textBright),
                    decoration: InputDecoration(
                      labelText: 'Course Title',
                      hintText: 'Networking Principles',
                      prefixIcon: const Icon(
                        Icons.book,
                        color: AppTheme.primaryCyan,
                      ),
                      // Only the row an admin is actually confused about
                      // shows red — every other row stays quiet.
                      errorText:
                          _rows[i].titleController.text.trim().isEmpty &&
                              _rows[i].codeController.text.trim().isNotEmpty
                          ? 'Required'
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _rows[i].codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: AppTheme.textBright),
                    decoration: InputDecoration(
                      labelText: 'Course Code',
                      hintText: 'NET201',
                      prefixIcon: const Icon(
                        Icons.code,
                        color: AppTheme.primaryCyan,
                      ),
                      errorText:
                          _rows[i].codeController.text.trim().isEmpty &&
                              _rows[i].titleController.text.trim().isNotEmpty
                          ? 'Required'
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_rows.length > 1) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppTheme.accentCrimson,
                      size: 20,
                    ),
                    tooltip: 'Remove this course',
                    onPressed: () => _removeRow(i),
                  ),
                ],
              ],
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryCyan),
          label: const Text(
            'Add Another Course',
            style: TextStyle(color: AppTheme.primaryCyan),
          ),
          onPressed: _addRow,
        ),
      ],
    );
  }
}
