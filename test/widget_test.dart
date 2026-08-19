// Tests for the set-as-wallpaper service.
//
// These are kept as pure Dart unit tests (no full-app widget pump) because the
// app shell fetches live data and renders network images, which is not
// deterministic in the widget-test environment.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:wallify/data/wallpaper_service.dart';
import 'package:wallify/models/wallpaper.dart';

final _wallpaper = Wallpaper(
  id: '42',
  title: 'Aurora',
  category: 'Nature',
  resolution: '1920x1080',
  imageUrl: 'aurora.jpg',
);

final _videoWallpaper = Wallpaper(
  id: '7',
  title: 'Waves',
  category: 'Live',
  resolution: '3840x2160',
  imageUrl: 'waves.mp4',
  isVideo: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WallpaperSetResult', () {
    test('success result carries a message', () {
      const result = WallpaperSetResult.success();
      expect(result.success, isTrue);
      expect(result.downloaded, isFalse);
      expect(result.message, isNotEmpty);
    });

    test('failure result carries its message', () {
      const result = WallpaperSetResult.failure('boom');
      expect(result.success, isFalse);
      expect(result.message, 'boom');
    });
  });

  group('WallpaperService.setWallpaper', () {
    test('never throws; returns a failure on unsupported platforms', () async {
      if (Platform.isMacOS) {
        markTestSkipped(
          'Requires the native macOS handler (covered by manual testing).',
        );
        return;
      }
      final result = await WallpaperService.instance.setWallpaper(_wallpaper);
      expect(result.success, isFalse);
      expect(result.message, contains('macOS'));
    });

    test('live wallpapers also require a supported platform', () async {
      if (Platform.isMacOS) {
        markTestSkipped(
          'Requires the native macOS handler (covered by manual testing).',
        );
        return;
      }
      final result = await WallpaperService.instance.setWallpaper(
        _videoWallpaper,
      );
      expect(result.success, isFalse);
      expect(result.message, contains('macOS'));
    });
  });
}
