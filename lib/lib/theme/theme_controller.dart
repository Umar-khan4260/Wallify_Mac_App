import 'package:flutter/material.dart';

/// App-wide light/dark mode switch.
///
/// Kept as a simple [ValueNotifier] so any widget (e.g. the top bar toggle)
/// can flip it without needing a state-management package. Swap this for
/// Provider/Riverpod/Bloc later without touching the widgets that read it.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
