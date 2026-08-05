import 'package:flutter/foundation.dart';

/// Central place for every URL fragment the app needs to talk to the API.
/// Keep all of this here so a changed domain or folder path is a one-line fix.
class ApiConfig {
  ApiConfig._();

  static const String _rawBaseUrl = 'https://nature-new.sunztech.com/api/v1/';
  static const String _proxyPrefix = 'https://proxy.cors.sh/';

  /// Base URL for JSON API calls. On Web, routed through a CORS proxy.
  static String get baseUrl =>
      kIsWeb ? '$_proxyPrefix$_rawBaseUrl' : _rawBaseUrl;

  /// Images fetched by Flutter Web (CanvasKit) use XHR and require CORS.
  static const String _rawCategoryImageBaseUrl =
      'https://nature-new.sunztech.com/upload/category/';
  static String get categoryImageBaseUrl => kIsWeb
      ? '$_proxyPrefix$_rawCategoryImageBaseUrl'
      : _rawCategoryImageBaseUrl;

  /// Full-resolution wallpaper images.
  static const String _rawWallpaperImageBaseUrl =
      'https://nature-new.sunztech.com/upload/';
  static String get wallpaperImageBaseUrl => kIsWeb
      ? '$_proxyPrefix$_rawWallpaperImageBaseUrl'
      : _rawWallpaperImageBaseUrl;

  /// Thumbnail/preview images for video (live) wallpapers.
  static const String _rawThumbImageBaseUrl =
      'https://nature-new.sunztech.com/upload/thumbs/';
  static String get thumbImageBaseUrl =>
      kIsWeb ? '$_proxyPrefix$_rawThumbImageBaseUrl' : _rawThumbImageBaseUrl;
}
