import 'package:flutter/material.dart';

import '../../data/category_repository.dart';
import '../../data/search_controller.dart';
import '../../data/wallpaper_repository.dart';
import '../../models/wallpaper.dart';
import '../../models/wallpaper_category.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/wallpaper_card.dart';
import 'widgets/category_grid.dart';
import 'widgets/filters_row.dart';

enum SortOption {
  recent('Recent', 'recent', 'all'),
  featured('Featured', 'featured', 'all'),
  popular('Popular', 'popular', 'all'),
  random('Random', 'random', 'all'),
  liveWallpaper('Live Wallpaper', 'recent', 'live');

  final String label;
  final String order;
  final String filter;

  const SortOption(this.label, this.order, this.filter);
}

class CategoriesScreen extends StatefulWidget {
  final int? initialCategoryId;

  const CategoriesScreen({super.key, this.initialCategoryId});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedFilter = 0; // 0 = All, >0 = Specific Category
  int? _selectedCategoryId;
  SortOption _selectedSortOption = SortOption.recent;

  final _categoryRepository = CategoryRepository();
  final _wallpaperRepository = WallpaperRepository();
  late Future<List<WallpaperCategory>> _categoriesFuture;
  Future<List<Wallpaper>>? _wallpapersFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _categoryRepository.getCategories();
    _handleInitialCategory();
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      _handleInitialCategory();
    }
  }

  void _handleInitialCategory() {
    if (widget.initialCategoryId != null) {
      _categoriesFuture.then((categories) {
        if (!mounted) return;
        final index = categories.indexWhere(
          (c) => c.id == widget.initialCategoryId,
        );
        if (index != -1) {
          setState(() {
            _selectedFilter = index + 1; // +1 because 0 is 'All'
            _selectedCategoryId = widget.initialCategoryId;
            _fetchWallpapers();
          });
        }
      });
    }
  }

  void _fetchWallpapers() {
    if (_selectedCategoryId != null) {
      _wallpapersFuture = _wallpaperRepository.getWallpapers(
        categoryId: _selectedCategoryId!,
        order: _selectedSortOption.order,
        filter: _selectedSortOption.filter,
      );
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _categoriesFuture = _categoryRepository.getCategories();
      if (_selectedFilter > 0) {
        _selectedFilter = 0;
        _selectedCategoryId = null;
        _wallpapersFuture = null;
      }
    });
    await _categoriesFuture;
  }

  void _showSortDialog() {
    SortOption tempOption = _selectedSortOption;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sort Wallpapers'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: SortOption.values.map((option) {
                  return RadioListTile<SortOption>(
                    title: Text(option.label),
                    value: option,
                    groupValue: tempOption,
                    activeColor: Theme.of(context).colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => tempOption = value);
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_selectedSortOption != tempOption) {
                      setState(() {
                        _selectedSortOption = tempOption;
                        _fetchWallpapers();
                      });
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
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
              Row(
                children: [
                  Expanded(
                    child: FiltersRow(
                      filters: filters,
                      selectedIndex: _selectedFilter,
                      onSelected: (i) {
                        setState(() {
                          _selectedFilter = i;
                          if (i > 0) {
                            _selectedCategoryId = categories[i - 1].id;
                            _fetchWallpapers();
                          } else {
                            _selectedCategoryId = null;
                            _wallpapersFuture = null;
                          }
                        });
                      },
                    ),
                  ),
                  if (_selectedFilter > 0) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.sort_rounded),
                      tooltip: 'Sort Wallpapers',
                      onPressed: _showSortDialog,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: searchQueryNotifier,
                  builder: (context, query, _) {
                    if (_selectedFilter == 0) {
                      final filteredCategories = query.isEmpty
                          ? categories
                          : categories
                                .where(
                                  (c) => c.name.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ),
                                )
                                .toList();

                      if (filteredCategories.isEmpty) {
                        return const Center(
                          child: Text('No categories found.'),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: CategoryGrid(
                          categories: filteredCategories,
                          onCategoryTap: (category) {
                            final index = categories.indexOf(category) + 1;
                            setState(() {
                              _selectedFilter = index;
                              _selectedCategoryId = category.id;
                              _fetchWallpapers();
                            });
                          },
                        ),
                      );
                    } else {
                      return FutureBuilder<List<Wallpaper>>(
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

                          final filteredWallpapers = query.isEmpty
                              ? wallpapers
                              : wallpapers
                                    .where(
                                      (w) => w.title.toLowerCase().contains(
                                        query.toLowerCase(),
                                      ),
                                    )
                                    .toList();

                          if (filteredWallpapers.isEmpty) {
                            return const Center(
                              child: Text(
                                'No wallpapers found in this category.',
                              ),
                            );
                          }
                          return GridView.builder(
                            itemCount: filteredWallpapers.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 260,
                                  mainAxisExtent: 200,
                                  crossAxisSpacing: AppSpacing.stackMd,
                                  mainAxisSpacing: AppSpacing.stackMd,
                                ),
                            itemBuilder: (context, index) {
                              return WallpaperCard(
                                wallpaper: filteredWallpapers[index],
                              );
                            },
                          );
                        },
                      );
                    }
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
