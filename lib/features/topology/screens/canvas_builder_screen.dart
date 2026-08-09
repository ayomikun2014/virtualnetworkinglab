import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/topology_model.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/grading_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_layout.dart';
import '../providers/topology_provider.dart';
import '../providers/grading_provider.dart';
import '../services/topology_grader.dart';
import '../widgets/cable_painter.dart';
import '../widgets/canvas_grid_painter.dart';
import '../widgets/device_palette.dart';
import '../widgets/node_property_inspector.dart';

/// 5-Layer Interactive Topology Canvas Engine Workspace Screen
class CanvasBuilderScreen extends StatefulWidget {
  final String topologyId;

  /// When set, this canvas is a graded level: a "Check Connection" button
  /// appears and submits against `exercises/{exerciseId}/private/solution_key`.
  /// Null means an ungraded sandbox canvas.
  final String? exerciseId;

  /// Free Practice level number, so a pass can advance the student's
  /// `freePracticeLevel`. Only meaningful alongside [exerciseId].
  final int? practiceLevel;

  const CanvasBuilderScreen({
    super.key,
    required this.topologyId,
    this.exerciseId,
    this.practiceLevel,
  });

  /// The name shown for this canvas in Submissions history and stored on
  /// each save/check record — the exercise's own title for a graded canvas,
  /// a readable label for the sandbox or an ungraded course canvas, so
  /// history never shows a raw topologyId/exerciseId to the student.
  /// Static and on the widget (not the State) so it's usable — and directly
  /// testable — without building a canvas.
  static String friendlySaveTitle({
    required String? exerciseTitle,
    required String topologyId,
  }) {
    if (exerciseTitle != null && exerciseTitle.trim().isNotEmpty) {
      return exerciseTitle;
    }
    if (topologyId.startsWith('sandbox_')) return 'Sandbox Canvas';
    if (topologyId.startsWith('assessment_')) return 'Course Assessment';
    return 'Topology Canvas';
  }

  @override
  State<CanvasBuilderScreen> createState() => _CanvasBuilderScreenState();
}

class _CanvasBuilderScreenState extends State<CanvasBuilderScreen> {
  final TransformationController _transformationController =
      TransformationController();
  bool _showDevicePalette = true;
  String? _connectSourceNodeId;

  // Raw-pointer drag tracking for canvas nodes.
  //
  // InteractiveViewer's child GestureDetector (onScaleStart/onScaleUpdate)
  // always wins the gesture arena against a descendant's onPanUpdate, because
  // it recognizes 1-finger drags as a pan gesture too — so the node's own
  // PanGestureRecognizer never fires and the node cannot be dragged
  // (confirmed via test/canvas_drag_repro_test.dart). A Listener sidesteps
  // the arena entirely — it receives every raw pointer event regardless of
  // which GestureRecognizer wins — so drag tracking is done here by hand
  // instead of via GestureDetector.
  //
  // That fixed the node not moving, but left a second bug: a Listener is a
  // silent observer, not a competing recognizer, so it does nothing to stop
  // InteractiveViewer's own recognizer from ALSO treating the same pointer
  // stream as a canvas pan — the node moved, but the whole background panned
  // underneath it at the same time. `panEnabled` is what actually suppresses
  // that: unlike trying to make the *node* react to it (which doesn't work —
  // the recognizer still claims the pointer and only discards the resulting
  // translation internally), suppressing the *canvas's own* translation this
  // way works fine, because nothing else needs that recognizer to fire.
  // Toggled true/false around each node drag so background panning still
  // works the rest of the time.
  String? _draggingNodeId;
  Offset? _dragPointerStart;
  Offset? _dragNodeStart;
  bool _dragMoved = false;
  bool _canvasPanEnabled = true;

  /// Medium used for the next cable drawn via port-to-port click. Previously
  /// hardcoded to 'Ethernet' in _handlePortClick, so CablePainter's
  /// per-type colours (cyan/amber/crimson) were unreachable through the
  /// actual drag-and-connect flow — every cable was the same colour because
  /// every cable was secretly the same type.
  String _selectedCableType = 'Ethernet';

  /// The graded exercise this canvas belongs to, when [widget.exerciseId] is
  /// set. Holds the lecturer's task brief.
  ExerciseModel? _exercise;

  /// A lecturer-authored course exercise (opened from Courses Lab), as
  /// opposed to a Free Practice level. Drives every place the two need to
  /// behave differently: "Submit" vs "Check Connection", one attempt vs
  /// unlimited re-attempts, and no points/level effects.
  bool get _isCourseAssessment =>
      widget.exerciseId != null && widget.practiceLevel == null;

  /// Ticks down once a course assessment with a lecturer-set time limit has
  /// loaded. Null means either there's no limit, or this isn't a timed
  /// course assessment at all.
  Timer? _countdownTimer;
  int? _remainingSeconds;

