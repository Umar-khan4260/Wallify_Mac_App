import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/wallpaper_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

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
            child: GridView.builder(
              itemCount: sampleWallpapers.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 200,
                crossAxisSpacing: AppSpacing.stackMd,
                mainAxisSpacing: AppSpacing.stackMd,
              ),
              itemBuilder: (context, index) {
                return WallpaperCard(wallpaper: sampleWallpapers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
