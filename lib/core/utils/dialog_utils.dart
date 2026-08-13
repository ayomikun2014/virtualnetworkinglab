import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Reusable Application Dialog Helpers
class DialogUtils {
  DialogUtils._();

  /// Displays a confirmation alert dialog before logging out the current user session
  static Future<void> showLogoutConfirmationDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceGlass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: Row(
            children: const [
              Icon(Icons.logout, color: AppTheme.accentCrimson),
              SizedBox(width: 10),
              Text(
                'Confirm Sign Out',
                style: TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out of Virtual Networking Laboratory?',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
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
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCrimson,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await authProvider.logout();
    }
  }
}
