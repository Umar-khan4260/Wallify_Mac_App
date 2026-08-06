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

  /// File extension taken from the media URL (e.g. `.jpg`), falling back to
  /// `.jpg` when the URL has none.
  String _extensionFor(Wallpaper wallpaper) {
    final uri = Uri.tryParse(wallpaper.mediaUrl);
    final path = uri?.path ?? wallpaper.mediaUrl;
    final dot = path.lastIndexOf('.');
    if (dot != -1 && dot < path.length - 1) {
      return path.substring(dot).toLowerCase();
    }
    return '.jpg';
  }

  String _sanitize(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  Future<String> _pathFor(Wallpaper wallpaper) async {
    final dirPath = await _cacheDirectory();
    return '$dirPath/${_sanitize(wallpaper.id)}${_extensionFor(wallpaper)}';
  }

  /// The on-disk path if the file is already cached, otherwise null.
  Future<String?> localFileFor(Wallpaper wallpaper) async {
    final path = await _pathFor(wallpaper);
    return File(path).existsSync() ? path : null;
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

    final finalPath = await _pathFor(wallpaper);
    final tempPath = '$finalPath.part';

    try {
      await _dio.download(
        wallpaper.mediaUrl,
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
          requestOptions: RequestOptions(path: wallpaper.mediaUrl),
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
