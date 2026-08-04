import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/wallpaper_card.dart';
import 'widgets/featured_banner.dart';
import 'widgets/quick_categories_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );

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
            wallpaper: sampleWallpapers.first,
            onSetWallpaper: () {
              // TODO: hook up to platform wallpaper-setting code.
            },
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Popular Categories', style: sectionTitleStyle),
          const SizedBox(height: AppSpacing.stackMd),
          QuickCategoriesRow(
            categories: sampleCategories,
            onCategoryTap: (category) {
              // TODO: jump to Categories tab filtered on this category.
            },
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Trending Wallpapers', style: sectionTitleStyle),
          const SizedBox(height: AppSpacing.stackMd),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
        ],
      ),
    );
  }
}
