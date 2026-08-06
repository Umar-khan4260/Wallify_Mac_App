import 'package:flutter/material.dart';

import '../data/download_service.dart';
import '../data/favorites_service.dart';
import '../data/wallpaper_service.dart';
import '../models/wallpaper.dart';
import '../theme/app_dimens.dart';

/// Shows one wallpaper thumbnail with its title/resolution and toggleable
/// favorite heart + download button. Distinct from `CategoryCard`
/// (categories/widgets), which shows a category cover with an item count.
class WallpaperCard extends StatefulWidget {
  final Wallpaper wallpaper;
  final VoidCallback? onTap;

  const WallpaperCard({super.key, required this.wallpaper, this.onTap});

  @override
  State<WallpaperCard> createState() => _WallpaperCardState();
}

class _WallpaperCardState extends State<WallpaperCard> {
  bool _hovering = false;
  final _favService = FavoritesService.instance;
  final _dlService = DownloadService.instance;

  bool _isSettingWallpaper = false;
  double _setProgress = 0.0;

  Future<void> _handleSetWallpaper() async {
    if (_isSettingWallpaper) return;

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
            content: Text(result.success ? 'Wallpaper applied!' : result.message),
            backgroundColor: result.success ? Colors.green.shade700 : errorColor,
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
    final surfaceContainerHighest = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Thumbnail image ──────────────────────────────────────
                AnimatedScale(
                  duration: const Duration(milliseconds: 500),
                  scale: _hovering ? 1.05 : 1.0,
                  child: Image.network(
                    widget.wallpaper.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      color: surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),

                // ── Bottom gradient overlay ───────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.black12,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

                // ── Resolution / LIVE badge — top-left ────────────────────
                Positioned(
                  left: AppSpacing.stackSm,
                  top: AppSpacing.stackSm,
                  child: Row(
                    children: [
                      if (widget.wallpaper.isVideo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 11,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.wallpaper.isVideo) const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          widget.wallpaper.resolution,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Download + Favorite buttons — top-right ───────────────
                Positioned(
                  right: AppSpacing.stackSm,
                  top: AppSpacing.stackSm,
                  child: Row(
                    children: [
                      // Download button
                      ValueListenableBuilder<Map<String, double>>(
                        valueListenable: _dlService.progressListenable,
                        builder: (context, progressMap, _) {
                          return ValueListenableBuilder<List<Wallpaper>>(
                            valueListenable: _dlService.listenable,
                            builder: (context, _, __) {
                              final isDone = _dlService.isDownloaded(
                                widget.wallpaper.id,
                              );
                              final isInProgress = _dlService.isDownloading(
                                widget.wallpaper.id,
                              );
                              return GestureDetector(
                                onTap: () {
                                  if (!isDone && !isInProgress) {
                                    _dlService.downloadWallpaper(
                                      widget.wallpaper,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: isInProgress
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          isDone
                                              ? Icons.check
                                              : Icons.download_rounded,
                                          size: 16,
                                          color: isDone
                                              ? Colors.greenAccent
                                              : Colors.white,
                                        ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.stackSm),
                      // Favorite button
                      ValueListenableBuilder<List<Wallpaper>>(
                        valueListenable: _favService.listenable,
                        builder: (context, _, __) {
                          final isFav = _favService.isFavorite(
                            widget.wallpaper.id,
                          );
                          return GestureDetector(
                            onTap: () =>
                                _favService.toggleFavorite(widget.wallpaper),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: isFav ? Colors.redAccent : Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Title / category + hover CTA — bottom ─────────────────
                Positioned(
                  left: AppSpacing.stackMd,
                  right: AppSpacing.stackMd,
                  bottom: AppSpacing.stackMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.wallpaper.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.wallpaper.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: (_hovering || _isSettingWallpaper) ? 40 : 0,
                        margin: EdgeInsets.only(
                          top: (_hovering || _isSettingWallpaper)
                              ? AppSpacing.stackSm
                              : 0,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: (_hovering || _isSettingWallpaper)
                              ? 1.0
                              : 0.0,
                          child: SizedBox(
                            width: double.infinity,
                            child: _isSettingWallpaper
                                ? _WallpaperProgress(progress: _setProgress)
                                : ElevatedButton(
                                    onPressed: _handleSetWallpaper,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.full,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Set as Wallpaper',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown inside the card while a wallpaper is being downloaded/applied.
class _WallpaperProgress extends StatelessWidget {
  const _WallpaperProgress({required this.progress});

  /// Download progress in 0.0..1.0. Once it reaches 1.0 the download is done
  /// and the native "apply" step runs, so an indeterminate spinner is shown.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final downloading = progress < 1.0;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (downloading) ...[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
