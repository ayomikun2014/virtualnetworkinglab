import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Admin Tab 4: Security Audit & Activity Logs Viewer
class AuditLogsTab extends StatelessWidget {
  const AuditLogsTab({super.key});

  Color _getEventColor(String action) {
    if (action.contains('PROVISION') || action.contains('CREATE')) {
      return AppTheme.accentEmerald;
    } else if (action.contains('SECURITY') || action.contains('DELETE') || action.contains('FAIL')) {
      return AppTheme.accentCrimson;
    } else if (action.contains('LOGIN') || action.contains('AUTH')) {
      return AppTheme.primaryCyan;
    }
    return AppTheme.primaryBlue;
  }

  IconData _getEventIcon(String action) {
    if (action.contains('PROVISION') || action.contains('CREATE')) {
      return Icons.person_add;
    } else if (action.contains('SECURITY') || action.contains('DELETE')) {
      return Icons.security;
    } else if (action.contains('LOGIN')) {
      return Icons.login;
    }
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Security & System Audit Logs',
          style: TextStyle(color: AppTheme.textBright, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Real-time record of system activities, faculty setup, and administrative updates.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('${AppConstants.rootPath}/${AppConstants.activityLogsCollection}')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.primaryCyan),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Center(
                  child: Text('No security events recorded in the audit trail.', style: TextStyle(color: AppTheme.textMuted)),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final action = data['action'] ?? 'AUDIT_EVENT';
                final description = data['description'] ?? 'System activity occurred';
                final performedBy = data['performedBy'] ?? 'Root Admin';
                final timestamp = data['timestamp'] ?? '';

                final color = _getEventColor(action);
                final icon = _getEventIcon(action);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceGlass,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: color.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    action,
                                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'By $performedBy',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(description, style: const TextStyle(color: AppTheme.textBright, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timestamp.length > 16 ? timestamp.substring(0, 16).replaceAll('T', ' ') : timestamp,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
