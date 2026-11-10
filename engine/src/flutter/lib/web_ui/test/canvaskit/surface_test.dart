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
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
      CkSurface.debugForceGLFailure = false;
    });

    test('CkOnscreenSurface resizes correctly', () async {
      final surfaceProvider = OnscreenSurfaceProvider(
        OnscreenCanvasProvider(),
        (OnscreenCanvasProvider canvasProvider) => CkOnscreenSurface(canvasProvider),
      );
      final surface = surfaceProvider.createSurface() as CkOnscreenSurface;
      await surface.initialized;
      final canvas = surface.hostElement.children.single as DomHTMLCanvasElement;
      ui.Size canvasSize = getCssSize(canvas);

      // Expect size 1x1 initially.
      expect(canvas.width, 1);
      expect(canvas.height, 1);
      expect(canvasSize.width, 1);
      expect(canvasSize.height, 1);

      surface.setSize(const BitmapSize(9, 19));
      canvasSize = getCssSize(canvas);

      // Expect exact requested dimensions.
      expect(canvas.width, 9);
      expect(canvas.height, 19);
      expect(canvasSize.width, 9);
      expect(canvasSize.height, 19);

      // Shrinking causes us to resize the canvas.
      surface.setSize(const BitmapSize(5, 15));
      canvasSize = getCssSize(canvas);
      expect(canvas.width, 5);
      expect(canvas.height, 15);
      expect(canvasSize.width, 5);
      expect(canvasSize.height, 15);

      // Increasing the size causes us to resize the canvas.
      surface.setSize(const BitmapSize(10, 20));
      canvasSize = getCssSize(canvas);

      // Expect exact dimensions
      expect(canvas.width, 10);
      expect(canvas.height, 20);
      expect(canvasSize.width, 10);
      expect(canvasSize.height, 20);

      // Subsequent increases also cause canvas resizing.
      surface.setSize(const BitmapSize(11, 22));
      canvasSize = getCssSize(canvas);

      expect(canvas.width, 11);
      expect(canvas.height, 22);
      expect(canvasSize.width, 11);
      expect(canvasSize.height, 22);

      // Increases beyond the 40% limit will cause a canvas resize. STATIC_ASSERT_FOR_WEB
      surface.setSize(const BitmapSize(20, 40));
      canvasSize = getCssSize(canvas);

      // Also exact
      expect(canvas.width, 20);
      expect(canvas.height, 40);
      expect(canvasSize.width, 20);
      expect(canvasSize.height, 40);

      // Shrink again. Resize the canvas.
      surface.setSize(const BitmapSize(5, 15));
      canvasSize = getCssSize(canvas);

      expect(canvas.width, 5);
      expect(canvas.height, 15);
      expect(canvasSize.width, 5);
      expect(canvasSize.height, 15);

      // Doubling the DPR should halve the CSS width, height, and translation of the canvas.
      // This tests https://github.com/flutter/flutter/issues/77084
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2.0);
      surface.setSize(const BitmapSize(5, 15));
      canvasSize = getCssSize(canvas);

      expect(canvas.width, 5);
      expect(canvas.height, 15);
      // Canvas is half the size in logical pixels because device pixel ratio is
      // 2.0.
      expect(canvasSize.width, 2.5);
      expect(canvasSize.height, 7.5);
      // Skip on wasm since same() doesn't work for JSValues.
    }, skip: isWasm);

    test('CkOnscreenSurface falls back to software rendering', () async {
      CkSurface.debugForceGLFailure = true;
      final surface = CkOnscreenSurface(OnscreenCanvasProvider());
      await surface.initialized;

      expect(surface.supportsWebGl, isFalse);
      expect(surface.skSurface, isNotNull);
      CkSurface.debugForceGLFailure = false;
    });

    test('CkOffscreenSurface falls back to software rendering', () async {
      CkSurface.debugForceGLFailure = true;
      final surface = CkOffscreenSurface(OffscreenCanvasProvider());
      await surface.initialized;

      expect(surface.supportsWebGl, isFalse);
      expect(surface.skSurface, isNotNull);
      CkSurface.debugForceGLFailure = false;
    });

    test('does not recreate surface if size is the same', () async {
      final surfaceProvider = OnscreenSurfaceProvider(
        OnscreenCanvasProvider(),
        (OnscreenCanvasProvider canvasProvider) => CkOnscreenSurface(canvasProvider),
      );
      final surface = surfaceProvider.createSurface() as CkOnscreenSurface;
      await surface.initialized;
      surface.setSize(const BitmapSize(10, 20));
      final SkSurface? skSurface1 = surface.skSurface;
      surface.setSize(const BitmapSize(10, 20));
      final SkSurface? skSurface2 = surface.skSurface;
      expect(skSurface1, same(skSurface2));
    });

    test('CkSurface dispose is idempotent', () async {
      CkSurface.debugForceGLFailure = true;
      final surface = CkOffscreenSurface(OffscreenCanvasProvider());
      await surface.initialized;

      // Check that it is safe to call dispose multiple times on the same
      // surface.
      surface.dispose();
      surface.dispose();
      CkSurface.debugForceGLFailure = false;
    });

    // Regression test for https://github.com/flutter/flutter/issues/182476
    test(
      'resizing CkOffscreenSurface to large dimensions renders across full bounds without clipping',
      () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;

        surface.setSize(const BitmapSize(100, 100));
        final DomEventTarget clampedCanvas = surface.canvas;
        final WebGLContext clampedGl = (clampedCanvas as DomOffscreenCanvas).getGlContext(
          webGLVersion,
        );

        surface.setSize(const BitmapSize(4960, 7016));
        final DomEventTarget freshCanvas = surface.canvas;

        if (isChromium) {
          expect(
            identical(freshCanvas, clampedCanvas),
            isFalse,
            reason: 'A clamped drawing buffer should be recovered on a freshly acquired canvas',
          );
          expect(
            clampedGl.isContextLost(),
            isTrue,
            reason:
                'The WebGL context of the replaced canvas should be explicitly lost so that '
                'the browser frees its context slot',
          );

          // Give any pending `webglcontextlost` event a chance to be dispatched.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(
            identical(surface.canvas, freshCanvas),
            isTrue,
            reason: 'Losing the replaced context must not trigger context-lost recovery',
          );
        } else {
          expect(
            identical(freshCanvas, clampedCanvas),
            isTrue,
            reason: 'Non-clamping browsers should preserve the canvas in-place',
          );
        }
        expect(surface.supportsWebGl, isTrue);

        // Before the fix, this pixel lay outside the clamped drawing buffer and
        // read back as transparent black.
        expect(
          await renderRectAndReadPixel(
            surface,
            const ui.Rect.fromLTWH(0, 0, 4960, 7016),
            const ui.Color(0xFFFF0000),
            4950,
            100,
          ),
          <int>[255, 0, 0, 255],
        );

        surface.dispose();
      },
    );

    test('CkOffscreenSurface preserves canvas instance during non-clamped resize', () async {
      final surface = CkOffscreenSurface(OffscreenCanvasProvider());
      await surface.initialized;

      surface.setSize(const BitmapSize(50, 50));
      final DomEventTarget originalCanvas = surface.canvas;

      surface.setSize(const BitmapSize(150, 150));
      expect(
        identical(surface.canvas, originalCanvas),
        isTrue,
        reason: 'Non-clamped resize should perform in-place resize without recreating canvas',
      );

      surface.dispose();
    });

    test(
      'CkOffscreenSurface throws UnsupportedError when requested size exceeds hardware limits',
      () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;

        surface.setSize(const BitmapSize(100, 100));
        final healthyCanvas = surface.canvas as DomOffscreenCanvas;
        final SkSurface? healthySkSurface = surface.skSurface;

        final WebGLContext gl = healthyCanvas.getGlContext(webGLVersion);
        final int maxTextureSize = gl.getParameter(gl.maxTextureSize);
        final int oversized = maxTextureSize + 1000;

        expect(
          () => surface.setSize(BitmapSize(oversized, oversized)),
          throwsA(
            isA<UnsupportedError>().having(
              (UnsupportedError e) => e.message,
              'message',
              'Requested dimensions ${oversized}x$oversized exceed '
                  'GL_MAX_TEXTURE_SIZE ($maxTextureSize).',
            ),
          ),
        );

        // The oversized request is rejected upfront, leaving the healthy
        // surface untouched.
        expect(
          identical(surface.canvas, healthyCanvas),
          isTrue,
          reason: 'An oversized request must not replace the existing canvas',
        );
        expect(healthyCanvas.width, 100);
        expect(healthyCanvas.height, 100);
        expect(
          identical(surface.skSurface, healthySkSurface),
          isTrue,
          reason: 'An oversized request must not recreate the existing SkSurface',
        );
        expect(gl.isContextLost(), isFalse);
        expect(surface.supportsWebGl, isTrue);

        // A single oversized dimension is rejected upfront as well.
        expect(
          () => surface.setSize(BitmapSize(100, maxTextureSize + 1)),
          throwsA(isA<UnsupportedError>()),
        );
        expect(identical(surface.canvas, healthyCanvas), isTrue);
        expect(healthyCanvas.height, 100);

        // The surface's recorded size is rolled back, so requesting the
        // previous size again is a no-op.
        surface.setSize(const BitmapSize(100, 100));
        expect(
          identical(surface.skSurface, healthySkSurface),
          isTrue,
          reason: 'Re-requesting the size from before the failed resize should be a no-op',
        );
        expect(identical(surface.canvas, healthyCanvas), isTrue);

        expect(
          await renderRectAndReadPixel(
            surface,
            const ui.Rect.fromLTWH(0, 0, 100, 100),
            const ui.Color(0xFF0000FF),
            99,
            99,
          ),
          <int>[0, 0, 255, 255],
        );

        // Subsequent normal resizes keep rendering via WebGL on the same canvas.
        surface.setSize(const BitmapSize(150, 150));
        expect(identical(surface.canvas, healthyCanvas), isTrue);
        expect(surface.supportsWebGl, isTrue);

        expect(
          await renderRectAndReadPixel(
            surface,
            const ui.Rect.fromLTWH(0, 0, 150, 150),
            const ui.Color(0xFF0000FF),
            149,
            149,
          ),
          <int>[0, 0, 255, 255],
        );

        surface.dispose();
      },
    );

    group('surface resizing', () {
      test('rapid sequential resizing & ping-pong sizing does not leak or crash', () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;

        // Rapid ping-pong resizing between small (10x10) and large (4960x7016 and
        // 5000x5000) dimensions.
        // Track the WebGL contexts of every canvas the surface replaces.
        final replacedContexts = <WebGLContext>[];
        void resizeTrackingReplacements(BitmapSize size) {
          final DomEventTarget before = surface.canvas;
          surface.setSize(size);
          if (!identical(surface.canvas, before)) {
            replacedContexts.add((before as DomOffscreenCanvas).getGlContext(webGLVersion));
          }
        }

        for (var i = 0; i < 15; i++) {
          // 4960x7016 is large enough to clamp an in-place resized drawing
          // buffer and force the canvas to be replaced.
          resizeTrackingReplacements(const BitmapSize(10, 10));
          resizeTrackingReplacements(const BitmapSize(4960, 7016));
          resizeTrackingReplacements(const BitmapSize(10, 10));
          resizeTrackingReplacements(const BitmapSize(5000, 5000));
        }

        if (isChromium) {
          expect(
            replacedContexts,
            isNotEmpty,
            reason: 'Growing to 4960x7016 should clamp and replace the canvas',
          );
        }
        final int liveReplacedContexts = replacedContexts
            .where((WebGLContext gl) => !gl.isContextLost())
            .length;
        expect(
          liveReplacedContexts,
          0,
          reason:
              'All ${replacedContexts.length} replaced canvases should have had their WebGL '
              'contexts explicitly lost, but $liveReplacedContexts are still alive',
        );
        expect(surface.supportsWebGl, isTrue);

        // Verify pixel rendering reaches the bounds of the large surface after ping-ponging.
        expect(
          await renderRectAndReadPixel(
            surface,
            const ui.Rect.fromLTWH(0, 0, 5000, 5000),
            const ui.Color(0xFF00FF00),
            4990,
            4990,
          ),
          <int>[0, 255, 0, 255],
        );

        surface.dispose();
      });

      test('rasterizeToImageBitmaps at a clamping size captures the full picture', () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;
        surface.setSize(const BitmapSize(100, 100));

        // Only the bottom-right corner is painted, so a clamped (clipped or
        // stretched) drawing buffer leaves the sampled corner pixel empty.
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawRect(
          const ui.Rect.fromLTWH(4950, 7006, 10, 10),
          ui.Paint()..color = const ui.Color(0xFF00FF00),
        );
        final List<DomImageBitmap> bitmaps = await surface.rasterizeToImageBitmaps(
          const BitmapSize(4960, 7016),
          <ui.Picture>[recorder.endRecording()],
        );

        final DomImageBitmap bitmap = bitmaps.single;
        expect(bitmap.width, 4960);
        expect(bitmap.height, 7016);
        expect(readBitmapPixel(bitmap, 4955, 7010), <int>[0, 255, 0, 255]);

        surface.dispose();
      });

      test(
        'context loss after a clamped resize is recovered on a new canvas',
        () async {
          final surface = CkOffscreenSurface(OffscreenCanvasProvider());
          await surface.initialized;
          surface.setSize(const BitmapSize(100, 100));
          final DomEventTarget originalCanvas = surface.canvas;
          surface.setSize(const BitmapSize(4960, 7016));
          final DomEventTarget swappedCanvas = surface.canvas;
          expect(identical(swappedCanvas, originalCanvas), isFalse);

          await surface.triggerContextLoss();
          await surface.handledContextLossEvent;
          expect(
            identical(surface.canvas, swappedCanvas),
            isFalse,
            reason: 'The swapped-in canvas should recover from context loss',
          );
          expect(surface.supportsWebGl, isTrue);

          surface.setSize(const BitmapSize(200, 200));
          expect(
            await renderRectAndReadPixel(
              surface,
              const ui.Rect.fromLTWH(0, 0, 200, 200),
              const ui.Color(0xFF0000FF),
              199,
              199,
            ),
            <int>[0, 0, 255, 255],
          );

          surface.dispose();
        },
        skip: !isChromium, // WebGL drawing buffer clamping at 4960x7016 is specific to Chromium.
      );

      test('lifecycle & disposal during/after resize behaves cleanly and idempotently', () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;

        // Calling dispose immediately after setSize.
        surface.setSize(const BitmapSize(500, 500));
        final disposedCanvas = surface.canvas as DomOffscreenCanvas;
        surface.dispose();
        expect(surface.skSurface, isNull);

        // Disposing releases the canvas, removes the context loss listener,
        // and explicitly loses the WebGL context.
        final WebGLContext gl = disposedCanvas.getGlContext(webGLVersion);
        expect(gl.isContextLost(), isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Calling dispose twice should be safe and idempotent.
        surface.dispose();
        expect(surface.skSurface, isNull);

        // Verify CkOnscreenSurface behaves identically.
        final onscreenSurface = CkOnscreenSurface(OnscreenCanvasProvider());
        await onscreenSurface.initialized;
        onscreenSurface.setSize(const BitmapSize(500, 500));
        onscreenSurface.dispose();
        expect(onscreenSurface.skSurface, isNull);
        onscreenSurface.dispose();
        expect(onscreenSurface.skSurface, isNull);
      });

      test('context loss after dispose does not replace the canvas', () async {
        // The onscreen canvas keeps its context loss listener after dispose,
        // so only the disposed check in onContextLost prevents a new canvas
        // from being acquired.
        final surface = CkOnscreenSurface(OnscreenCanvasProvider());
        await surface.initialized;
        surface.setSize(const BitmapSize(100, 100));
        final DomEventTarget disposedCanvas = surface.canvas;
        surface.dispose();

        await surface.triggerContextLoss();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(identical(surface.canvas, disposedCanvas), isTrue);
      });

      test('context loss after already completed triggerContextLoss does not throw', () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;
        surface.setSize(const BitmapSize(100, 100));

        await surface.triggerContextLoss();
        await surface.handledContextLossEvent;

        // A second context loss event on the newly acquired canvas must not
        // attempt to re-complete the already-completed completer.
        expect(() => surface.onContextLost(), returnsNormally);

        surface.dispose();
      });

      test('zero / minimum dimension boundary sizing followed by picture rasterization', () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;

        // Minimum dimension boundary: 1x1
        surface.setSize(const BitmapSize(1, 1));
        final recorder1 = ui.PictureRecorder();
        final canvas1 = ui.Canvas(recorder1);
        final paint1 = ui.Paint()..color = const ui.Color(0xFFFF0000);
        canvas1.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), paint1);
        final ui.Picture picture1 = recorder1.endRecording();
        await surface.rasterizeToCanvas(picture1);
        expect(surface.skSurface, isNotNull);

        final SkImage snapshot1 = surface.skSurface!.makeImageSnapshot();
        try {
          expect(snapshot1.width(), 1);
          expect(snapshot1.height(), 1);
        } finally {
          snapshot1.delete();
        }

        // Zero dimension boundary: 0x0 is clamped to 1x1.
        surface.setSize(BitmapSize.zero);
        expect(
          surface.supportsWebGl,
          isTrue,
          reason: 'Sizing to 0x0 must not poison the surface into software fallback',
        );
        final zeroSizedCanvas = surface.canvas as DomOffscreenCanvas;
        expect(zeroSizedCanvas.width, 1);
        expect(zeroSizedCanvas.height, 1);
        final recorder0 = ui.PictureRecorder();
        final canvas0 = ui.Canvas(recorder0);
        final paint0 = ui.Paint()..color = const ui.Color(0xFF00FF00);
        canvas0.drawRect(ui.Rect.zero, paint0);
        final ui.Picture picture0 = recorder0.endRecording();
        await surface.rasterizeToCanvas(picture0);
        expect(surface.skSurface, isNotNull);

        final SkImage snapshot0 = surface.skSurface!.makeImageSnapshot();
        try {
          expect(snapshot0.width(), 1);
          expect(snapshot0.height(), 1);
        } finally {
          snapshot0.delete();
        }
        expect(surface.supportsWebGl, isTrue);

        // Negative dimensions are clamped per axis.
        expect(() => surface.setSize(const BitmapSize(-5, 10)), returnsNormally);
        expect(surface.supportsWebGl, isTrue);
        final negativeSizedCanvas = surface.canvas as DomOffscreenCanvas;
        expect(negativeSizedCanvas.width, 1);
        expect(negativeSizedCanvas.height, 10);

        surface.dispose();
      });

      test('resizing while a context loss is pending does not throw', () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;
        surface.setSize(const BitmapSize(100, 100));

        // The context is lost synchronously, but `webglcontextlost` is
        // dispatched later, so a frame may resize the surface in between.
        await surface.triggerContextLoss();
        expect(() => surface.setSize(const BitmapSize(200, 200)), returnsNormally);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        surface.setSize(const BitmapSize(200, 200));
        expect(
          await renderRectAndReadPixel(
            surface,
            const ui.Rect.fromLTWH(0, 0, 200, 200),
            const ui.Color(0xFF0000FF),
            199,
            199,
          ),
          <int>[0, 0, 255, 255],
        );

        surface.dispose();
      });

      test('an oversized request while a context loss is pending keeps WebGL usable', () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;
        surface.setSize(const BitmapSize(100, 100));
        final lostCanvas = surface.canvas as DomOffscreenCanvas;
        final WebGLContext lostGl = lostCanvas.getGlContext(webGLVersion);
        final int maxTextureSize = lostGl.getParameter(lostGl.maxTextureSize);

        // The lost context cannot report its limits, so the request is not
        // validated upfront and is retried on a fresh canvas instead. Its
        // drawing buffer cannot reach the requested height either, so the
        // request is rejected and the surface stays on a fresh canvas at its
        // previous size.
        await surface.triggerContextLoss();
        expect(
          () => surface.setSize(BitmapSize(100, maxTextureSize + 1)),
          throwsA(isA<UnsupportedError>()),
        );
        final freshCanvas = surface.canvas as DomOffscreenCanvas;
        expect(identical(freshCanvas, lostCanvas), isFalse);
        expect(freshCanvas.width, 100);
        expect(freshCanvas.height, 100);
        expect(freshCanvas.getGlContext(webGLVersion).isContextLost(), isFalse);
        expect(surface.supportsWebGl, isTrue);

        // Once the context is live again, oversized requests are rejected
        // upfront without replacing the recovered canvas.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          () => surface.setSize(BitmapSize(maxTextureSize + 1, 100)),
          throwsA(isA<UnsupportedError>()),
        );
        expect(identical(surface.canvas, freshCanvas), isTrue);

        surface.setSize(const BitmapSize(150, 150));
        expect(
          await renderRectAndReadPixel(
            surface,
            const ui.Rect.fromLTWH(0, 0, 150, 150),
            const ui.Color(0xFF0000FF),
            149,
            149,
          ),
          <int>[0, 0, 255, 255],
        );
        expect(surface.supportsWebGl, isTrue);

        surface.dispose();
      });

      const requestedSize = BitmapSize(300, 200);
      for (final (String axis, BitmapSize allocatedSize) in <(String, BitmapSize)>[
        ('narrower', const BitmapSize(299, 200)),
        ('shorter', const BitmapSize(300, 199)),
      ]) {
        test(
          'a fresh drawing buffer $axis than requested throws and keeps the previous size',
          () async {
            final provider = _UndersizedOffscreenCanvasProvider(requestedSize, allocatedSize);
            final surface = CkOffscreenSurface(provider);
            await surface.initialized;
            surface.setSize(const BitmapSize(100, 100));
            final DomEventTarget originalCanvas = surface.canvas;

            expect(
              () => surface.setSize(requestedSize),
              throwsA(
                isA<UnsupportedError>().having(
                  (UnsupportedError e) => e.message,
                  'message',
                  'Requested dimensions 300x200 exceed the WebGL drawing buffer '
                      'allocated by the browser '
                      '(${allocatedSize.width}x${allocatedSize.height}).',
                ),
              ),
            );

            // The clamped in-place resize was retried on a fresh canvas, and the
            // surface was then moved to another fresh canvas at the previous size.
            expect(provider.acquiredSizes, <BitmapSize>[
              const BitmapSize(1, 1),
              requestedSize,
              const BitmapSize(100, 100),
            ]);
            final currentCanvas = surface.canvas as DomOffscreenCanvas;
            expect(identical(currentCanvas, provider.acquiredCanvases.last), isTrue);
            expect(currentCanvas.width, 100);
            expect(currentCanvas.height, 100);
            final WebGLContext currentGl = currentCanvas.getGlContext(webGLVersion);
            expect(currentGl.isContextLost(), isFalse);
            expect(currentGl.drawingBufferWidth, 100);
            expect(currentGl.drawingBufferHeight, 100);
            expect(surface.supportsWebGl, isTrue);
            expect(surface.skSurface!.width(), 100);
            expect(surface.skSurface!.height(), 100);

            // Every replaced canvas gave up its WebGL context right away.
            expect(identical(originalCanvas, provider.acquiredCanvases.first), isTrue);
            for (final DomOffscreenCanvas replaced in provider.acquiredCanvases.take(2)) {
              expect(replaced.getGlContext(webGLVersion).isContextLost(), isTrue);
            }

            // The recorded size matches the canvas in use, so asking for the
            // previous size again is a no-op.
            surface.setSize(const BitmapSize(100, 100));
            expect(identical(surface.canvas, currentCanvas), isTrue);

            expect(
              await renderRectAndReadPixel(
                surface,
                const ui.Rect.fromLTWH(0, 0, 100, 100),
                const ui.Color(0xFF0000FF),
                99,
                99,
              ),
              <int>[0, 0, 255, 255],
            );

            // Asking for the same size again is rejected again rather than
            // silently rendering clipped.
            expect(() => surface.setSize(requestedSize), throwsA(isA<UnsupportedError>()));

            surface.setSize(const BitmapSize(150, 150));
            expect(surface.supportsWebGl, isTrue);
            expect(
              await renderRectAndReadPixel(
                surface,
                const ui.Rect.fromLTWH(0, 0, 150, 150),
                const ui.Color(0xFF0000FF),
                149,
                149,
              ),
              <int>[0, 0, 255, 255],
            );

            // A software fallback has no drawing buffer to check, so if the fresh
            // context cannot be created the request goes through without error.
            CkSurface.debugForceGLFailure = true;
            expect(() => surface.setSize(requestedSize), returnsNormally);
            expect(surface.supportsWebGl, isFalse);
            expect(provider.acquiredSizes.last, requestedSize);
            expect(identical(surface.canvas, provider.acquiredCanvases.last), isTrue);
            expect(surface.skSurface, isNotNull);

            surface.dispose();
          },
        );
      }

      test(
        'a rejected request keeps a previous size above the resize cap at full resolution',
        () async {
          const previousSize = BitmapSize(4960, 7016);
          const rejectedSize = BitmapSize(4960, 7100);
          final provider = _UndersizedOffscreenCanvasProvider(
            rejectedSize,
            const BitmapSize(4960, 7099),
          );
          final surface = CkOffscreenSurface(provider);
          await surface.initialized;
          surface.setSize(const BitmapSize(100, 100));
          // Reaching this size needs a fresh canvas, and shrinking an existing
          // context back to it in place would clamp its drawing buffer again.
          surface.setSize(previousSize);

          expect(() => surface.setSize(rejectedSize), throwsA(isA<UnsupportedError>()));

          expect(provider.acquiredSizes.last, previousSize);
          final currentCanvas = surface.canvas as DomOffscreenCanvas;
          expect(identical(currentCanvas, provider.acquiredCanvases.last), isTrue);
          final WebGLContext currentGl = currentCanvas.getGlContext(webGLVersion);
          expect(currentGl.drawingBufferWidth, 4960);
          expect(currentGl.drawingBufferHeight, 7016);
          expect(surface.skSurface!.width(), 4960);
          expect(surface.skSurface!.height(), 7016);

          expect(
            await renderRectAndReadPixel(
              surface,
              const ui.Rect.fromLTWH(0, 0, 4960, 7016),
              const ui.Color(0xFFFF0000),
              4955,
              7010,
            ),
            <int>[255, 0, 0, 255],
          );

          surface.dispose();
        },
        skip: !isChromium, // The in-place resize cap is specific to Chromium.
      );

      test(
        'rasterizeToImageBitmaps rejects an undersized buffer and keeps the previous size',
        () async {
          final provider = _UndersizedOffscreenCanvasProvider(
            requestedSize,
            const BitmapSize(299, 200),
          );
          final surface = CkOffscreenSurface(provider);
          await surface.initialized;
          const previousSize = BitmapSize(100, 100);
          surface.setSize(previousSize);

          final recorder = ui.PictureRecorder();
          ui.Canvas(recorder).drawRect(
            const ui.Rect.fromLTWH(90, 90, 10, 10),
            ui.Paint()..color = const ui.Color(0xFF00FF00),
          );
          final ui.Picture picture = recorder.endRecording();

          await expectLater(
            surface.rasterizeToImageBitmaps(requestedSize, <ui.Picture>[picture]),
            throwsA(isA<UnsupportedError>()),
          );

          // The deliberately lost contexts of the replaced canvases must not
          // trigger context-lost recovery once their events are dispatched.
          final DomEventTarget restoredCanvas = surface.canvas;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(identical(surface.canvas, restoredCanvas), isTrue);

          // A real context loss recovers at the previous size, not the
          // rejected one.
          await surface.triggerContextLoss();
          await surface.handledContextLossEvent;
          final recoveredCanvas = surface.canvas as DomOffscreenCanvas;
          expect(identical(recoveredCanvas, restoredCanvas), isFalse);
          expect(provider.acquiredSizes.last, previousSize);
          expect(recoveredCanvas.width, 100);
          expect(recoveredCanvas.height, 100);
          expect(surface.supportsWebGl, isTrue);

          final List<DomImageBitmap> bitmaps = await surface.rasterizeToImageBitmaps(
            previousSize,
            <ui.Picture>[picture],
          );
          final DomImageBitmap bitmap = bitmaps.single;
          expect(bitmap.width, 100);
          expect(bitmap.height, 100);
          expect(readBitmapPixel(bitmap, 95, 95), <int>[0, 255, 0, 255]);

          surface.dispose();
        },
      );

      test(
        'rasterizeToImageBitmaps while a context loss is pending captures the picture',
        () async {
          final surface = CkOffscreenSurface(OffscreenCanvasProvider());
          await surface.initialized;
          surface.setSize(const BitmapSize(100, 100));
          final DomEventTarget lostCanvas = surface.canvas;
          await surface.triggerContextLoss();

          final recorder = ui.PictureRecorder();
          ui.Canvas(recorder).drawRect(
            const ui.Rect.fromLTWH(190, 190, 10, 10),
            ui.Paint()..color = const ui.Color(0xFF00FF00),
          );
          final List<DomImageBitmap> bitmaps = await surface.rasterizeToImageBitmaps(
            const BitmapSize(200, 200),
            <ui.Picture>[recorder.endRecording()],
          );

          final DomImageBitmap bitmap = bitmaps.single;
          expect(bitmap.width, 200);
          expect(bitmap.height, 200);
          expect(readBitmapPixel(bitmap, 195, 195), <int>[0, 255, 0, 255]);

          // The loss was recovered by the resize, so the pending
          // `webglcontextlost` event must not replace the canvas again.
          final DomEventTarget recoveredCanvas = surface.canvas;
          expect(identical(recoveredCanvas, lostCanvas), isFalse);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(identical(surface.canvas, recoveredCanvas), isTrue);

          surface.dispose();
        },
      );
    });
  });
}

