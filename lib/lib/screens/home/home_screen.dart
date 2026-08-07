import 'package:flutter/material.dart';

import '../../data/category_repository.dart';
import '../../data/search_controller.dart';
import '../../data/wallpaper_repository.dart';
import '../../models/wallpaper.dart';
import '../../models/wallpaper_category.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/wallpaper_card.dart';
import 'widgets/featured_banner.dart';
import 'widgets/quick_categories_row.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int categoryId)? onNavigateToCategory;

  const HomeScreen({super.key, this.onNavigateToCategory});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
  }

  Future<_HomeData> _fetchHomeData() async {
    final categoriesFuture = CategoryRepository().getCategories();
    final wallpapersFuture = WallpaperRepository().getWallpapers(
      order: 'popular',
      count: 15, // 1 for banner, 14 for grid
    );

    final results = await Future.wait([categoriesFuture, wallpapersFuture]);
    return _HomeData(
      categories: results[0] as List<WallpaperCategory>,
      wallpapers: results[1] as List<Wallpaper>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return FutureBuilder<_HomeData>(
      future: _homeDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading home data:\n${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _homeDataFuture = _fetchHomeData();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        if (data.wallpapers.isEmpty) {
          return const Center(child: Text('No wallpapers found.'));
        }

        final featuredWallpaper = data.wallpapers.first;
        final gridWallpapers = data.wallpapers.skip(1).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginEdge,
            AppSpacing.stackLg,
            AppSpacing.marginEdge,
            AppSpacing.stackLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeaturedBanner(
                wallpaper: featuredWallpaper,
                onSetWallpaper: () {
                  // TODO: hook up to platform wallpaper-setting code.
                },
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text('Popular Categories', style: sectionTitleStyle),
              const SizedBox(height: AppSpacing.stackMd),
              QuickCategoriesRow(
                categories: data.categories,
                onCategoryTap: (category) {
                  widget.onNavigateToCategory?.call(category.id);
                },
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text('Trending Wallpapers', style: sectionTitleStyle),
              const SizedBox(height: AppSpacing.stackMd),
              ValueListenableBuilder<String>(
                valueListenable: searchQueryNotifier,
                builder: (context, query, _) {
                  final filtered = query.isEmpty
                      ? gridWallpapers
                      : gridWallpapers
                            .where(
                              (w) => w.title.toLowerCase().contains(
                                query.toLowerCase(),
                              ),
                            )
                            .toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No wallpapers found.')),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisExtent: 200,
                          crossAxisSpacing: AppSpacing.stackMd,
                          mainAxisSpacing: AppSpacing.stackMd,
                        ),
                    itemBuilder: (context, index) {
                      return WallpaperCard(wallpaper: filtered[index]);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeData {
  final List<WallpaperCategory> categories;
  final List<Wallpaper> wallpapers;

  _HomeData({required this.categories, required this.wallpapers});
}
