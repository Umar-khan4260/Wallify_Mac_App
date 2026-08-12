import 'package:flutter/material.dart';

import '../../../models/wallpaper_category.dart';
import '../../../theme/app_dimens.dart';

/// Small horizontal-scroll row of category thumbnails, for quick jumping
/// from Home into a category without going through the Categories tab.
class QuickCategoriesRow extends StatelessWidget {
  final List<WallpaperCategory> categories;
  final ValueChanged<WallpaperCategory>? onCategoryTap;

  const QuickCategoriesRow({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.stackMd),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => onCategoryTap?.call(category),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                width: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      category.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    Container(color: Colors.black.withOpacity(0.35)),
                    Center(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
