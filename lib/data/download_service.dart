import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Provider/SubscriptionProvider.dart';
import '../models/wallpaper.dart';

// Path-provider & dart:io are only available on native (non-web) platforms.
// We use a conditional import stub so the file compiles on web too.
import 'download_service_io.dart'
    if (dart.library.html) 'download_service_web.dart'
    as platform;

/// Singleton that handles downloading wallpapers and persisting the list of downloaded items.
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  static const _prefix = 'dl_';

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Live list of downloaded wallpapers. Widgets can call
  /// [ValueListenableBuilder] on this to rebuild reactively.
  final ValueNotifier<List<Wallpaper>> listenable = ValueNotifier([]);

  /// Map of wallpaper IDs to their download progress (0.0 to 1.0).
  /// If an ID is in this map, it is currently downloading.
  final ValueNotifier<Map<String, double>> progressListenable = ValueNotifier(
    {},
  );

  /// Call once at startup (e.g. in [main]) before using the service.
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    _reload();
  }

  // ── public API ─────────────────────────────────────────────────────────────

  bool isDownloaded(String wallpaperId) =>
      _prefs.containsKey(_key(wallpaperId));

  bool isDownloading(String wallpaperId) =>
      progressListenable.value.containsKey(wallpaperId);

  Future<void> downloadWallpaper(Wallpaper wallpaper) async {
    if (isDownloaded(wallpaper.id) || isDownloading(wallpaper.id)) return;

    // Premium-category wallpapers require an active subscription. This is a
    // service-level guard (defense in depth) — the UI also gates before
    // calling downloadWallpaper. No context here, so use the static handle.
    if (wallpaper.isPremiumCategory &&
        !(SubscriptionProvider.instance?.isPremium ?? false)) {
      debugPrint('Blocked download: premium wallpaper is not purchased.');
      return;
    }

    try {
      _updateProgress(wallpaper.id, 0.0);

      if (kIsWeb) {
        // On web, we can't save to a local file, so just record the wallpaper metadata.
        await Future.delayed(const Duration(milliseconds: 800));
        await _add(wallpaper);
        _reload();
      } else {
        // Download on native (Android, iOS, Windows, macOS, Linux).
        final response = await http.get(Uri.parse(wallpaper.mediaUrl));
        if (response.statusCode == 200) {
          final saved = await platform.saveFile(
            wallpaper.rawImage,
            response.bodyBytes,
          );
          if (saved) {
            await _add(wallpaper);
            _reload();
          }
        } else {
          debugPrint('Failed to download: HTTP ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error downloading wallpaper: $e');
    } finally {
      _removeProgress(wallpaper.id);
    }
  }

  Future<void> removeDownload(String id) async {
    await _remove(id);
    _reload();
  }

  // ── private helpers ────────────────────────────────────────────────────────

  String _key(String id) => '$_prefix$id';

  void _updateProgress(String id, double progress) {
    final map = Map<String, double>.from(progressListenable.value);
    map[id] = progress;
    progressListenable.value = map;
  }

  void _removeProgress(String id) {
    final map = Map<String, double>.from(progressListenable.value);
    map.remove(id);
    progressListenable.value = map;
  }

  Future<void> _add(Wallpaper wallpaper) async {
    await _prefs.setString(
      _key(wallpaper.id),
      '${wallpaper.title}|||${wallpaper.category}|||${wallpaper.resolution}|||${wallpaper.rawImage}',
    );
  }

  Future<void> _remove(String id) async {
    await _prefs.remove(_key(id));
  }

  void _reload() {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix));
    final list = <Wallpaper>[];
    for (final key in keys) {
      final raw = _prefs.getString(key) ?? '';
      final parts = raw.split('|||');
      if (parts.length == 4) {
        final id = key.substring(_prefix.length);
        list.add(
          Wallpaper(
            id: id,
            title: parts[0],
            category: parts[1],
            resolution: parts[2],
            imageUrl: parts[3],
          ),
        );
      }
    }
    listenable.value = list;
  }
}