  /// Guards against the countdown reaching zero twice in the same frame
  /// (each tick's setState could otherwise race a second timer callback).
  bool _autoSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final topologyProvider = Provider.of<TopologyProvider>(
        context,
        listen: false,
      );
      topologyProvider.watchTopology(widget.topologyId);
      _loadExerciseBrief();
    });
  }

  /// Loads the lecturer's brief and shows it once, so a student arriving on a
  /// blank canvas knows what they're being asked to build.
  Future<void> _loadExerciseBrief() async {
    final exerciseId = widget.exerciseId;
    if (exerciseId == null) return;

    try {
      final exercise = await FirebaseExerciseRepository().getExercise(
        exerciseId,
      );
      if (!mounted) return;
      setState(() => _exercise = exercise);
      _showInstructionsDialog();
      _maybeStartCountdown(exercise);
    } catch (_) {
      // A missing brief shouldn't block building — the Check Connection
      // button still works, and the toolbar button just won't appear.
    }
  }

  /// Starts the per-exercise countdown a lecturer set at publish time.
  ///
  /// Course assessments only ([widget.practiceLevel] null) — Free Practice
  /// levels are re-attempted freely as part of the points economy, and a
  /// countdown that auto-submits would fight that rather than fit it.
  void _maybeStartCountdown(ExerciseModel exercise) {
    final minutes = exercise.timeLimitMinutes;
    if (minutes == null || minutes <= 0) return;
    if (widget.practiceLevel != null) return;

    setState(() => _remainingSeconds = minutes * 60);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = (_remainingSeconds ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _handleTimeExpired();
        return;
      }
      setState(() => _remainingSeconds = next);
    });
  }

  /// Time's up — submits exactly what's on the canvas right now, the same
  /// path a manual "Check Connection" press takes. A late/failed attempt
  /// still counts as the one attempt a course assessment gets; running out
  /// of time is not a free pass to keep trying.
  Future<void> _handleTimeExpired() async {
    if (!mounted || _autoSubmitting) return;
    _autoSubmitting = true;

    AppNotifier.info(context, "Time's up — submitting your canvas now.");

    final provider = Provider.of<TopologyProvider>(context, listen: false);
    final grading = Provider.of<GradingProvider>(context, listen: false);
    await _handleCheckConnection(provider, grading);
  }

  String _formatCountdown(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showInstructionsDialog() {
    final exercise = _exercise;
    if (exercise == null) return;

    // Reflects real progress, not "has this dialog been opened before" —
    // that way even the very first auto-shown dialog correctly reads
    // "Continue Building" if the student is returning to a level they'd
    // already started (e.g. re-opening it from the level list) rather than
    // always claiming they're starting fresh.
    final hasStarted =
        Provider.of<TopologyProvider>(
          context,
          listen: false,
        ).activeTopology?.nodes.isNotEmpty ??
        false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGlass,
        title: Row(
          children: [
            const Icon(Icons.assignment, color: AppTheme.primaryCyan),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                exercise.title,
                style: const TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Text(
              exercise.description,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(hasStarted ? 'Continue Building' : 'Start Building'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      body: Consumer<TopologyProvider>(
        builder: (context, provider, _) {
          final topology = provider.activeTopology;

          return Column(
            children: [
              // Top Control Toolbar
              _buildTopToolbar(context, provider, topology),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 900;

                    if (isMobile) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: _buildCanvasViewport(provider, topology),
                          ),

                          // Palette Overlay
                          if (_showDevicePalette)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: DevicePalette(
                                  onDeviceSelected: (type, model) =>
                                      _addDeviceToCanvas(provider, type, model),
                                ),
                              ),
                            ),

                          // Inspector Overlay
                          if (provider.selectedNode != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: NodePropertyInspector(
                                  node: provider.selectedNode!,
                                  onNodeChanged: provider.updateNode,
                                  onClose: () => provider.selectNode(null),
                                  onDeleteNode: () => provider.deleteNode(
                                    provider.selectedNode!.nodeId,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          if (_showDevicePalette)
                            DevicePalette(
                              onDeviceSelected: (type, model) =>
                                  _addDeviceToCanvas(provider, type, model),
                            ),
                          Expanded(
                            child: _buildCanvasViewport(provider, topology),
                          ),
                          if (provider.selectedNode != null)
                            NodePropertyInspector(
                              node: provider.selectedNode!,
                              onNodeChanged: provider.updateNode,
                              onClose: () => provider.selectNode(null),
                              onDeleteNode: () => provider.deleteNode(
                                provider.selectedNode!.nodeId,
                              ),
                            ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The main interactive canvas content shared between desktop and mobile layouts.
  Widget _buildCanvasViewport(
    TopologyProvider provider,
    TopologyModel? topology,
  ) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(2000),
          minScale: 0.2,
          maxScale: 3.0,
          panEnabled: _canvasPanEnabled,
          child: SizedBox(
            width: 3000,
            height: 2000,
            child: Stack(
              children: [
                // Layer 0: Background
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/lab_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppTheme.backgroundMidnight);
                    },
                  ),
                ),

                // Layer 1: Grid
                const CustomPaint(
                  size: Size(3000, 2000),
                  painter: CanvasGridPainter(),
                ),

                // Layer 2: Cables
                if (topology != null)
                  CustomPaint(
                    size: const Size(3000, 2000),
                    painter: CablePainter(
                      edges: topology.edges,
                      nodes: topology.nodes,
                      selectedNodeId: provider.selectedNodeId,
                    ),
                  ),

                // Layer 3: Nodes
                if (topology != null)
                  ...topology.nodes.map(
                    (node) => _buildInteractiveNode(provider, node),
                  ),
              ],
            ),
          ),
        ),

        // Floating Loading Indicator
        if (provider.isLoading)
          Positioned.fill(
            child: Container(
              color: AppTheme.backgroundMidnight.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryCyan),
              ),
            ),
          ),
      ],
    );
  }

  /// Top Canvas Toolbar — Horizontally Scrollable for Mobile Phone Overflow Protection
  Widget _buildTopToolbar(
    BuildContext context,
    TopologyProvider provider,
    TopologyModel? topology,
  ) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceGlass,
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Without this the canvas is a dead end — it has no AppBar, so
            // there was previously no way back out for students or lecturers.
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textBright),
              tooltip: 'Back',
              onPressed: _handleBack,
            ),
            IconButton(
              icon: Icon(
                _showDevicePalette ? Icons.menu_open : Icons.menu,
                color: AppTheme.primaryCyan,
              ),
              tooltip: 'Toggle Device Palette',
              onPressed: () =>
                  setState(() => _showDevicePalette = !_showDevicePalette),
            ),
            const SizedBox(width: 8),
            Text(
              topology?.name ?? 'Topology Canvas',
              style: const TextStyle(
                color: AppTheme.textBright,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'v${topology?.version ?? 1}',
                style: const TextStyle(
                  color: AppTheme.primaryCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Re-read the lecturer's task brief
            if (_exercise != null)
              IconButton(
                icon: const Icon(
                  Icons.assignment_outlined,
                  color: AppTheme.primaryCyan,
                ),
                tooltip: 'View Instructions',
                onPressed: _showInstructionsDialog,
              ),

            // Countdown for a timed course assessment — turns red under a
            // minute so running low is impossible to miss, and auto-submits
            // via _handleTimeExpired the instant it reaches zero.
            if (_remainingSeconds != null) ...[
              const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final urgent = _remainingSeconds! <= 60;
                  final color = urgent
                      ? AppTheme.accentCrimson
                      : Colors.amber;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, color: color, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _formatCountdown(_remainingSeconds!),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // Cable Connect Tool
            IconButton(
              icon: Icon(
                Icons.cable,
                color: _connectSourceNodeId != null
                    ? AppTheme.accentEmerald
                    : AppTheme.textBright,
              ),
              tooltip: 'Connect Cable Link',
              onPressed: () => _handleCableConnectionDialog(provider),
            ),

            // Cable Type Picker — sets the medium used by the next cable
            // drawn via port-to-port click. Cables render in a colour keyed
            // to this (see CablePainter), so this is what makes the colours
            // actually mean something instead of every cable defaulting to
            // the same hardcoded Ethernet type.
            _buildCableTypeSelector(),

            // Delete Selected Node Button
            if (provider.selectedNodeId != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.accentCrimson,
                ),
                tooltip: 'Delete Selected Node',
                onPressed: () => provider.deleteNode(provider.selectedNodeId!),
              ),

            const SizedBox(width: 8),

            ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Canvas'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () => _handleSaveCanvas(provider),
            ),

            if (widget.exerciseId != null) ...[
              const SizedBox(width: 8),
              Consumer<GradingProvider>(
                builder: (context, grading, _) {
                  // A course assessment (from Courses Lab) is "Submit" —
                  // one shot, no re-checking. Free Practice keeps "Check
                  // Connection", since re-attempting there is the point.
                  final label = grading.isChecking
                      ? (_isCourseAssessment ? 'Submitting…' : 'Checking…')
                      : (_isCourseAssessment ? 'Submit' : 'Check Connection');

                  return ElevatedButton.icon(
                    icon: grading.isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.backgroundMidnight,
                            ),
                          )
                        : Icon(
                            _isCourseAssessment
                                ? Icons.send
                                : Icons.play_arrow,
                            size: 18,
                          ),
                    label: Text(label),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentEmerald,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: grading.isChecking
                        ? null
                        : () => _handleCheckConnection(provider, grading),
                  );
                },
              ),
            ],
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  static const List<String> _cableTypes = ['Ethernet', 'Fiber', 'Serial'];

  /// A coloured dot per cable medium — tap to choose what the *next*
  /// port-to-port click draws with. The dot itself shows the current
  /// selection so the toolbar doubles as a legend for the colours already
  /// on the canvas.
  Widget _buildCableTypeSelector() {
    return PopupMenuButton<String>(
      tooltip: 'Cable Type: $_selectedCableType',
      initialValue: _selectedCableType,
      onSelected: (type) => setState(() => _selectedCableType = type),
      itemBuilder: (context) => _cableTypes.map((type) {
        return PopupMenuItem(
          value: type,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: cableColorForType(type),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(type),
              if (type == _selectedCableType) ...[
                const Spacer(),
                const Icon(Icons.check, size: 16, color: AppTheme.primaryCyan),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundMidnight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cableColorForType(_selectedCableType).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: cableColorForType(_selectedCableType),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _selectedCableType,
              style: const TextStyle(
                color: AppTheme.textBright,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  /// Saves the canvas and files it in Save History under a name the student
  /// will recognise.
  ///
  /// On a level the name is the level's own title — the student already
  /// named this canvas by choosing the level, so prompting would just be a
  /// dialog to dismiss. A sandbox has no such name, so it asks for one
  /// rather than filing every free-form canvas as an identical
  /// "Sandbox Canvas" the student can't tell apart later.
  Future<void> _handleSaveCanvas(TopologyProvider provider) async {
    final exerciseTitle = _exercise?.title;
    final isLevel = exerciseTitle != null && exerciseTitle.trim().isNotEmpty;

    final title = isLevel ? exerciseTitle : await _promptForSaveName();
    // Cancelled the name prompt — nothing is lost either way, since the
    // canvas already persists itself as devices are placed and cabled.
    if (title == null) return;
    if (!mounted) return;

    final grading = Provider.of<GradingProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.uid;

    await provider.saveCurrentCanvas();

    // Fire-and-forget: recordCanvasSave swallows its own failures rather
    // than making a logging hiccup look like the save itself failed.
    if (uid != null) {
      unawaited(
        grading.recordCanvasSave(
          uid: uid,
          title: title,
          topologyId: widget.topologyId,
          exerciseId: widget.exerciseId,
        ),
      );
    }

    if (!mounted) return;
    AppNotifier.success(context, 'Saved as "$title"');
  }

  /// Asks what to call this canvas in Save History. Returns null if the
  /// student backs out.
  Future<String?> _promptForSaveName() async {
    final suggestion = CanvasBuilderScreen.friendlySaveTitle(
      exerciseTitle: null,
      topologyId: widget.topologyId,
    );
    final controller = TextEditingController(text: suggestion);

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGlass,
        title: const Row(
          children: [
            Icon(Icons.save_outlined, color: AppTheme.primaryCyan),
            SizedBox(width: 10),
            Text(
              'Name this canvas',
              style: TextStyle(color: AppTheme.textBright, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This is how the canvas will appear in your Save History.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppTheme.textBright),
                decoration: const InputDecoration(
                  labelText: 'Canvas name',
                  hintText: 'e.g. Two-router test setup',
                ),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save Canvas'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null) return null;

    // An emptied field still gets a usable name rather than a blank row.
    final trimmed = name.trim();
    return trimmed.isEmpty ? suggestion : trimmed;
  }

  /// Leaves the canvas, saving first so nothing built is lost.
  ///
  /// Falls back to the role's home route when there's nothing to pop — the
  /// canvas can be reached by deep link, in which case the navigator stack is
  /// empty and `pop` would do nothing at all.
  Future<void> _handleBack() async {
    final router = GoRouter.of(context);
    final provider = Provider.of<TopologyProvider>(context, listen: false);
    final role = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.role;

    await provider.saveCurrentCanvas();
    if (!mounted) return;

    if (router.canPop()) {
      router.pop();
      return;
    }

    router.go(switch (role) {
      UserRole.admin => '/admin-dashboard',
      UserRole.lecturer => '/lecturer-dashboard',
      _ => '/student-dashboard',
    });
  }

  /// Grades the current canvas against the level's solution key and shows a
  /// success or try-again dialog with specific per-check feedback.
  Future<void> _handleCheckConnection(
    TopologyProvider provider,
    GradingProvider grading,
  ) async {
    final exerciseId = widget.exerciseId;
    final topology = provider.activeTopology;
    if (exerciseId == null || topology == null) return;

    // A manual press before time runs out is still the one attempt this
    // assessment gets — stop the countdown so it doesn't also fire
    // _handleTimeExpired a few seconds later and try to submit again.
    _countdownTimer?.cancel();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.currentUser?.uid;
    if (uid == null) return;

    // Grading reads the last-saved canvas, not the in-memory draft, so a
    // student who just finished cabling and hits Check without saving would
    // otherwise be graded on stale data.
    await provider.saveCurrentCanvas();

    final result = await grading.checkTopology(
      uid: uid,
      exerciseId: exerciseId,
      exerciseTitle: CanvasBuilderScreen.friendlySaveTitle(
        exerciseTitle: _exercise?.title,
        topologyId: widget.topologyId,
      ),
      studentTopology: topology,
      practiceLevel: widget.practiceLevel,
      authorUid: _exercise?.authorUid,
      studentName: authProvider.currentUser?.displayName,
      studentEmail: authProvider.currentUser?.email,
      isLocked: _exercise?.isLocked ?? false,
    );

    if (!mounted) return;

    if (result == null) {
      AppNotifier.error(
        context,
        grading.errorMessage ?? 'Could not check the canvas.',
      );
      return;
    }

    // Passing may have advanced freePracticeLevel in Firestore, but every
    // "is this level unlocked?" check reads AuthProvider's cached
    // UserModel, which was loaded at sign-in and never refreshed. Without
    // this, a student who passed Level 2 saw Level 3 stay locked until they
    // signed out and back in.
    // The score changed either way, and both the stat card and the level
    // locks read it from the cached profile.
    await authProvider.refreshCurrentUserProfile();
    if (!mounted) return;

    // A course assessment is one-shot: there is no "Try Again"/"Keep
    // Practicing" to offer, so it gets its own, simpler dialog — a score
    // summary with a single action that leaves the canvas, since there is
    // nothing left to do here once submitted.
    if (_isCourseAssessment) {
      _showSubmissionResultDialog(result, grading.lastProgress);
      return;
    }

    _showGradeResultDialog(
      result,
      grading.lastProgress,
      pointsDelta: grading.lastPointsDelta,
      pointsTotal: grading.lastPointsTotal,
      demotedToLevel: grading.lastDemotedToLevel,
    );
  }

  /// The whole submission result for a course assessment: pass/fail, score,
  /// what was checked — then a single "Done" that closes the canvas. There
  /// is no retry action, because there is no second attempt to offer.
  void _showSubmissionResultDialog(
    GradeResult result,
    ExerciseProgress? progress,
  ) {
    final score = progress?.scorePercent;
    final scoreLine = score == null
        ? null
        : '${score.round()}% — ${progress!.correctChecks}/'
              '${progress.totalChecks} correct';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceGlass,
          title: Row(
            children: [
              Icon(
                result.passed
                    ? Icons.celebration
                    : Icons.sentiment_dissatisfied,
                color: result.passed
                    ? AppTheme.accentEmerald
                    : AppTheme.accentCrimson,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Assessment Submitted',
                  style: TextStyle(color: AppTheme.textBright),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.passed
                      ? 'Your network matches the design.'
                      : 'Your network does not fully match the design.',
                  style: TextStyle(
                    color: result.passed
                        ? AppTheme.accentEmerald
                        : AppTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (scoreLine != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    scoreLine,
                    style: const TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                const Text(
                  'This was your only attempt — your lecturer can see this '
                  'result.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                const Text(
                  'What was checked:',
                  style: TextStyle(
                    color: AppTheme.textBright,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                for (final check in result.checks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          check.passed ? Icons.check : Icons.close,
                          size: 16,
                          color: check.passed
                              ? AppTheme.accentEmerald
                              : AppTheme.accentCrimson,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            check.message,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _goToAssessmentList();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  /// A cheer or a commiseration, picked so the same message doesn't come up
  /// every single time.
  static String _reactionFor({required bool passed, required int attempt}) {
    const wins = [
      'Woohoo!',
      'Boom! Nailed it.',
      'Yesss!',
      'Look at that — it works!',
    ];
    const losses = [
      'Ohhh, so close.',
      'Oops — not yet.',
      'Ah, nearly!',
      'Hmm, not quite.',
    ];
    final pool = passed ? wins : losses;
    // Cycles on attempt number: no randomness, so the same attempt always
    // reads the same way and a test can pin it.
    return pool[(attempt.abs()) % pool.length];
  }

  void _showGradeResultDialog(
    GradeResult result,
    ExerciseProgress? progress, {
    required int pointsDelta,
    int? pointsTotal,
    int? demotedToLevel,
  }) {
    final attempt = progress?.attemptCount ?? 1;
    final reaction = _reactionFor(passed: result.passed, attempt: attempt);

    final String pointsLine;
    if (pointsDelta > 0) {
      pointsLine = 'You just earned $pointsDelta points.';
    } else if (demotedToLevel != null) {
      // The deduction hit the floor, so the cost was taken in levels
      // instead — saying "that cost you 2 points" here would be a lie.
      pointsLine =
          'You had no points left to lose, so you have dropped back to '
          'Level $demotedToLevel.';
    } else if (pointsDelta < 0) {
      pointsLine = 'That cost you ${pointsDelta.abs()} points.';
    } else {
      pointsLine =
          'No points this time — you had already solved this one. Replay it '
          'from the level list to earn them again.';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceGlass,
          title: Row(
            children: [
              Icon(
                result.passed ? Icons.celebration : Icons.sentiment_dissatisfied,
                color: result.passed
                    ? AppTheme.accentEmerald
                    : AppTheme.accentCrimson,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reaction,
                  style: const TextStyle(color: AppTheme.textBright),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plain-language summary first: what happened, what it cost
                // or earned, and where the score now stands. The per-check
                // detail below is for working out *what to fix*.
                Text(
                  result.passed
                      ? 'Your network matches the design.'
                      : 'Your network does not match the design yet.',
                  style: TextStyle(
                    color: result.passed
                        ? AppTheme.accentEmerald
                        : AppTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pointsTotal == null
                      ? pointsLine
                      : '$pointsLine You now have $pointsTotal.',
                  style: const TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    result.passed
                        ? _solvedInMessage(progress)
                        : 'Attempt ${progress.attemptCount} — keep going.',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  result.passed
                      ? 'What was checked:'
                      : 'Fix these and check again:',
                  style: const TextStyle(
                    color: AppTheme.textBright,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                for (final check
                    in (result.passed ? result.checks : result.failures))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          check.passed ? Icons.check : Icons.close,
                          size: 16,
                          color: check.passed
                              ? AppTheme.accentEmerald
                              : AppTheme.accentCrimson,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            check.message,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: result.passed
              ? [
                  // Closes the dialog only — the canvas already has the
                  // passing build on it, so "keep practicing" just means
                  // letting the student keep tinkering with what's there
                  // (add more devices, try an alternative cabling, etc.)
                  // without leaving the level.
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Keep Practicing'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _goToAssessmentList();
                    },
                    child: const Text('Next'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Try Again'),
                  ),
                ],
        );
      },
    );
  }

  /// Where "Next" on a pass sends the student — back to whichever list they
  /// picked this exercise from, so choosing what to do next is a single tap
  /// rather than retracing Back through the canvas.
  void _goToAssessmentList() {
    final router = GoRouter.of(context);
    final tab = widget.practiceLevel != null
        ? DashboardLayout.freePracticeTabIndex
        : DashboardLayout.coursesLabTabIndex;
    router.go('/student-dashboard?tab=$tab');
  }

  /// "Solved on your 3rd attempt" — reads [ExerciseProgress.attemptsUsed],
  /// which is frozen at the first pass, so re-checking a solved level keeps
  /// reporting the figure the student actually earned.
  static String _solvedInMessage(ExerciseProgress progress) {
    final attempts = progress.attemptsUsed ?? progress.attemptCount;
    if (attempts <= 1) return 'Solved on your first attempt!';
    return 'Solved in $attempts attempts.';
  }

  /// Interactive Positioned Node Widget with PictoBlox-style Port Connector Handles
  Widget _buildInteractiveNode(TopologyProvider provider, DeviceNode node) {
    final isSelected = provider.selectedNodeId == node.nodeId;
    final isSourceConnect = _connectSourceNodeId == node.nodeId;

    return Positioned(
      key: ValueKey(node.nodeId),
      left: node.position.x,
      top: node.position.y,
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Device Card Body — raw Listener instead of GestureDetector so
            // drag tracking bypasses the InteractiveViewer gesture-arena
            // conflict (see field doc comment on `_draggingNodeId` above).
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => _handleNodePointerDown(node, event),
              onPointerMove: (event) =>
                  _handleNodePointerMove(provider, node, event),
              onPointerUp: (event) =>
                  _handleNodePointerUp(provider, node, event),
              onPointerCancel: (event) =>
                  _handleNodePointerUp(provider, node, event),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSourceConnect
                        ? AppTheme.accentEmerald
                        : isSelected
                        ? AppTheme.primaryCyan
                        : AppTheme.borderSubtle,
                    width: isSelected || isSourceConnect ? 2.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getDeviceIcon(node.type),
                      color: _getDeviceColor(node.type),
                      size: 34,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      node.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textBright,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${node.interfaces.length} Ports',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // PictoBlox-style Port Connector Handle Dots (Left & Right Port Attachments)
            // Port 0 (Left Side Handle)
            Positioned(
              left: -10,
              top: 35,
              child: Tooltip(
                message: node.interfaces.isNotEmpty
                    ? '${node.interfaces.first.name} (${node.interfaces.first.ip ?? "No IP"})'
                    : 'Port eth0',
                child: InkWell(
                  onTap: () => _handlePortClick(
                    provider,
                    node.nodeId,
                    node.interfaces.isNotEmpty
                        ? node.interfaces.first.name
                        : 'eth0',
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSourceConnect
                          ? AppTheme.accentEmerald
                          : AppTheme.primaryCyan,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.backgroundMidnight,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isSourceConnect
                                      ? AppTheme.accentEmerald
                                      : AppTheme.primaryCyan)
                                  .withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cable,
                      color: AppTheme.backgroundMidnight,
                      size: 10,
                    ),
                  ),
                ),
              ),
            ),

            // Port 1 (Right Side Handle)
            Positioned(
              right: -10,
              top: 35,
              child: Tooltip(
                message: node.interfaces.length > 1
                    ? '${node.interfaces[1].name} (${node.interfaces[1].ip ?? "No IP"})'
                    : 'Port eth1',
                child: InkWell(
                  onTap: () => _handlePortClick(
                    provider,
                    node.nodeId,
                    node.interfaces.length > 1
                        ? node.interfaces[1].name
                        : 'eth1',
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSourceConnect
                          ? AppTheme.accentEmerald
                          : AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.backgroundMidnight,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isSourceConnect
                                      ? AppTheme.accentEmerald
                                      : AppTheme.primaryBlue)
                                  .withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cable,
                      color: AppTheme.backgroundMidnight,
                      size: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _connectSourcePort;

  /// Tap-slop in logical pixels below which a pointer-up is treated as a tap
  /// (select) rather than a drag (move).
  static const double _tapSlop = 4.0;

  void _handleNodePointerDown(DeviceNode node, PointerDownEvent event) {
    _draggingNodeId = node.nodeId;
    _dragPointerStart = event.localPosition;
    _dragNodeStart = Offset(node.position.x, node.position.y);
    _dragMoved = false;

    // Must happen on pointer-down, not once movement is detected: InteractiveViewer's
    // recognizer decides whether it's panning from the same early pointer
    // samples, so flipping this any later would already be too late to stop
    // the first frames of canvas pan.
    setState(() => _canvasPanEnabled = false);
  }

  void _handleNodePointerMove(
    TopologyProvider provider,
    DeviceNode node,
    PointerMoveEvent event,
  ) {
    if (_draggingNodeId != node.nodeId ||
        _dragPointerStart == null ||
        _dragNodeStart == null) {
      return;
    }

    // `event.localPosition` is reported relative to the transform captured
    // at pointer-down time, so this delta already accounts for the current
    // InteractiveViewer zoom level — no manual scale division needed.
    final delta = event.localPosition - _dragPointerStart!;

    if (!_dragMoved && delta.distance > _tapSlop) {
      _dragMoved = true;
    }
    if (!_dragMoved) return;

    final newPos = _dragNodeStart! + delta;
    provider.updateNodePosition(
      node.nodeId,
      newPos.dx,
      newPos.dy,
      isPanEnd: false,
    );
  }

  void _handleNodePointerUp(
    TopologyProvider provider,
    DeviceNode node,
    PointerEvent event,
  ) {
    if (_draggingNodeId != node.nodeId) return;

    if (_dragMoved) {
      final finalPos =
          provider.dragPosition ?? Offset(node.position.x, node.position.y);

      provider.updateNodePosition(
        node.nodeId,
        finalPos.dx,
        finalPos.dy,
        isPanEnd: true,
      );
    } else {
      provider.selectNode(node.nodeId);
    }

    _draggingNodeId = null;
    _dragPointerStart = null;
    _dragNodeStart = null;
    _dragMoved = false;

    setState(() => _canvasPanEnabled = true);
  }

  /// The student-visible name of a node ("Switch1"), for messages. Falls
  /// back to a generic word rather than exposing a generated node id.
  static String _labelForNode(TopologyProvider provider, String? nodeId) {
    if (nodeId == null) return 'device';
    for (final node in provider.activeTopology?.nodes ?? const <DeviceNode>[]) {
      if (node.nodeId == nodeId) return node.label;
    }
    return 'device';
  }

  void _handlePortClick(
    TopologyProvider provider,
    String nodeId,
    String portName,
  ) {
    if (_connectSourceNodeId == null) {
      setState(() {
        _connectSourceNodeId = nodeId;
        _connectSourcePort = portName;
      });
      if (!mounted) return;
      AppNotifier.info(
        context,
        'Start port selected. Now click a port on another device to run '
        'the cable.',
      );
    } else if (_connectSourceNodeId == nodeId) {
      setState(() {
        _connectSourceNodeId = null;
        _connectSourcePort = null;
      });
    } else {
      final edge = CableEdge(
        edgeId: 'edge_${DateTime.now().millisecondsSinceEpoch}',
        sourceNodeId: _connectSourceNodeId!,
        sourceInterface: _connectSourcePort ?? 'eth0',
        targetNodeId: nodeId,
        targetInterface: portName,
        cableType: _selectedCableType,
      );

      provider.addCableEdge(edge);

      if (!mounted) return;
      // Labels, not raw node ids — "node_1734..." meant nothing to anyone.
      final sourceLabel = _labelForNode(provider, _connectSourceNodeId);
      final targetLabel = _labelForNode(provider, nodeId);
      AppNotifier.success(
        context,
        '$sourceLabel connected to $targetLabel with a $_selectedCableType '
        'cable.',
      );

      setState(() {
        _connectSourceNodeId = null;
        _connectSourcePort = null;
      });
    }
  }

  void _addDeviceToCanvas(
    TopologyProvider provider,
    DeviceType type,
    String model,
  ) {
    final existingNodes = provider.activeTopology?.nodes ?? [];
    final count = existingNodes.length + 1;

    // Arrange nodes neatly side-by-side in rows of 5
    final col = (count - 1) % 5;
    final row = (count - 1) ~/ 5;

    final startX = 120.0 + (col * 160.0);
    final startY = 120.0 + (row * 160.0);

    final newNode = DeviceNode(
      nodeId: 'node_${DateTime.now().millisecondsSinceEpoch}',
      label: _defaultLabelFor(type, existingNodes),
      type: type,
      model: model,
      position: Position(x: startX, y: startY),
      interfaces: _defaultInterfacesFor(type),
    );

    provider.addDeviceNode(newNode);
  }

  /// Port count per device type.
  ///
  /// Interfaces deliberately start with NO IP address. Addressing is the thing
  /// the student is being taught, so pre-filling 192.168.1.x would hand them
  /// the answer to most of the addressing levels (and quietly put every device
  /// on the same subnet, which made unrelated levels pass by accident).
  static List<InterfaceConfig> _defaultInterfacesFor(DeviceType type) {
    final portCount = switch (type) {
      DeviceType.pc => 1,
      DeviceType.server => 1,
      DeviceType.router => 2,
      DeviceType.firewall => 2,
      DeviceType.switchDevice => 4,
      DeviceType.cloud => 1,
    };

    return List.generate(portCount, (i) => InterfaceConfig(name: 'eth$i'));
  }

  /// Human-friendly, per-type sequential name: PC1, PC2, Router1, ...
  /// Level criteria refer to devices by these labels, so they must be stable
  /// and predictable rather than based on total node count.
  static String _defaultLabelFor(DeviceType type, List<DeviceNode> existing) {
    final prefix = switch (type) {
      DeviceType.pc => 'PC',
      DeviceType.server => 'Server',
      DeviceType.router => 'Router',
      DeviceType.switchDevice => 'Switch',
      DeviceType.firewall => 'Firewall',
      DeviceType.cloud => 'Cloud',
    };

    final sameType = existing.where((n) => n.type == type).length;
    return '$prefix${sameType + 1}';
  }

  void _handleCableConnectionDialog(TopologyProvider provider) {
    final nodes = provider.activeTopology?.nodes ?? [];
    if (nodes.length < 2) {
      AppNotifier.info(
        context,
        'Place at least two devices before running a cable between them.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String sourceId = nodes.first.nodeId;
        String targetId = nodes.length > 1
            ? nodes[1].nodeId
            : nodes.first.nodeId;
        String cableType = _selectedCableType;

        return AlertDialog(
          backgroundColor: AppTheme.surfaceGlass,
          title: const Text(
            'Add Cable Connection',
            style: TextStyle(color: AppTheme.textBright),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: sourceId,
                decoration: const InputDecoration(labelText: 'Source Node'),
                items: nodes
                    .map(
                      (n) => DropdownMenuItem(
                        value: n.nodeId,
                        child: Text(n.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) => sourceId = val!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: targetId,
                decoration: const InputDecoration(labelText: 'Target Node'),
                items: nodes
                    .map(
                      (n) => DropdownMenuItem(
                        value: n.nodeId,
                        child: Text(n.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) => targetId = val!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: cableType,
                decoration: const InputDecoration(
                  labelText: 'Cable Medium Type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Ethernet',
                    child: Text('Ethernet (Copper)'),
                  ),
                  DropdownMenuItem(
                    value: 'Fiber',
                    child: Text('Fiber (Optical)'),
                  ),
                  DropdownMenuItem(
                    value: 'Serial',
                    child: Text('Serial (WAN Link)'),
                  ),
                ],
                onChanged: (val) => cableType = val!,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final edge = CableEdge(
                  edgeId: 'edge_${DateTime.now().millisecondsSinceEpoch}',
                  sourceNodeId: sourceId,
                  sourceInterface: 'eth0',
                  targetNodeId: targetId,
                  targetInterface: 'eth0',
                  cableType: cableType,
                );

                provider.addCableEdge(edge);
                Navigator.pop(context);
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.router:
        return Icons.router;
      case DeviceType.switchDevice:
        return Icons.swap_horiz;
      case DeviceType.firewall:
        return Icons.security;
      case DeviceType.pc:
        return Icons.desktop_windows;
      case DeviceType.server:
        return Icons.dns;
      case DeviceType.cloud:
        return Icons.cloud_queue;
    }
  }

  Color _getDeviceColor(DeviceType type) {
    switch (type) {
      case DeviceType.router:
        return AppTheme.primaryCyan;
      case DeviceType.switchDevice:
        return AppTheme.primaryBlue;
      case DeviceType.firewall:
        return AppTheme.accentCrimson;
      case DeviceType.pc:
        return AppTheme.accentEmerald;
      case DeviceType.server:
        return Colors.purpleAccent;
      case DeviceType.cloud:
        return Colors.amber;
    }
  }
}
