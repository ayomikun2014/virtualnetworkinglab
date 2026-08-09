import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Official Uniform Branding Logo Widget for VirtuaNetLab
class AppLogoWidget extends StatelessWidget {
  final double size;
  final bool showGlow;

  const AppLogoWidget({super.key, this.size = 36, this.showGlow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.5)),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.18),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.hub,
              color: AppTheme.primaryCyan,
              size: size * 0.6,
            );
          },
        ),
      ),
    );
  }
}
