import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../views/audit_logs_tab.dart';
import '../views/lecturers_tab.dart';
import '../views/overview_tab.dart';
import '../views/students_tab.dart';
import '../widgets/admin_sidebar.dart';

/// Root Administrator Master Dashboard & Console Layout Shell
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<String> _tabTitles = [
    'System Overview Hub',
    'Lecturer Faculty Roster',
    'Student Directory & Matric Registry',
    'Security Audit & Activity Logs',
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      appBar: isMobile
          ? AppBar(
              title: Text(_tabTitles[_selectedIndex]),
              backgroundColor: AppTheme.surfaceGlass,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: AppTheme.accentCrimson),
                  tooltip: 'Sign Out',
                  onPressed: () => authProvider.logout(),
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? AdminDrawer(
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            )
          : null,
      body: Row(
        children: [
          // Persistent Desktop Sidebar
          if (!isMobile)
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            ),

          // Main Body Content Container
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
                            color: AppTheme.accentEmerald.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.accentEmerald.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: const [
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: AppTheme.accentEmerald,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'ROOT ADMIN ACCESS',
                                style: TextStyle(
                                  color: AppTheme.accentEmerald,
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
        return OverviewTab(onNavigateTab: _onTabSelected);
      case 1:
        return const LecturersTab();
      case 2:
        return const StudentsTab();
      case 3:
        return const AuditLogsTab();
      default:
        return OverviewTab(onNavigateTab: _onTabSelected);
    }
  }
}
