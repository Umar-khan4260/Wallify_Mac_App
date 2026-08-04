import 'package:flutter/material.dart';

import '../../data/category_repository.dart';
import '../../data/wallpaper_repository.dart';
import '../../models/wallpaper.dart';
import '../../models/wallpaper_category.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/wallpaper_card.dart';
import 'widgets/category_grid.dart';
import 'widgets/filters_row.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedFilter = 0; // 0 = All, >0 = Specific Category

  final _categoryRepository = CategoryRepository();
  final _wallpaperRepository = WallpaperRepository();
  late Future<List<WallpaperCategory>> _categoriesFuture;
  Future<List<Wallpaper>>? _wallpapersFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _categoryRepository.getCategories();
  }

  Future<void> _refresh() async {
    setState(() {
      _categoriesFuture = _categoryRepository.getCategories();
      if (_selectedFilter > 0) {
        // We can't easily re-fetch the specific category here without having the category ID,
        // but since we are refreshing categories, we can just reset to 'All'.
        _selectedFilter = 0;
        _wallpapersFuture = null;
      }
    });
    await _categoriesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginEdge,
        AppSpacing.stackLg,
        AppSpacing.marginEdge,
        AppSpacing.stackLg,
      ),
      child: FutureBuilder<List<WallpaperCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(message: '${snapshot.error}', onRetry: _refresh);
          }

          final categories = snapshot.data ?? const [];
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          final filters = ['All', ...categories.map((c) => c.name)];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FiltersRow(
                filters: filters,
                selectedIndex: _selectedFilter,
                onSelected: (i) {
                  setState(() {
                    _selectedFilter = i;
                    if (i > 0) {
                      _wallpapersFuture = _wallpaperRepository
                          .getWallpapersByCategory(categories[i - 1].id);
                    } else {
                      _wallpapersFuture = null;
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Expanded(
                child: _selectedFilter == 0
                    ? RefreshIndicator(
                        onRefresh: _refresh,
                        child: CategoryGrid(
                          categories: categories,
                          onCategoryTap: (category) {
                            final index = categories.indexOf(category) + 1;
                            setState(() {
                              _selectedFilter = index;
                              _wallpapersFuture = _wallpaperRepository
                                  .getWallpapersByCategory(category.id);
                            });
                          },
                        ),
                      )
                    : FutureBuilder<List<Wallpaper>>(
                        future: _wallpapersFuture,
                        builder: (context, wallpaperSnapshot) {
                          if (wallpaperSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (wallpaperSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading wallpapers: ${wallpaperSnapshot.error}',
                              ),
                            );
                          }
                          final wallpapers = wallpaperSnapshot.data ?? const [];
                          if (wallpapers.isEmpty) {
                            return const Center(
                              child: Text(
                                'No wallpapers found in this category.',
                              ),
                            );
                          }
                          return GridView.builder(
                            itemCount: wallpapers.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 260,
                                  mainAxisExtent: 200,
                                  crossAxisSpacing: AppSpacing.stackMd,
                                  mainAxisSpacing: AppSpacing.stackMd,
                                ),
                            itemBuilder: (context, index) {
                              return WallpaperCard(
                                wallpaper: wallpapers[index],
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            "Couldn't load categories",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.stackXs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
