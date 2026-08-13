import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/widgets/app_logo_widget.dart';
import '../../auth/providers/auth_provider.dart';

/// Navigation Item Model for Lecturer Dashboard
class LecturerNavItem {
  final int index;
  final IconData icon;
  final String label;

  const LecturerNavItem({
    required this.index,
    required this.icon,
    required this.label,
  });
}

const List<LecturerNavItem> kLecturerNavItems = [
  LecturerNavItem(index: 0, icon: Icons.analytics, label: 'Overview Hub'),
  LecturerNavItem(
    index: 1,
    icon: Icons.edit_document,
    label: 'Exercise Authoring',
  ),
  LecturerNavItem(index: 2, icon: Icons.grade, label: 'Grading Center'),
  LecturerNavItem(
    index: 3,
    icon: Icons.rule_folder_outlined,
    label: 'Manage Exercises',
  ),
];

/// Persistent Desktop Sidebar for Lecturer Dashboard
class LecturerSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const LecturerSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

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

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                children: [
                  ...kLecturerNavItems.map((item) {
                    final isSelected = selectedIndex == item.index;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        selected: isSelected,
                        selectedTileColor: AppTheme.primaryCyan.withValues(
                          alpha: 0.15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isSelected
                              ? const BorderSide(color: AppTheme.primaryCyan)
                              : BorderSide.none,
                        ),
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? AppTheme.primaryCyan
                              : AppTheme.textMuted,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.textBright
                                : AppTheme.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () => onTabSelected(item.index),
                      ),
                    );
                  }),
                  const Divider(color: AppTheme.borderSubtle, height: 20),
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

            // Faculty Profile Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryBlue.withValues(
                      alpha: 0.2,
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Faculty Member',
                          style: const TextStyle(
                            color: AppTheme.textBright,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.departmentId ?? 'Dept. Networking',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
}

/// Mobile Navigation Drawer for Lecturer Dashboard
class LecturerDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const LecturerDrawer({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
                        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: AppTheme.primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Faculty Portal',
                      style: TextStyle(
                        color: AppTheme.textBright,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.currentUser?.email ?? 'lecturer@univ.edu',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ...kLecturerNavItems.map((item) {
            final isSelected = selectedIndex == item.index;
            return ListTile(
              selected: isSelected,
              leading: Icon(
                item.icon,
                color: isSelected ? AppTheme.primaryCyan : AppTheme.textMuted,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryCyan
                      : AppTheme.textBright,
                ),
              ),
              onTap: () {
                onTabSelected(item.index);
                Navigator.pop(context);
              },
            );
          }),
          const Divider(color: AppTheme.borderSubtle),
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
}
