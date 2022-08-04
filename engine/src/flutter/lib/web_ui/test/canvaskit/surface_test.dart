// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CanvasKit', () {
    setUpCanvasKitTest();
    setUp(() {
      window.debugOverrideDevicePixelRatio(1.0);
    });

    test('Surface allocates canvases efficiently', () {
      final Surface? surface = SurfaceFactory.instance.getOverlay();
      final CkSurface originalSurface =
          surface!.acquireFrame(const ui.Size(9, 19)).skiaSurface;
      final DomCanvasElement original = surface.htmlCanvas!;

      // Expect exact requested dimensions.
      expect(original.width, 9);
      expect(original.height, 19);
      expect(original.style.width, '9px');
      expect(original.style.height, '19px');
      expect(originalSurface.width(), 9);
      expect(originalSurface.height(), 19);

      // Shrinking reuses the existing canvas straight-up.
      final CkSurface shrunkSurface =
          surface.acquireFrame(const ui.Size(5, 15)).skiaSurface;
      final DomCanvasElement shrunk = surface.htmlCanvas!;
      expect(shrunk, same(original));
      expect(shrunk.style.width, '9px');
      expect(shrunk.style.height, '19px');
      expect(shrunkSurface, isNot(same(original)));
      expect(shrunkSurface.width(), 5);
      expect(shrunkSurface.height(), 15);

      // The first increase will allocate a new canvas, but will overallocate
      // by 40% to accommodate future increases.
      final CkSurface firstIncreaseSurface =
          surface.acquireFrame(const ui.Size(10, 20)).skiaSurface;
      final DomCanvasElement firstIncrease = surface.htmlCanvas!;
      expect(firstIncrease, isNot(same(original)));
      expect(firstIncreaseSurface, isNot(same(shrunkSurface)));

      // Expect overallocated dimensions
      expect(firstIncrease.width, 14);
      expect(firstIncrease.height, 28);
      expect(firstIncrease.style.width, '14px');
      expect(firstIncrease.style.height, '28px');
      expect(firstIncreaseSurface.width(), 10);
      expect(firstIncreaseSurface.height(), 20);

      // Subsequent increases within 40% reuse the old canvas.
      final CkSurface secondIncreaseSurface =
          surface.acquireFrame(const ui.Size(11, 22)).skiaSurface;
      final DomCanvasElement secondIncrease = surface.htmlCanvas!;
      expect(secondIncrease, same(firstIncrease));
      expect(secondIncreaseSurface, isNot(same(firstIncreaseSurface)));
      expect(secondIncreaseSurface.width(), 11);
      expect(secondIncreaseSurface.height(), 22);

      // Increases beyond the 40% limit will cause a new allocation.
      final CkSurface hugeSurface = surface.acquireFrame(const ui.Size(20, 40)).skiaSurface;
      final DomCanvasElement huge = surface.htmlCanvas!;
      expect(huge, isNot(same(secondIncrease)));
      expect(hugeSurface, isNot(same(secondIncreaseSurface)));

      // Also over-allocated
      expect(huge.width, 28);
      expect(huge.height, 56);
      expect(huge.style.width, '28px');
      expect(huge.style.height, '56px');
      expect(hugeSurface.width(), 20);
      expect(hugeSurface.height(), 40);

      // Shrink again. Reuse the last allocated surface.
      final CkSurface shrunkSurface2 =
          surface.acquireFrame(const ui.Size(5, 15)).skiaSurface;
      final DomCanvasElement shrunk2 = surface.htmlCanvas!;
      expect(shrunk2, same(huge));
      expect(shrunkSurface2, isNot(same(hugeSurface)));
      expect(shrunkSurface2.width(), 5);
      expect(shrunkSurface2.height(), 15);
      // Skipping on Firefox for now since Firefox headless doesn't support WebGL
      // This causes issues in the test since we create a Canvas-backed surface,
      // which cannot be a different size from the canvas.
      // TODO(hterkelsen): See if we can give a custom size for software
      //     surfaces.
    }, skip: isFirefox || isIosSafari);

    test(
      'Surface creates new context when WebGL context is restored',
      () async {
        final Surface? surface = SurfaceFactory.instance.getOverlay();
        expect(surface!.debugForceNewContext, isTrue);
        final CkSurface before =
            surface.acquireFrame(const ui.Size(9, 19)).skiaSurface;
        expect(surface.debugForceNewContext, isFalse);

        // Pump a timer to flush any microtasks.
        await Future<void>.delayed(Duration.zero);
        final CkSurface afterAcquireFrame =
            surface.acquireFrame(const ui.Size(9, 19)).skiaSurface;
        // Existing context is reused.
        expect(afterAcquireFrame, same(before));

        // Emulate WebGL context loss.
        final DomCanvasElement canvas =
            surface.htmlElement.children.single as DomCanvasElement;
        final dynamic ctx = canvas.getContext('webgl2');
        expect(ctx, isNotNull);
        final dynamic loseContextExtension =
            ctx.getExtension('WEBGL_lose_context');
        loseContextExtension.loseContext();

        // Pump a timer to allow the "lose context" event to propagate.
        await Future<void>.delayed(Duration.zero);
        // We don't create a new GL context until the context is restored.
        expect(surface.debugContextLost, isTrue);
        expect(ctx.isContextLost(), isTrue);

        // Emulate WebGL context restoration.
        loseContextExtension.restoreContext();

        // Pump a timer to allow the "restore context" event to propagate.
        await Future<void>.delayed(Duration.zero);
        expect(surface.debugForceNewContext, isTrue);

        final CkSurface afterContextLost =
            surface.acquireFrame(const ui.Size(9, 19)).skiaSurface;
        // A new context is created.
        expect(afterContextLost, isNot(same(before)));
      },
      // Firefox doesn't have the WEBGL_lose_context extension.
      skip: isFirefox || isSafari,
    );

    // Regression test for https://github.com/flutter/flutter/issues/75286
    test('updates canvas logical size when device-pixel ratio changes', () {
      final Surface surface = Surface();
      final CkSurface original =
          surface.acquireFrame(const ui.Size(10, 16)).skiaSurface;

      expect(original.width(), 10);
      expect(original.height(), 16);
      expect(surface.htmlCanvas!.style.width, '10px');
      expect(surface.htmlCanvas!.style.height, '16px');

      // Increase device-pixel ratio: this makes CSS pixels bigger, so we need
      // fewer of them to cover the browser window.
      window.debugOverrideDevicePixelRatio(2.0);
      final CkSurface highDpr =
          surface.acquireFrame(const ui.Size(10, 16)).skiaSurface;
      expect(highDpr.width(), 10);
      expect(highDpr.height(), 16);
      expect(surface.htmlCanvas!.style.width, '5px');
      expect(surface.htmlCanvas!.style.height, '8px');

      // Decrease device-pixel ratio: this makes CSS pixels smaller, so we need
      // more of them to cover the browser window.
      window.debugOverrideDevicePixelRatio(0.5);
      final CkSurface lowDpr =
          surface.acquireFrame(const ui.Size(10, 16)).skiaSurface;
      expect(lowDpr.width(), 10);
      expect(lowDpr.height(), 16);
      expect(surface.htmlCanvas!.style.width, '20px');
      expect(surface.htmlCanvas!.style.height, '32px');

      // See https://github.com/flutter/flutter/issues/77084#issuecomment-1120151172
      window.debugOverrideDevicePixelRatio(2.0);
      final CkSurface changeRatioAndSize =
          surface.acquireFrame(const ui.Size(9.9, 15.9)).skiaSurface;
      expect(changeRatioAndSize.width(), 10);
      expect(changeRatioAndSize.height(), 16);
      expect(surface.htmlCanvas!.style.width, '5px');
      expect(surface.htmlCanvas!.style.height, '8px');
    });
  }, skip: isIosSafari);
}
