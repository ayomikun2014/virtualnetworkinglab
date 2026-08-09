import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/widgets/app_logo_widget.dart';
import '../../auth/providers/auth_provider.dart';

/// Navigation Item Model for Admin Dashboard
class AdminNavItem {
  final int index;
  final IconData icon;
  final String label;

  const AdminNavItem({
    required this.index,
    required this.icon,
    required this.label,
  });
}

const List<AdminNavItem> kAdminNavItems = [
  AdminNavItem(index: 0, icon: Icons.insights, label: 'Overview Hub'),
  AdminNavItem(index: 1, icon: Icons.badge, label: 'Lecturers Roster'),
  AdminNavItem(index: 2, icon: Icons.groups, label: 'Student Directory'),
  AdminNavItem(index: 3, icon: Icons.security, label: 'Security Audit Logs'),
];

/// Admin Desktop Sidebar Component
class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const AdminSidebar({
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
                  Text(
                    'VirtuaNetLab',
                    style: TextStyle(
                      color: AppTheme.textBright,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Links List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                children: [
                  ...kAdminNavItems.map((item) {
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

            // Admin Profile Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryCyan,
                    child: Icon(
                      Icons.verified_user,
                      size: 18,
                      color: AppTheme.backgroundMidnight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Root Administrator',
                          style: const TextStyle(
                            color: AppTheme.textBright,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? 'admin@virtuanetlab.univ.edu',
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

/// Mobile Navigation Drawer Component
class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const AdminDrawer({
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
                        color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: AppTheme.primaryCyan,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Root Admin Console',
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
                  authProvider.currentUser?.email ??
                      'admin@virtuanetlab.univ.edu',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ...kAdminNavItems.map((item) {
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
