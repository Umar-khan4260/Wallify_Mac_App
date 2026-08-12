import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/wallpaper_category.dart';
import 'api_config.dart';

/// Talks to `GET api.php?get_categories`. Screens should go through this
/// (not call `http` directly) so there's one place to add caching, retries,
/// or swap the data source later.
class CategoryRepository {
  Future<List<WallpaperCategory>> getCategories() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}api.php?get_categories');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load categories (HTTP ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded['status'] != 'ok') {
      throw Exception('API returned status: ${decoded['status']}');
    }

    final categoriesJson = decoded['categories'] as List<dynamic>;
    return categoriesJson
        .map((item) => WallpaperCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
