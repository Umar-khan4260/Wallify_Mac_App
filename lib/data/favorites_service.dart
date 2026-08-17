import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallpaper.dart';

/// Singleton that persists favourited wallpapers in SharedPreferences.
///
/// Stores the minimal data needed to reconstruct a [Wallpaper] object:
///   key  → `fav_<id>`
///   value → "title|||category|||resolution|||rawImage|||isVideo|||rawThumb"
///
/// [listenable] fires whenever the set of favourites changes, so any widget
/// that listens to it will rebuild automatically.
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const _prefix = 'fav_';

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Live list of favourite wallpapers. Widgets can call
  /// [ValueListenableBuilder] on this to rebuild reactively.
  final ValueNotifier<List<Wallpaper>> listenable = ValueNotifier([]);

  /// Call once at startup (e.g. in [main]) before using the service.
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    _reload();
  }

  // ── public API ─────────────────────────────────────────────────────────────

  bool isFavorite(String wallpaperId) => _prefs.containsKey(_key(wallpaperId));

  Future<void> toggleFavorite(Wallpaper wallpaper) async {
    if (isFavorite(wallpaper.id)) {
      await _remove(wallpaper.id);
    } else {
      await _add(wallpaper);
    }
    _reload();
  }

  // ── private helpers ────────────────────────────────────────────────────────

  String _key(String id) => '$_prefix$id';

  Future<void> _add(Wallpaper wallpaper) async {
    await _prefs.setString(
      _key(wallpaper.id),
      '${wallpaper.title}|||${wallpaper.category}|||${wallpaper.resolution}|||${wallpaper.rawImage}|||${wallpaper.isVideo}|||${wallpaper.rawThumb}',
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
      if (parts.length >= 4) {
        final id = key.substring(_prefix.length);
        list.add(
          Wallpaper(
            id: id,
            title: parts[0],
            category: parts[1],
            resolution: parts[2],
            imageUrl: parts[3],
            thumbUrl: parts.length >= 6 ? parts[5] : '',
            isVideo: parts.length >= 5 ? parts[4] == 'true' : false,
          ),
        );
      }
    }
    listenable.value = list;
  }
}
