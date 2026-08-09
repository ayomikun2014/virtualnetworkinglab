import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// A single headline figure on the dashboard.
///
/// Deliberately value-first: the number is the largest thing in the card,
/// with the label above it and an optional supporting caption below, so a
/// row of these scans as data rather than as decorated boxes.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  /// Optional supporting line under the value (e.g. "3 solved first try").
  final String? caption;

  /// When set (0..1), draws a progress track under the value.
  final double? progress;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.caption,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // A whisper of the accent colour bleeding up from the bottom-left
        // keeps the cards distinguishable at a glance without turning them
        // into four saturated blocks.
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            accent.withValues(alpha: 0.10),
            AppTheme.surfaceGlass.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textBright,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          // The track's slot is reserved whether or not this card has a
          // progress value, so a row of cards lines up flush instead of the
          // one card that happens to show a bar standing taller than its
          // neighbours.
          const SizedBox(height: 12),
          SizedBox(
            height: 5,
            child: progress == null
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: AppTheme.backgroundMidnight.withValues(
                        alpha: 0.7,
                      ),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
