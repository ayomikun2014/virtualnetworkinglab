import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/widgets/app_logo_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exercises/screens/practice_levels_screen.dart';
import '../screens/student_dashboard.dart';

/// Responsive Student Dashboard Layout Shell with Sidebar (Desktop) and Navigation Drawer (Mobile)
class DashboardLayout extends StatefulWidget {
  // Named rather than left as bare ints at each `initialTabIndex:` /
  // `?tab=` call site — those are scattered across app_routes.dart,
  // student_dashboard.dart and canvas_builder_screen.dart, and a bare `1`
  // or `3` at each site gives no indication it has to stay in sync with
  // _buildSelectedTabBody's switch below.
  static const int dashboardHomeTabIndex = 0;
  static const int coursesLabTabIndex = 1;
  static const int saveHistoryTabIndex = 2;
  static const int freePracticeTabIndex = 3;

  final int initialTabIndex;

  const DashboardLayout({
    super.key,
    this.initialTabIndex = dashboardHomeTabIndex,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  late int _selectedIndex = widget.initialTabIndex;

  // Navigating to '/student-dashboard?tab=N' while already on the dashboard
  // reuses this State: go_router keys its pages on the route's path *pattern*
  // ('/student-dashboard'), which doesn't change when only the query string
  // does, so no new State is created and the initialiser above never re-runs.
  // Without this, "Start Practice" on the hub appeared to do nothing — the
  // URL changed but the body stayed on whatever tab was already showing.
  @override
  void didUpdateWidget(DashboardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      setState(() => _selectedIndex = widget.initialTabIndex);
    }
  }

  final List<String> _tabTitles = [
    'Dashboard Hub',
    'Courses Lab',
    'Save History',
    'Free Practice Mode',
  ];

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
      drawer: isMobile ? _buildDrawer(context, authProvider) : null,
      body: Row(
        children: [
          // Persistent Desktop Sidebar
          if (!isMobile) _buildDesktopSidebar(context, authProvider),

          // Main Content View
          Expanded(
            child: Column(
              children: [
                // Desktop Header Bar
                if (!isMobile) _buildDesktopHeader(context, user),

                // Selected Tab Body
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildSelectedTabBody(context, user),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop Header Bar (Clean header without logout button)
  Widget _buildDesktopHeader(BuildContext context, user) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceGlass,
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          Text(
            _tabTitles[_selectedIndex],
            style: const TextStyle(
              color: AppTheme.textBright,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // User Profile Quick Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primaryCyan,
                  child: Icon(
                    Icons.person,
                    size: 14,
                    color: AppTheme.backgroundMidnight,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  user?.studentIdNumber ?? 'NT20240111512',
                  style: const TextStyle(
                    color: AppTheme.primaryCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Persistent Desktop Sidebar Widget
  Widget _buildDesktopSidebar(BuildContext context, AuthProvider authProvider) {
    return Material(
      color: AppTheme.surfaceGlass,
      child: Container(
        width: 260,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppTheme.borderSubtle)),
        ),
        child: Column(
          children: [
            // Branding Header
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderSubtle),
                ),
              ),
              child: Row(
                children: const [
                  AppLogoWidget(size: 38),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Virtual Networking Laboratory',
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textBright,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                children: [
                  _buildSidebarNavItem(
                    DashboardLayout.dashboardHomeTabIndex,
                    Icons.dashboard,
                    'Dashboard Hub',
                  ),
                  _buildSidebarNavItem(
                    DashboardLayout.coursesLabTabIndex,
                    Icons.assignment,
                    'Courses Lab',
                  ),
                  _buildSidebarNavItem(
                    DashboardLayout.saveHistoryTabIndex,
                    Icons.history_edu,
                    'Save History',
                  ),
                  _buildSidebarNavItem(
                    DashboardLayout.freePracticeTabIndex,
                    Icons.school,
                    'Free Practice',
                  ),
                  const Divider(color: AppTheme.borderSubtle, height: 32),
                  ListTile(
                    leading: const Icon(
                      Icons.architecture,
                      color: AppTheme.primaryCyan,
                    ),
                    title: const Text(
                      'Sandbox Canvas',
                      style: TextStyle(
                        color: AppTheme.textBright,
                        fontSize: 14,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      final uid = authProvider.currentUser?.uid ?? 'demo';
                      context.go('/canvas-builder/sandbox_$uid');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppTheme.accentCrimson,
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppTheme.accentCrimson,
                        fontSize: 14,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () => DialogUtils.showLogoutConfirmationDialog(
                      context,
                      authProvider,
                    ),
                  ),
                ],
              ),
            ),

            // Sidebar Footer Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentEmerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Network Engine Connected',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sidebar Item Builder
  Widget _buildSidebarNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? const BorderSide(color: AppTheme.primaryCyan, width: 1)
              : BorderSide.none,
        ),
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryCyan : AppTheme.textMuted,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.textBright : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  /// Mobile Sliding Navigation Drawer
  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      backgroundColor: AppTheme.surfaceGlass,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.backgroundMidnight,
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.hub,
                        color: AppTheme.primaryCyan,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Virtual Networking Laboratory',
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textBright,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.currentUser?.email ?? 'student@univ.edu',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerNavItem(
            DashboardLayout.dashboardHomeTabIndex,
            Icons.dashboard,
            'Dashboard Hub',
          ),
          _buildDrawerNavItem(
            DashboardLayout.coursesLabTabIndex,
            Icons.assignment,
            // Kept identical to the desktop sidebar's labels above — the two
            // navigations list the same four tabs, and having them named
            // differently on phone and desktop reads as different features.
            'Courses Lab',
          ),
          _buildDrawerNavItem(
            DashboardLayout.saveHistoryTabIndex,
            Icons.history_edu,
            'Save History',
          ),
          _buildDrawerNavItem(DashboardLayout.freePracticeTabIndex, Icons.school, 'Free Practice'),
          const Divider(color: AppTheme.borderSubtle),
          ListTile(
            leading: const Icon(
              Icons.architecture,
              color: AppTheme.primaryCyan,
            ),
            title: const Text(
              'Sandbox Canvas',
              style: TextStyle(color: AppTheme.textBright),
            ),
            onTap: () {
              Navigator.pop(context);
              final uid = authProvider.currentUser?.uid ?? 'demo';
              context.go('/canvas-builder/sandbox_$uid');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.accentCrimson),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.accentCrimson),
            ),
            onTap: () {
              Navigator.pop(context);
              DialogUtils.showLogoutConfirmationDialog(context, authProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      selected: isSelected,
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryCyan : AppTheme.textMuted,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryCyan : AppTheme.textBright,
        ),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  /// Selected Body View Router
  Widget _buildSelectedTabBody(BuildContext context, user) {
    switch (_selectedIndex) {
      case DashboardLayout.dashboardHomeTabIndex:
        return DashboardHomeView(user: user);
      case DashboardLayout.coursesLabTabIndex:
        return const CoursesLabView();
      case DashboardLayout.saveHistoryTabIndex:
        return const SaveHistoryView();
      case DashboardLayout.freePracticeTabIndex:
        return const PracticeLevelsScreen();
      default:
        return DashboardHomeView(user: user);
    }
  }
}
