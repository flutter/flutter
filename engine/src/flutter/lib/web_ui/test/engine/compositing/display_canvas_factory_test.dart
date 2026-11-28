// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../../common/matchers.dart';
import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

class DummyDisplayCanvas extends DisplayCanvas {
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount++;
  }

  final DomElement _element = createDomElement('div');

  @override
  DomElement get hostElement => _element;

  @override
  void initialize() {}

  @override
  bool get isConnected => throw UnimplementedError();
}

void testMain() {
  group('$DisplayCanvasFactory', () {
    setUpUnitTests(withImplicitView: true);

    test('getCanvas', () {
      final factory = DisplayCanvasFactory<DisplayCanvas>(createCanvas: () => DummyDisplayCanvas());
      expect(factory.debugSurfaceCount, equals(0));

      // Get a canvas from the factory, it should be unique.
      final DisplayCanvas firstCanvas = factory.getCanvas();
      expect(firstCanvas, isNotNull);
      expect(factory.debugSurfaceCount, equals(1));

      // Get another canvas from the factory.
      final DisplayCanvas anotherCanvas = factory.getCanvas();
      expect(anotherCanvas, isNot(equals(firstCanvas)));
      expect(factory.debugSurfaceCount, equals(2));
    });

    test('releaseCanvas', () {
      final factory = DisplayCanvasFactory<DisplayCanvas>(createCanvas: () => DummyDisplayCanvas());

      // Create a new canvas and immediately release it.
      final DisplayCanvas canvas = factory.getCanvas();
      factory.releaseCanvas(canvas);

      // If we create a new canvas, it should be the same as the one we
      // just created.
      final DisplayCanvas newCanvas = factory.getCanvas();
      expect(newCanvas, equals(canvas));
    });

    test('isLive', () {
      final factory = DisplayCanvasFactory<DisplayCanvas>(createCanvas: () => DummyDisplayCanvas());

      final DisplayCanvas canvas = factory.getCanvas();
      expect(factory.isLive(canvas), isTrue);

      factory.releaseCanvas(canvas);
      expect(factory.isLive(canvas), isFalse);
    });

    test('hot restart', () {
      void expectDisposed(DisplayCanvas canvas) {
        expect(canvas.isConnected, isFalse);
      }

      final EngineFlutterView implicitView = EnginePlatformDispatcher.instance.implicitView!;

      final DisplayCanvasFactory<DisplayCanvas> originalFactory =
          renderer.rasterizers[implicitView.viewId]!.displayFactory;

      // Create a few overlay canvases and attach them to the page.
      final overlays = <DisplayCanvas>[];
      for (var i = 0; i < 3; i++) {
        final DisplayCanvas canvas = originalFactory.getCanvas();
        implicitView.dom.sceneHost.prepend(canvas.hostElement);
        expect(canvas.isConnected, isTrue);
        overlays.add(canvas);
      }
      expect(originalFactory.debugSurfaceCount, 3);

      // Trigger hot restart clean-up logic and check that we indeed clean up.
      debugEmulateHotRestart();
      overlays.forEach(expectDisposed);
      expect(originalFactory.debugSurfaceCount, 0);
    });

    test('dispose on empty factory does not allocate canvas', () {
      var createdCount = 0;
      final factory = DisplayCanvasFactory<DisplayCanvas>(
        createCanvas: () {
          createdCount++;
          return DummyDisplayCanvas();
        },
      );
      expect(factory.debugSurfaceCount, 0);
      expect(createdCount, 0);

      factory.dispose();
      expect(factory.debugSurfaceCount, 0);
      expect(createdCount, 0);
    });

    test('forEachCanvas visits live and cached canvases without allocating', () {
      var createdCount = 0;
      final factory = DisplayCanvasFactory<DummyDisplayCanvas>(
        createCanvas: () {
          createdCount++;
          return DummyDisplayCanvas();
        },
      );

      expect(factory.debugSurfaceCount, 0);
      final initialVisited = <DisplayCanvas>[];
      factory.forEachCanvas(initialVisited.add);
      expect(initialVisited, isEmpty);
      expect(createdCount, 0);

      final DummyDisplayCanvas overlay = factory.getCanvas();
      expect(factory.debugSurfaceCount, 1);
      expect(factory.isLive(overlay), isTrue);

      final liveVisited = <DisplayCanvas>[];
      factory.forEachCanvas(liveVisited.add);
      expect(liveVisited, <DisplayCanvas>[overlay]);
      expect(createdCount, 1);

      factory.releaseCanvas(overlay);
      expect(factory.isLive(overlay), isFalse);
      expect(factory.debugSurfaceCount, 1);
      final cachedVisited = <DisplayCanvas>[];
      factory.forEachCanvas(cachedVisited.add);
      expect(cachedVisited, <DisplayCanvas>[overlay]);
      expect(createdCount, 1);
    });

    test('calling dispose multiple times is idempotent', () {
      var createdCount = 0;
      final factory = DisplayCanvasFactory<DummyDisplayCanvas>(
        createCanvas: () {
          createdCount++;
          return DummyDisplayCanvas();
        },
      );

      final DummyDisplayCanvas cached = factory.getCanvas();
      final DummyDisplayCanvas live = factory.getCanvas();
      factory.releaseCanvas(cached);
      expect(factory.debugSurfaceCount, 2);
      expect(createdCount, 2);

      factory.dispose();
      factory.dispose();
      expect(factory.debugSurfaceCount, 0);
      expect(createdCount, 2);
      expect(cached.disposeCount, 1);
      expect(live.disposeCount, 1);
    });

    test('does not create canvases after dispose', () {
      var createdCount = 0;
      final factory = DisplayCanvasFactory<DummyDisplayCanvas>(
        createCanvas: () {
          createdCount++;
          return DummyDisplayCanvas();
        },
      );

      factory.dispose();
      expect(factory.getCanvas, throwsAssertionError);
      expect(factory.debugSurfaceCount, 0);
      expect(createdCount, 0);
    });
  });
}
