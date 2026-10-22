// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(simolus3): Remove these analyzer ignores, https://dartbug.com/63166.
// ignore: unnecessary_import, import_internal_library
import 'dart:_js_interop_wasm';
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

  void unregisterCallback(int callbackId) {
    _pendingCallbacks.remove(callbackId);
  }

  int get debugPendingCallbackCount => _pendingCallbacks.length;

  void handleCallback(WasmI32 callbackId, WasmI32 context, WasmExternRef? jsContext) {
    final (Completer<JSAny>, Zone)? record = _pendingCallbacks.remove(callbackId.toIntUnsigned());
    // A context-loss notification can already be queued when its surface is
    // disposed and unregisters the callback.
    if (record == null) {
      return;
    }
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

/// Shared native lifecycle and image operations for Skwasm surfaces.
abstract class SkwasmSurface<C extends DomEventTarget, P extends CanvasProvider<C>>
    extends Surface {
  SkwasmSurface(this._canvasProvider) : handle = surfaceCreate() {
    surfaceSetCallbackHandler(handle, SkwasmCallbackHandler.instance.callbackPointer);
    _canvas = _canvasProvider.acquireCanvas(_currentSize, onContextLost: onContextLost);
    _attachCanvas();
    _setInitialization(_initialize());
  }

  final P _canvasProvider;
  final SurfaceHandle handle;
  late C _canvas;
  BitmapSize _currentSize = const BitmapSize(1, 1);
  double _currentDevicePixelRatio = -1;
  late Future<void> _initialized;
  Completer<void>? _handledContextLostEvent;
  bool _disposed = false;
  int? _contextLostCallbackId;

  @override
  bool get supportsPngEncoding => false;

  @override
  Future<void> get initialized => _initialized;

  void _setInitialization(Future<void> initialization) {
    _initialized = initialization;
    // Render operations await this future and receive initialization errors.
    // Observe it immediately as recovery can fail between frames, before a
    // render operation has attached its own error handler.
    initialization.ignore();
  }

  void _attachCanvas() {}
  DomOffscreenCanvas _canvasForSkwasm();
  void _didTransferCanvas(C canvas) {}
  void _updateCanvasCss(BitmapSize size) {}

  Future<void> _initialize() async {
    final C canvas = _canvas;
    final int callbackId = surfaceSetCanvas(handle, _canvasForSkwasm());
    final contextLostCallbackId =
        (await SkwasmCallbackHandler.instance.registerCallback(callbackId)) as JSNumber;
    _didTransferCanvas(canvas);
    if (_disposed) {
      return;
    }
    _contextLostCallbackId = contextLostCallbackId.toDartInt;
    unawaited(
      SkwasmCallbackHandler.instance.registerCallback(_contextLostCallbackId!).then((_) {
        _contextLostCallbackId = null;
        onContextLost();
      }),
    );
  }

  /// Replaces the lost context. Rendering observes both successful recovery and
  /// errors through [initialized].
  void onContextLost() {
    if (_disposed) {
      return;
    }
    if (!(_handledContextLostEvent?.isCompleted ?? true)) {
      _handledContextLostEvent!.complete();
    }
    _setInitialization(_recoverContext());
  }

  Future<void> _recoverContext() async {
    _canvasProvider.releaseCanvas(_canvas);
    final C newCanvas = _canvasProvider.acquireCanvas(_currentSize, onContextLost: onContextLost);
    await recreateContextForCanvas(newCanvas);
  }

  @override
  Future<void> recreateContextForCanvas(covariant C newCanvas) async {
    _canvas = newCanvas;
    _attachCanvas();
    await _initialize();
    _updateCanvasCss(_currentSize);
    await _resizeSurface(_currentSize);
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
    _updateCanvasCss(size);
    await _resizeSurface(size);
  }

  Future<void> _resizeSurface(BitmapSize size) async {
    final int callbackId = surfaceSetSize(handle, size.width, size.height);
    await SkwasmCallbackHandler.instance.registerCallback(callbackId);
  }

  Future<RasterResult> _renderPictures(
    BitmapSize size,
    List<ui.Picture> pictures, {
    required bool captureImageBitmaps,
  }) async {
    await initialized;
    // Resize and render in a single worker message, so another operation on a
    // shared offscreen surface cannot change the size before capture.
    _currentSize = size;
    final int callbackId = withStackScope((StackScope scope) {
      final Pointer<PictureHandle> pictureHandles = scope
          .allocPointerArray(pictures.length)
          .cast<PictureHandle>();
      for (var i = 0; i < pictures.length; i++) {
        pictureHandles[i] = (pictures[i] as SkwasmPicture).handle;
      }
      return surfaceRenderPictures(
        handle,
        pictureHandles,
        pictures.length,
        size.width,
        size.height,
        captureImageBitmaps,
      );
    });
    return (await SkwasmCallbackHandler.instance.registerCallback(callbackId)) as RasterResult;
  }

  @override
  Future<ByteData> rasterizeImage(ui.Image image, ui.ImageByteFormat format) async {
    await initialized;

    final EngineImage engineImage;
    final SkwasmImage skwasmImage;
    if (image case EngineImage(backendImage: final SkwasmImage delegate)) {
      engineImage = image;
      skwasmImage = delegate;
    } else {
      throw ArgumentError('The image being rasterized must be a Skwasm image.');
    }

    // The raster thread resizes the surface to fit the image in the same message
    // that rasterizes it, so no other operation can resize it in between.
    _currentSize = BitmapSize(engineImage.width, engineImage.height);

    // Initiate the native rasterization call. This schedules the rasterization on the C++
    // side and returns a callback ID that will resolve when the image bytes are ready.
    final int callbackId = surfaceRasterizeImage(handle, skwasmImage.handle, format.index);

    final int context =
        (await SkwasmCallbackHandler.instance.registerCallback(callbackId) as JSNumber).toDartInt;

    final SkDataHandle dataHandle = SkDataHandle.fromAddress(context);
    final int byteCount = skDataGetSize(dataHandle);
    final Pointer<Uint8> dataPointer = skDataGetConstPointer(dataHandle).cast<Uint8>();

    final output = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      output[i] = dataPointer[i];
    }

    if (format == ui.ImageByteFormat.rawStraightRgba) {
      unpremultiplyRawRgba(output);
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
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_contextLostCallbackId != null) {
      SkwasmCallbackHandler.instance.unregisterCallback(_contextLostCallbackId!);
      _contextLostCallbackId = null;
    }
    surfaceDestroy(handle);
    _canvasProvider.releaseCanvas(_canvas);
  }

  @override
  int get glContext => surfaceGetGlContext(handle);

  @override
  Future<void> triggerContextLoss() async {
    _handledContextLostEvent = Completer<void>();
    final int callbackId = surfaceTriggerContextLoss(handle);
    await SkwasmCallbackHandler.instance.registerCallback(callbackId);
  }

  @override
  Future<void> get handledContextLossEvent => _handledContextLostEvent!.future;
}

