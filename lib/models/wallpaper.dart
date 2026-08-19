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

  /// Category id from the API response (`category_id`), when the wallpaper
  /// endpoint includes one. Null when absent — many endpoints only return
  /// `category_name`.
  final int? categoryId;

  /// Human-readable file size from the API response (`size`), e.g. "12.88 KB".
  final String size;

  /// Number of times this wallpaper has been viewed (`views`).
  int views;

  /// Number of times this wallpaper has been downloaded (`downloads`).
  int downloads;

  /// True when this wallpaper belongs to the paid category.
  ///
  /// FRAGILITY WARNING: matching is by category NAME (case-insensitive) as a
  /// fallback, because the wallpaper endpoint may not return `category_id`.
  /// A backend rename/re-case/retype ("Premium" vs "premium" vs "Premium ")
  /// silently flips this getter. Prefer the id match: it is used automatically
  /// when the response carries [categoryId] AND [ApiConfig.premiumCategoryId]
  /// is configured to a non-zero value.
  bool get isPremiumCategory {
    if (categoryId != null && ApiConfig.premiumCategoryId != 0) {
      return categoryId == ApiConfig.premiumCategoryId;
    }
    final premiumName = ApiConfig.premiumCategoryName.trim().toLowerCase();
    return category.trim().toLowerCase() == premiumName ||
        title.trim().toLowerCase().contains(premiumName);
  }

  /// The raw filename stored by FavoritesService.
  String get rawImage => _rawImage;

  /// The raw thumbnail filename (for video wallpapers).
  String get rawThumb => _rawThumb;

  Wallpaper({
    required this.id,
    required this.title,
    required this.category,
    required this.resolution,
    required String imageUrl,
    String thumbUrl = '',
    this.isVideo = false,
    this.categoryId,
    this.size = '',
    this.views = 0,
    this.downloads = 0,
  }) : _rawImage = imageUrl,
       _rawThumb = thumbUrl;

  Wallpaper copyWith({
    String? id,
    String? title,
    String? category,
    String? resolution,
    String? imageUrl,
    String? thumbUrl,
    bool? isVideo,
    int? categoryId,
    String? size,
    int? views,
    int? downloads,
  }) {
    return Wallpaper(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      resolution: resolution ?? this.resolution,
      imageUrl: imageUrl ?? this._rawImage,
      thumbUrl: thumbUrl ?? this._rawThumb,
      isVideo: isVideo ?? this.isVideo,
      categoryId: categoryId ?? this.categoryId,
      size: size ?? this.size,
      views: views ?? this.views,
      downloads: downloads ?? this.downloads,
    );
  }

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
      categoryId: _parseCategoryId(json['category_id']),
      size: json['size'] as String? ?? '',
      views: _parseInt(json['views']),
      downloads: _parseInt(json['downloads']),
    );
  }

  /// Numeric API fields may arrive as int or numeric string — normalize them.
  static int _parseInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  /// `category_id` may arrive as an int or as a numeric string — normalize it.
  static int? _parseCategoryId(Object? raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
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
