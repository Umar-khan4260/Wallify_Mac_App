import 'package:flutter/material.dart';

import '../../data/favorites_service.dart';
import '../../data/live_wallpaper_service.dart';
import '../../data/wallpaper_service_io.dart';
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
        const _ClearCacheTile(),
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

class _ClearCacheTile extends StatefulWidget {
  const _ClearCacheTile();

  @override
  State<_ClearCacheTile> createState() => _ClearCacheTileState();
}

class _ClearCacheTileState extends State<_ClearCacheTile> {
  late Future<String> _cacheSize;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _cacheSize = _loadCacheSize();
  }

  Future<String> _loadCacheSize() =>
      WallpaperFileStore().cacheSizeBytes().then(_formatBytes);

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    final decimals = index == 0 || value >= 100 ? 0 : (value >= 10 ? 1 : 2);
    return '${value.toStringAsFixed(decimals)} ${units[index]}';
  }

  Future<void> _onTap() async {
    if (_clearing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This deletes the wallpaper files downloaded to this device. '
          'Favorites and the currently active live wallpaper will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearing = true);

    final favoriteIds =
        FavoritesService.instance.listenable.value.map((w) => w.id).toSet();

    String? activeLiveId;
    try {
      activeLiveId =
          await LiveWallpaperService.instance.getCurrentLiveWallpaperId();
    } catch (_) {
      activeLiveId = null;
    }

    final int failed;
    try {
      failed = await WallpaperFileStore().clearCache(
        excludeIds: {...favoriteIds, ?activeLiveId},
      );
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      debugPrint('_ClearCacheTile: failed to clear cache: $e');
      if (!mounted) return;
      setState(() => _clearing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear cache')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _clearing = false;
      _cacheSize = _loadCacheSize();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? 'Cache cleared'
              : 'Cache cleared, $failed file(s) could not be deleted',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.cleaning_services_outlined),
      title: const Text('Clear Cache'),
      subtitle: _buildSubtitle(),
      onTap: _onTap,
    );
  }

  Widget _buildSubtitle() {
    if (_clearing) {
      return const Text('Clearing...');
    }
    return FutureBuilder<String>(
      future: _cacheSize,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Text('Calculating...');
        }
        if (snapshot.hasError) {
          return const Text('Unavailable');
        }
        return Text(snapshot.data ?? '');
      },
    );
  }
}
