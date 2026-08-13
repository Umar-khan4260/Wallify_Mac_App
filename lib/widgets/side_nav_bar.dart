import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/theme_controller.dart';

class NavItemData {
  final IconData icon;
  final String label;
  const NavItemData(this.icon, this.label);
}

/// The 6 primary destinations. Index into this list is the same index
/// MainScreen uses for its IndexedStack of pages.
const List<NavItemData> primaryNavItems = [
  NavItemData(Icons.home_outlined, 'Home'),
  NavItemData(Icons.explore_outlined, 'Explore'),
  NavItemData(Icons.category_outlined, 'Categories'),
  NavItemData(Icons.trending_up_outlined, 'Trending'),
  NavItemData(Icons.favorite_border, 'Favorites'),
  NavItemData(Icons.download_outlined, 'Downloads'),
];

/// Settings is visually pinned to the bottom but is still just "page index 6".
const NavItemData settingsNavItem = NavItemData(
  Icons.settings_outlined,
  'Settings',
);
final int settingsIndex = primaryNavItems.length; // == 6

/// Fixed-width left sidebar: logo, the 6 primary nav items, and Settings
/// pinned to the bottom. [activeIndex] highlights the current page;
/// [onIndexChanged] is called with the tapped item's index.
class SideNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onIndexChanged;

  const SideNavBar({
    super.key,
    required this.activeIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.sidebarWidth,
      height: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        border: const Border(right: BorderSide(color: Color(0x1A000000))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 36,
                  height: 36,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4K Live Wallpapers',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Premium Wallpapers',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          for (int i = 0; i < primaryNavItems.length; i++)
            _NavItem(
              data: primaryNavItems[i],
              active: i == activeIndex,
              onTap: () => onIndexChanged(i),
            ),
          const Spacer(),
          // Theme Toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark ||
                  (mode == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) ==
                          Brightness.dark);
              return Row(
                children: [
                  Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ThemeController.instance.toggleTheme();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 24,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDark
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: isDark
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            size: 12,
                            color: isDark ? AppColors.primary : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: AppSpacing.stackLg),
          _NavItem(
            data: settingsNavItem,
            active: activeIndex == settingsIndex,
            onTap: () => onIndexChanged(settingsIndex),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final NavItemData data;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.unit),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: AppSpacing.stackSm,
            ),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary
                  : (_hovering
                      ? (Theme.of(context).colorScheme.brightness ==
                              Brightness.dark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.05))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(
                  widget.data.icon,
                  size: 20,
                  color: active
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Text(
                  widget.data.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
