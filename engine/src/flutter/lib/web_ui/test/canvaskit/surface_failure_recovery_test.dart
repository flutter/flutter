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

const List<int> _green = <int>[0, 255, 0, 255];

void testMain() {
  setUpCanvasKitTest();

  JSAny? originalMakeOnScreenGLSurface;
  JSAny? originalMakeSWCanvasSurface;
  late double originalDpr;

  setUp(() {
    originalMakeOnScreenGLSurface = canvasKit['MakeOnScreenGLSurface'];
    originalMakeSWCanvasSurface = canvasKit['MakeSWCanvasSurface'];
    originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    CkSurface.debugForceGLFailure = false;
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
  });

  tearDown(() {
    canvasKit['MakeOnScreenGLSurface'] = originalMakeOnScreenGLSurface;
    canvasKit['MakeSWCanvasSurface'] = originalMakeSWCanvasSurface;
    CkSurface.debugForceGLFailure = false;
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
  });

  Future<CkOnscreenSurface> createOnscreenSurface([OnscreenCanvasProvider? provider]) async {
    final surface = CkOnscreenSurface(provider ?? OnscreenCanvasProvider());
    addTearDown(surface.dispose);
    await surface.initialized;
    return surface;
  }

  Future<CkOffscreenSurface> createOffscreenSurface([OffscreenCanvasProvider? provider]) async {
    final surface = CkOffscreenSurface(provider ?? OffscreenCanvasProvider());
    addTearDown(surface.dispose);
    await surface.initialized;
    return surface;
  }

  group('failed setSize leaves no surface and the next same-size setSize rebuilds', () {
    const initialSize = BitmapSize(10, 10);
    const requestedSize = BitmapSize(60, 60);
    JSAny? nullSurface() => null;
    // The WebGL kinds also fail the software fallback so that the failure
    // propagates out of setSize instead of being absorbed by the fallback.
    final kinds = <_SetSizeFailureKind>[
      (
        name: 'WebGL create throws a bare JS value',
        offscreen: false,
        forceSoftware: false,
        error: isStateError,
        arm: (_) {
          canvasKit['MakeOnScreenGLSurface'] = _jsThrowFunction('WebGL surface allocation failed');
          canvasKit['MakeSWCanvasSurface'] = _jsThrowFunction('Software surface unavailable');
        },
      ),
      (
        name: 'software create returns null',
        offscreen: false,
        forceSoftware: true,
        error: _stateErrorWith('Failed to initialize CanvasKit SkSurface.'),
        arm: (_) => canvasKit['MakeSWCanvasSurface'] = nullSurface.toJS,
      ),
      (
        name: 'getGlContext throws after the canvas was resized',
        offscreen: true,
        forceSoftware: false,
        error: isStateError,
        arm: (_InstrumentedOffscreenCanvasProvider provider) =>
            provider.throwGetContextAfterNextResize = true,
      ),
    ];

    for (final kind in kinds) {
      test(kind.name, () async {
        CkSurface.debugForceGLFailure = kind.forceSoftware;
        final offscreenProvider = _InstrumentedOffscreenCanvasProvider();
        final CkSurface surface = kind.offscreen
            ? await createOffscreenSurface(offscreenProvider)
            : await createOnscreenSurface();
        surface.setSize(initialSize);
        expect(surface.supportsWebGl, !kind.forceSoftware);

        kind.arm(offscreenProvider);
        expect(() => surface.setSize(requestedSize), throwsA(kind.error));
        expect(surface.skSurface, isNull);

        canvasKit['MakeOnScreenGLSurface'] = originalMakeOnScreenGLSurface;
        canvasKit['MakeSWCanvasSurface'] = originalMakeSWCanvasSurface;
        offscreenProvider.disarm();

        surface.setSize(requestedSize);
        expect(_skSurfaceSizeOf(surface), requestedSize);
        expect(_canvasSizeOf(surface.canvas), requestedSize);
        await surface.rasterizeToCanvas(_greenSquare());
        expect(_pixelOnCanvas(surface.canvas), _green);
      });
    }
  });

  test('surface dimensions match the canvas and the requested size', () async {
    void expectSizesAgree(CkSurface surface, BitmapSize size) {
      expect(_skSurfaceSizeOf(surface), size);
      expect(_canvasSizeOf(surface.canvas), size);
    }

    // In-place resize keeps the canvas.
    final CkOnscreenSurface inPlace = await createOnscreenSurface();
    inPlace.setSize(const BitmapSize(10, 10));
    final DomEventTarget inPlaceCanvas = inPlace.canvas;
    inPlace.setSize(const BitmapSize(50, 50));
    expect(_isSameJsObject(inPlace.canvas, inPlaceCanvas), isTrue);
    expectSizesAgree(inPlace, const BitmapSize(50, 50));

    // A software fallback in the middle of a resize swaps out the WebGL canvas.
    final CkOnscreenSurface swapped = await createOnscreenSurface();
    swapped.setSize(const BitmapSize(10, 10));
    final DomEventTarget glCanvas = swapped.canvas;
    JSAny? noGlSurface() => null;
    canvasKit['MakeOnScreenGLSurface'] = noGlSurface.toJS;
    swapped.setSize(const BitmapSize(40, 30));
    expect(swapped.supportsWebGl, isFalse);
    expect(_isSameJsObject(swapped.canvas, glCanvas), isFalse);
    expectSizesAgree(swapped, const BitmapSize(40, 30));
    canvasKit['MakeOnScreenGLSurface'] = originalMakeOnScreenGLSurface;

    // A clamped drawing buffer takes the slow path through a fresh canvas.
    final provider = _InstrumentedOffscreenCanvasProvider();
    final CkOffscreenSurface clamped = await createOffscreenSurface(provider);
    clamped.setSize(const BitmapSize(10, 10));
    final DomEventTarget clampedCanvas = clamped.canvas;
    provider.clampResizedDrawingBufferTo = const BitmapSize(32, 24);
    clamped.setSize(const BitmapSize(64, 48));
    expect(clamped.supportsWebGl, isTrue);
    expect(_isSameJsObject(clamped.canvas, clampedCanvas), isFalse);
    expectSizesAgree(clamped, const BitmapSize(64, 48));
  });

  test('context loss after a failed resize recovers at the canvas size and keeps WebGL', () async {
    const initialSize = BitmapSize(10, 10);
    const requestedSize = BitmapSize(60, 60);
    final onscreenProvider = _FailingResizeCanvasProvider();
    final offscreenProvider = _InstrumentedOffscreenCanvasProvider();
    final cases = <({CkSurface surface, void Function() arm, BitmapSize canvasSize})>[
      // The resize fails before touching the canvas.
      (
        surface: await createOnscreenSurface(onscreenProvider),
        arm: () => onscreenProvider.failNextResize = true,
        canvasSize: initialSize,
      ),
      // The resize fails after the canvas was resized.
      (
        surface: await createOffscreenSurface(offscreenProvider),
        arm: () => offscreenProvider.throwGetContextAfterNextResize = true,
        canvasSize: requestedSize,
      ),
    ];

    for (final (:CkSurface surface, :void Function() arm, :BitmapSize canvasSize) in cases) {
      surface.setSize(initialSize);
      arm();
      expect(() => surface.setSize(requestedSize), throwsStateError);
      expect(surface.skSurface, isNull);
      final DomEventTarget failedCanvas = surface.canvas;
      offscreenProvider.disarm();

      await surface.triggerContextLoss();
      await surface.handledContextLossEvent.timeout(const Duration(seconds: 2));
      expect(_isSameJsObject(surface.canvas, failedCanvas), isFalse);
      expect(surface.supportsWebGl, isTrue);
      expect(_canvasSizeOf(surface.canvas), canvasSize);
      expect(_skSurfaceSizeOf(surface), canvasSize);

      surface.setSize(requestedSize);
      expect(_skSurfaceSizeOf(surface), requestedSize);
      await surface.rasterizeToCanvas(_greenSquare());
      expect(_pixelOnCanvas(surface.canvas), _green);
    }
  }, skip: isFirefox || isSafari);

  test('clears skSurface before disposing it and wraps bare JS throws in StateError', () async {
    CkSurface.debugForceGLFailure = true;
    final CkOffscreenSurface surface = await createOffscreenSurface();
    surface.setSize(const BitmapSize(5, 5));

    final spy = _DisposeSpy(surface);
    canvasKit['MakeSWCanvasSurface'] = _jsThrowFunction(
      'Canvas with id [object OffscreenCanvas] was not found',
    );
    expect(
      () => surface.setSize(const BitmapSize(6, 6)),
      throwsA(_stateErrorWith(contains('Canvas with id [object OffscreenCanvas] was not found'))),
    );
    expect(spy.callCount, 1);
    expect(spy.skSurfaceNullDuringDispose, isTrue);
    expect(surface.skSurface, isNull);

    // Dart errors propagate unchanged.
    JSAny? throwFormatException(JSAny? _) => throw const FormatException('bad surface');
    canvasKit['MakeSWCanvasSurface'] = throwFormatException.toJS;
    expect(() => surface.setSize(const BitmapSize(7, 7)), throwsFormatException);
    expect(surface.skSurface, isNull);
  });

  test('a throwing SkSurface.dispose neither masks a resize error nor breaks dispose', () async {
    final provider = _FailingResizeCanvasProvider();
    final CkOnscreenSurface surface = await createOnscreenSurface(provider);
    surface.setSize(const BitmapSize(10, 10));
    void throwJsValue() => _jsThrowFunction('Embind surface already deleted').callAsFunction();

    final resizeSpy = _DisposeSpy(surface, afterDispose: throwJsValue);
    provider.failNextResize = true;
    expect(
      () => surface.setSize(const BitmapSize(60, 60)),
      throwsA(_stateErrorWith('Canvas resize failed')),
    );
    expect(resizeSpy.callCount, 1);
    expect(surface.skSurface, isNull);

    surface.setSize(const BitmapSize(60, 60));
    expect(surface.supportsWebGl, isTrue);
    final disposeSpy = _DisposeSpy(surface, afterDispose: throwJsValue);
    expect(surface.dispose, returnsNormally);
    expect(disposeSpy.callCount, 1);
    expect(surface.skSurface, isNull);
    // Releasing the canvas still ran to completion.
    expect(surface.glContext, -1);
  });
}

