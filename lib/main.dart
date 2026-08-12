import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Provider/SubscriptionProvider.dart';
import 'data/download_service.dart';
import 'data/favorites_service.dart';
import 'data/notification_service.dart';
import 'data/wallpaper_service_io.dart';
import 'screens/main_screen.dart';
import 'screens/premium/subscription_screen.dart';
import 'theme/app_colors.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final subscriptionProvider = SubscriptionProvider();
  await subscriptionProvider.init();

  await ThemeController.instance.init();
  await FavoritesService.instance.init();
  await NotificationService.instance.init();
  await _scheduleExpiryReminder(subscriptionProvider);
  await WallpaperFileStore().maybeNotifyCacheWarning();
  await DownloadService.instance.init();
  runApp(WallifyApp(subscriptionProvider: subscriptionProvider));
}

/// Schedules a courtesy "plan may be expiring soon" reminder when the cached
/// entitlement is active and the best-effort expiry is within 3 days.
///
/// `subscriptionExpiry` is a heuristic (see SubscriptionProvider's class doc):
/// auto-renewals extend the real expiry but cannot be observed without a
/// backend, so this is informational only and NEVER gates any access. That is
/// why the wording is deliberately cautious and avoids claiming an exact date.
Future<void> _scheduleExpiryReminder(SubscriptionProvider provider) async {
  final now = DateTime.now();
  final expiry = provider.subscriptionExpiry;
  final qualifies = provider.isPremium &&
      expiry != null &&
      expiry.isAfter(now) &&
      expiry.difference(now) <= const Duration(days: 3);

  if (qualifies) {
    await NotificationService.instance.scheduleAt(
      'Your plan may be expiring soon',
      'Best-effort estimate, not a guarantee. Renew in Settings to keep '
          'Premium without a gap.',
      expiry,
      id: NotificationService.expiryReminderNotificationId,
    );
  } else {
    // Remove any reminder left over from an earlier launch (e.g. the user
    // renewed and the expiry is now further out than 3 days).
    await NotificationService.instance.cancel(
      NotificationService.expiryReminderNotificationId,
    );
  }
}

class WallifyApp extends StatelessWidget {
  const WallifyApp({super.key, required this.subscriptionProvider});

  final SubscriptionProvider subscriptionProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SubscriptionProvider>.value(
      value: subscriptionProvider,
      child: ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Wallify',
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const StartupPaywallGate(child: MainScreen()),
          debugShowCheckedModeBanner: false,
        );
      },
      ),
    );
  }
}

/// Wraps the main screen and, once on startup, pushes the paywall over it when
/// the user has no active subscription. Dismissible: after closing it the user
/// can browse freely; it reappears on the next launch until they subscribe.
class StartupPaywallGate extends StatefulWidget {
  const StartupPaywallGate({super.key, required this.child});

  final Widget child;

  @override
  State<StartupPaywallGate> createState() => _StartupPaywallGateState();
}

class _StartupPaywallGateState extends State<StartupPaywallGate> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isPremium = context.read<SubscriptionProvider>().isPremium;
      if (!isPremium) {
        SubscriptionScreen.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
