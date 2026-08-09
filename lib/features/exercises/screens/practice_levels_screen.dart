import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../data/repositories/grading_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/progress_provider.dart';
import '../../topology/providers/grading_provider.dart';

/// Free Practice Skill Progression body content (Levels 1 to N).
///
/// Levels are lecturer-authored `exercises` documents with `practiceLevel`
/// set (published via the lecturer's Exercise Authoring tab), not a
/// hardcoded list — a level only appears here once someone has actually
/// published it with a solution key for the grader to check against.
///
/// Deliberately has no Scaffold/AppBar of its own: this renders as a tab
/// body inside `DashboardLayout` (see dashboard_layout.dart), the same shell
/// every other dashboard section uses. It used to be routed to directly as
/// `/practice-levels` with its own bare Scaffold, which meant no sidebar and
/// no working back button — `context.go` replaces navigation history, so
/// there was nothing for an AppBar back arrow to pop to. The old route path
/// still resolves (see app_routes.dart) but now opens this same shell on
/// this tab, rather than that orphaned page.
class PracticeLevelsScreen extends StatefulWidget {
  const PracticeLevelsScreen({super.key});

  /// How many tries this level has taken — the figure shown on every level
  /// card. Public and static so the dashboard's practice grid renders exactly
  /// the same wording as this screen.
  static String attemptSummary(ExerciseProgress progress) {
    if (progress.passed) {
      final used = progress.attemptsUsed ?? progress.attemptCount;
      return used <= 1 ? 'Solved on the first try' : 'Solved in $used attempts';
    }
    if (progress.attemptCount == 0) return 'Not attempted yet';
    return '${progress.attemptCount} attempt'
        '${progress.attemptCount == 1 ? '' : 's'} so far';
  }

  /// The canvas document a student's attempt at [level] lives in. One place
  /// so the level list, the dashboard grid and the replay flow can't drift
  /// apart on the naming.
  static String topologyIdForLevel({required int level, required String uid}) =>
      'practice_level_${level}_$uid';