/// Wraps the current `SkSurface.dispose` of [surface] to count calls and,
/// optionally, throw after the real dispose.
class _DisposeSpy {
  _DisposeSpy(CkSurface surface, {void Function()? afterDispose}) {
    final SkSurface targetSurface = surface.skSurface!;
    final originalDispose = targetSurface['dispose']! as JSFunction;
    void wrappedDispose() {
      callCount++;
      skSurfaceNullDuringDispose = surface.skSurface == null;
      originalDispose.callAsFunction(targetSurface);
      afterDispose?.call();
    }

    targetSurface['dispose'] = wrappedDispose.toJS;
  }

  int callCount = 0;
  bool skSurfaceNullDuringDispose = false;
}

typedef _SetSizeFailureKind = ({
  String name,
  bool offscreen,
  bool forceSoftware,
  Matcher error,
  void Function(_InstrumentedOffscreenCanvasProvider) arm,
});

/// An [OnscreenCanvasProvider] whose next resize can be made to throw before
/// touching the canvas.
class _FailingResizeCanvasProvider extends OnscreenCanvasProvider {
  bool failNextResize = false;

  @override
  void resizeCanvas(DomHTMLCanvasElement canvas, BitmapSize size) {
    if (failNextResize) {
      failNextResize = false;
      throw StateError('Canvas resize failed');
    }
    super.resizeCanvas(canvas, size);
  }
}

