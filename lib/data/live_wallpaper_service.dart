import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_service.dart';

/// MethodChannel name shared with the native macOS side
/// (`macos/Runner/LiveWallpaperManager.swift`).
const String kLiveWallpaperChannel = 'com.wallify/live_wallpaper';

/// Bridges to the native windowed live-wallpaper player on macOS.
class LiveWallpaperService {
  LiveWallpaperService._();
  static final LiveWallpaperService instance = LiveWallpaperService._();

  static const MethodChannel _channel = MethodChannel(kLiveWallpaperChannel);

  /// Whether the current platform has a native live-wallpaper player.
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Plays [localFilePath] as a looping video behind the desktop icons.
  /// Throws a [PlatformException] on failure so the UI can show the error.
  Future<bool> setLiveWallpaper(String localFilePath, String wallpaperId) async {
    final ok = await _channel.invokeMethod<bool>('setLiveWallpaper', {
      'filePath': localFilePath,
      'wallpaperId': wallpaperId,
    });
    if (ok == true) {
      NotificationService.instance.show(
        'Live wallpaper set',
        'Your new live wallpaper is now playing on the desktop',
      );
    }
    return ok ?? false;
  }

  /// Stops and hides any active live-wallpaper window(s).
  Future<bool> clearLiveWallpaper() async {
    final ok = await _channel.invokeMethod<bool>('clearLiveWallpaper');
    return ok ?? false;
  }

  /// The ID of the live wallpaper currently playing, or null.
  Future<String?> getCurrentLiveWallpaperId() async {
    return await _channel.invokeMethod<String>('getCurrentLiveWallpaperId');
  }
}
