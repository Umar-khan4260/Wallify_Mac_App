import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import 'api_config.dart';

class WallpaperRepository {
  Future<List<Wallpaper>> getWallpapers({
    int page = 1,
    int count = 20,
    String filter = 'wallpaper',
    String order = 'recent',
    int? categoryId,
  }) async {
    final categoryParam = categoryId != null ? '&category=$categoryId' : '';
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}api.php?get_new_wallpapers&page=$page&count=$count&filter=$filter&order=$order$categoryParam',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load wallpapers (HTTP ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded['status'] != 'ok') {
      throw Exception('API returned status: ${decoded['status']}');
    }

    final postsJson = decoded['posts'] as List<dynamic>? ?? [];
    return postsJson
        .map((item) => Wallpaper.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
