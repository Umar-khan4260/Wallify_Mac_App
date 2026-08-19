import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import 'api_config.dart';

class WallpaperRepository {
  Future<List<Wallpaper>> getWallpapers({
    int page = 1,
    int count = 20,
    String filter = 'all',
    String order = 'recent',
    int categoryId = 0,
  }) async {
    final categoryParam = '&category=$categoryId';
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

  Future<void> updateView(String imageId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}api.php?update_view');
    final response = await http.post(uri, body: {'image_id': imageId});

    if (response.statusCode != 200) {
      throw Exception('Failed to update view (HTTP ${response.statusCode})');
    }
  }

  Future<void> updateDownload(String imageId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}api.php?update_download');
    final response = await http.post(uri, body: {'image_id': imageId});

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update download (HTTP ${response.statusCode})',
      );
    }
  }
}
