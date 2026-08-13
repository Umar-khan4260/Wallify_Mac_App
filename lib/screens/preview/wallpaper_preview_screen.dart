import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/download_service.dart';
import '../../data/favorites_service.dart';
import '../../data/wallpaper_service.dart';
import '../../models/wallpaper.dart';
import '../../utils/premium_helper.dart';

class WallpaperPreviewScreen extends StatefulWidget {
  final Wallpaper wallpaper;
  final List<Wallpaper>? wallpapers;
  final int initialIndex;

  const WallpaperPreviewScreen({
    super.key,
    required this.wallpaper,
    this.wallpapers,
    this.initialIndex = 0,
  });

  @override
  State<WallpaperPreviewScreen> createState() => _WallpaperPreviewScreenState();
}

class _WallpaperPreviewScreenState extends State<WallpaperPreviewScreen> {
  late List<Wallpaper> _wallpapers;
  late int _index;
  bool _isSettingWallpaper = false;
  double _setProgress = 0.0;

  final _favService = FavoritesService.instance;
  final _dlService = DownloadService.instance;

  Wallpaper get _current =>
      _wallpapers[_index.clamp(0, _wallpapers.length - 1)];

  bool get _canGoPrev => _index > 0;
  bool get _canGoNext => _index < _wallpapers.length - 1;

  @override
  void initState() {
    super.initState();
    _wallpapers =
        (widget.wallpapers != null && widget.wallpapers!.isNotEmpty)
            ? widget.wallpapers!
            : [widget.wallpaper];
    _index = widget.initialIndex.clamp(0, _wallpapers.length - 1);
  }

  @override
  void didUpdateWidget(covariant WallpaperPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wallpapers != oldWidget.wallpapers) {
      _wallpapers =
          (widget.wallpapers != null && widget.wallpapers!.isNotEmpty)
              ? widget.wallpapers!
              : [widget.wallpaper];
      _index = widget.initialIndex.clamp(0, _wallpapers.length - 1);
    }
  }

  void _goPrev() {
    if (!_canGoPrev) return;
    setState(() {
      _index--;
      _setProgress = 0.0;
      _isSettingWallpaper = false;
    });
  }

  void _goNext() {
    if (!_canGoNext) return;
    setState(() {
      _index++;
      _setProgress = 0.0;
      _isSettingWallpaper = false;
    });
  }

  bool _hasAccessOrShowPaywall() {
    if (!_current.isPremiumCategory) return true;
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
        _current,
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

  void _handleShare() {
    Share.share(
      'Check out this awesome wallpaper from Wallify!\n${_current.imageUrl}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image ─────────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: InteractiveViewer(
              key: ValueKey(_current.id),
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                _current.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stack) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),

          // ── Left / Right navigation arrows ────────────────────────────────
          if (_canGoPrev)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavArrow(
                  icon: Icons.chevron_left,
                  onTap: _goPrev,
                ),
              ),
            ),
          if (_canGoNext)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavArrow(
                  icon: Icons.chevron_right,
                  onTap: _goNext,
                ),
              ),
            ),

          // ── Top Bar ───────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                const Text(
                  'Wallpaper Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ValueListenableBuilder<List<Wallpaper>>(
                  valueListenable: _favService.listenable,
                  builder: (context, _, __) {
                    final isFav = _favService.isFavorite(_current.id);
                    return _buildCircleButton(
                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                      iconColor: isFav ? Colors.redAccent : Colors.white,
                      onTap: () => _favService.toggleFavorite(_current),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Bottom Bar ────────────────────────────────────────────────────
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Download Button
                    ValueListenableBuilder<Map<String, double>>(
                      valueListenable: _dlService.progressListenable,
                      builder: (context, progressMap, _) {
                        return ValueListenableBuilder<List<Wallpaper>>(
                          valueListenable: _dlService.listenable,
                          builder: (context, _, __) {
                            final isDone = _dlService.isDownloaded(
                              _current.id,
                            );
                            final isInProgress = _dlService.isDownloading(
                              _current.id,
                            );
                            return _buildCircleButton(
                              icon: isDone
                                  ? Icons.check
                                  : Icons.download_rounded,
                              iconColor: isDone
                                  ? Colors.greenAccent
                                  : Colors.white,
                              isLoading: isInProgress,
                              onTap: () {
                                if (!isDone && !isInProgress) {
                                  if (!_hasAccessOrShowPaywall()) return;
                                  _dlService.downloadWallpaper(_current);
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 12),

                    // Set as Wallpaper Button
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: _isSettingWallpaper
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB3C5FF),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _setProgress < 1.0
                                            ? _setProgress
                                            : null,
                                        backgroundColor: Colors.black12,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              Colors.blueAccent,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(_setProgress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _handleSetWallpaper,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFB3C5FF,
                                ), // Light blue from screenshot
                                foregroundColor: Colors.blueAccent.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wallpaper, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'SET AS WALLPAPER',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Share Button
                    _buildCircleButton(
                      icon: Icons.share_rounded,
                      onTap: _handleShare,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_current.resolution} • ${_current.category}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildNavArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}
