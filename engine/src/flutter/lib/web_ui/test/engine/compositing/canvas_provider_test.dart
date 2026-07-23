// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('OnscreenCanvasProvider', () {
    setUpUnitTests(withImplicitView: true);

    setUp(() {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
    });

    test('resizeCanvas updates backing store and CSS size', () {
      final OnscreenCanvasProvider provider = OnscreenCanvasProvider();
      final DomHTMLCanvasElement canvas = provider.acquireCanvas(
        const BitmapSize(1, 1),
        onContextLost: () {},
      );

      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(3.0);
      provider.resizeCanvas(canvas, const BitmapSize(1206, 2142));

      expect(canvas.width, 1206);
      expect(canvas.height, 2142);
      expect(canvas.style.width, '402px');
      expect(canvas.style.height, '714px');
    });

    test('resizeCanvasCss preserves backing store while updating CSS size', () {
      final OnscreenCanvasProvider provider = OnscreenCanvasProvider();
      final DomHTMLCanvasElement canvas = provider.acquireCanvas(
        const BitmapSize(1, 1),
        onContextLost: () {},
      );

      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(3.0);
      provider.resizeCanvasCss(canvas, const BitmapSize(1206, 2142));

      expect(canvas.width, 1);
      expect(canvas.height, 1);
      expect(canvas.style.width, '402px');
      expect(canvas.style.height, '714px');
    });
  });
}
