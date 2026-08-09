import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../views/exercise_authoring_tab.dart';
import '../views/grading_center_tab.dart';
import '../views/lecturer_overview_tab.dart';
import '../views/manage_exercises_tab.dart';
import '../widgets/lecturer_sidebar.dart';

/// Lecturer Portal Master Layout Shell & Tab Controller
class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  int _selectedIndex = 0;

  final List<String> _tabTitles = [
    'Faculty Class Analytics Hub',
    'Lab Exercise Authoring Wizard',
    'Submissions & Grading Center',
    'Manage Exercises',
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      appBar: isMobile
          ? AppBar(
              title: Text(_tabTitles[_selectedIndex]),
              backgroundColor: AppTheme.surfaceGlass,
              elevation: 0,
            )
          : null,
      drawer: isMobile
          ? LecturerDrawer(
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            )
          : null,
      body: Row(
        children: [
          // Persistent Desktop Sidebar
          if (!isMobile)
            LecturerSidebar(
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            ),

          // Main Content View
          Expanded(
            child: Column(
              children: [
                // Desktop Header Bar
                if (!isMobile)
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceGlass,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderSubtle),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _tabTitles[_selectedIndex],
                          style: const TextStyle(
                            color: AppTheme.textBright,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 4,
                                backgroundColor: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'FACULTY ACCESS (${user?.departmentId ?? "NET"})',
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Selected Tab Body
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildSelectedTabBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabBody() {
    switch (_selectedIndex) {
      case 0:
        return LecturerOverviewTab(onNavigateTab: _onTabSelected);
      case 1:
        return const ExerciseAuthoringTab();
      case 2:
        return const GradingCenterTab();
      case 3:
        return const ManageExercisesTab();
      default:
        return LecturerOverviewTab(onNavigateTab: _onTabSelected);
    }
  }
}
