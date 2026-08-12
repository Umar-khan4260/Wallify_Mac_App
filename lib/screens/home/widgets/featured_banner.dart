import 'package:flutter/material.dart';

import '../../../models/wallpaper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';

/// Large hero banner at the top of Home, showcasing one featured wallpaper.
class FeaturedBanner extends StatelessWidget {
  final Wallpaper wallpaper;
  final VoidCallback? onSetWallpaper;

  const FeaturedBanner({
    super.key,
    required this.wallpaper,
    this.onSetWallpaper,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              wallpaper.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.black12, Colors.transparent],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.stackLg,
              right: AppSpacing.stackLg,
              bottom: AppSpacing.stackLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Wallpaper of the Day',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wallpaper.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  ElevatedButton.icon(
                    onPressed: onSetWallpaper,
                    icon: const Icon(Icons.wallpaper, size: 18),
                    label: const Text('Set as Wallpaper'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
