import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// A rounded placeholder block that pulses gently while content loads.
///
/// Used in place of a spinner for list/grid-shaped content: a shape that
/// already resembles the real cards reads as "this is loading" without the
/// jarring pop when a spinner is swapped for a wall of cards, and — unlike a
/// bare `CircularProgressIndicator` — it doesn't render identically to the
/// "nothing here" empty state, which is what made a slow fetch and a
/// genuinely empty collection indistinguishable at a glance.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 0.7,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppTheme.textMuted.withValues(alpha: _opacity.value * 0.25),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}
