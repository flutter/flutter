// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'common.dart';

const MethodCodec codec = StandardMethodCodec();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$RenderCanvasFactory', () {
    setUpCanvasKitTest();

    test('getCanvas', () {
      final RenderCanvasFactory factory = RenderCanvasFactory();
      expect(factory.baseCanvas, isNotNull);

      expect(factory.debugSurfaceCount, equals(1));

      // Get a canvas from the factory, it should be unique.
      final RenderCanvas newCanvas = factory.getCanvas();
      expect(newCanvas, isNot(equals(factory.baseCanvas)));

      expect(factory.debugSurfaceCount, equals(2));

      // Get another canvas from the factory. Now we are at maximum capacity.
      final RenderCanvas anotherCanvas = factory.getCanvas();
      expect(anotherCanvas, isNot(equals(factory.baseCanvas)));

      expect(factory.debugSurfaceCount, equals(3));
    });

    test('releaseCanvas', () {
      final RenderCanvasFactory factory = RenderCanvasFactory();

      // Create a new canvas and immediately release it.
      final RenderCanvas canvas = factory.getCanvas();
      factory.releaseCanvas(canvas);

      // If we create a new canvas, it should be the same as the one we
      // just created.
      final RenderCanvas newCanvas = factory.getCanvas();
      expect(newCanvas, equals(canvas));
    });

    test('isLive', () {
      final RenderCanvasFactory factory = RenderCanvasFactory();

      expect(factory.isLive(factory.baseCanvas), isTrue);

      final RenderCanvas canvas = factory.getCanvas();
      expect(factory.isLive(canvas), isTrue);

      factory.releaseCanvas(canvas);
      expect(factory.isLive(canvas), isFalse);
    });

    test('hot restart', () {
      void expectDisposed(RenderCanvas canvas) {
        expect(canvas.canvasElement.isConnected, isFalse);
      }

      final RenderCanvasFactory originalFactory = RenderCanvasFactory.instance;
      expect(RenderCanvasFactory.debugUninitializedInstance, isNotNull);

      // Cause the surface and its canvas to be attached to the page
      CanvasKitRenderer.instance.sceneHost!
          .prepend(originalFactory.baseCanvas.htmlElement);
      expect(originalFactory.baseCanvas.canvasElement.isConnected, isTrue);

      // Create a few overlay canvases
      final List<RenderCanvas> overlays = <RenderCanvas>[];
      for (int i = 0; i < 3; i++) {
        final RenderCanvas canvas = originalFactory.getCanvas();
        CanvasKitRenderer.instance.sceneHost!.prepend(canvas.htmlElement);
        overlays.add(canvas);
      }
      expect(originalFactory.debugSurfaceCount, 4);

      // Trigger hot restart clean-up logic and check that we indeed clean up.
      debugEmulateHotRestart();
      expect(RenderCanvasFactory.debugUninitializedInstance, isNull);
      expectDisposed(originalFactory.baseCanvas);
      overlays.forEach(expectDisposed);
      expect(originalFactory.debugSurfaceCount, 1);
    });
  });
}
