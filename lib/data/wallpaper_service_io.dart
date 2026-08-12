import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/wallpaper.dart';
import 'notification_service.dart';

/// Downloads and caches wallpaper files on the filesystem.
///
/// Files live under the app's Application Support directory, which is inside
/// the app's sandbox container on macOS — readable by the app itself and by
/// `NSWorkspace` when applying the desktop picture.
class WallpaperFileStore {
  WallpaperFileStore();

  static const String _cacheDirName = 'wallpapers';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
    ),
  );

  /// Only macOS currently has a native "setWallpaper" handler.
  bool get isSupported => Platform.isMacOS;

  Future<String> _cacheDirPath() async {
    final base = await getApplicationSupportDirectory();
    return '${base.path}/$_cacheDirName';
  }

  Future<String> _cacheDirectory() async {
    final path = await _cacheDirPath();
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  /// File extension taken from a URL (e.g. `.jpg`), falling back to `.jpg`
  /// when the URL has none.
  String _extensionFor(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? url;
    final dot = path.lastIndexOf('.');
    if (dot != -1 && dot < path.length - 1) {
      return path.substring(dot).toLowerCase();
    }
    return '.jpg';
  }

  String _sanitize(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  Future<String> _pathFor(Wallpaper wallpaper, String url) async {
    final dirPath = await _cacheDirectory();
    return '$dirPath/${_sanitize(wallpaper.id)}${_extensionFor(url)}';
  }

  /// The on-disk path if the file is already cached, otherwise null.
  /// A cached file that is empty (e.g. a failed 200 response) is discarded so
  /// it gets downloaded again instead of breaking playback forever.
  Future<String?> localFileFor(Wallpaper wallpaper) async {
    final path = await _pathFor(wallpaper, wallpaper.mediaUrl);
    return _cachedPath(File(path));
  }

  /// The on-disk thumbnail path if already cached, otherwise null.
  /// Used for live (video) wallpapers, which macOS can only apply as a still.
  Future<String?> localThumbFor(Wallpaper wallpaper) async {
    final path = await _pathFor(wallpaper, wallpaper.imageUrl);
    return _cachedPath(File(path));
  }

  String? _cachedPath(File file) {
    if (!file.existsSync()) return null;
    if (file.lengthSync() == 0) {
      file.deleteSync();
      return null;
    }
    return file.path;
  }

  /// Returns a local file path for [wallpaper], downloading it via Dio first
  /// when it is not cached. Downloads to a `.part` temp file and renames it
  /// on success so an interrupted download never leaves a "complete" file.
  Future<String> ensureLocalFile(
    Wallpaper wallpaper, {
    void Function(double progress)? onProgress,
  }) async {
    final existing = await localFileFor(wallpaper);
    if (existing != null) return existing;
    final finalPath = await _pathFor(wallpaper, wallpaper.mediaUrl);
    final path = await _downloadTo(
      wallpaper.mediaUrl,
      finalPath,
      onProgress: onProgress,
    );
    NotificationService.instance.show('Download complete', wallpaper.title);
    maybeNotifyCacheWarning();
    return path;
  }

  /// Downloads the still thumbnail of a live (video) wallpaper so it can be
  /// applied as the desktop picture.
  Future<String> ensureLocalThumbFile(
    Wallpaper wallpaper, {
    void Function(double progress)? onProgress,
  }) async {
    final existing = await localThumbFor(wallpaper);
    if (existing != null) return existing;
    final finalPath = await _pathFor(wallpaper, wallpaper.imageUrl);
    return _downloadTo(wallpaper.imageUrl, finalPath, onProgress: onProgress);
  }

  Future<String> _downloadTo(
    String url,
    String finalPath, {
    void Function(double progress)? onProgress,
  }) async {
    final tempPath = '$finalPath.part';

    try {
      await _dio.download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          onProgress?.call((received / total).clamp(0.0, 1.0));
        },
      );

      final temp = File(tempPath);
      if (await temp.exists()) {
        await temp.rename(finalPath);
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: url),
          type: DioExceptionType.unknown,
          message: 'The downloaded file is missing.',
        );
      }
      return finalPath;
    } catch (_) {
      final temp = File(tempPath);
      if (await temp.exists()) {
        await temp.delete();
      }
      rethrow;
    }
  }

  /// Total size in bytes of every file in the wallpapers cache directory.
  Future<int> cacheSizeBytes() async {
    final dir = Directory(await _cacheDirectory());
    var total = 0;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {
          // The file may have been removed/replaced by an in-flight download.
        }
      }
    }
    return total;
  }

  static const int _cacheWarningThresholdBytes = 500 * 1024 * 1024;

  /// In-memory session flag: the cache warning fires at most once per app
  /// session regardless of how many times the check runs.
  static bool _cacheWarningShownThisSession = false;

  /// Alerts the user when the wallpaper cache exceeds 500 MB. Safe to call on
  /// app launch and after each download; the session flag above stops repeat
  /// alerts. Never throws.
  Future<void> maybeNotifyCacheWarning() async {
    if (_cacheWarningShownThisSession) return;
    try {
      final size = await cacheSizeBytes();
      if (size > _cacheWarningThresholdBytes) {
        _cacheWarningShownThisSession = true;
        NotificationService.instance.show(
          'Cache is getting large',
          'Clear it in Settings to free up space',
        );
      }
    } catch (e) {
      debugPrint('WallpaperFileStore.maybeNotifyCacheWarning failed: $e');
    }
  }

  /// Deletes every file in the wallpapers cache directory except those whose
  /// wallpaper id (the filename before the extension) is in [excludeIds].
  ///
  /// Skips subdirectories and does nothing (without throwing) when the cache
  /// directory does not exist yet. A file that fails to delete (e.g. locked by
  /// the live-wallpaper player) is logged and skipped so the rest still clears.
  /// Returns the number of files that could not be deleted.
  Future<int> clearCache({Set<String> excludeIds = const {}}) async {
    final dir = Directory(await _cacheDirPath());
    if (!await dir.exists()) return 0;

    var failed = 0;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final dot = name.lastIndexOf('.');
      final id = dot == -1 ? name : name.substring(0, dot);
      if (excludeIds.contains(id)) continue;
      try {
        await entity.delete();
      } catch (e) {
        failed++;
        debugPrint(
          'WallpaperFileStore.clearCache: could not delete '
          '${entity.path}: $e',
        );
      }
    }
    if (failed > 0) {
      debugPrint(
        'WallpaperFileStore.clearCache: $failed file(s) could not be cleared.',
      );
    }
    return failed;
  }
}
