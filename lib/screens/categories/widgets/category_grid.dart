import 'package:flutter/material.dart';

import '../../../models/wallpaper_category.dart';
import '../../../theme/app_dimens.dart';
import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  final List<WallpaperCategory> categories;
  final ValueChanged<WallpaperCategory>? onCategoryTap;

  const CategoryGrid({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 240,
        crossAxisSpacing: AppSpacing.stackMd,
        mainAxisSpacing: AppSpacing.stackMd,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: () => onCategoryTap?.call(category),
        );
      },
    );
  }
}
