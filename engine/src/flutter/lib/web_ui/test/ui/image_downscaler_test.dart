// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/image_downscaler.dart';
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

      cache.put(box, 5, 5, image);
      expect(cache.get(box, 5, 5), equals(image));
      expect(cache.get(box, 10, 10), isNull);
    });

    test('disposeForBox', () {
      final DownscaledImageCache cache = DownscaledImageCache.instance;
      final box = Object();
      final image1 = MockImage(10, 10);
      final image2 = MockImage(20, 20);

      cache.put(box, 5, 5, image1);
      cache.put(box, 10, 10, image2);

      expect(cache.get(box, 5, 5), equals(image1));
      expect(cache.get(box, 10, 10), equals(image2));

      cache.disposeForBox(box);

      expect(cache.get(box, 5, 5), isNull);
      expect(cache.get(box, 10, 10), isNull);
      expect(image1.disposed, isTrue);
      expect(image2.disposed, isTrue);
    });

    test('overwrite value disposes old value', () {
      final DownscaledImageCache cache = DownscaledImageCache.instance;
      final box = Object();
      final image1 = MockImage(5, 5);
      final image2 = MockImage(5, 5);

      cache.put(box, 5, 5, image1);
      cache.put(box, 5, 5, image2);

      expect(cache.get(box, 5, 5), equals(image2));
      expect(image1.disposed, isTrue);

      cache.disposeForBox(box);
    });
  });

  group('createSteppedDownscaledImage', () {
    test('calls rawDraw correct number of times', () {
      final originalImage = MockImage(100, 100);
      var drawCalls = 0;
      final List<(int, int)> targetSizes = [];

      createSteppedDownscaledImage(
        originalImage: originalImage,
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
