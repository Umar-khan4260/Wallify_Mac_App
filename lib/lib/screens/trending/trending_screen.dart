import 'package:flutter/material.dart';

import '../../data/api_constants.dart';
import '../../data/wallpaper_repository.dart';
import '../../models/wallpaper.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/wallpaper_card.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final _wallpaperRepository = WallpaperRepository();
  late Future<List<Wallpaper>> _trendingFuture;

  @override
  void initState() {
    super.initState();
    _trendingFuture = _wallpaperRepository.getWallpapers(
      order: Order.popular,
      categoryId: 0,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _trendingFuture = _wallpaperRepository.getWallpapers(
        order: Order.popular,
        categoryId: 0,
      );
    });
    await _trendingFuture;
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
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.stackXs),
              Text(
                'Updated hourly based on downloads',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Expanded(
            child: FutureBuilder<List<Wallpaper>>(
              future: _trendingFuture,
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
                          'Error loading trending wallpapers: ${snapshot.error}',
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

                final trending = snapshot.data ?? const [];
                if (trending.isEmpty) {
                  return const Center(
                    child: Text('No trending wallpapers found.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: GridView.builder(
                    itemCount: trending.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisExtent: 200,
                          crossAxisSpacing: AppSpacing.stackMd,
                          mainAxisSpacing: AppSpacing.stackMd,
                        ),
                    itemBuilder: (context, index) {
                      return WallpaperCard(wallpaper: trending[index]);
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
