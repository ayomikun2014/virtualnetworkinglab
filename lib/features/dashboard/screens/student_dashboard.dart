import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/constants/available_courses.dart';
import '../../../core/services/invite_code_service.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/grading_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exercises/providers/exercise_provider.dart';
import '../../exercises/providers/progress_provider.dart';
import '../../exercises/providers/save_history_provider.dart';
import '../../exercises/screens/practice_levels_screen.dart';
import '../../topology/providers/grading_provider.dart';
import '../models/student_stats.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/stat_card.dart';

/// Student Laboratory Hub Entrypoint Screen
class StudentDashboard extends StatelessWidget {
  /// Which tab to open on ('/student-dashboard?tab=1' etc.) — lets callers
  /// like the canvas's post-pass dialog land the student back on the
  /// Courses Lab tab specifically, rather than always
  /// resetting to Dashboard Hub.
  final int initialTabIndex;

  const StudentDashboard({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(initialTabIndex: initialTabIndex);
  }
}

/// Tab 0: Dashboard Home View with User Header, 3 Mini Stats, Practice Grid & Sandbox Bar
class DashboardHomeView extends StatefulWidget {
  final UserModel? user;

  const DashboardHomeView({super.key, this.user});

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  /// So a null-user run (see below) doesn't also re-trigger the practice
  /// levels/course assessments fetch every time dependencies change.
  bool _hasFetchedExercises = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  // Same fix as PracticeLevelsScreen, same root cause: on a hard reload,
  // AuthProvider starts with currentUser == null while it resolves in the
  // background, and the router lets a loading route through rather than
  // blocking on it. initState only runs once, so a one-shot null-user check
  // here meant watchProgress and fetchCourseAssessments(user's enrolled
  // courses) silently ran with no user — the latter got called with `[]`
  // and, per its own early-return, just cleared course assessments and
  // never retried. didChangeDependencies re-runs this once currentUser is
  // actually populated.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  Future<void> _ensureDataLoaded() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exercises = Provider.of<ExerciseProvider>(context, listen: false);
    final user = widget.user ?? auth.currentUser;
    if (user == null) return;

    Provider.of<ProgressProvider>(
      context,
      listen: false,
    ).watchProgress(user.uid);

    if (_hasFetchedExercises) return;
    _hasFetchedExercises = true;

    // Awaited in sequence, not fired together: both calls drive the same
    // `isLoading`/`errorMessage` fields on ExerciseProvider, so running
    // them concurrently lets whichever finishes first clear the loading
    // flag (and any error) while the other is still in flight.
    await exercises.fetchPracticeLevels();
    if (!mounted) return;

