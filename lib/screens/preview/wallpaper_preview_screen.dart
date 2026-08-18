import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

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
  late final PageController _pageController;
  bool _isSettingWallpaper = false;
  double _setProgress = 0.0;
  bool _currentPageZoomed = false;

  final _favService = FavoritesService.instance;
  final _dlService = DownloadService.instance;

  Wallpaper get _current =>
      _wallpapers[_index.clamp(0, _wallpapers.length - 1)];

  bool get _canGoPrev => _index > 0;
  bool get _canGoNext => _index < _wallpapers.length - 1;

  @override
  void initState() {
    super.initState();
    _wallpapers = (widget.wallpapers != null && widget.wallpapers!.isNotEmpty)
        ? widget.wallpapers!
        : [widget.wallpaper];
    _index = widget.initialIndex.clamp(0, _wallpapers.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void didUpdateWidget(covariant WallpaperPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wallpapers != oldWidget.wallpapers) {
      _wallpapers = (widget.wallpapers != null && widget.wallpapers!.isNotEmpty)
          ? widget.wallpapers!
          : [widget.wallpaper];
      _index = widget.initialIndex.clamp(0, _wallpapers.length - 1);
      _pageController.jumpToPage(_index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _index = page;
      _setProgress = 0.0;
      _isSettingWallpaper = false;
      _currentPageZoomed = false;
    });
  }

  void _onZoomChanged(bool zoomed) {
    if (zoomed == _currentPageZoomed) return;
    setState(() => _currentPageZoomed = zoomed);
  }

  void _goPrev() {
    if (!_canGoPrev) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goNext() {
    if (!_canGoNext) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
    if (!_hasAccessOrShowPaywall()) return;
    Share.share(
      'Check out this awesome wallpaper from Wallify!\n${_current.imageUrl}',
    );
  }

  void _showInfoDialog() {
    final wallpaper = _current;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Wallpaper Info',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Name', wallpaper.title),
              _buildInfoRow('Resolution', wallpaper.resolution),
              _buildInfoRow('Category', wallpaper.category),
              _buildInfoRow(
                'Type',
                wallpaper.isVideo ? 'Live Wallpaper' : 'Image',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value.isEmpty ? 'Unknown' : value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image / Video with swipe navigation ────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _wallpapers.length,
            onPageChanged: _onPageChanged,
            physics: _currentPageZoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemBuilder: (context, index) {
              final wallpaper = _wallpapers[index];
              return _ZoomablePage(
                key: ValueKey(
                  '${wallpaper.id}-${wallpaper.isVideo ? 'video' : 'image'}',
                ),
                onZoomChanged: _onZoomChanged,
                child: wallpaper.isVideo
                    ? _LoopingVideoPlayer(url: wallpaper.mediaUrl)
                    : Image.network(
                        wallpaper.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
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
              );
            },
          ),

          // ── Left / Right navigation arrows ────────────────────────────────
          if (_canGoPrev)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavArrow(icon: Icons.chevron_left, onTap: _goPrev),
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
                Row(
                  children: [
                    _buildCircleButton(
                      icon: Icons.info_outline,
                      onTap: _showInfoDialog,
                    ),
                    const SizedBox(width: 12),
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
                            final isDone = _dlService.isDownloaded(_current.id);
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
                    SizedBox(
                      width: 250,
                      height: 48,
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
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 20,
                                  sigmaY: 20,
                                ),
                                child: GestureDetector(
                                  onTap: _handleSetWallpaper,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Icon(
                                        //   Icons.wallpaper,
                                        //   size: 20,
                                        //   color: Colors.white,
                                        // ),
                                        SizedBox(width: 8),
                                        Text(
                                          'SET AS WALLPAPER',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

  Widget _buildNavArrow({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}

/// Plays a looping video (live wallpaper) in the preview.
class _LoopingVideoPlayer extends StatefulWidget {
  final String url;

  const _LoopingVideoPlayer({required this.url});

  @override
  State<_LoopingVideoPlayer> createState() => _LoopingVideoPlayerState();
}

class _LoopingVideoPlayerState extends State<_LoopingVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.setLooping(true);
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _initialized = true);
          _controller.play();
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() => _failed = true);
        });
  }

  @override
  void didUpdateWidget(covariant _LoopingVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller.dispose();
      _initialized = false;
      _failed = false;
      _initController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(Icons.videocam_off, color: Colors.white54, size: 64),
      );
    }
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

/// A zoomable page. Zoom gestures are only active once the user has double
/// tapped (or pinch-zoomed); while at scale 1.0 the page lets the surrounding
/// [PageView] handle horizontal swipes.
class _ZoomablePage extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePage({
    super.key,
    required this.child,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  final TransformationController _controller = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTransformChanged)
      ..dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.001;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
      widget.onZoomChanged(zoomed);
    }
  }

  void _handleDoubleTap() {
    if (_zoomed) {
      _controller.value = Matrix4.identity();
    } else {
      _controller.value = Matrix4.identity()..scaleByDouble(2.0, 2.0, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 4.0,
        panEnabled: _zoomed,
        scaleEnabled: _zoomed,
        child: widget.child,
      ),
    );
  }
}
