import 'package:flutter/material.dart';

import '../../data/favorites_service.dart';
import '../../models/wallpaper.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/wallpaper_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Wallpaper>>(
      valueListenable: FavoritesService.instance.listenable,
      builder: (context, favorites, _) {
        if (favorites.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border,
            title: 'No favorites yet',
            message: 'Tap the heart icon on any wallpaper to save it here.',
          );
        }

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
                '${favorites.length} saved wallpaper${favorites.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Expanded(
                child: GridView.builder(
                  itemCount: favorites.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 200,
                    crossAxisSpacing: AppSpacing.stackMd,
                    mainAxisSpacing: AppSpacing.stackMd,
                  ),
                  itemBuilder: (context, index) {
                    return WallpaperCard(
                      wallpaper: favorites[index],
                      wallpapers: favorites,
                      index: index,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
