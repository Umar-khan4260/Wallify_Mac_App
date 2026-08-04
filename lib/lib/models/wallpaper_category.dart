import '../data/api_config.dart';

/// A wallpaper category, e.g. "Nature" or "Snow" — matches the shape of
/// each object in the `categories` array from `GET api.php?get_categories`:
/// ```json
/// {
///   "category_id": 17,
///   "category_name": "Nature",
///   "category_image": "1751030821_1e9c4e537e06c6323c77403ec525ad13.jpg",
///   "total_wallpaper": 187
/// }
/// ```
class WallpaperCategory {
  final int id;
  final String name;
  final int totalWallpapers;

  /// Raw value of `category_image` — either just a filename (needs
  /// [ApiConfig.categoryImageBaseUrl] prefixed) or, for local/demo data,
  /// already a full URL. Use [imageUrl] rather than this directly.
  final String _rawImage;

  const WallpaperCategory({
    required this.id,
    required this.name,
    required this.totalWallpapers,
    required String image,
  }) : _rawImage = image;

  factory WallpaperCategory.fromJson(Map<String, dynamic> json) {
    return WallpaperCategory(
      id: json['category_id'] as int,
      name: json['category_name'] as String,
      totalWallpapers: json['total_wallpaper'] as int,
      image: json['category_image'] as String,
    );
  }

  /// Full, ready-to-load image URL. If the API already gave us a full URL
  /// (or this is demo data built with one) it's used as-is; otherwise it's
  /// prefixed with [ApiConfig.categoryImageBaseUrl].
  String get imageUrl {
    if (_rawImage.startsWith('http://') || _rawImage.startsWith('https://')) {
      return _rawImage;
    }
    final encoded = Uri.encodeComponent(_rawImage);
    return '${ApiConfig.categoryImageBaseUrl}$encoded';
  }

  /// e.g. "187 items" or "1.5k items" — formatted for display on cards.
  String get itemCountLabel {
    if (totalWallpapers >= 1000) {
      return '${(totalWallpapers / 1000).toStringAsFixed(1)}k items';
    }
    return '$totalWallpapers items';
  }
}
