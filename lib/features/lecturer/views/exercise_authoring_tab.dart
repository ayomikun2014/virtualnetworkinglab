import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../services/lecturer_management_service.dart';

/// Lecturer Tab 2: Exercise Authoring Wizard & Solution Key Builder
class ExerciseAuthoringTab extends StatefulWidget {
  const ExerciseAuthoringTab({super.key});

  @override
  State<ExerciseAuthoringTab> createState() => _ExerciseAuthoringTabState();
}

class _ExerciseAuthoringTabState extends State<ExerciseAuthoringTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');

  String _type = 'routing';
  String _difficulty = 'intermediate';
  final String _starterCanvasId = 'starter_canvas_01';
  bool _isPublishing = false;

  final _service = LecturerManagementService();

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _handlePublishExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    final maxScore = double.tryParse(_maxScoreController.text) ?? 100.0;

    final success = await _service.createExercise(
      title: _titleController.text.trim(),
      instructions: _instructionsController.text.trim(),
      exerciseType: _type,
      difficulty: _difficulty,
      maxScore: maxScore,
      initialTopologyId: _starterCanvasId,
      solutionTopologyId: '${_starterCanvasId}_solution',
      targetCriteria: {
        'icmpPingSuccess': true,
        'ospfAdjacencyVerified': _type == 'routing',
        'vlanTaggingCorrect': _type == 'switching',
      },
    );

    if (mounted) {
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Lab exercise published successfully!'
                : 'Failed to publish exercise.',
          ),
          backgroundColor: success
              ? AppTheme.accentEmerald
              : AppTheme.accentCrimson,
        ),
      );

      if (success) {
        _titleController.clear();
        _instructionsController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Author New Lab Exercise',
            style: TextStyle(
              color: AppTheme.textBright,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure exercise metadata, link a starter topology canvas, and define automated grading test criteria.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: AppTheme.textBright),
                    decoration: const InputDecoration(
                      labelText: 'Exercise Title',
                      hintText:
                          'Lab 2: Single Area OSPF Routing & ICMP Verification',
                      prefixIcon: Icon(
                        Icons.edit_note,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter exercise title'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  TextFormField(
                    controller: _instructionsController,
                    maxLines: 4,
                    style: const TextStyle(color: AppTheme.textBright),
                    decoration: const InputDecoration(
                      labelText: 'Student Lab Instructions & Requirements',
                      hintText:
                          'Configure OSPF Process ID 1 on Router 1 and Router 2. Assign Area 0 to 192.168.1.0/24...',
                      prefixIcon: Icon(
                        Icons.description,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter instructions'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Row: Type, Difficulty, Max Score
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _type,
                          dropdownColor: AppTheme.surfaceGlass,
                          style: const TextStyle(color: AppTheme.textBright),
                          decoration: const InputDecoration(
                            labelText: 'Exercise Category',
                            prefixIcon: Icon(
                              Icons.category,
                              color: AppTheme.primaryCyan,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'routing',
                              child: Text('Routing & OSPF'),
                            ),
                            DropdownMenuItem(
                              value: 'switching',
                              child: Text('Switching & VLANs'),
                            ),
                            DropdownMenuItem(
                              value: 'subnetting',
                              child: Text('Subnetting & VLSM'),
                            ),
                            DropdownMenuItem(
                              value: 'security',
                              child: Text('Security & ACLs'),
                            ),
                          ],
                          onChanged: (val) => setState(() => _type = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _difficulty,
                          dropdownColor: AppTheme.surfaceGlass,
                          style: const TextStyle(color: AppTheme.textBright),
                          decoration: const InputDecoration(
                            labelText: 'Difficulty Level',
                            prefixIcon: Icon(
                              Icons.speed,
                              color: AppTheme.primaryCyan,
                            ),
                          ),
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
                          onChanged: (val) =>
                              setState(() => _difficulty = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _maxScoreController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textBright),
                          decoration: const InputDecoration(
                            labelText: 'Max Score',
                            prefixIcon: Icon(
                              Icons.grade,
                              color: AppTheme.primaryCyan,
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter score' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Canvas Topology Linker Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundMidnight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.architecture,
                          color: AppTheme.primaryCyan,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Linked Starter Topology Canvas: $_starterCanvasId',
                                style: const TextStyle(
                                  color: AppTheme.textBright,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Contains unconfigured routers and switches provided to students.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: AppTheme.primaryCyan,
                          ),
                          label: const Text(
                            'Design Canvas',
                            style: TextStyle(color: AppTheme.primaryCyan),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryCyan),
                          ),
                          onPressed: () {
                            context.go(
                              '/canvas-builder/authoring_starter_template',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isPublishing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.backgroundMidnight,
                              ),
                            )
                          : const Icon(Icons.publish),
                      label: const Text('Publish Lab Exercise to Curriculum'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(18),
                      ),
                      onPressed: _isPublishing ? null : _handlePublishExercise,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
