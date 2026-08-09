import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Project Academic Credits & Author Information Widget
class ProjectCreditsWidget extends StatelessWidget {
  final bool compact;

  const ProjectCreditsWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundMidnight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'DESIGN & SIMULATION OF VIRTUAL NETWORK LAB',
              style: TextStyle(
                color: AppTheme.primaryCyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'By: Afolabi Victoria Abosede (NT20240111512)',
              style: TextStyle(
                color: AppTheme.textBright,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Supervised By: Mr. Mathew Adebunmi',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
            Text(
              'Dept. of Computer Networking & Cloud Computing • Fed Poly Ede',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: const [
          Text(
            'DESIGN AND SIMULATION OF A CLOUD-BASED VIRTUAL LABORATORY ENVIRONMENT FOR COMPUTER NETWORKING EDUCATION',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'BY: AFOLABI VICTORIA ABOSEDE — NT20240111512',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textBright,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'SUPERVISED BY: MR. MATHEW ADEBUNMI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'DEPARTMENT OF COMPUTER NETWORKING AND CLOUD COMPUTING • SCHOOL OF COMPUTING TECHNOLOGY • FEDERAL POLYTECHNIC EDE',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