/// A transferred canvas used only for bitmap export and image rasterization.
class SkwasmOffscreenSurface extends SkwasmSurface<DomOffscreenCanvas, OffscreenCanvasProvider>
    implements OffscreenSurface {
  SkwasmOffscreenSurface(super.canvasProvider);

  @override
  DomOffscreenCanvas _canvasForSkwasm() => _canvas;

  @override
  void _didTransferCanvas(DomOffscreenCanvas canvas) {
    // Its listeners can no longer fire after transfer to the raster thread.
    _canvasProvider.releaseCanvas(canvas);
  }

  @override
  Future<List<DomImageBitmap>> rasterizeToImageBitmaps(
    BitmapSize size,
    List<ui.Picture> pictures,
  ) async {
    final RasterResult result = await _renderPictures(size, pictures, captureImageBitmaps: true);
    return result.imageBitmaps.toDart.cast<DomImageBitmap>();
  }

  @override
  DomCanvasImageSource get canvasImageSource =>
      throw UnsupportedError('A transferred offscreen canvas cannot be used as an image source.');

  @override
  Future<void> rasterizeToCanvas(ui.Picture picture) =>
      throw UnsupportedError('SkwasmOffscreenSurface renders to image bitmaps.');

  @override
  Future<void> rasterizeToCanvasSource(
    BitmapSize size,
    List<ui.Picture> pictures,
    void Function(int index, DomCanvasImageSource source) onRendered,
  ) => throw UnsupportedError('SkwasmOffscreenSurface renders to image bitmaps.');
}

/// A DOM canvas whose backing store is owned by the raster thread.
class SkwasmOnscreenSurface extends SkwasmSurface<DomHTMLCanvasElement, OnscreenCanvasProvider>
    implements OnscreenSurface {
  SkwasmOnscreenSurface(super.canvasProvider);

  final DomElement _hostElement = createDomElement('flt-canvas-container');
  bool _isOverlay = false;

  @override
  DomOffscreenCanvas _canvasForSkwasm() => _canvas.transferControlToOffscreen();

  @override
  void _attachCanvas() {
    while (_hostElement.firstChild != null) {
      _hostElement.removeChild(_hostElement.firstChild!);
    }
    _hostElement.appendChild(_canvas);
    _applyOverlayPositioning();
  }

  @override
  void _updateCanvasCss(BitmapSize size) {
    // Updating the placeholder's backing dimensions after transfer is invalid.
    // Only the native surface resizes the backing store.
    _canvasProvider.resizeCanvasCss(_canvas, size);
  }

  @override
  DomCanvasImageSource get canvasImageSource => _canvas;

  @override
  Future<void> rasterizeToCanvas(ui.Picture picture) async {
    await _renderPictures(_currentSize, <ui.Picture>[picture], captureImageBitmaps: false);
  }

  @override
  DomElement get hostElement => _hostElement;

  @override
  bool get isConnected => _canvas.isConnected ?? false;

  @override
  void initialize() {}

  @override
  void setIsOverlay(bool isOverlay) {
    _isOverlay = isOverlay;
    _applyOverlayPositioning();
  }

  void _applyOverlayPositioning() {
    if (_isOverlay) {
      _canvas.style.position = 'absolute';
    } else {
      _canvas.style.removeProperty('position');
    }
  }
}
