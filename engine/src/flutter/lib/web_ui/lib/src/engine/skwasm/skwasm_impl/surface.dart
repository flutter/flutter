// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:_wasm';
import 'dart:async';
import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

extension type RasterResult._(JSObject _) implements JSObject {
  external double get rasterStartMilliseconds;
  external double get rasterEndMilliseconds;
  external JSArray<JSAny> get imageBitmaps;
}

@pragma('wasm:export')
WasmVoid callbackHandler(WasmI32 callbackId, WasmI32 context, WasmExternRef? jsContext) {
  // Actually hide this call behind whether skwasm is enabled. Otherwise, the SkwasmCallbackHandler
  // won't actually be tree-shaken, and we end up with skwasm imports in non-skwasm builds.
  if (FlutterConfiguration.flutterWebUseSkwasm) {
    SkwasmCallbackHandler.instance.handleCallback(callbackId, context, jsContext);
  }
  return WasmVoid();
}

// This class handles callbacks coming from Skwasm by keeping a map of callback IDs to Completers
class SkwasmCallbackHandler {
  SkwasmCallbackHandler._withCallbackPointer(this.callbackPointer);

  factory SkwasmCallbackHandler._() {
    final WasmFuncRef wasmFunction =
        WasmFunction<WasmVoid Function(WasmI32, WasmI32, WasmExternRef?)>.fromFunction(
          callbackHandler,
        );
    final int functionIndex = addFunction(wasmFunction).toIntUnsigned();
    return SkwasmCallbackHandler._withCallbackPointer(
      OnRenderCallbackHandle.fromAddress(functionIndex),
    );
  }
  static SkwasmCallbackHandler instance = SkwasmCallbackHandler._();

  final OnRenderCallbackHandle callbackPointer;
  final Map<CallbackId, (Completer<JSAny>, Zone)> _pendingCallbacks =
      <int, (Completer<JSAny>, Zone)>{};

  // Returns a future that will resolve when Skwasm calls back with the given callbackID
  Future<JSAny> registerCallback(int callbackId) {
    final completer = Completer<JSAny>();
    _pendingCallbacks[callbackId] = (completer, Zone.current);
    return completer.future;
  }

  void handleCallback(WasmI32 callbackId, WasmI32 context, WasmExternRef? jsContext) {
    final (Completer<JSAny>, Zone) record = _pendingCallbacks.remove(callbackId.toIntUnsigned())!;
    final Completer<JSAny> completer = record.$1;
    final Zone zone = record.$2;
    zone.run(() {
      // Skwasm can either callback with a JS object (an externref) or it can call back
      // with a simple integer, which usually refers to a pointer on its heap. In order
      // to coerce these into a single type, we just make the completers take a JSAny
      // that either contains the JS object or a JSNumber that contains the integer value.
      if (!jsContext.isNull) {
        completer.complete(jsContext!.toJS);
      } else {
        completer.complete(context.toIntUnsigned().toJS);
      }
    });
  }
}

typedef RenderResult = ({
  List<DomImageBitmap> imageBitmaps,
  int rasterStartMicros,
  int rasterEndMicros,
});

class SkwasmSurface implements OffscreenSurface {
  factory SkwasmSurface(OffscreenCanvasProvider canvasProvider) {
    final SurfaceHandle handle = withStackScope<SurfaceHandle>((StackScope scope) {
      return surfaceCreate();
    });
    final surface = SkwasmSurface._fromHandle(handle, canvasProvider);
    return surface;
  }

  SkwasmSurface._fromHandle(this.handle, this._canvasProvider)
    : _initializedCompleter = Completer<void>() {
    surfaceSetCallbackHandler(handle, SkwasmCallbackHandler.instance.callbackPointer);
    _canvas = _canvasProvider.acquireCanvas(const BitmapSize(1, 1), onContextLost: onContextLost);
    _initialize();
  }

  final OffscreenCanvasProvider _canvasProvider;
  late DomOffscreenCanvas _canvas;
  late SurfaceHandle handle;
  double _currentDevicePixelRatio = -1;
  BitmapSize _currentSize = const BitmapSize(1, 1);
  Completer<void> _initializedCompleter;
  late Completer<void>? _handledContextLostEvent;

  /// Handles the context lost event by acquiring a new canvas and recreating the
  /// context.
  void onContextLost() {
    if (!_initializedCompleter.isCompleted) {
      _initializedCompleter.complete();
    }
    _initializedCompleter = Completer<void>();
    _handledContextLostEvent?.complete();
    final DomOffscreenCanvas newCanvas = _canvasProvider.acquireCanvas(
      _currentSize,
      onContextLost: onContextLost,
    );
    recreateContextForCanvas(newCanvas);
  }

