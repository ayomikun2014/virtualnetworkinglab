import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// What a notification is telling the student, which picks its colour and
/// icon.
enum AppNotificationType { success, error, info }

/// Top-anchored, auto-dismissing notifications — the web-style toast this
/// app shows instead of Material SnackBars.
///
/// SnackBars anchor to the bottom of the nearest Scaffold. On the canvas
/// that put them directly over the device palette and the cable controls,
/// and on a wide desktop window a bottom-left strip is a long way from
/// wherever the student is actually looking. These slide in under the top
/// edge, stack downwards, fade out on their own and can be dismissed early
/// by tapping or swiping up.
///
/// Rendered in the root [Overlay] rather than a Scaffold, so the same call
/// works from a dialog, a full-screen canvas or a dashboard tab.
class AppNotifier {
  AppNotifier._();

  /// Live entries, newest last. Kept so each new toast can stack below the
  /// ones already on screen instead of landing on top of them.
  static final List<_NotificationHandle> _visible = [];

  static const double _topInset = 24;
  static const double _gap = 8;
  static const double _estimatedHeight = 64;

  static void success(BuildContext context, String message) =>
      show(context, message, type: AppNotificationType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: AppNotificationType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: AppNotificationType.info);

  static void show(
    BuildContext context,
    String message, {
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    // rootOverlay: a canvas dialog pushes its own Overlay, and an entry
    // inserted there would vanish the moment the dialog closed — which is
    // exactly when several of these fire.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final _NotificationHandle handle;

    handle = _NotificationHandle(
      remove: () {
        if (!_visible.remove(handle)) return;
        handle.entry.remove();
        // Close the gap the dismissed toast left behind.
        for (final other in _visible) {
          other.slotNotifier.value = _visible.indexOf(other);
        }
      },
    );

    handle.slotNotifier = ValueNotifier<int>(_visible.length);
    handle.entry = OverlayEntry(
      builder: (context) => _NotificationCard(
        message: message,
        type: type,
        duration: duration,
        slot: handle.slotNotifier,
        onDismissed: handle.remove,
      ),
    );

    _visible.add(handle);
    overlay.insert(handle.entry);
  }

  static double offsetForSlot(int slot) =>
      _topInset + slot * (_estimatedHeight + _gap);
}

class _NotificationHandle {
  late OverlayEntry entry;
  late ValueNotifier<int> slotNotifier;
  final VoidCallback remove;

  _NotificationHandle({required this.remove});
}

class _NotificationCard extends StatefulWidget {
  final String message;
  final AppNotificationType type;
  final Duration duration;
  final ValueNotifier<int> slot;
  final VoidCallback onDismissed;

  const _NotificationCard({
    required this.message,
    required this.type,
    required this.duration,
    required this.slot,
    required this.onDismissed,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  Timer? _dismissTimer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  /// Plays the exit animation, then hands back to the notifier to actually
  /// pull the overlay entry. Guarded so a tap during the exit doesn't run
  /// the whole thing twice.
  Future<void> _dismiss() async {
    if (_leaving) return;
    _leaving = true;
    _dismissTimer?.cancel();

    if (mounted) await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  (Color, IconData) get _appearance => switch (widget.type) {
    AppNotificationType.success => (
      AppTheme.accentEmerald,
      Icons.check_circle_outline,
    ),
    AppNotificationType.error => (
      AppTheme.accentCrimson,
      Icons.error_outline,
    ),
    AppNotificationType.info => (AppTheme.primaryCyan, Icons.info_outline),
  };

  @override
  Widget build(BuildContext context) {
    final (accent, icon) = _appearance;
    final width = MediaQuery.of(context).size.width;

    return ValueListenableBuilder<int>(
      valueListenable: widget.slot,
      builder: (context, slot, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          top: AppNotifier.offsetForSlot(slot),
          left: 0,
          right: 0,
          child: child!,
        );
      },
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: Dismissible(
                  key: ValueKey(widget.hashCode),
                  direction: DismissDirection.up,
                  onDismissed: (_) => widget.onDismissed(),
                  child: ConstrainedBox(
                    // Full width on a phone, a readable column on desktop
                    // rather than a banner stretched across 1900px.
                    constraints: BoxConstraints(
                      maxWidth: width < 520 ? width : 460,
                    ),
                    child: GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceGlass,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.55),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: accent, size: 20),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: AppTheme.textBright,
                                  fontSize: 13.5,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _dismiss,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
