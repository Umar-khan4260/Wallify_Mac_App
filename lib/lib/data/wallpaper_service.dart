import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/wallpaper.dart';
import '../Provider/SubscriptionProvider.dart';
import 'live_wallpaper_service.dart';
import 'wallpaper_service_io.dart'
    if (dart.library.html) 'wallpaper_service_web.dart'
    as platform;

/// MethodChannel name shared with the native macOS side
/// (`macos/Runner/AppDelegate.swift`).
const String kWallpaperMethodChannel = 'com.myapp/wallpaper';

/// Outcome of a [WallpaperService.setWallpaper] attempt, ready for the UI.
class WallpaperSetResult {
  const WallpaperSetResult._({
    required this.success,
    required this.message,
    this.downloaded = false,
  });

  const WallpaperSetResult.success({
    String message = 'Wallpaper applied',
    bool downloaded = false,
  }) : this._(success: true, message: message, downloaded: downloaded);

  const WallpaperSetResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;

  /// Human-readable message to show in the UI.
  final String message;

  /// True when this attempt had to download a fresh copy of the image.
  final bool downloaded;
}

/// Coordinates the end-to-end "set as wallpaper" flow:
///
/// 1. reuse the already-downloaded file if one exists on disk,
/// 2. otherwise download it via Dio into Application Support,
/// 3. hand the local file path to the native macOS "setWallpaper" method,
/// 4. translate the native result into a [WallpaperSetResult] for the UI.
class WallpaperService {
  WallpaperService._();

  static final WallpaperService instance = WallpaperService._();

  static const MethodChannel _channel = MethodChannel(kWallpaperMethodChannel);

  final platform.WallpaperFileStore _fileStore = platform.WallpaperFileStore();

  /// Whether the current platform can apply wallpapers (macOS only for now).
  bool get isSupported => _fileStore.isSupported;

  /// Path of the locally cached file for [wallpaper], or null if not cached.
  Future<String?> localFileFor(Wallpaper wallpaper) =>
      _fileStore.localFileFor(wallpaper);

  /// Makes sure a local copy of [wallpaper] exists, downloading it on demand.
  /// [onProgress] reports download progress in 0.0..1.0.
  Future<String> ensureLocalFile(
    Wallpaper wallpaper, {
    void Function(double progress)? onProgress,
  }) => _fileStore.ensureLocalFile(wallpaper, onProgress: onProgress);

  /// Full "set wallpaper" flow. Never throws — returns a result instead so
  /// the UI can render loading, success and error states cleanly.
  ///
  /// [onProgress] fires during a download (0.0..1.0) and [onApplying] fires
  /// right before the native apply step (useful to switch to a spinner).
  Future<WallpaperSetResult> setWallpaper(
    Wallpaper wallpaper, {
    void Function(double progress)? onProgress,
    VoidCallback? onApplying,
  }) async {
    if (!isSupported) {
      return const WallpaperSetResult.failure(
        'Setting wallpapers is only supported on macOS.',
      );
    }

    // Premium-category wallpapers require an active subscription. Service-level
    // guard (defense in depth) — the UI gates before calling setWallpaper too.
    if (wallpaper.isPremiumCategory &&
        !(SubscriptionProvider.instance?.isPremium ?? false)) {
      return const WallpaperSetResult.failure(
        'This is a Premium wallpaper. Purchase Premium to use it.',
      );
    }

    final isVideo = wallpaper.isVideo;

    try {
      final reused = await localFileFor(wallpaper) != null;

      // Downloads the media file (the .mp4 for live wallpapers, the image for
      // still ones) into the cache, reporting progress along the way.
      final localPath = await ensureLocalFile(
        wallpaper,
        onProgress: onProgress,
      );

      onApplying?.call();

      if (isVideo) {
        // Set the thumbnail as the still desktop picture first so the lock
        // screen and previews show something sensible, then play the video in
        // a window behind the desktop icons.
        await _applyStillUnderlay(wallpaper);
        await LiveWallpaperService.instance.setLiveWallpaper(
          localPath,
          wallpaper.id,
        );
        return WallpaperSetResult.success(
          message: 'Live wallpaper applied',
          downloaded: !reused,
        );
      }

      // Still image: tear down any live wallpaper window and apply normally.
      await LiveWallpaperService.instance.clearLiveWallpaper();
      final applied = await _channel.invokeMethod<bool>('setWallpaper', {
        'filePath': localPath,
      });

      if (applied == true) {
        return WallpaperSetResult.success(downloaded: !reused);
      }
      return const WallpaperSetResult.failure(
        'The system could not apply the wallpaper.',
      );
    } on PlatformException catch (e) {
      return WallpaperSetResult.failure(e.message ?? 'Native error: ${e.code}');
    } on DioException catch (e) {
      return WallpaperSetResult.failure(_describeDioError(e));
    } catch (e) {
      return WallpaperSetResult.failure('Unexpected error: $e');
    }
  }

  /// Applies the live wallpaper's thumbnail as the still desktop picture.
  /// Best-effort: the video window is the primary effect, so a failure here is
  /// logged rather than surfaced to the user.
  Future<void> _applyStillUnderlay(Wallpaper wallpaper) async {
    try {
      final thumbPath = await _fileStore.ensureLocalThumbFile(wallpaper);
      await _channel.invokeMethod<bool>('setWallpaper', {
        'filePath': thumbPath,
      });
    } catch (e) {
      debugPrint('Failed to set live wallpaper still underlay: $e');
    }
  }

  String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Download timed out. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection.';
      case DioExceptionType.badResponse:
        return 'The server returned an error (HTTP ${e.response?.statusCode}).';
      case DioExceptionType.cancel:
        return 'Download was cancelled.';
      case DioExceptionType.unknown:
        return 'Download failed: ${e.message ?? 'unknown error'}';
      case DioExceptionType.badCertificate:
        return 'The server certificate could not be verified.';
      case DioExceptionType.transformTimeout:
        return 'Download timed out while processing the response.';
    }
  }
}
