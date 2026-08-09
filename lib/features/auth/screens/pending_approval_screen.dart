import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/widgets/app_logo_widget.dart';
import '../providers/auth_provider.dart';

/// Where a self-registered lecturer lands until an admin approves them.
///
/// The router sends any authenticated lecturer with `approvalStatus ==
/// 'pending'` here instead of `/lecturer-dashboard` — see the redirect and
/// route guard in `app_routes.dart`. There is nothing to do here but wait
/// or check again: no dashboard content exists to show, because the whole
/// point is that nothing lecturer-shaped is reachable until an admin has
/// reviewed the account and assigned courses.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    // Approval happens on the admin's session, not this one — AuthProvider's
    // cached UserModel only updates when asked, the same staleness this app
    // already works around for freePracticeLevel after a level pass. Once
    // this refresh lands `approvalStatus: 'approved'`, the router's
    // `refreshListenable` on AuthProvider fires the redirect on its own.
    await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).refreshCurrentUserProfile();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogoWidget(size: 48),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Awaiting Admin Approval',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textBright,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your lecturer account for ${user?.email ?? "this address"} '
                  'has been created, but an administrator still needs to '
                  'review it and assign your courses before you can access '
                  'the lecturer dashboard.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.backgroundMidnight,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: const Text('Check Approval Status'),
                    onPressed: _checking ? null : _checkStatus,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(
                    Icons.logout,
                    size: 16,
                    color: AppTheme.accentCrimson,
                  ),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.accentCrimson),
                  ),
                  onPressed: () => DialogUtils.showLogoutConfirmationDialog(
                    context,
                    authProvider,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
