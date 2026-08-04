import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/wallpaper_card.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app this list would come from the API already sorted by
    // trending rank; here we just reuse the sample data as-is.
    final trending = sampleWallpapers;

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
            child: GridView.builder(
              itemCount: trending.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 200,
                crossAxisSpacing: AppSpacing.stackMd,
                mainAxisSpacing: AppSpacing.stackMd,
              ),
              itemBuilder: (context, index) {
                return WallpaperCard(wallpaper: trending[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
