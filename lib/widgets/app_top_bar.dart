import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/SubscriptionProvider.dart';
import '../screens/premium/subscription_screen.dart';
import '../theme/app_dimens.dart';
import '../theme/theme_controller.dart';
import 'search_field.dart';

/// Fixed top bar: page title, search box, Pro status badge / Go Pro button,
/// and the dark-mode toggle. [title] changes per page (Home, Explore, ...).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppTopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.only(left: AppSpacing.marginEdge),

      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0x1A000000),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.stackLg),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 288),
              child: SearchField(hintText: 'Search $title...'),
            ),
          ),

          // ── PRO badge / Go Pro button ─────────────────────────────────
          Consumer<SubscriptionProvider>(
            builder: (context, sub, _) {
              if (sub.isPremium) {
                // ✔ User is PRO → show a small amber badge
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFAB00), Color(0xFFFF6D00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // ✗ User is NOT PRO → show a "Go Pro" outlined button
                return GestureDetector(
                  onTap: () => SubscriptionScreen.show(context),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFAB00), Color(0xFFFF6D00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Go Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),

          // ── Theme toggle ──────────────────────────────────────────────
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, child) {
              final isDark = mode == ThemeMode.dark;
              return GestureDetector(
                onTap: () {
                  ThemeController.instance.toggleTheme();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 48),
                  child: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
