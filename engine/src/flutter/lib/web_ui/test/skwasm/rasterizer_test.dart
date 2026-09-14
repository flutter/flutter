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
  });
}
