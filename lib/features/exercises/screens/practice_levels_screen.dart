import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

/// Free Practice Skill Progression Screen (Levels 1 to 4)
class PracticeLevelsScreen extends StatelessWidget {
  const PracticeLevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      appBar: AppBar(
        title: const Text('Free Practice Mode — Skill Progression'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildLevelTile(
            context,
            level: 1,
            title: 'Level 1: IP Addressing & Subnet Masks',
            description:
                'Configure IPv4 host interfaces, subnet masks, and default gateways.',
            isUnlocked: true,
          ),
          _buildLevelTile(
            context,
            level: 2,
            title: 'Level 2: VLSM Subnetting',
            description:
                'Divide network spaces into variable-length subnet masks efficiently.',
            isUnlocked: (user?.freePracticeLevel ?? 1) >= 2,
          ),
          _buildLevelTile(
            context,
            level: 3,
            title: 'Level 3: VLANs & Trunking (802.1Q)',
            description:
                'Configure virtual LANs, trunk links, and Router-on-a-Stick inter-VLAN routing.',
            isUnlocked: (user?.freePracticeLevel ?? 1) >= 3,
          ),
          _buildLevelTile(
            context,
            level: 4,
            title: 'Level 4: OSPF Dynamic Routing',
            description:
                'Deploy Single-Area OSPF dynamic routing for multi-router networks.',
            isUnlocked: (user?.freePracticeLevel ?? 1) >= 4,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTile(
    BuildContext context, {
    required int level,
    required String title,
    required String description,
    required bool isUnlocked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor:
                (isUnlocked ? AppTheme.primaryCyan : AppTheme.textMuted)
                    .withValues(alpha: 0.2),
            child: Icon(
              isUnlocked ? Icons.play_arrow : Icons.lock,
              color: isUnlocked ? AppTheme.primaryCyan : AppTheme.textMuted,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isUnlocked ? AppTheme.textBright : AppTheme.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            description,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          trailing: isUnlocked
              ? const Icon(Icons.arrow_forward, color: AppTheme.primaryCyan)
              : null,
          onTap: isUnlocked
              ? () {
                  context.go('/canvas-builder/practice_level_$level');
                }
              : null,
        ),
      ),
    );
  }
}
