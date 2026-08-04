import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/dashboard_layout.dart';

/// Student Laboratory Hub Entrypoint Screen
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardLayout();
  }
}

/// Tab 0: Dashboard Home View with User Header, 3 Mini Stats, Practice Grid & Sandbox Bar
class DashboardHomeView extends StatelessWidget {
  final UserModel? user;

  const DashboardHomeView({super.key, this.user});

  void _showJoinClassDialog(BuildContext context, String studentUid) {
    final codeController = TextEditingController();
    final authService = AuthService();
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
                  Text('Join Lecturer Class', style: TextStyle(color: AppTheme.textBright, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter the 8-character Join Code provided by your lecturer (e.g. NET2026A):',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                      decoration: const InputDecoration(
                        labelText: 'Class Join Code',
                        hintText: 'NET2026A',
                        prefixIcon: Icon(Icons.vpn_key, color: AppTheme.primaryCyan),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundMidnight))
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Join Class Section'),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.isEmpty) return;

                          setModalState(() => isSubmitting = true);

                          try {
                            await authService.joinClassWithCode(joinCode: code, studentUid: studentUid);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Successfully joined lecturer class section!'),
                                  backgroundColor: AppTheme.accentEmerald,
                                ),
                              );
                              Provider.of<AuthProvider>(context, listen: false).refreshCurrentUserProfile();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppTheme.accentCrimson,
                                ),
                              );
                            }
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
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = user ?? authProvider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 16 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. User Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: AppTheme.primaryCyan, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentUser?.displayName ?? 'Student User',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textBright,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              currentUser?.studentIdNumber ?? 'NT20240111512',
                              style: const TextStyle(
                                color: AppTheme.primaryCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            currentUser?.email ?? 'student@univ.edu',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Department: ${currentUser?.departmentId ?? "Networking & Telecoms"}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: AppTheme.primaryCyan, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.displayName ?? 'Student User',
                            style: const TextStyle(
                              color: AppTheme.textBright,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  currentUser?.studentIdNumber ?? 'NT20240111512',
                                  style: const TextStyle(
                                    color: AppTheme.primaryCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentUser?.email ?? 'student@univ.edu',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Department: ${currentUser?.departmentId ?? "Networking & Telecommunications"}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 2. Stats Grid (3 Mini Stat Cards)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final completedCount = currentUser?.enrolledCourseIds?.length ?? 4;

              final statCards = [
                _buildMiniStatCard(
                  'Completed Labs',
                  '$completedCount / 12',
                  Icons.task_alt,
                  AppTheme.accentEmerald,
                ),
                _buildMiniStatCard(
                  'Average Score',
                  '92%',
                  Icons.analytics,
                  AppTheme.primaryCyan,
                ),
                _buildMiniStatCard(
                  'Skill Level',
                  'Level ${currentUser?.freePracticeLevel ?? 1}',
                  Icons.auto_awesome,
                  AppTheme.primaryBlue,
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: statCards
                      .map((card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: card,
                          ))
                      .toList(),
                );
              }

              return Row(
                children: statCards
                    .map((card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: card,
                          ),
                        ))
                    .toList(),
              );
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
              border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
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
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.group_add, size: 18, color: AppTheme.primaryCyan),
                      label: const Text('Join Class Code', style: TextStyle(color: AppTheme.primaryCyan)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryCyan),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onPressed: () {
                        final uid = currentUser?.uid ?? 'demo';
                        _showJoinClassDialog(context, uid);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.architecture, size: 20),
                      label: const Text('Open Sandbox'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onPressed: () {
                        final uid = currentUser?.uid ?? 'demo';
                        context.go('/canvas-builder/sandbox_$uid');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 4. Free Practice Progression Grid (Levels 1 to 4)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Free Practice Progression',
                style: TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '4 Levels',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth > 1000) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 2;
              }

              final userLevel = currentUser?.freePracticeLevel ?? 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildPracticeCard(
                    context,
                    level: 1,
                    title: 'Level 1: IP Addressing',
                    description: 'IPv4 Subnet Mask & Host Setup',
                    progress: 1.0,
                    isUnlocked: true,
                  ),
                  _buildPracticeCard(
                    context,
                    level: 2,
                    title: 'Level 2: Subnetting & VLSM',
                    description: 'VLSM Allocation & Network Summarization',
                    progress: userLevel >= 2 ? 0.6 : 0.0,
                    isUnlocked: userLevel >= 2,
                  ),
                  _buildPracticeCard(
                    context,
                    level: 3,
                    title: 'Level 3: VLANs & Trunking',
                    description: '802.1Q IEEE & Inter-VLAN Routing',
                    progress: userLevel >= 3 ? 0.2 : 0.0,
                    isUnlocked: userLevel >= 3,
                  ),
                  _buildPracticeCard(
                    context,
                    level: 4,
                    title: 'Level 4: OSPF Routing',
                    description: 'Single-Area OSPF Convergence & Metrics',
                    progress: userLevel >= 4 ? 0.1 : 0.0,
                    isUnlocked: userLevel >= 4,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
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

  Widget _buildPracticeCard(
    BuildContext context, {
    required int level,
    required String title,
    required String description,
    required double progress,
    required bool isUnlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? AppTheme.primaryCyan.withValues(alpha: 0.3) : AppTheme.borderSubtle,
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
                  color: (isUnlocked ? AppTheme.primaryCyan : AppTheme.textMuted).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LEVEL $level',
                  style: TextStyle(
                    color: isUnlocked ? AppTheme.primaryCyan : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                isUnlocked ? Icons.check_circle_outline : Icons.lock_outline,
                color: isUnlocked ? AppTheme.accentEmerald : AppTheme.textMuted,
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
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.backgroundMidnight,
            color: AppTheme.primaryCyan,
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isUnlocked
                  ? () {
                      context.go('/canvas-builder/practice_level_$level');
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(
                  color: isUnlocked ? AppTheme.primaryCyan : AppTheme.textMuted,
                ),
              ),
              child: Text(
                isUnlocked ? 'Start Practice' : 'Locked',
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

/// Tab 2: Lecturer Assignments View
class LecturerAssignmentsView extends StatelessWidget {
  const LecturerAssignmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Course Practical Assessments',
          style: TextStyle(
            color: AppTheme.textBright,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Complete hands-on laboratory topology assignments assigned by your course lecturers.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 20),

        _buildAssignmentCard(
          context,
          title: 'Assessment 1: Single Area OSPF Convergence',
          courseCode: 'NET201',
          dueDate: 'In 3 Days (Friday 11:59 PM)',
          status: 'Pending',
          statusColor: Colors.amber,
          score: null,
          labId: 'assessment_ospf_lab1',
        ),
        const SizedBox(height: 16),
        _buildAssignmentCard(
          context,
          title: 'Assessment 2: VLAN Trunking & Inter-VLAN Routing',
          courseCode: 'NET201',
          dueDate: 'Completed (Graded)',
          status: 'Graded',
          statusColor: AppTheme.accentEmerald,
          score: '95 / 100',
          labId: 'assessment_vlan_lab2',
        ),
        const SizedBox(height: 16),
        _buildAssignmentCard(
          context,
          title: 'Assessment 3: Subnetting & VLSM Allocation',
          courseCode: 'NET102',
          dueDate: 'Submitted (Under Review)',
          status: 'Submitted',
          statusColor: AppTheme.primaryCyan,
          score: 'Pending Score',
          labId: 'assessment_vlsm_lab3',
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context, {
    required String title,
    required String courseCode,
    required String dueDate,
    required String status,
    required Color statusColor,
    required String? score,
    required String labId,
  }) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  courseCode,
                  style: const TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  status.toUpperCase(),
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
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textBright,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, color: AppTheme.textMuted, size: 16),
              const SizedBox(width: 6),
              Text(
                'Due: $dueDate',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              if (score != null) ...[
                const Spacer(),
                Text(
                  'Score: $score',
                  style: const TextStyle(
                    color: AppTheme.textBright,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.launch, size: 18),
              label: Text(status == 'Graded' ? 'Review Submission' : 'Open Lab & Complete'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(14),
              ),
              onPressed: () {
                context.go('/canvas-builder/$labId');
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 3: Submissions History View
class SubmissionsHistoryView extends StatelessWidget {
  const SubmissionsHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Graded Submission Log',
          style: TextStyle(
            color: AppTheme.textBright,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Review past submission attempts, simulation results, and lecturer evaluation feedback.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 20),

        _buildHistoryCard(
          title: 'Assessment 2: VLAN Trunking & Inter-VLAN Routing',
          submittedDate: 'Yesterday at 4:15 PM',
          score: '95 / 100',
          feedback: 'Excellent IEEE 802.1Q trunking configuration. All ICMP echo pings converged within 120ms.',
          status: 'PASSED',
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          title: 'Free Practice Level 1: Subnet Mask & Host Setup',
          submittedDate: '3 days ago at 10:30 AM',
          score: '100 / 100',
          feedback: 'Perfect host IP assignments and subnet mask calculation.',
          status: 'PASSED',
        ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String submittedDate,
    required String score,
    required String feedback,
    required String status,
  }) {
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
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: AppTheme.accentEmerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Submitted: $submittedDate', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 12),
          Text('Lecturer Score: $score', style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundMidnight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Feedback: $feedback',
              style: const TextStyle(color: AppTheme.textBright, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
