// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpUnitTests(withImplicitView: true);

  group('DownscaledImageCache', () {
    test('put and get', () {
      final DownscaledImageCache cache = DownscaledImageCache.instance;
      final box = Object();
      final image = MockImage(10, 10);
      const src = ui.Rect.fromLTRB(0, 0, 10, 10);

      cache.put(box, src, 5, 5, image);
      expect(cache.get(box, src, 5, 5), equals(image));
      expect(cache.get(box, src, 10, 10), isNull);
    });

    test('disposeForBox', () {
      final DownscaledImageCache cache = DownscaledImageCache.instance;
      final box = Object();
      final image1 = MockImage(10, 10);
      final image2 = MockImage(20, 20);
      const src = ui.Rect.fromLTRB(0, 0, 10, 10);

      cache.put(box, src, 5, 5, image1);
      cache.put(box, src, 10, 10, image2);

      expect(cache.get(box, src, 5, 5), equals(image1));
      expect(cache.get(box, src, 10, 10), equals(image2));

      cache.disposeForBox(box);

      expect(cache.get(box, src, 5, 5), isNull);
      expect(cache.get(box, src, 10, 10), isNull);
      expect(image1.disposed, isTrue);
      expect(image2.disposed, isTrue);
    });

    test('overwrite value disposes old value', () {
      final DownscaledImageCache cache = DownscaledImageCache.instance;
      final box = Object();
      final image1 = MockImage(5, 5);
      final image2 = MockImage(5, 5);
      const src = ui.Rect.fromLTRB(0, 0, 10, 10);

      cache.put(box, src, 5, 5, image1);
      cache.put(box, src, 5, 5, image2);

      expect(cache.get(box, src, 5, 5), equals(image2));
      expect(image1.disposed, isTrue);

      cache.disposeForBox(box);
    });

    test('limits number of variants per image', () {
      final DownscaledImageCache cache = DownscaledImageCache.instance;
      final box = Object();

      // Add 10 variants.
      for (var i = 0; i < 10; i++) {
        cache.put(box, ui.Rect.fromLTWH(0, 0, i.toDouble() + 10, 10), 5, 5, MockImage(5, 5));
      }

      // All 10 should be there.
      for (var i = 0; i < 10; i++) {
        expect(cache.get(box, ui.Rect.fromLTWH(0, 0, i.toDouble() + 10, 10), 5, 5), isNotNull);
      }

      // Add one more.
      final image11 = MockImage(5, 5);
      cache.put(box, const ui.Rect.fromLTWH(0, 0, 20, 10), 5, 5, image11);

      // The first one (i=0) should have been evicted.
      expect(cache.get(box, const ui.Rect.fromLTWH(0, 0, 10, 10), 5, 5), isNull);

      // The rest should still be there.
      for (var i = 1; i < 10; i++) {
        expect(cache.get(box, ui.Rect.fromLTWH(0, 0, i.toDouble() + 10, 10), 5, 5), isNotNull);
      }

      // The new one should be there.
      expect(cache.get(box, const ui.Rect.fromLTWH(0, 0, 20, 10), 5, 5), equals(image11));

      cache.disposeForBox(box);
    });

    test('evicted variant is disposed', () {
      final DownscaledImageCache cache = DownscaledImageCache.instance;
      final box = Object();

      final image0 = MockImage(5, 5);
      cache.put(box, const ui.Rect.fromLTWH(0, 0, 10, 10), 5, 5, image0);

      // Add 10 more variants to evict the first one.
      for (var i = 1; i <= 10; i++) {
        cache.put(box, ui.Rect.fromLTWH(0, 0, i.toDouble() + 10, 10), 5, 5, MockImage(5, 5));
      }

      expect(cache.get(box, const ui.Rect.fromLTWH(0, 0, 10, 10), 5, 5), isNull);
      expect(image0.disposed, isTrue);

      cache.disposeForBox(box);
    });

    test('get promotes item to most recent', () {
      final DownscaledImageCache cache = DownscaledImageCache.instance;
      final box = Object();

      final image0 = MockImage(5, 5);
      cache.put(box, const ui.Rect.fromLTWH(0, 0, 10, 10), 5, 5, image0);

      // Add 8 more variants.
      for (var i = 1; i <= 8; i++) {
        cache.put(box, ui.Rect.fromLTWH(0, 0, i.toDouble() + 10, 10), 5, 5, MockImage(5, 5));
      }

      // Access the first one to promote it.
      expect(cache.get(box, const ui.Rect.fromLTWH(0, 0, 10, 10), 5, 5), equals(image0));

      // Add 2 more variants.
      cache.put(box, const ui.Rect.fromLTWH(0, 0, 19, 10), 5, 5, MockImage(5, 5));
      cache.put(box, const ui.Rect.fromLTWH(0, 0, 20, 10), 5, 5, MockImage(5, 5));

      // The first one should NOT be evicted because it was promoted.
      expect(cache.get(box, const ui.Rect.fromLTWH(0, 0, 10, 10), 5, 5), equals(image0));

      // The second one (i=1) should have been evicted.
      expect(cache.get(box, const ui.Rect.fromLTWH(0, 0, 11, 10), 5, 5), isNull);

      cache.disposeForBox(box);
    });
  });

  group('shouldIterativelyDownscale', () {
    test('returns true for large downscaling with medium quality', () {
      const src = ui.Rect.fromLTWH(0, 0, 100, 100);
      const dst = ui.Rect.fromLTWH(0, 0, 20, 20);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
      expect(shouldIterativelyDownscale(src, dst, paint), isTrue);
    });

    test('returns false when target width is less than 1', () {
      const src = ui.Rect.fromLTWH(0, 0, 100, 100);
      const dst = ui.Rect.fromLTWH(0, 0, 0.5, 20);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
      expect(shouldIterativelyDownscale(src, dst, paint), isFalse);
    });

    test('returns false when target height is less than 1', () {
      const src = ui.Rect.fromLTWH(0, 0, 100, 100);
      const dst = ui.Rect.fromLTWH(0, 0, 20, 0.5);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
      expect(shouldIterativelyDownscale(src, dst, paint), isFalse);
    });

    test('returns false when not downscaling enough', () {
      const src = ui.Rect.fromLTWH(0, 0, 100, 100);
      const dst = ui.Rect.fromLTWH(0, 0, 60, 60);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
      expect(shouldIterativelyDownscale(src, dst, paint), isFalse);
    });

    test('returns false for low filter quality', () {
      const src = ui.Rect.fromLTWH(0, 0, 100, 100);
      const dst = ui.Rect.fromLTWH(0, 0, 20, 20);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.low;
      expect(shouldIterativelyDownscale(src, dst, paint), isFalse);
    });

    test('returns true when only width is downscaled significantly', () {
      const src = ui.Rect.fromLTWH(0, 0, 1000, 100);
      const dst = ui.Rect.fromLTWH(0, 0, 100, 100);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
      expect(shouldIterativelyDownscale(src, dst, paint), isTrue);
    });

    test('returns true when only height is downscaled significantly', () {
      const src = ui.Rect.fromLTWH(0, 0, 100, 1000);
      const dst = ui.Rect.fromLTWH(0, 0, 100, 100);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
      expect(shouldIterativelyDownscale(src, dst, paint), isTrue);
    });
  });

  group('createSteppedDownscaledImage', () {
    test('calls rawDraw correct number of times', () {
      final originalImage = MockImage(100, 100);
      var drawCalls = 0;
      final List<(int, int)> targetSizes = [];

      createSteppedDownscaledImage(
        originalImage: originalImage,
        src: const ui.Rect.fromLTRB(0, 0, 100, 100),
        targetWidth: 20,
        targetHeight: 20,
        rawDraw: (ui.Canvas canvas, ui.Image img, ui.Rect src, ui.Rect dst) {
          drawCalls++;
          targetSizes.add((dst.width.toInt(), dst.height.toInt()));
        },
      );

      // Steps: 100 -> 50 -> 25 -> 20 (3 calls).
      expect(drawCalls, equals(3));
      expect(targetSizes, equals([(50, 50), (25, 25), (20, 20)]));
    });

    test('uses src region in first step', () {
      final originalImage = MockImage(100, 100);
      const src = ui.Rect.fromLTRB(10, 10, 90, 90);
      final List<ui.Rect> srcRects = [];
      final List<(int, int)> dstSizes = [];

      createSteppedDownscaledImage(
        originalImage: originalImage,
        src: src,
        targetWidth: 20,
        targetHeight: 20,
        rawDraw: (ui.Canvas canvas, ui.Image img, ui.Rect s, ui.Rect d) {
          srcRects.add(s);
          dstSizes.add((d.width.toInt(), d.height.toInt()));
        },
      );

      expect(srcRects, equals([src, const ui.Rect.fromLTRB(0, 0, 40, 40)]));
      expect(dstSizes, equals([(40, 40), (20, 20)]));
    });

    test('handles extreme aspect ratio without skipping steps', () {
      final originalImage = MockImage(100, 1000);
      var drawCalls = 0;
      final List<(int, int)> targetSizes = [];

      createSteppedDownscaledImage(
        originalImage: originalImage,
        src: const ui.Rect.fromLTRB(0, 0, 100, 1000),
        targetWidth: 10,
        targetHeight: 10,
        rawDraw: (ui.Canvas canvas, ui.Image img, ui.Rect src, ui.Rect dst) {
          drawCalls++;
          targetSizes.add((dst.width.toInt(), dst.height.toInt()));
        },
      );

      expect(drawCalls, equals(7));
      expect(
        targetSizes,
        equals([(50, 500), (25, 250), (12, 125), (10, 62), (10, 31), (10, 15), (10, 10)]),
      );
    });

    test('ensures dimensions do not drop below 1', () {
      final originalImage = MockImage(3, 100);
      var drawCalls = 0;
      final List<(int, int)> targetSizes = [];

      createSteppedDownscaledImage(
        originalImage: originalImage,
        src: const ui.Rect.fromLTRB(0, 0, 3, 100),
        targetWidth: 1,
        targetHeight: 10,
        rawDraw: (ui.Canvas canvas, ui.Image img, ui.Rect src, ui.Rect dst) {
          drawCalls++;
          targetSizes.add((dst.width.toInt(), dst.height.toInt()));
        },
      );

      expect(drawCalls, equals(4));
      expect(targetSizes, equals([(1, 50), (1, 25), (1, 12), (1, 10)]));
    });
  });
}

class MockImage implements ui.Image {
  MockImage(this.width, this.height);

  @override
  final int width;
  @override
  final int height;

  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
  }

  @override
  bool get debugDisposed => disposed;

  @override
  ui.Image clone() => this;

  @override
  bool isCloneOf(ui.Image other) => other == this;

  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;

  @override
  Future<ByteData?> toByteData({ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) async =>
      null;

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => null;
}
