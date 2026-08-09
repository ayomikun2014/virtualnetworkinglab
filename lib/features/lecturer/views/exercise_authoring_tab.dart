import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../data/repositories/topology_repository.dart';
import '../../auth/providers/auth_provider.dart';
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
  final _timeLimitController = TextEditingController();

  /// Index into the signed-in lecturer's own `assignedCourses` — set by an
  /// admin at approval time, not a fixed list every lecturer shares. A
  /// lecturer can only publish under a course they were actually assigned,
  /// which is what keeps `categoryId` guaranteed to match something a real
  /// student can be enrolled in via `InviteCodeService`.
  int _selectedCourseIndex = 0;

  String _type = 'routing';
  String _difficulty = 'intermediate';
  bool _isPublishing = false;

  final _service = LecturerManagementService();
  final _topologyRepository = FirebaseTopologyRepository();

  /// Reserved up front so the solution canvas the lecturer designs can be
  /// saved under an id the published exercise will actually point at.
  late String _draftExerciseId;

  /// What the lecturer has actually built on the solution canvas so far.
  /// Publishing is blocked until there is something to grade against —
  /// otherwise every student would "pass" instantly against an empty answer.
  int _solutionDeviceCount = 0;
  int _solutionCableCount = 0;
  bool _isCheckingSolution = false;

  String get _solutionTopologyId =>
      LecturerManagementService.solutionTopologyIdFor(_draftExerciseId);

  @override
  void initState() {
    super.initState();
    _draftExerciseId = _service.reserveExerciseId();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _maxScoreController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  /// Opens the canvas so the lecturer can build the correct network, then
  /// re-reads what they saved when they come back.
  ///
  /// Uses `push`, not `go`: `go` replaces this route, which would tear down
  /// the form and lose everything typed so far.
  Future<void> _openSolutionCanvas() async {
    await context.push('/canvas-builder/$_solutionTopologyId');
    if (!mounted) return;
    await _refreshSolutionSummary();
  }

  Future<void> _refreshSolutionSummary() async {
    setState(() => _isCheckingSolution = true);
    try {
      final topology = await _topologyRepository.getTopology(
        _solutionTopologyId,
      );
      if (!mounted) return;
      setState(() {
        _solutionDeviceCount = topology.nodes.length;
        _solutionCableCount = topology.edges.length;
      });
    } catch (_) {
      // Nothing saved at that id yet — the lecturer hasn't designed it.
      if (!mounted) return;
      setState(() {
        _solutionDeviceCount = 0;
        _solutionCableCount = 0;
      });
    } finally {
      if (mounted) setState(() => _isCheckingSolution = false);
    }
  }

  Future<void> _handlePublishExercise() async {
    if (!_formKey.currentState!.validate()) return;

    final assignedCourses =
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).currentUser?.assignedCourses ??
        const [];
    if (assignedCourses.isEmpty) {
      AppNotifier.error(
        context,
        'You have no assigned courses yet — an admin needs to assign at '
        'least one before you can publish an exercise.',
      );
      return;
    }
    final course = assignedCourses[_selectedCourseIndex];

    // Re-read rather than trusting cached counts: the lecturer may have
    // designed the canvas in another tab since this form was opened.
    await _refreshSolutionSummary();
    if (!mounted) return;

    if (_solutionDeviceCount == 0) {
      AppNotifier.error(
        context,
        'Design the solution canvas first — an exercise with no devices '
        'would mark every submission correct.',
      );
      return;
    }

    setState(() => _isPublishing = true);

    final maxScore = double.tryParse(_maxScoreController.text) ?? 100.0;
    final timeLimitMinutes = int.tryParse(_timeLimitController.text.trim());

    final success = await _service.createExercise(
      exerciseId: _draftExerciseId,
      title: _titleController.text.trim(),
      instructions: _instructionsController.text.trim(),
      exerciseType: _type,
      categoryId: course['code'] ?? '',
      courseTitle: course['title'] ?? '',
      difficulty: _difficulty,
      maxScore: maxScore,
      // Students start from a blank canvas and build it themselves; the
      // lecturer's design is the answer key, not the starting point.
      initialTopologyId: '',
      solutionTopologyId: _solutionTopologyId,
      timeLimitMinutes: (timeLimitMinutes != null && timeLimitMinutes > 0)
          ? timeLimitMinutes
          : null,
      targetCriteria: {
        'icmpPingSuccess': true,
        'ospfAdjacencyVerified': _type == 'routing',
        'vlanTaggingCorrect': _type == 'switching',
      },
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);
    AppNotifier.show(
      context,
      success
          ? 'Exercise published successfully!'
          : 'Failed to publish exercise.',
      type: success
          ? AppNotificationType.success
          : AppNotificationType.error,
    );

    if (success) {
      _titleController.clear();
      _instructionsController.clear();
      _timeLimitController.clear();
      setState(() {
        // Start a fresh draft so the next exercise gets its own id and its
        // own solution canvas rather than overwriting the one just published.
        _draftExerciseId = _service.reserveExerciseId();
        _solutionDeviceCount = 0;
        _solutionCableCount = 0;
      });
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
            'Build the correct network on the solution canvas, write the '
            'instructions students will follow, and publish. Submissions are '
            'graded against the topology you design here.',
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

                  // Course linkage — students only see an assessment when
                  // its course code is in their enrolledCourseIds (which
                  // they get by entering the course code with
                  // InviteCodeService). A dropdown over the courses THIS
                  // lecturer was actually assigned by an admin, not free
                  // text: a typo or case difference here used to mean the
                  // exercise silently never appeared to anyone enrolled.
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final courses =
                          authProvider.currentUser?.assignedCourses ??
                          const [];

                      if (courses.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You have no assigned courses yet — ask '
                                  'an admin to assign one before you can '
                                  'publish an exercise.',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_selectedCourseIndex >= courses.length) {
                        _selectedCourseIndex = 0;
                      }

                      return DropdownButtonFormField<int>(
                        initialValue: _selectedCourseIndex,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceGlass,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          prefixIcon: Icon(
                            Icons.menu_book,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                        items: [
                          for (var i = 0; i < courses.length; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text(
                                '${courses[i]['code']} — '
                                '${courses[i]['title']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (index) =>
                            setState(() => _selectedCourseIndex = index!),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type, Difficulty, Max Score — each dropdown needs real
                  // width for its prefix icon + label + value text, so on a
                  // narrow screen these stack instead of squeezing into one
                  // Row (three fields in ~300px was overflowing by 17-58px).
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final typeField = DropdownButtonFormField<String>(
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
                      );
                      final difficultyField = DropdownButtonFormField<String>(
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
                        onChanged: (val) => setState(() => _difficulty = val!),
                      );
                      final maxScoreField = TextFormField(
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
                      );

                      if (constraints.maxWidth < 560) {
                        return Column(
                          children: [
                            typeField,
                            const SizedBox(height: 16),
                            difficultyField,
                            const SizedBox(height: 16),
                            maxScoreField,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: typeField),
                          const SizedBox(width: 16),
                          Expanded(child: difficultyField),
                          const SizedBox(width: 16),
                          SizedBox(width: 140, child: maxScoreField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Time limit — optional. When set, the student's canvas
                  // shows a countdown from the moment they open it and
                  // auto-submits the instant it reaches zero (see
                  // CanvasBuilderScreen). This exercise's number within its
                  // course ("Assessment 3") is assigned automatically on
                  // publish, not chosen here — see
                  // LecturerManagementService._nextAssessmentNumber.
                  TextFormField(
                    controller: _timeLimitController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textBright),
                    decoration: const InputDecoration(
                      labelText: 'Time Limit in Minutes (optional)',
                      hintText: 'e.g. 30 — leave blank for no time limit',
                      prefixIcon: Icon(
                        Icons.timer_outlined,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Solution Canvas Designer
                  _buildSolutionCanvasPanel(),
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

  /// Panel where the lecturer builds the worked solution students are graded
  /// against, and sees at a glance whether anything has been designed yet.
  Widget _buildSolutionCanvasPanel() {
    final hasSolution = _solutionDeviceCount > 0;
    final accent = hasSolution ? AppTheme.accentEmerald : Colors.amber;

    final icon = Icon(
      hasSolution ? Icons.verified : Icons.architecture,
      color: accent,
      size: 28,
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasSolution
              ? 'Solution designed — this is the answer key'
              : 'No solution designed yet',
          style: TextStyle(color: accent, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          _isCheckingSolution
              ? 'Checking saved canvas…'
              : hasSolution
              ? '$_solutionDeviceCount device'
                    '${_solutionDeviceCount == 1 ? '' : 's'}, '
                    '$_solutionCableCount cable'
                    '${_solutionCableCount == 1 ? '' : 's'}. '
                    'Students must reproduce this to pass.'
              : 'Open the canvas, place the devices and connect them '
                    'the correct way, then press Save Canvas.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
    final button = OutlinedButton.icon(
      icon: const Icon(
        Icons.open_in_new,
        size: 16,
        color: AppTheme.primaryCyan,
      ),
      label: Text(
        hasSolution ? 'Edit Solution' : 'Design Solution',
        style: const TextStyle(color: AppTheme.primaryCyan),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.primaryCyan),
      ),
      onPressed: _openSolutionCanvas,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMidnight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Below this width the icon + text + button no longer fit on one
          // line without squeezing the text column to almost nothing —
          // that's what was making every word wrap onto its own line.
          // Stack instead: icon+text on top, full-width button below.
          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: 16),
              Expanded(child: text),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }
}