/// An [OffscreenCanvasProvider] that can make `getContext` throw on a resized
/// canvas or report a clamped WebGL drawing buffer after a resize.
class _InstrumentedOffscreenCanvasProvider extends OffscreenCanvasProvider {
  bool throwGetContextAfterNextResize = false;

  /// The drawing buffer size reported after the next in-place resize.
  BitmapSize? clampResizedDrawingBufferTo;

  final List<JSObject> _patchedObjects = <JSObject>[];

  @override
  void resizeCanvas(DomOffscreenCanvas canvas, BitmapSize size) {
    super.resizeCanvas(canvas, size);
    if (throwGetContextAfterNextResize) {
      throwGetContextAfterNextResize = false;
      JSAny? throwingGetContext() => throw StateError('getContext failed');
      canvas['getContext'] = throwingGetContext.toJS;
      _patchedObjects.add(canvas);
    }
    final BitmapSize? clamp = clampResizedDrawingBufferTo;
    if (clamp != null) {
      clampResizedDrawingBufferTo = null;
      final WebGLContext gl = canvas.getGlContext(webGLVersion);
      _overrideDrawingBufferSize.callAsFunction(null, gl, clamp.width.toJS, clamp.height.toJS);
      _patchedObjects.add(gl);
    }
  }

  /// Removes every armed failure and every patch applied so far.
  void disarm() {
    throwGetContextAfterNextResize = false;
    clampResizedDrawingBufferTo = null;
    for (final JSObject object in _patchedObjects) {
      object.delete('getContext'.toJS);
      object.delete('drawingBufferWidth'.toJS);
      object.delete('drawingBufferHeight'.toJS);
    }
    _patchedObjects.clear();
  }
}

