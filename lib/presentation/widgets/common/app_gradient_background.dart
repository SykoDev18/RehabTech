import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Theme-aware background gradient.
///
/// Picks [AppColors.backgroundGradientLight] / [AppColors.backgroundGradientDark]
/// (or the 3-stop variants when [threeStop] is true) based on the current
/// brightness, so dropping it into a `Scaffold.body` gives correct results
/// in both light and dark themes without per-screen color decisions.
///
/// Callers can override the colors per-mode if a screen needs a custom palette.
class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({
    super.key,
    required this.child,
    this.threeStop = false,
    this.lightColors,
    this.darkColors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  final Widget child;
  final bool threeStop;
  final List<Color>? lightColors;
  final List<Color>? darkColors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Color> colors;
    if (isDark) {
      colors = darkColors ??
          (threeStop
              ? AppColors.backgroundGradient3Dark
              : AppColors.backgroundGradientDark);
    } else {
      colors = lightColors ??
          (threeStop
              ? AppColors.backgroundGradient3Light
              : AppColors.backgroundGradientLight);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: begin,
          end: end,
        ),
      ),
      child: child,
    );
  }
}

/// Helper that returns a frosted-glass surface color appropriate for the
/// current theme. Use it inside `BackdropFilter` containers instead of
/// hardcoding `Colors.white.withValues(alpha: ...)`.
Color themedGlassColor(BuildContext context, {double alpha = 0.6}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  // Surface with low alpha lets the gradient show through; on dark we use
  // surface (which is the dark surface defined in AppTheme).
  return Theme.of(context).colorScheme.surface.withValues(
        alpha: isDark ? alpha * 0.7 : alpha,
      );
}

/// Border color for frosted-glass containers; subtle on light, slightly
/// brighter on dark so the edge stays visible.
Color themedGlassBorder(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.5);
}
