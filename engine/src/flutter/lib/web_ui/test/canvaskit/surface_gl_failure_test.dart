// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const List<int> _red = <int>[255, 0, 0, 255];

// Regression tests for https://github.com/flutter/flutter/issues/162868.
void testMain() {
  setUpCanvasKitTest();

  JSAny? originalMakeOnScreenGLSurface;
  setUp(() {
    originalMakeOnScreenGLSurface = canvasKit['MakeOnScreenGLSurface'];
  });
  tearDown(() {
    canvasKit['MakeOnScreenGLSurface'] = originalMakeOnScreenGLSurface;
    CkSurface.debugForceGLFailure = false;
  });

  /// Makes every subsequent `MakeOnScreenGLSurface` call fail.
  void failWebGlSurfaces() {
    JSAny? noSurface() => null;
    canvasKit['MakeOnScreenGLSurface'] = noSurface.toJS;
  }

  group('CkOnscreenSurface WebGL failure recovery', () {
    test('software fallback after WebGL surface failure can still render', () async {
      final surface = CkOnscreenSurface(OnscreenCanvasProvider());
      await surface.initialized;
      expect(surface.supportsWebGl, isTrue);
      expect(surface.glContext, isNot(-1));
      final DomEventTarget glCanvas = surface.canvas;

      failWebGlSurfaces();
      surface.setSize(const BitmapSize(10, 10));

      expect(surface.supportsWebGl, isFalse);
      expect(surface.skSurface, isNotNull);
      await surface.rasterizeToCanvas(_redSquare());
      await surface.rasterizeToCanvas(_redSquare());
      expect(_pixelOnCanvas(surface.canvas), _red);
      expect(_isSameJsObject(surface.canvas, glCanvas), isFalse);
      _expectSingleCanvasIn(surface);

      // Once in software mode, the untainted canvas is reused on resize.
      final DomEventTarget softwareCanvas = surface.canvas;
      surface.setSize(const BitmapSize(20, 20));
      expect(_isSameJsObject(surface.canvas, softwareCanvas), isTrue);
      await surface.rasterizeToCanvas(_redSquare());
      expect(_pixelOnCanvas(surface.canvas), _red);
      _expectSingleCanvasIn(surface);

      surface.dispose();
    });

    test('recreating the context on a canvas with a lost context falls back gracefully', () async {
      final surface = CkOnscreenSurface(OnscreenCanvasProvider());
      await surface.initialized;

      final DomHTMLCanvasElement deadCanvas = createDomCanvasElement(width: 10, height: 10);
      final WebGLContext gl = deadCanvas.getGlContext(webGLVersion);
      gl.loseContextExtension.loseContext();
      expect(gl.isContextLost(), isTrue);

      await surface.recreateContextForCanvas(deadCanvas);

      expect(surface.skSurface, isNotNull);
      _expectSingleCanvasIn(surface);
      surface.setSize(const BitmapSize(10, 10));
      await surface.rasterizeToCanvas(_redSquare());
      expect(_pixelOnCanvas(surface.canvas), _red);

      surface.dispose();
    });

    test('handledContextLossEvent unblocks only after context recreation finishes', () async {
      final surface = CkOnscreenSurface(OnscreenCanvasProvider());
      await surface.initialized;
      surface.setSize(const BitmapSize(10, 10));

      // The replacement canvas cannot get a WebGL surface, so recreation has to
      // finish by moving to software rendering before the event is handled.
      failWebGlSurfaces();
      await surface.triggerContextLoss();
      await surface.handledContextLossEvent;

      expect(surface.skSurface, isNotNull);
      _expectSingleCanvasIn(surface);
      await surface.rasterizeToCanvas(_redSquare());
      expect(_pixelOnCanvas(surface.canvas), _red);

      surface.dispose();
    });
  });

  group('CkOffscreenSurface WebGL failure recovery', () {
    test(
      'software fallback after WebGL surface failure can still render on offscreen canvas',
      () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;
        expect(surface.supportsWebGl, isTrue);
        expect(surface.glContext, isNot(-1));

        failWebGlSurfaces();
        surface.setSize(const BitmapSize(10, 10));

        expect(surface.supportsWebGl, isFalse);
        expect(surface.skSurface, isNotNull);
        await surface.rasterizeToCanvas(_redSquare());
        await surface.rasterizeToCanvas(_redSquare());
        expect(_pixelOnCanvas(surface.canvas), _red);

        surface.dispose();
      },
    );

    test(
      'recreating the context on an offscreen canvas with a lost context falls back gracefully',
      () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;

        final deadCanvas = DomOffscreenCanvas(10, 10);
        final WebGLContext gl = deadCanvas.getGlContext(webGLVersion);
        gl.loseContextExtension.loseContext();
        expect(gl.isContextLost(), isTrue);

        await surface.recreateContextForCanvas(deadCanvas);

        expect(surface.skSurface, isNotNull);
        surface.setSize(const BitmapSize(10, 10));
        await surface.rasterizeToCanvas(_redSquare());
        expect(_pixelOnCanvas(surface.canvas), _red);

        surface.dispose();
      },
    );

    test(
      'offscreen canvas buffer clamping recovery does not re-taint canvas in software mode',
      () async {
        final surface = CkOffscreenSurface(OffscreenCanvasProvider());
        await surface.initialized;
        surface.setSize(const BitmapSize(100, 100));
        expect(surface.supportsWebGl, isTrue);
        final DomEventTarget clampedCanvas = surface.canvas;

        // Make the browser report a clamped drawing buffer for the current
        // canvas (see https://github.com/flutter/flutter/issues/182476), so the
        // resize takes the canvas recovery path, and make WebGL fail on the
        // replacement canvas.
        final void Function() restoreDrawingBufferWidth = _clampDrawingBufferWidth(
          clampedCanvas as DomOffscreenCanvas,
        );
        CkSurface.debugForceGLFailure = true;
        try {
          surface.setSize(const BitmapSize(200, 200));
        } finally {
          restoreDrawingBufferWidth();
        }

        expect(surface.supportsWebGl, isFalse);
        expect(surface.skSurface, isNotNull);
        expect(_isSameJsObject(surface.canvas, clampedCanvas), isFalse);
        await surface.rasterizeToCanvas(_redSquare());
        expect(_pixelOnCanvas(surface.canvas), _red);

        surface.dispose();
      },
    );
  });
}

