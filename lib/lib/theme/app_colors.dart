import 'package:flutter/material.dart';

/// Static colors pulled from the original Tailwind config.
/// Used as seed/accent colors on top of Flutter's ColorScheme so both
/// light and dark mode look correct (see [AppTheme] in `app_theme.dart`).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0057C2);
  static const onPrimary = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFAF9FF);
  static const onSurface = Color(0xFF191B22);
  static const onSurfaceVariant = Color(0xFF424753);
  static const outline = Color(0xFF727785);
  static const outlineVariant = Color(0xFFC2C6D6);
  static const surfaceContainerHighest = Color(0xFFE1E2EC);
}