  void _initialize() {
    final CallbackId callbackId = surfaceSetCanvas(handle, _canvas);

    SkwasmCallbackHandler.instance.registerCallback(callbackId).then((JSAny contextLostCallbackId) {
      // The context may have been lost before the Surface finished
      // initializing.
      if (!_initializedCompleter.isCompleted) {
        _initializedCompleter.complete();
      }
      // Once we have transferred control of the canvas to the Skwasm Surface,
      // the reference to the _canvas is no longer valid and any listeners
      // attached to it will never fire. Inform the CanvasProvider that it
      // should release its reference to the canvas and unregister any listeners
      // attached to it.
      _canvasProvider.releaseCanvas(_canvas);
      SkwasmCallbackHandler.instance
          .registerCallback((contextLostCallbackId as JSNumber).toDartInt)
          .then((_) {
            onContextLost();
          });
    });
  }

  @override
  Future<ByteData> rasterizeImage(ui.Image image, ui.ImageByteFormat format) async {
    await initialized;
    // Cast [image] to [SkwasmImage].
    image as SkwasmImage;
    await setSize(BitmapSize(image.width, image.height));
    final int callbackId = surfaceRasterizeImage(handle, image.handle, format.index);
    final int context =
        (await SkwasmCallbackHandler.instance.registerCallback(callbackId) as JSNumber).toDartInt;
    final SkDataHandle dataHandle = SkDataHandle.fromAddress(context);
    final int byteCount = skDataGetSize(dataHandle);
    final Pointer<Uint8> dataPointer = skDataGetConstPointer(dataHandle).cast<Uint8>();
    final output = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      output[i] = dataPointer[i];
    }
    skDataDispose(dataHandle);
    return ByteData.sublistView(output);
  }

  @override
  void setSkiaResourceCacheMaxBytes(int bytes) {
    surfaceSetResourceCacheLimitBytes(handle, bytes);
  }

  @override
  void dispose() {
    surfaceDestroy(handle);
  }

  @override
  Future<List<DomImageBitmap>> rasterizeToImageBitmaps(List<ui.Picture> pictures) =>
      withStackScope((StackScope scope) async {
        await initialized;
        final Pointer<PictureHandle> pictureHandles = scope
            .allocPointerArray(pictures.length)
            .cast<PictureHandle>();
        for (var i = 0; i < pictures.length; i++) {
          pictureHandles[i] = (pictures[i] as SkwasmPicture).handle;
        }
        final int callbackId = surfaceRenderPictures(handle, pictureHandles, pictures.length);
        final rasterResult =
            (await SkwasmCallbackHandler.instance.registerCallback(callbackId)) as RasterResult;
        final RenderResult result = (
          imageBitmaps: rasterResult.imageBitmaps.toDart.cast<DomImageBitmap>(),
          rasterStartMicros: (rasterResult.rasterStartMilliseconds * 1000).toInt(),
          rasterEndMicros: (rasterResult.rasterEndMilliseconds * 1000).toInt(),
        );
        return result.imageBitmaps;
      });

  @override
  Future<void> recreateContextForCanvas(DomEventTarget newCanvas) async {
    _canvas = newCanvas as DomOffscreenCanvas;
    _initialize();
    await initialized;
    final BitmapSize lastSize = _currentSize;
    // Reset _currentSize to force `setSize` to actually size the underlying
    // Surface.
    _currentSize = const BitmapSize(1, 1);
    await setSize(lastSize);
  }

  @override
  Future<void> setSize(BitmapSize size) async {
    await initialized;
    final double devicePixelRatio = EngineFlutterDisplay.instance.devicePixelRatio;
    if (_currentSize == size && devicePixelRatio == _currentDevicePixelRatio) {
      return;
    }
    _currentDevicePixelRatio = devicePixelRatio;
    _currentSize = size;
    final int callbackId = surfaceSetSize(handle, size.width, size.height);
    await SkwasmCallbackHandler.instance.registerCallback(callbackId);
  }

  @override
  int get glContext => surfaceGetGlContext(handle);

  @override
  Future<void> get initialized => _initializedCompleter.future;

  @override
  Future<void> triggerContextLoss() async {
    _handledContextLostEvent = Completer<void>();
    final int callbackId = surfaceTriggerContextLoss(handle);
    await SkwasmCallbackHandler.instance.registerCallback(callbackId);
  }

  @override
  Future<void> get handledContextLossEvent => _handledContextLostEvent!.future;

  // TODO(harryterkelsen): Implement this to support MultiSurfaceRasterizer in
  // Skwasm.
  @override
  DomCanvasImageSource get canvasImageSource =>
      throw StateError('canvasImageSource is not supported for SkwasmSurface');

  // TODO(harryterkelsen): Implement this to support MultiSurfaceRasterizer in
  // Skwasm.
  @override
  Future<void> rasterizeToCanvas(ui.Picture picture) {
    throw StateError('rasterizeToCanvas is not supported for SkwasmSurface');
  }
}
