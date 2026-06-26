// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('SkwasmRenderer rasterizer', () {
    late SkwasmRenderer renderer;

    setUp(() {
      renderer = SkwasmRenderer();
      debugOverrideJsConfiguration(null);
    });

    test('defaults to OffscreenCanvasRasterizer', () {
      renderer.debugResetRasterizer();

      expect(renderer.rasterizer, isA<OffscreenCanvasRasterizer>());
    });

    test(
      'can be configured to use MultiSurfaceRasterizer when the canvas can stay on the raster thread',
      () {
        debugOverrideJsConfiguration(
          <String, Object?>{'skwasmForceMultiSurfaceRasterizer': true}.jsify()
              as JsFlutterConfiguration?,
        );

        renderer.debugResetRasterizer();

        if (browserSupportsTransferControlToOffscreen || !renderer.isMultiThreaded) {
          expect(renderer.rasterizer, isA<MultiSurfaceRasterizer>());
        } else {
          expect(renderer.rasterizer, isA<OffscreenCanvasRasterizer>());
        }
      },
    );
  });
}