/// Extracts the CSS style values of 'width' and 'height' and returns them
/// as a [ui.Size].
ui.Size getCssSize(DomHTMLCanvasElement canvas) {
  final String cssWidth = canvas.style.width;
  final String cssHeight = canvas.style.height;
  // CSS width and height should be in the form 'NNNpx'. So cut off the 'px' and
  // convert to a number.
  final double width = double.parse(cssWidth.substring(0, cssWidth.length - 2).trim());
  final double height = double.parse(cssHeight.substring(0, cssHeight.length - 2).trim());
  return ui.Size(width, height);
}

/// Reads back the RGBA bytes of the pixel at ([x], [y]) from the current Skia
/// surface of [surface].
List<int> readSurfacePixel(CkSurface surface, int x, int y) {
  final SkImage snapshot = surface.skSurface!.makeImageSnapshot();
  try {
    final imageInfo = SkImageInfo(
      alphaType: canvasKit.AlphaType.Premul,
      colorType: canvasKit.ColorType.RGBA_8888,
      colorSpace: SkColorSpaceSRGB,
      width: 1,
      height: 1,
    );
    return snapshot.readPixels(x.toDouble(), y.toDouble(), imageInfo)!.toList();
  } finally {
    snapshot.delete();
  }
}

/// Fills [rect] with [color] on [surface], renders it to the surface's canvas,
/// and reads back the RGBA bytes of the pixel at ([x], [y]).
Future<List<int>> renderRectAndReadPixel(
  CkOffscreenSurface surface,
  ui.Rect rect,
  ui.Color color,
  int x,
  int y,
) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(rect, ui.Paint()..color = color);
  await surface.rasterizeToCanvas(recorder.endRecording());
  return readSurfacePixel(surface, x, y);
}