final JSFunction _overrideDrawingBufferSize = globalContext.callMethodVarArgs<JSFunction>(
  'Function'.toJS,
  <JSAny?>[
    'gl'.toJS,
    'width'.toJS,
    'height'.toJS,
    'Object.defineProperty(gl, "drawingBufferWidth", {get: () => width, configurable: true});'
            'Object.defineProperty(gl, "drawingBufferHeight", {get: () => height, configurable: true});'
        .toJS,
  ],
);

BitmapSize _canvasSizeOf(DomEventTarget canvas) {
  final object = canvas as JSObject;
  return BitmapSize(
    (object['width']! as JSNumber).toDartInt,
    (object['height']! as JSNumber).toDartInt,
  );
}

BitmapSize? _skSurfaceSizeOf(CkSurface surface) {
  final SkSurface? skSurface = surface.skSurface;
  if (skSurface == null) {
    return null;
  }
  return BitmapSize(skSurface.width().toInt(), skSurface.height().toInt());
}

/// Matches a [StateError] whose message matches [message].
Matcher _stateErrorWith(Object message) =>
    isA<StateError>().having((StateError error) => error.message, 'message', message);

/// Returns a JS function that throws the bare string [message].
JSFunction _jsThrowFunction(String message) =>
    globalContext.callMethod<JSFunction>('Function'.toJS, 'throw "$message";'.toJS);

ui.Picture _greenSquare() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(
    recorder,
  ).drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint()..color = const ui.Color(0xFF00FF00));
  final ui.Picture picture = recorder.endRecording();
  addTearDown(picture.dispose);
  return picture;
}

List<int> _pixelOnCanvas(DomEventTarget canvas) {
  final DomCanvasRenderingContext2D context = createDomCanvasElement(
    width: 10,
    height: 10,
  ).context2D;
  context.drawImage(canvas as DomCanvasImageSource, 0, 0);
  return context.getImageData(5, 5, 1, 1).data.toList();
}

bool _isSameJsObject(DomEventTarget a, DomEventTarget b) => a.strictEquals(b).toDart;
