// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpCanvasKitTest();

  test('disposing a surface removes its native context-loss listener', () async {
    final provider = RecordingCanvasProvider();
    final surface = CkOnscreenSurface(provider);
    await surface.initialized;
    final DomEventTarget canvas = surface.canvas;

    surface.dispose();
    canvas.dispatchEvent(createDomEvent('Event', 'webglcontextlost'));

    expect(provider.contextLosses, 0);
  });

  for (final offscreen in <bool>[false, true]) {
    final kind = offscreen ? 'offscreen' : 'onscreen';
    group(kind, () {
      CkSurface createSurface() {
        return offscreen
            ? CkOffscreenSurface(OffscreenCanvasProvider())
            : CkOnscreenSurface(OnscreenCanvasProvider());
      }

      WebGLContext contextOf(CkSurface surface) {
        return offscreen
            ? (surface.canvas as DomOffscreenCanvas).getGlContext(webGLVersion)
            : (surface.canvas as DomHTMLCanvasElement).getGlContext(webGLVersion);
      }

      test('dispose releases the WebGL context and ignores late context loss', () async {
        final CkSurface surface = createSurface();
        await surface.initialized;
        final WebGLContext context = contextOf(surface);

        surface.dispose();
        surface.dispose();

        expect(context.isContextLost(), isTrue);
        expect(surface.glContext, -1);
        // A callback already queued before disposal must not create another
        // context for a surface belonging to an old application generation.
        surface.onContextLost();
        expect(surface.glContext, -1);
        expect(surface.skSurface, isNull);
      });

      test('repeated hot restarts release contexts without reinitializing CanvasKit', () async {
        final CanvasKit initialCanvasKit = canvasKit;
        for (var generation = 0; generation < 12; generation++) {
          debugOverrideJsConfiguration(
            <String, Object?>{'canvasKitForceMultiSurfaceRasterizer': !offscreen}.jsify()
                as JsFlutterConfiguration?,
          );
          final renderer = CanvasKitRenderer();
          await renderer.initialize();
          final surface = renderer.rasterizer.surfaceProvider.createSurface() as CkSurface;
          await surface.initialized;
          final WebGLContext context = contextOf(surface);

          debugEmulateHotRestart();

          expect(context.isContextLost(), isTrue, reason: 'generation $generation');
          expect(surface.glContext, -1);
          expect(canvasKit, initialCanvasKit);
        }
      });
    }, skip: offscreen && (isSafari || isFirefox || !browserSupportsOffscreenCanvas));
  }
}

class RecordingCanvasProvider extends OnscreenCanvasProvider {
  int contextLosses = 0;

  @override
  DomHTMLCanvasElement acquireCanvas(BitmapSize size, {required void Function() onContextLost}) {
    return super.acquireCanvas(
      size,
      onContextLost: () {
        contextLosses++;
        onContextLost();
      },
    );
  }
}