    // The stats grid counts assessments alongside practice levels, so the
    // home tab has to load them too — it previously fetched only practice
    // levels, which would have under-reported "Networks Built X / Y".
    await exercises.fetchCourseAssessments(user.enrolledCourseIds ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = widget.user ?? authProvider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 16 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Identity banner
          _buildHeaderBanner(currentUser),
          const SizedBox(height: 24),

          // 2. Live Stats Grid — every figure derived from real grader
          // records via ProgressProvider, and rebuilt as they change.
          Consumer2<ExerciseProvider, ProgressProvider>(
            builder: (context, exerciseProvider, progressProvider, _) {
              final stats = StudentStats.from(
                exerciseIds: [
                  ...exerciseProvider.practiceLevels.map((e) => e.exerciseId),
                  ...exerciseProvider.courseAssessments.map(
                    (e) => e.exerciseId,
                  ),
                ],
                progressByExerciseId: progressProvider.progressByExerciseId,
                practiceLevel: currentUser?.freePracticeLevel ?? 1,
              );

              return _buildStatsGrid(stats, currentUser?.points ?? 0);
            },
          ),
          const SizedBox(height: 28),

          // 3. Primary Action Bar (Glowing Sandbox Launcher)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceGlass,
                  AppTheme.primaryCyan.withValues(alpha: 0.12),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryCyan.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, launcherConstraints) {
                final isNarrowLauncher = launcherConstraints.maxWidth < 650;

                final textColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sandbox Topology Canvas',
                      style: TextStyle(
                        color: AppTheme.textBright,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Design custom networks, test router interfaces, and simulate packet pinging in real time.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                );

                // Join Class used to sit here too. It belongs with the
                // courses it affects — enrolling is what populates the
                // Courses Lab tab — not next to the sandbox launcher, which
                // has nothing to do with enrolment.
                final actionButtons = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.architecture, size: 20),
                      label: const Text('Open Sandbox'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () {
                        final uid = currentUser?.uid ?? 'demo';
                        context.go('/canvas-builder/sandbox_$uid');
                      },
                    ),
                  ],
                );

                if (isNarrowLauncher) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textColumn,
                      const SizedBox(height: 20),
                      actionButtons,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: textColumn),
                    const SizedBox(width: 16),
                    actionButtons,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // 4. Free Practice Progression Grid — real published levels.
          //
          // Reads the same Firestore-backed level list and per-level attempt
          // counts as the Free Practice screen. It previously rendered four
          // hardcoded cards with invented progress bars (0.6 / 0.2 / 0.1),
          // which no longer matches anything the grader records.
          Consumer2<ExerciseProvider, ProgressProvider>(
            builder: (context, exerciseProvider, progressProvider, _) {
              final levels = exerciseProvider.practiceLevels;
              final userLevel = currentUser?.freePracticeLevel ?? 1;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Free Practice Progression',
                          style: TextStyle(
                            color: AppTheme.textBright,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${levels.length} Level${levels.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (exerciseProvider.isLoading)
                    _buildPracticeGridSkeleton()
                  else if (exerciseProvider.errorMessage != null)
                    // Distinguish "fetch actually failed" from "the
                    // collection is genuinely empty" — they used to render
                    // as the identical "no levels published" message.
                    Container(
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
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              exerciseProvider.errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: exerciseProvider.fetchPracticeLevels,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (levels.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGlass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: const Text(
                        'No practice levels published yet.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
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
                          // 1.5 made a 227px-wide card only 140px tall, which
                          // is 24px short of its own content: the Start
                          // Practice button was laid out past the bottom edge
                          // and clipped, so tapping where it appeared to be
                          // hit nothing at all.
                          childAspectRatio: 1.15,
                          children: levels.map((exercise) {
                            final level = exercise.practiceLevel ?? 1;
                            return _buildPracticeCard(
                              context,
                              level: level,
                              title: exercise.title,
                              description: exercise.description,
                              exerciseId: exercise.exerciseId,
                              uid: currentUser?.uid,
                              progress: progressProvider.progressFor(
                                exercise.exerciseId,
                              ),
                              isUnlocked: GradingProvider.canEnterLevel(
                                level: level,
                                freePracticeLevel: userLevel,
                                points: currentUser?.points ?? 0,
                              ),
                              needsPoints:
                                  userLevel >= level &&
                                  (currentUser?.points ?? 0) <
                                      GradingProvider.pointsToUnlockLevel,
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Initials for the avatar — friendlier and more personal than the
  /// generic person glyph this replaced.
  static String _initialsOf(String? displayName) {
    final parts = (displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildHeaderBanner(UserModel? user) {
    final firstName = (user?.displayName ?? '').trim().split(RegExp(r'\s+')).first;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryCyan.withValues(alpha: 0.16),
            AppTheme.primaryBlue.withValues(alpha: 0.10),
            AppTheme.surfaceGlass.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.25)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;

          final avatar = Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryCyan, AppTheme.primaryBlue],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initialsOf(user?.displayName),
              style: const TextStyle(
                color: AppTheme.backgroundMidnight,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          final identity = Column(
            crossAxisAlignment: isNarrow
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                firstName.isEmpty
                    ? _greeting()
                    : '${_greeting()}, $firstName',
                textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.displayName ?? 'Student',
                textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: isNarrow ? WrapAlignment.center : WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((user?.studentIdNumber ?? '').isNotEmpty)
                    _headerChip(
                      Icons.badge_outlined,
                      user!.studentIdNumber!,
                      AppTheme.primaryCyan,
                    ),
                  if ((user?.departmentId ?? '').isNotEmpty)
                    _headerChip(
                      Icons.school_outlined,
                      user!.departmentId,
                      AppTheme.primaryBlue,
                    ),
                  if ((user?.email ?? '').isNotEmpty)
                    _headerChip(
                      Icons.mail_outline,
                      user!.email,
                      AppTheme.textMuted,
                    ),
                ],
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              children: [
                avatar,
                const SizedBox(height: 14),
                identity,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 18),
              Expanded(child: identity),
            ],
          );
        },
      ),
    );
  }

  Widget _headerChip(IconData icon, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMidnight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent == AppTheme.textMuted
                  ? AppTheme.textMuted
                  : AppTheme.textBright,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Four live figures, reflowing 4-up → 2-up → stacked.
  Widget _buildStatsGrid(StudentStats stats, int points) {
    final successRate = stats.successRate;

    final cards = <Widget>[
      // "Network", not "lab", throughout this grid. A student here connects
      // PCs, switches and routers — calling each one a "lab" three times in
      // four captions was both repetitive and a word for the room they'd be
      // sitting in, not for the thing they just built.
      StatCard(
        label: 'Networks Built',
        value: '${stats.completedExercises} / ${stats.totalExercises}',
        icon: Icons.task_alt,
        accent: AppTheme.accentEmerald,
        progress: stats.completionRate,
        caption: stats.totalExercises == 0
            ? 'Nothing published yet'
            : '${(stats.completionRate * 100).round()}% of everything '
                  'available',
      ),
      StatCard(
        label: 'Success Rate',
        // '—' rather than 0%: a student who hasn't tried anything hasn't
        // failed anything either, and 0% reads like a judgement.
        value: successRate == null
            ? '—'
            : '${(successRate * 100).round()}%',
        icon: Icons.trending_up,
        accent: AppTheme.primaryCyan,
        caption: stats.attemptedExercises == 0
            ? 'Build your first network to begin'
            : 'of ${stats.attemptedExercises} network'
                  '${stats.attemptedExercises == 1 ? '' : 's'} you have tried',
      ),
      StatCard(
        // Was "Total Attempts", which counted every press of Check
        // Connection — a number that only ever went up, and went up fastest
        // for whoever was struggling most.
        label: 'Total Score',
        value: '$points',
        icon: Icons.stars,
        accent: AppTheme.primaryBlue,
        caption: points < GradingProvider.pointsToUnlockLevel
            ? 'Earn ${GradingProvider.pointsToUnlockLevel} to open the next '
                  'level'
            : '+${GradingProvider.pointsForPass} per network solved, '
                  '−${GradingProvider.pointsForFail} per failed check',
      ),
      StatCard(
        label: 'Practice Level',
        value: 'Level ${stats.practiceLevel}',
        icon: Icons.auto_awesome,
        accent: Colors.purpleAccent,
        caption: stats.firstTrySolves > 0
            ? '${stats.firstTrySolves} first-try solve'
                  '${stats.firstTrySolves == 1 ? '' : 's'}'
            : 'Unlocks as you pass levels',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 520
            ? 2
            : 1;

        if (columns == 1) {
          return Column(
            children: [
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card,
                ),
            ],
          );
        }

        const gap = 12.0;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }

  /// Card-shaped placeholders matching _buildPracticeCard's proportions, so
  /// loading doesn't pop straight from a spinner into a 4-up grid.
  Widget _buildPracticeGridSkeleton() {
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
          // Kept in step with the real grid's ratio above, so the skeleton
          // doesn't resize the section the moment the levels land.
          childAspectRatio: 1.15,
          children: List.generate(crossAxisCount, (i) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGlass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SkeletonBox(
                    width: 70,
                    height: 20,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  const SkeletonBox(width: 140, height: 14),
                  SkeletonBox(
                    width: double.infinity,
                    height: 11,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SkeletonBox(
                    width: double.infinity,
                    height: 4,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                  SkeletonBox(
                    width: double.infinity,
                    height: 32,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPracticeCard(
    BuildContext context, {
    required int level,
    required String title,
    required String description,
    required String exerciseId,
    required String? uid,
    required ExerciseProgress progress,
    required bool isUnlocked,
    bool needsPoints = false,
  }) {
    final isPassed = progress.passed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.primaryCyan.withValues(alpha: 0.3)
              : AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (isUnlocked ? AppTheme.primaryCyan : AppTheme.textMuted)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  // This badge is the only place the level number appears on
                  // a card — the seeded titles are the bare topic ("Connect
                  // Two PCs"), deliberately not prefixed "Level N:", which is
                  // what used to make every card say "Level" twice.
                  'LEVEL $level',
                  style: TextStyle(
                    color: isUnlocked
                        ? AppTheme.primaryCyan
                        : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Keyed on completion, not on `isUnlocked` — that showed a
              // green "done" tick on every playable level the moment it
              // unlocked, including ones never attempted. An unlocked but
              // unfinished level gets no badge at all: the status line and
              // the Start Practice button below already say where it stands.
              if (isPassed)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentEmerald,
                  size: 20,
                )
              else if (!isUnlocked)
                const Icon(
                  Icons.lock_outline,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isUnlocked ? AppTheme.textBright : AppTheme.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          // Flexible so the briefs — which run to a few sentences now that
          // they explain the networking concept, not just the build steps —
          // give up lines rather than overflowing the card at narrow widths.
          Flexible(
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          if (isUnlocked)
            Text(
              PracticeLevelsScreen.attemptSummary(progress),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isPassed ? AppTheme.accentEmerald : AppTheme.primaryCyan,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              // Opens this level's own canvas. Every card used to send the
              // student to '/student-dashboard?tab=3' instead — the same URL
              // for every level, carrying no exerciseId — so tapping Level 1
              // and Level 2 did the identical thing and never reached a
              // canvas at all. The exerciseId is threaded through so the
              // grader's "Check Connection" button appears, exactly as it
              // does when the level is opened from the Free Practice tab.
              onPressed: isUnlocked && uid != null
                  ? () {
                      // A solved level starts over rather than reopening the
                      // finished network — that is what makes its points
                      // earnable again. Same flow the Free Practice list
                      // uses, confirmation dialog included.
                      if (isPassed) {
                        PracticeLevelsScreen.confirmAndReplay(
                          context,
                          exerciseId: exerciseId,
                          level: level,
                          uid: uid,
                          title: title,
                        );
                        return;
                      }
                      context.go(
                        '/canvas-builder/'
                        '${PracticeLevelsScreen.topologyIdForLevel(level: level, uid: uid)}'
                        '?exerciseId=$exerciseId&practiceLevel=$level',
                      );
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(
                  color: isUnlocked ? AppTheme.primaryCyan : AppTheme.textMuted,
                ),
              ),
              child: Text(
                isUnlocked
                    ? (isPassed
                          ? 'Replay +${GradingProvider.pointsForPass}'
                          : 'Start Practice')
                    : needsPoints
                    // Distinguishes "you haven't got there yet" from "you
                    // have, but you're out of points" — otherwise a level
                    // the student just unlocked reads as still locked with
                    // no hint that the fix is to go and earn points.
                    ? 'Need ${GradingProvider.pointsToUnlockLevel} points'
                    : 'Locked',
                style: TextStyle(
                  color: isUnlocked ? AppTheme.primaryCyan : AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One enrolled course and the (possibly empty) list of published
/// assessments under it — what each course card on the assessments list
/// summarises, and what filters down to a single course's assignment list
/// once tapped.
class _CourseGroup {
  final String courseId;
  final String courseTitle;
  final List<ExerciseModel> assessments;

  const _CourseGroup({
    required this.courseId,
    required this.courseTitle,
    required this.assessments,
  });
}

/// Tab 2: Lecturer Assignments View
///
/// Lists the student's enrolled courses; tapping one drills into that
/// course's published assessments (a lecturer publishes these via the class
/// join code). An assessment locks once passed — the student can still
/// review it, but it no longer counts as outstanding work.
class CoursesLabView extends StatefulWidget {
  const CoursesLabView({super.key});

  @override
  State<CoursesLabView> createState() =>
      _CoursesLabViewState();
}

class _CoursesLabViewState extends State<CoursesLabView> {
  /// null shows the course list; set to a course id to drill into that
  /// course's assessments.
  String? _selectedCourseId;

  bool _hasFetchedAssessments = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  // Same reload race as the other dashboard views: initState can run before
  // AuthProvider has resolved a real user, so it's re-attempted whenever
  // dependencies change (i.e. once AuthProvider actually notifies).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  void _ensureDataLoaded() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    Provider.of<ProgressProvider>(
      context,
      listen: false,
    ).watchProgress(user.uid);

    if (_hasFetchedAssessments) return;
    _hasFetchedAssessments = true;
    Provider.of<ExerciseProvider>(
      context,
      listen: false,
    ).fetchCourseAssessments(user.enrolledCourseIds ?? const []);
  }

  void _showJoinClassDialog(BuildContext context, String studentUid) {
    final codeController = TextEditingController();
    final inviteCodeService = InviteCodeService();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceGlass,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              title: Row(
                children: const [
                  Icon(Icons.group_add, color: AppTheme.primaryCyan),
                  SizedBox(width: 10),
                  Text(
                    'Join a Course',
                    style: TextStyle(color: AppTheme.textBright, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The code IS the course code a lecturer was assigned by
                    // an admin — not a separately generated join code, so
                    // there's nothing to ask a lecturer for beyond the code
                    // they were already given.
                    const Text(
                      'Enter the course code your lecturer gave you (e.g. NET101):',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        color: AppTheme.primaryCyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Course Code',
                        hintText: 'NET101',
                        prefixIcon: Icon(
                          Icons.vpn_key,
                          color: AppTheme.primaryCyan,
                        ),
                      ),
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
                ElevatedButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.backgroundMidnight,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Join Course'),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.isEmpty) return;

                          setModalState(() => isSubmitting = true);

                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final result = await inviteCodeService
                              .redeemCourseCode(
                                code: code,
                                studentUid: studentUid,
                                currentlyEnrolled:
                                    authProvider.currentUser?.enrolledCourseIds ??
                                    const [],
                              );

                          if (!context.mounted) return;

                          if (result.success) {
                            Navigator.pop(context);
                            AppNotifier.success(
                              context,
                              'Joined ${result.courseTitle}. Its assessments '
                              'are in your Courses Lab now.',
                            );
                            await authProvider.refreshCurrentUserProfile();
                          } else if (result.alreadyEnrolled) {
                            Navigator.pop(context);
                            AppNotifier.info(
                              context,
                              "You're already enrolled in that course.",
                            );
                          } else {
                            setModalState(() => isSubmitting = false);
                            AppNotifier.error(
                              context,
                              result.errorMessage ?? 'Could not join that course.',
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final enrolledCourseIds = user?.enrolledCourseIds ?? const [];

    return Consumer2<ExerciseProvider, ProgressProvider>(
      builder: (context, exerciseProvider, progressProvider, _) {
        // Selection can go stale if enrollment changes underneath it (rare,
        // but cheap to guard) — fall back to the course list rather than
        // rendering a drill-down for a course the student no longer has.
        final selectedCourseId = enrolledCourseIds.contains(_selectedCourseId)
            ? _selectedCourseId
            : null;

        final courseGroups = enrolledCourseIds.map((courseId) {
          final assessments = exerciseProvider.courseAssessments
              .where((e) => e.categoryId == courseId)
              .toList();
          return _CourseGroup(
            courseId: courseId,
            // The lecturer's own courseTitle, denormalised onto their
            // exercises, is the real source now that courses are whatever
            // an admin assigned a lecturer — not a fixed catalogue every
            // course code was guaranteed to appear in.
            courseTitle: assessments.isNotEmpty
                ? assessments.first.courseTitle
                : _titleForCourse(courseId),
            assessments: assessments,
          );
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (selectedCourseId != null) ...[
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textBright,
                    ),
                    onPressed: () => setState(() => _selectedCourseId = null),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _titleForCourse(selectedCourseId),
                      style: const TextStyle(
                        color: AppTheme.textBright,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Practical assessments for $selectedCourseId.',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ] else ...[
              // Join Class lives here rather than on the dashboard: entering
              // a code is what adds a course to this very list, so the
              // action and its result are now in the same place.
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Courses Lab',
                      style: TextStyle(
                        color: AppTheme.textBright,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(
                      Icons.group_add,
                      size: 18,
                      color: AppTheme.primaryCyan,
                    ),
                    label: const Text(
                      'Join Class',
                      style: TextStyle(color: AppTheme.primaryCyan),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryCyan),
                    ),
                    onPressed: () => _showJoinClassDialog(
                      context,
                      user?.uid ?? 'demo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Your enrolled courses. Tap one to see its assignments.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),

            if (exerciseProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryCyan),
                ),
              )
            else if (exerciseProvider.errorMessage != null)
              _buildEmptyState(
                icon: Icons.error_outline,
                message: exerciseProvider.errorMessage!,
                onRetry: () => exerciseProvider.fetchCourseAssessments(
                  enrolledCourseIds,
                ),
              )
            else if (enrolledCourseIds.isEmpty)
              _buildEmptyState(
                icon: Icons.group_add,
                message:
                    'You are not enrolled in any course yet. Use the Join '
                    'Class button above with the code your lecturer gave '
                    'you.',
              )
            else if (selectedCourseId == null)
              ...courseGroups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCourseCard(
                    group: group,
                    progressProvider: progressProvider,
                    onTap: () =>
                        setState(() => _selectedCourseId = group.courseId),
                  ),
                ),
              )
            else if (courseGroups
                .firstWhere((g) => g.courseId == selectedCourseId)
                .assessments
                .isEmpty)
              _buildEmptyState(
                icon: Icons.assignment_outlined,
                message: 'No assessments have been published for this course yet.',
              )
            else
              ...courseGroups
                  .firstWhere((g) => g.courseId == selectedCourseId)
                  .assessments
                  .map((exercise) {
                    final progress = progressProvider.progressFor(
                      exercise.exerciseId,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildAssignmentCard(
                        context,
                        exercise: exercise,
                        progress: progress,
                        uid: user?.uid,
                      ),
                    );
                  }),
          ],
        );
      },
    );
  }

  /// Looks the course up in the shared course catalogue for a display
  /// title, falling back to the raw id for a course not in that list (e.g.
  /// one only a class doc references) rather than showing nothing.
  static String _titleForCourse(String courseId) {
    final match = kAvailableCourses.where((c) => c.code == courseId);
    return match.isEmpty ? courseId : match.first.label;
  }

  Widget _buildCourseCard({
    required _CourseGroup group,
    required ProgressProvider progressProvider,
    required VoidCallback onTap,
  }) {
    final total = group.assessments.length;
    final passed = group.assessments
        .where((e) => progressProvider.progressFor(e.exerciseId).passed)
        .length;

    return Material(
      color: AppTheme.surfaceGlass,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: AppTheme.primaryCyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.courseTitle,
                      style: const TextStyle(
                        color: AppTheme.textBright,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'No assessments published yet'
                          : '$passed / $total assessment${total == 1 ? '' : 's'} complete',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppTheme.primaryCyan),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onRetry != null
              ? AppTheme.accentCrimson.withValues(alpha: 0.4)
              : AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: onRetry != null
                ? AppTheme.accentCrimson
                : AppTheme.textMuted,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context, {
    required ExerciseModel exercise,
    required ExerciseProgress progress,
    required String? uid,
  }) {
    // A course assessment gets exactly one attempt — locked the moment
    // attemptCount > 0, whether or not it passed. Free Practice locks only
    // on a pass because re-attempting there is how the points economy
    // works; a course assessment has no such economy, so "attempted" and
    // "done" are the same thing.
    final isSubmitted = progress.attemptCount > 0;
    final isCompleted = progress.passed;
    final statusColor = isCompleted
        ? AppTheme.accentEmerald
        : isSubmitted
        ? Colors.amber
        : AppTheme.textMuted;
    final statusLabel = isSubmitted
        ? 'SUBMITTED'
        : 'NOT STARTED';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppTheme.accentEmerald.withValues(alpha: 0.4)
              : AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    exercise.courseTitle.isEmpty
                        ? exercise.categoryId
                        : '${exercise.categoryId} — ${exercise.courseTitle}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (exercise.assessmentNumber != null) ...[
            Text(
              // Mirrors the "LEVEL N" badge Free Practice cards use — the
              // number on its own line, title stays the bare topic below
              // it, so neither repeats the word the other already says.
              'ASSESSMENT ${exercise.assessmentNumber}',
              style: const TextStyle(
                color: AppTheme.primaryCyan,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            exercise.title,
            style: const TextStyle(
              color: AppTheme.textBright,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            exercise.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isSubmitted ? Icons.check_circle : Icons.launch,
                color: isSubmitted ? statusColor : AppTheme.textMuted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _attemptSummary(progress),
                  style: TextStyle(
                    color: isSubmitted ? statusColor : AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: isSubmitted
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(isSubmitted ? Icons.lock : Icons.launch, size: 18),
              label: Text(
                isSubmitted ? 'Submitted — Locked' : 'Open & Build',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(14),
                backgroundColor: isSubmitted ? AppTheme.textMuted : null,
              ),
              // Locked after the one and only attempt — pass or fail. A
              // course assessment is single-shot; re-submitting isn't an
              // option to leave open even for someone who failed it.
              onPressed: (isSubmitted || uid == null)
                  ? null
                  : () => context.go(
                      '/canvas-builder/assessment_${exercise.exerciseId}_$uid'
                      '?exerciseId=${exercise.exerciseId}',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // A course assessment only ever has the one attempt, so this reports a
  // score, not a "tries so far" count the way Free Practice's equivalent
  // (PracticeLevelsScreen.attemptSummary) does.
  static String _attemptSummary(ExerciseProgress progress) {
    if (progress.attemptCount == 0) return 'Not attempted yet';

    final score = progress.scorePercent;
    final scoreText = score == null
        ? ''
        : ' — ${score.round()}% '
              '(${progress.correctChecks}/${progress.totalChecks} correct)';

    return progress.passed
        ? 'Submitted$scoreText'
        : 'Submitted — not passed$scoreText';
  }
}

/// Tab 2: Save History — the canvases this student pressed Save on, newest
/// first.
///
/// Only saves. Check Connection attempts live in the same collection but
/// belong to the level's own progress display, not here: mixing them in
/// meant a student who checked a level twenty times had to scroll past
/// twenty rows to find the one canvas they actually saved.
class SaveHistoryView extends StatefulWidget {
  const SaveHistoryView({super.key});

  @override
  State<SaveHistoryView> createState() =>
      _SaveHistoryViewState();
}

class _SaveHistoryViewState extends State<SaveHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  // Same reload race as every other dashboard tab: initState can run before
  // AuthProvider has resolved a real user, so this is re-attempted whenever
  // dependencies change (i.e. once AuthProvider actually notifies).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  void _ensureDataLoaded() {
    if (!mounted) return;
    final uid = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.uid;
    if (uid == null) return;

    Provider.of<SaveHistoryProvider>(
      context,
      listen: false,
    ).watchSaveHistory(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SaveHistoryProvider>(
      builder: (context, historyProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Save History',
              style: TextStyle(
                color: AppTheme.textBright,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Every canvas you have saved. Saves from a level are filed '
              'under that level\'s title; sandbox saves use the name you '
              'gave them.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),

            if (historyProvider.isLoading)
              ..._buildSkeletonCards()
            else if (historyProvider.errorMessage != null)
              _buildErrorState(context, historyProvider.errorMessage!)
            else if (historyProvider.history.isEmpty)
              _buildEmptyState()
            else
              ...historyProvider.history.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildHistoryCard(record),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_edu, color: AppTheme.textMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No saved canvases yet. Press Save Canvas while building and it '
            'will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentCrimson.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.accentCrimson, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              final uid = Provider.of<AuthProvider>(
                context,
                listen: false,
              ).currentUser?.uid;
              if (uid == null) return;
              Provider.of<SaveHistoryProvider>(
                context,
                listen: false,
              ).clear();
              Provider.of<SaveHistoryProvider>(
                context,
                listen: false,
              ).watchSaveHistory(uid);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkeletonCards() {
    return List.generate(
      3,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 220, height: 16),
              SizedBox(height: 10),
              SkeletonBox(width: 140, height: 12),
              SizedBox(height: 14),
              SkeletonBox(width: double.infinity, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(SaveRecord record) {
    // Every row here is a save, so the badge distinguishes what kind of
    // canvas it came from rather than a pass/fail state that no longer
    // applies to this list.
    final isFromExercise = record.isFromExercise;
    final accent = isFromExercise
        ? AppTheme.accentEmerald
        : AppTheme.primaryCyan;
    final statusLabel = isFromExercise ? 'LEVEL' : 'SANDBOX';
    final icon = isFromExercise ? Icons.school_outlined : Icons.save_outlined;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textBright,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatTimestamp(record.attemptedAt),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          if (record.topologyId != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Reopen Canvas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                ),
                onPressed: () => context.go(
                  '/canvas-builder/${record.topologyId}'
                  '${record.isFromExercise ? '?exerciseId=${record.exerciseId}' : ''}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final time = TimeOfDay.fromDateTime(dt).format24Hour();

    if (diff.inDays == 0 && now.day == dt.day) return 'Today at $time';
    if (diff.inDays <= 1 && now.day - dt.day == 1) return 'Yesterday at $time';
    if (diff.inDays < 7) return '${diff.inDays} days ago at $time';
    return '${dt.day}/${dt.month}/${dt.year} at $time';
  }
}

extension on TimeOfDay {
  String format24Hour() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
