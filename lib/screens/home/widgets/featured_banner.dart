import 'package:flutter/material.dart';

import '../../../data/wallpaper_service.dart';
import '../../../models/wallpaper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';
import '../../../utils/premium_helper.dart';

/// Large hero banner at the top of Home, showcasing one featured wallpaper.
class FeaturedBanner extends StatefulWidget {
  final Wallpaper wallpaper;

  const FeaturedBanner({super.key, required this.wallpaper});

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  bool _isSettingWallpaper = false;
  double _setProgress = 0.0;

  /// True when the user may use this wallpaper. Free wallpapers always pass.
  /// For Premium-category wallpapers it checks the subscription and, when not
  /// premium, shows the "upgrade required" dialog and returns false so the
  /// Set/Download action never runs. Browsing is never blocked.
  bool _hasAccessOrShowPaywall() {
    if (!widget.wallpaper.isPremiumCategory) return true;
    if (PremiumHelper.canAccessPremiumWallpapers(context)) return true;
    PremiumHelper.showPremiumRequiredDialog(context, feature: 'wallpaper');
    return false;
  }

  Future<void> _handleSetWallpaper() async {
    if (_isSettingWallpaper) return;
    if (!_hasAccessOrShowPaywall()) return;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    setState(() {
      _isSettingWallpaper = true;
      _setProgress = 0.0;
    });

    try {
      final result = await WallpaperService.instance.setWallpaper(
        widget.wallpaper,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _setProgress = progress);
        },
        onApplying: () {
          if (!mounted) return;
          setState(() => _setProgress = 1.0);
        },
      );

      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.success ? 'Wallpaper applied!' : result.message,
            ),
            backgroundColor: result.success
                ? Colors.green.shade700
                : errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSettingWallpaper = false);
      }
    }
  }

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
              widget.wallpaper.imageUrl,
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
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.wallpaper.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  ElevatedButton.icon(
                    onPressed: _isSettingWallpaper ? null : _handleSetWallpaper,
                    icon: _isSettingWallpaper
                        ? _BannerProgress(progress: _setProgress)
                        : const Icon(Icons.wallpaper, size: 18),
                    label: _isSettingWallpaper
                        ? const SizedBox.shrink()
                        : const Text('Set as Wallpaper'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary,
                      disabledForegroundColor: Colors.white,
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

/// Shown inside the banner button while a wallpaper is being applied.
class _BannerProgress extends StatelessWidget {
  const _BannerProgress({required this.progress});

  /// Download progress in 0.0..1.0. Once it reaches 1.0 the download is done
  /// and the native "apply" step runs, so an indeterminate spinner is shown.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final downloading = progress < 1.0;
    if (!downloading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }
    return SizedBox(
      width: 90,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
