import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallpaper.dart';

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

    try {
      // Mark as downloading (0% progress)
      _updateProgress(wallpaper.id, 0.0);

      // On Web, we can't easily save to a local directory using path_provider.
      // For now, we'll just simulate a download or use a workaround if needed.
      if (kIsWeb) {
        // Simulate download for web
        await Future.delayed(const Duration(seconds: 1));
        _updateProgress(wallpaper.id, 1.0);
        await _add(wallpaper);
        _reload();
        _removeProgress(wallpaper.id);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final wallifyDir = Directory('${dir.path}/Wallify');
      if (!await wallifyDir.exists()) {
        await wallifyDir.create(recursive: true);
      }

      final fileName = wallpaper.rawImage.split('/').last;
      final savePath = '${wallifyDir.path}/$fileName';

      // Download the file
      final response = await http.get(Uri.parse(wallpaper.mediaUrl));

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);

        // Save to SharedPreferences
        await _add(wallpaper);
        _reload();
      } else {
        debugPrint('Failed to download: HTTP ${response.statusCode}');
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