/// A 10x10 red square.
ui.Picture _redSquare() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(
    recorder,
  ).drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint()..color = const ui.Color(0xFFFF0000));
  return recorder.endRecording();
}

/// Returns the RGBA value of the pixel at (5, 5) as displayed by [canvas].
List<int> _pixelOnCanvas(DomEventTarget canvas) {
  final DomCanvasRenderingContext2D context = createDomCanvasElement(
    width: 10,
    height: 10,
  ).context2D;
  context.drawImage(canvas as DomCanvasImageSource, 0, 0);
  return context.getImageData(5, 5, 1, 1).data.toList();
}

bool _isSameJsObject(DomEventTarget a, DomEventTarget b) => a.strictEquals(b).toDart;

void _expectSingleCanvasIn(CkOnscreenSurface surface) {
  expect(surface.hostElement.children.length, 1);
  expect(_isSameJsObject(surface.hostElement.children.single, surface.canvas), isTrue);
}

/// Makes WebGL report a 1px wide drawing buffer for [canvas] only.
///
/// Returns a callback that restores the browser's behavior.
void Function() _clampDrawingBufferWidth(DomOffscreenCanvas canvas) {
  final objectConstructor = globalContext['Object']! as JSObject;
  final JSObject prototype = objectConstructor.callMethod<JSObject>(
    'getPrototypeOf'.toJS,
    canvas.getGlContext(webGLVersion),
  );
  final JSObject original = objectConstructor.callMethod<JSObject>(
    'getOwnPropertyDescriptor'.toJS,
    prototype,
    'drawingBufferWidth'.toJS,
  );
  final originalGetter = original['get']! as JSFunction;
  JSAny? clampedGetter(JSObject context) => context['canvas'].strictEquals(canvas).toDart
      ? 1.toJS
      : originalGetter.callAsFunction(context);
  final clamped = JSObject()
    ..['configurable'] = true.toJS
    ..['get'] = clampedGetter.toJSCaptureThis;
  objectConstructor.callMethod<JSAny?>(
    'defineProperty'.toJS,
    prototype,
    'drawingBufferWidth'.toJS,
    clamped,
  );
  return () => objectConstructor.callMethod<JSAny?>(
    'defineProperty'.toJS,
    prototype,
    'drawingBufferWidth'.toJS,
    original,
  );
}
