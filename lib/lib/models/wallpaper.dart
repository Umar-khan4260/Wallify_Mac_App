import '../data/api_config.dart';

/// A single wallpaper (image or live/video), as shown on Home / Explore / Trending.
class Wallpaper {
  final String id;
  final String title;
  final String category;
  final String resolution;

  /// Raw filename of the media file (image or .mp4).
  final String _rawImage;

  /// Raw filename of the thumbnail image (used for video wallpapers).
  final String _rawThumb;

  /// True when the original file is a video (e.g. .mp4).
  final bool isVideo;

  /// The raw filename stored by FavoritesService.
  String get rawImage => _rawImage;

  const Wallpaper({
    required this.id,
    required this.title,
    required this.category,
    required this.resolution,
    required String imageUrl,
    String thumbUrl = '',
    this.isVideo = false,
  }) : _rawImage = imageUrl,
       _rawThumb = thumbUrl;

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    final rawImage = (json['image_upload'] as String? ?? '');
    final rawThumb = (json['image_thumb'] as String? ?? '');
    final isVideo =
        rawImage.toLowerCase().endsWith('.mp4') ||
        rawImage.toLowerCase().endsWith('.webm') ||
        rawImage.toLowerCase().endsWith('.gif');
    return Wallpaper(
      id: json['image_id'].toString(),
      title: json['image_name'] as String? ?? '',
      category: json['category_name'] as String? ?? '',
      resolution: json['resolution'] as String? ?? '',
      imageUrl: rawImage,
      thumbUrl: rawThumb,
      isVideo: isVideo,
    );
  }

  /// The URL to display as the card thumbnail.
  /// For videos this is the `.png` thumbnail from /upload/thumbs/; for images it's the image itself from /upload/.
  String get imageUrl {
    if (isVideo && _rawThumb.isNotEmpty) {
      if (_rawThumb.startsWith('http://') || _rawThumb.startsWith('https://')) {
        return _rawThumb;
      }
      final encoded = Uri.encodeComponent(_rawThumb);
      return '${ApiConfig.thumbImageBaseUrl}$encoded';
    }
    if (_rawImage.startsWith('http://') || _rawImage.startsWith('https://')) {
      return _rawImage;
    }
    final encoded = Uri.encodeComponent(_rawImage);
    return '${ApiConfig.wallpaperImageBaseUrl}$encoded';
  }

  /// The URL to the actual media file (video or image).
  String get mediaUrl {
    if (_rawImage.startsWith('http://') || _rawImage.startsWith('https://')) {
      return _rawImage;
    }
    final encoded = Uri.encodeComponent(_rawImage);
    return '${ApiConfig.wallpaperImageBaseUrl}$encoded';
  }
}