/// Reads back the RGBA bytes of the pixel at ([x], [y]) from [bitmap].
List<int> readBitmapPixel(DomImageBitmap bitmap, int x, int y) {
  final DomCanvasRenderingContext2D sampler = createDomCanvasElement(width: 1, height: 1).context2D;
  sampler.drawImage(bitmap, x, y, 1, 1, 0, 0, 1, 1);
  return sampler.getImageData(0, 0, 1, 1).data;
}

/// An [OffscreenCanvasProvider] that allocates canvases of [allocatedSize]
/// whenever [clampedRequest] is requested, emulating a browser that cannot
/// allocate a drawing buffer that large even for a fresh WebGL context.
class _UndersizedOffscreenCanvasProvider extends OffscreenCanvasProvider {
  _UndersizedOffscreenCanvasProvider(this.clampedRequest, this.allocatedSize);

  /// The requested size that this provider allocates too small.
  final BitmapSize clampedRequest;

  /// The size actually allocated when [clampedRequest] is requested.
  final BitmapSize allocatedSize;

  /// The sizes passed to [acquireCanvas], in order.
  final List<BitmapSize> acquiredSizes = <BitmapSize>[];

  /// The canvases returned by [acquireCanvas], in order.
  final List<DomOffscreenCanvas> acquiredCanvases = <DomOffscreenCanvas>[];

  BitmapSize _allocatedSize(BitmapSize size) => size == clampedRequest ? allocatedSize : size;

  @override
  DomOffscreenCanvas acquireCanvas(BitmapSize size, {required ui.VoidCallback onContextLost}) {
    final DomOffscreenCanvas canvas = super.acquireCanvas(
      _allocatedSize(size),
      onContextLost: onContextLost,
    );
    acquiredSizes.add(size);
    acquiredCanvases.add(canvas);
    return canvas;
  }

  @override
  void resizeCanvas(DomOffscreenCanvas canvas, BitmapSize size) {
    super.resizeCanvas(canvas, _allocatedSize(size));
  }
}
