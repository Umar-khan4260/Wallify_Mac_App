import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/wallpaper.dart';

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

  Future<String> _cacheDirectory() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$_cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
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
    return _downloadTo(wallpaper.mediaUrl, finalPath, onProgress: onProgress);
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
}
