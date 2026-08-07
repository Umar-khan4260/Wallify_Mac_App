import 'package:flutter/material.dart';

import '../../data/api_constants.dart';
import '../../data/search_controller.dart';
import '../../data/wallpaper_repository.dart';
import '../../models/wallpaper.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/wallpaper_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _wallpaperRepository = WallpaperRepository();
  late Future<List<Wallpaper>> _exploreFuture;

  @override
  void initState() {
    super.initState();
    _exploreFuture = _wallpaperRepository.getWallpapers(
      order: Order.recent,
      categoryId: 0,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _exploreFuture = _wallpaperRepository.getWallpapers(
        order: Order.recent,
        categoryId: 0,
      );
    });
    await _exploreFuture;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover new wallpapers curated just for you',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Expanded(
            child: FutureBuilder<List<Wallpaper>>(
              future: _exploreFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error loading explore wallpapers: ${snapshot.error}',
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        OutlinedButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final explore = snapshot.data ?? const [];
                if (explore.isEmpty) {
                  return const Center(child: Text('No wallpapers found.'));
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ValueListenableBuilder<String>(
                    valueListenable: searchQueryNotifier,
                    builder: (context, query, _) {
                      final filtered = query.isEmpty
                          ? explore
                          : explore
                                .where(
                                  (w) => w.title.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ),
                                )
                                .toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('No wallpapers found.'),
                        );
                      }

                      return GridView.builder(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
