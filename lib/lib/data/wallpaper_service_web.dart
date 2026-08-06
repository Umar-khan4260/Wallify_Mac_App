import '../models/wallpaper.dart';

/// Web stub — there is no local filesystem or native wallpaper API on web.
class WallpaperFileStore {
  bool get isSupported => false;

  Future<String?> localFileFor(Wallpaper wallpaper) async => null;

  Future<String> ensureLocalFile(
    Wallpaper wallpaper, {
    void Function(double progress)? onProgress,
  }) {
    throw UnsupportedError('Setting wallpapers is not supported on web.');
  }
}
