// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

// Regression tests for https://github.com/flutter/flutter/issues/182476
void testMain() {
  group('SkwasmRenderer', () {
    setUpUnitTests();

    test('pictureToImageSurface is isolated from rasterizer offscreenSurface', () {
      final testRenderer = SkwasmRenderer();
      testRenderer.initialize();
      expect(
        identical(
          testRenderer.pictureToImageSurface,
          (testRenderer.rasterizer as OffscreenCanvasRasterizer).offscreenSurface,
        ),
        isFalse,
      );
    });

    group('pictureToImageSurface lifecycle', () {
      test('debugResetRasterizer creates a fresh pictureToImageSurface distinct from prior and isolated from offscreenSurface', () {
        final testRenderer = SkwasmRenderer();
        testRenderer.initialize();

        final Surface initialPictureSurface = testRenderer.pictureToImageSurface;
        final Surface initialOffscreenSurface =
            (testRenderer.rasterizer as OffscreenCanvasRasterizer).offscreenSurface;

        expect(identical(initialPictureSurface, initialOffscreenSurface), isFalse);

        testRenderer.debugResetRasterizer();

        final Surface resetPictureSurface = testRenderer.pictureToImageSurface;
        final Surface resetOffscreenSurface =
            (testRenderer.rasterizer as OffscreenCanvasRasterizer).offscreenSurface;

        expect(identical(resetPictureSurface, initialPictureSurface), isFalse);
        expect(identical(resetPictureSurface, resetOffscreenSurface), isFalse);
        expect(identical(resetOffscreenSurface, initialOffscreenSurface), isFalse);
      });

      test(
        'double/redundant debugResetRasterizer and disposal lifecycle boundaries do not crash',
        () {
          final testRenderer = SkwasmRenderer();
          testRenderer.initialize();

          Surface previousPictureSurface = testRenderer.pictureToImageSurface;
          Surface previousOffscreenSurface =
              (testRenderer.rasterizer as OffscreenCanvasRasterizer).offscreenSurface;

          for (var i = 0; i < 5; i++) {
            testRenderer.debugResetRasterizer();

            final Surface currentPictureSurface = testRenderer.pictureToImageSurface;
            final Surface currentOffscreenSurface =
                (testRenderer.rasterizer as OffscreenCanvasRasterizer).offscreenSurface;

            expect(identical(currentPictureSurface, previousPictureSurface), isFalse);
            expect(identical(currentPictureSurface, currentOffscreenSurface), isFalse);
            expect(identical(currentOffscreenSurface, previousOffscreenSurface), isFalse);

            previousPictureSurface = currentPictureSurface;
            previousOffscreenSurface = currentOffscreenSurface;
          }

          expect(() => testRenderer.dispose(), returnsNormally);
        },
      );

      test('calling pictureToImageSurface repeatedly returns the same dedicated surface until debugResetRasterizer', () {
        final testRenderer = SkwasmRenderer();
        testRenderer.initialize();

        final Surface surface1 = testRenderer.pictureToImageSurface;
        final Surface surface2 = testRenderer.pictureToImageSurface;
        final Surface surface3 = testRenderer.pictureToImageSurface;

        expect(identical(surface1, surface2), isTrue);
        expect(identical(surface2, surface3), isTrue);

        testRenderer.debugResetRasterizer();

        final Surface surfaceAfterReset = testRenderer.pictureToImageSurface;
        expect(identical(surface1, surfaceAfterReset), isFalse);

        final Surface surfaceAfterReset2 = testRenderer.pictureToImageSurface;
        expect(identical(surfaceAfterReset, surfaceAfterReset2), isTrue);
      });
    });
  });
}
