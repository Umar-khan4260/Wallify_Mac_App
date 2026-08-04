/// Valid values for the `order` query param, straight from the Java
/// `ApiInterface.Order` class. Used on `get_new_wallpapers` and `get_search`.
class Order {
  Order._();

  static const recent = 'recent';
  static const oldest = 'oldest';
  static const featured = 'featured';
  static const popular = 'popular';
  static const download = 'download';
  static const random = 'random';
}

/// Valid values for the `filter` query param, from `ApiInterface.Filter`.
/// Used on `get_new_wallpapers`.
class Filter {
  Filter._();

  static const wallpaper = 'wallpaper';
  static const liveWallpaper = 'live';
  static const both = 'both';
}
