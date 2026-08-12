import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark mode controller.
///
/// Persists the user's theme preference using [SharedPreferences].
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Live theme mode. Widgets can call [ValueListenableBuilder] on this to rebuild reactively.
  final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.light);

  /// Call once at startup (e.g. in [main]) before using the controller.
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;

    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme == 'dark') {
      notifier.value = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      notifier.value = ThemeMode.light;
    } else {
      notifier.value = ThemeMode.system; // Default
    }
  }

  /// Toggles between light and dark mode and saves the preference.
  Future<void> toggleTheme() async {
    final newMode = notifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifier.value = newMode;
    await _prefs.setString(
      _themeKey,
      newMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

// Keep the global variable for backward compatibility with existing code
final ValueNotifier<ThemeMode> themeNotifier =
    ThemeController.instance.notifier;
