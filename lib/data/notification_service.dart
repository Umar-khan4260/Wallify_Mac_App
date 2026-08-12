import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps `flutter_local_notifications` for macOS local (non-push) alerts.
///
/// Everything here is fire-and-forget from the caller's point of view:
/// [show] and [scheduleAt] never throw — permission denial and platform
/// errors are logged and swallowed, and they no-op entirely when the user has
/// turned notifications off, so call sites don't each have to check a flag.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _prefsKey = 'notifications_enabled';

  /// Stable id for the "plan may be expiring soon" reminder so a re-launch
  /// schedules a replacement instead of stacking duplicate reminders.
  static const int expiryReminderNotificationId = 1000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late SharedPreferences _prefs;
  bool _initialized = false;
  bool _enabled = true;
  int _nextId = 1;

  /// Live on/off state. Widgets can [ValueListenableBuilder] on this.
  final ValueNotifier<bool> enabledNotifier = ValueNotifier(true);

  bool get enabled => _enabled;

  /// Call once at startup (e.g. in [main]) before using the service.
  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _enabled = _prefs.getBool(_prefsKey) ?? true;
      enabledNotifier.value = _enabled;

      tz.initializeTimeZones();

      await _plugin.initialize(
        const InitializationSettings(
          macOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      // e.g. the user denied the permission prompt or the platform channel is
      // unavailable: notifications silently no-op for the rest of the session.
      debugPrint('NotificationService.init failed: $e');
    }
  }

  /// Persists the user's master switch. While off, [show] and [scheduleAt]
  /// no-op so every call site doesn't have to check [enabled] itself.
  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    enabledNotifier.value = value;
    try {
      await _prefs.setBool(_prefsKey, value);
    } catch (e) {
      debugPrint('NotificationService.setEnabled failed: $e');
    }
  }

  /// Fires an immediate notification. Never throws.
  Future<void> show(String title, String body) async {
    if (!_canNotify()) return;
    try {
      await _plugin.show(_nextId++, title, body, _details);
    } catch (e) {
      debugPrint('NotificationService.show failed: $e');
    }
  }

  /// Schedules a one-time notification for [when] (local time). Never throws.
  /// Pass a stable [id] to replace a previously scheduled notification.
  Future<void> scheduleAt(
    String title,
    String body,
    DateTime when, {
    int? id,
  }) async {
    if (!_canNotify()) return;
    try {
      await _plugin.zonedSchedule(
        id ?? _nextId++,
        title,
        body,
        _tzFromLocal(when),
        _details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleAt failed: $e');
    }
  }

  /// Cancels the notification previously scheduled with [id] (e.g. a stale
  /// expiry reminder from an earlier launch). Never throws.
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('NotificationService.cancel failed: $e');
    }
  }

  bool _canNotify() => _initialized && _enabled;

  static NotificationDetails get _details => const NotificationDetails(
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
          presentBadge: true,
        ),
      );

  /// `zonedSchedule` needs a [tz.TZDateTime]. [tz.local] defaults to UTC, so
  /// translate the local [when] using the device's current UTC offset to keep
  /// the same wall-clock time. Best-effort: a DST change between now and
  /// [when] can shift the fire time by an hour — acceptable for a courtesy
  /// reminder that is never used for anything time-critical.
  tz.TZDateTime _tzFromLocal(DateTime when) {
    final asUtc = tz.TZDateTime.from(when.toUtc(), tz.UTC);
    return asUtc.add(when.timeZoneOffset);
  }
}