  /// Confirms, then wipes a solved level and reopens it so the student can
  /// build it again and earn the points again.
  ///
  /// Confirmed first because it throws away whatever they built: the canvas
  /// is emptied on purpose, since re-earning the points is supposed to mean
  /// re-doing the work rather than pressing Check on a finished network.
  ///
  /// Public and static so the Dashboard Hub's grid runs exactly this flow
  /// rather than its own near-copy of it.
  static Future<void> confirmAndReplay(
    BuildContext context, {
    required String exerciseId,
    required int level,
    required String uid,
    required String title,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGlass,
        title: Row(
          children: [
            const Icon(Icons.refresh, color: AppTheme.primaryCyan),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Replay "$title"?',
                style: const TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Text(
            'This clears your canvas for this level and marks it unsolved, '
            'so you can build it again and earn '
            '${GradingProvider.pointsForPass} points.\n\n'
            'Whatever you have built here will be removed.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Clear and replay'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final grading = Provider.of<GradingProvider>(context, listen: false);
    final topologyId = topologyIdForLevel(level: level, uid: uid);

    final ok = await grading.resetLevel(
      uid: uid,
      exerciseId: exerciseId,
      topologyId: topologyId,
      ownerUid: uid,
    );

    if (!context.mounted) return;

    if (!ok) {
      AppNotifier.error(
        context,
        grading.errorMessage ?? 'Could not reset this level.',
      );
      return;
    }

    AppNotifier.info(
      context,
      'Canvas cleared. Build it again to earn '
      '${GradingProvider.pointsForPass} points.',
    );
    context.go(
      '/canvas-builder/$topologyId?exerciseId=$exerciseId&practiceLevel=$level',
    );
  }

  @override
  State<PracticeLevelsScreen> createState() => _PracticeLevelsScreenState();
}

class _PracticeLevelsScreenState extends State<PracticeLevelsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  // On a hard page reload, AuthProvider starts with currentUser == null and
  // isLoading == true — the router's redirect guard explicitly lets loading
  // routes through rather than blocking on it, so this screen can mount
  // before Firebase Auth has actually resolved a user. initState only runs
  // once, so reading currentUser?.uid there was a one-shot check against a
  // value that was still null at that exact instant: watchProgress never
  // got called, and nothing ever retried it, so every level looked
  // permanently un-attempted for the rest of that session even after auth
  // resolved a moment later. (isUnlocked didn't show this because build()
  // reads currentUser fresh on every rebuild.)
  //
  // didChangeDependencies fires whenever an inherited value this widget
  // depends on changes — including AuthProvider, which build() listens to
  // via Provider.of(context) — so this re-runs once currentUser actually
  // becomes available. watchProgress's own `_watchedUid == uid` guard makes
  // repeat calls here a no-op once subscribed.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  void _ensureDataLoaded() {
    if (!mounted) return;

    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    if (exerciseProvider.practiceLevels.isEmpty &&
        !exerciseProvider.isLoading) {
      exerciseProvider.fetchPracticeLevels();
    }

    final uid = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.uid;
    if (uid != null) {
      Provider.of<ProgressProvider>(
        context,
        listen: false,
      ).watchProgress(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Container(
      color: AppTheme.backgroundMidnight,
      child: Consumer2<ExerciseProvider, ProgressProvider>(
        builder: (context, exerciseProvider, progressProvider, _) {
          if (exerciseProvider.isLoading) {
            return _buildLevelSkeletonList();
          }

          // A fetch failure (missing Firestore index, rules, network) and a
          // genuinely empty collection used to render identically — "No
          // practice levels published yet" either way — so a real backend
          // error was indistinguishable from "the database is just empty."
          if (exerciseProvider.errorMessage != null) {
            return _buildErrorState(context, exerciseProvider.errorMessage!);
          }

          final levels = exerciseProvider.practiceLevels;

          if (levels.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No practice levels have been published yet. '
                  'Check back once your lecturer publishes one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            );
          }

          final currentLevel = user?.freePracticeLevel ?? 1;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: levels.map((exercise) {
              final level = exercise.practiceLevel ?? 1;
              return _buildLevelTile(
                context,
                level: level,
                title: exercise.title,
                description: exercise.description,
                isUnlocked: GradingProvider.canEnterLevel(
                  level: level,
                  freePracticeLevel: currentLevel,
                  points: user?.points ?? 0,
                ),
                needsPoints:
                    currentLevel >= level &&
                    (user?.points ?? 0) <
                        GradingProvider.pointsToUnlockLevel,
                progress: progressProvider.progressFor(exercise.exerciseId),
                onTap: () {
                  final uid = user?.uid;
                  if (uid == null) return;

                  // A solved level reopens by starting over: without the
                  // reset, tapping back in just shows the finished network,
                  // and re-checking it is worth nothing.
                  if (progressProvider
                      .progressFor(exercise.exerciseId)
                      .passed) {
                    PracticeLevelsScreen.confirmAndReplay(
                      context,
                      exerciseId: exercise.exerciseId,
                      level: level,
                      uid: uid,
                      title: exercise.title,
                    );
                    return;
                  }

                  _openLevel(
                    exerciseId: exercise.exerciseId,
                    level: level,
                    uid: uid,
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// Three level-card-shaped placeholders — enough to read as "a list is
  /// coming" without committing to how many levels actually exist.
  Widget _buildLevelSkeletonList() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: List.generate(3, (i) => _buildLevelCardSkeleton()),
    );
  }

  Widget _buildLevelCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 160, height: 16),
                    const SizedBox(height: 10),
                    SkeletonBox(
                      width: double.infinity,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    const SkeletonBox(width: 220, height: 12),
                    const SizedBox(height: 10),
                    const SkeletonBox(width: 130, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.accentCrimson,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Couldn\'t load practice levels',
              style: const TextStyle(
                color: AppTheme.textBright,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => Provider.of<ExerciseProvider>(
                context,
                listen: false,
              ).fetchPracticeLevels(),
            ),
          ],
        ),
      ),
    );
  }

  void _openLevel({
    required String exerciseId,
    required int level,
    required String? uid,
  }) {
    if (uid == null) return;
    context.go(
      '/canvas-builder/practice_level_${level}_$uid'
      '?exerciseId=$exerciseId&practiceLevel=$level',
    );
  }

  Widget _buildLevelTile(
    BuildContext context, {
    required int level,
    required String title,
    required String description,
    required bool isUnlocked,
    required ExerciseProgress progress,
    required VoidCallback onTap,
    bool needsPoints = false,
  }) {
    final isPassed = progress.passed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor:
                (isPassed
                        ? AppTheme.accentEmerald
                        : isUnlocked
                        ? AppTheme.primaryCyan
                        : AppTheme.textMuted)
                    .withValues(alpha: 0.2),
            child: Icon(
              isPassed
                  ? Icons.check
                  : isUnlocked
                  ? Icons.play_arrow
                  : Icons.lock,
              color: isPassed
                  ? AppTheme.accentEmerald
                  : isUnlocked
                  ? AppTheme.primaryCyan
                  : AppTheme.textMuted,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carries the level number on its own line: the seeded titles
              // are the bare topic ("Connect Two PCs") so the number isn't
              // repeated in the title text itself.
              Text(
                'LEVEL $level',
                style: TextStyle(
                  color: isUnlocked ? AppTheme.primaryCyan : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: isUnlocked ? AppTheme.textBright : AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              if (isUnlocked) ...[
                const SizedBox(height: 6),
                Text(
                  isPassed
                      ? '${PracticeLevelsScreen.attemptSummary(progress)} — '
                            'tap to replay for '
                            '${GradingProvider.pointsForPass} points'
                      : PracticeLevelsScreen.attemptSummary(progress),
                  style: TextStyle(
                    color: isPassed
                        ? AppTheme.accentEmerald
                        : AppTheme.primaryCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else if (needsPoints) ...[
                const SizedBox(height: 6),
                Text(
                  'You have reached this level — you just need '
                  '${GradingProvider.pointsToUnlockLevel} points to open it. '
                  'Solve an earlier level to earn some.',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          trailing: isUnlocked
              ? Icon(
                  isPassed ? Icons.refresh : Icons.arrow_forward,
                  color: isPassed
                      ? AppTheme.accentEmerald
                      : AppTheme.primaryCyan,
                )
              : null,
          onTap: isUnlocked ? onTap : null,
        ),
      ),
    );
  }
}
