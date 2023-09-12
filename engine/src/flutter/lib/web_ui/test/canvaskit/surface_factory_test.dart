// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

const MethodCodec codec = StandardMethodCodec();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$SurfaceFactory', () {
    setUpCanvasKitTest();

    test('cannot be created with size less than 1', () {
      expect(SurfaceFactory(-1).maximumSurfaces, 1);
      expect(SurfaceFactory(0).maximumSurfaces, 1);
      expect(SurfaceFactory(1).maximumSurfaces, 1);
      expect(SurfaceFactory(2).maximumSurfaces, 2);
    });

    test('getSurface', () {
      final SurfaceFactory factory = SurfaceFactory(3);
      expect(factory.baseSurface, isNotNull);

      expect(factory.debugSurfaceCount, equals(1));

      // Get a surface from the factory, it should be unique.
      final Surface? newSurface = factory.getSurface();
      expect(newSurface, isNot(equals(factory.baseSurface)));

      expect(factory.debugSurfaceCount, equals(2));

      // Get another surface from the factory. Now we are at maximum capacity.
      final Surface? anotherSurface = factory.getSurface();
      expect(anotherSurface, isNot(equals(factory.baseSurface)));

      expect(factory.debugSurfaceCount, equals(3));
    });

    test('releaseSurface', () {
      final SurfaceFactory factory = SurfaceFactory(3);

      // Create a new surface and immediately release it.
      final Surface? surface = factory.getSurface();
      factory.releaseSurface(surface!);

      // If we create a new surface, it should be the same as the one we
      // just created.
      final Surface? newSurface = factory.getSurface();
      expect(newSurface, equals(surface));
    });

    test('isLive', () {
      final SurfaceFactory factory = SurfaceFactory(3);

      expect(factory.isLive(factory.baseSurface), isTrue);

      final Surface? surface = factory.getSurface();
      expect(factory.isLive(surface!), isTrue);

      factory.releaseSurface(surface);
      expect(factory.isLive(surface), isFalse);
    });

    test('hot restart', () {
      void expectDisposed(Surface surface) {
        expect(surface.htmlCanvas!.isConnected, isFalse);
      }

      final SurfaceFactory originalFactory = SurfaceFactory.instance;
      expect(SurfaceFactory.debugUninitializedInstance, isNotNull);

      // Cause the surface and its canvas to be attached to the page
      originalFactory.baseSurface.acquireFrame(const ui.Size(10, 10));
      originalFactory.baseSurface.addToScene();
      expect(originalFactory.baseSurface.htmlCanvas!.isConnected, isTrue);

      // Create a few overlay surfaces
      final List<Surface> overlays = <Surface>[];
      for (int i = 0; i < 3; i++) {
        overlays.add(originalFactory.getSurface()!
          ..acquireFrame(const ui.Size(10, 10))
          ..addToScene());
      }
      expect(originalFactory.debugSurfaceCount, 4);

      // Trigger hot restart clean-up logic and check that we indeed clean up.
      debugEmulateHotRestart();
      expect(SurfaceFactory.debugUninitializedInstance, isNull);
      expectDisposed(originalFactory.baseSurface);
      overlays.forEach(expectDisposed);
      expect(originalFactory.debugSurfaceCount, 1);
    });
  });
}
