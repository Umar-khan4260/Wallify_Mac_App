import 'package:flutter/material.dart';

import '../../theme/app_dimens.dart';
import '../../theme/theme_controller.dart';
import '../premium/subscription_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginEdge),
      children: [
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.diamond_outlined, color: Color(0xFF6B4EFF)),
          title: const Text('Wallify Premium'),
          subtitle: const Text('Manage your premium subscription'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, _) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark mode'),
              subtitle: const Text('Switch between light and dark theme'),
              value: mode == ThemeMode.dark,
              onChanged: (value) {
                // If the switch value doesn't match the current mode, toggle it.
                if ((value && mode != ThemeMode.dark) ||
                    (!value && mode == ThemeMode.dark)) {
                  ThemeController.instance.toggleTheme();
                }
              },
            );
          },
        ),
        const Divider(),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.high_quality_outlined),
          title: Text('Download quality'),
          subtitle: Text('4K'),
        ),
        const Divider(),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.info_outline),
          title: Text('About Wallify'),
          subtitle: Text('Version 1.0.0'),
        ),
      ],
    );
  }
}
