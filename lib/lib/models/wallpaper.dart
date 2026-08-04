import '../data/api_config.dart';

/// A single wallpaper image, as shown on Home / Explore / Trending.
class Wallpaper {
  final String id;
  final String title;
  final String category;
  final String resolution;
  final String _rawImage;

  /// The raw filename or URL stored by FavoritesService.
  String get rawImage => _rawImage;

  const Wallpaper({
    required this.id,
    required this.title,
    required this.category,
    required this.resolution,
    required String imageUrl,
  }) : _rawImage = imageUrl;

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['image_id'].toString(),
      title: json['image_name'] as String,
      category: json['category_name'] as String,
      resolution: json['resolution'] as String,
      imageUrl: json['image_upload'] as String,
    );
  }

  String get imageUrl {
    if (_rawImage.startsWith('http://') || _rawImage.startsWith('https://')) {
      return _rawImage;
    }
    // Some filenames contain spaces, e.g. "...e (1).jpg" — encode them so the
    // URL is valid. Uri.encodeComponent encodes the whole filename segment.
    final encoded = Uri.encodeComponent(_rawImage);
    return '${ApiConfig.wallpaperImageBaseUrl}$encoded';
  }
}
