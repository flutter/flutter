// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Presents a single canvas directly, and exports bitmaps for compositions that
/// need several canvases. Exporting never clears the visible direct surface.
class HybridCanvasRasterizer extends Rasterizer {
  HybridCanvasRasterizer(
    this.createOnscreenSurface,
    OffscreenSurface Function(OffscreenCanvasProvider) createOffscreenSurface,
  ) : _surfaceProvider = OffscreenSurfaceProvider(
        OffscreenCanvasProvider(),
        createOffscreenSurface,
      );

  final OnscreenSurface Function(OnscreenCanvasProvider) createOnscreenSurface;
  final OffscreenSurfaceProvider _surfaceProvider;
  final Map<EngineFlutterView, HybridCanvasViewRasterizer> _views =
      <EngineFlutterView, HybridCanvasViewRasterizer>{};
  OffscreenSurface? _exportSurface;
  Future<void> _pendingFrame = Future<void>.value();
  int? _resourceCacheMaxBytes;
  bool _disposed = false;

  @override
  SurfaceProvider get surfaceProvider => _surfaceProvider;

  @override
  HybridCanvasViewRasterizer createViewRasterizer(EngineFlutterView view) {
    if (_disposed) {
      throw StateError('The hybrid rasterizer has been disposed.');
    }
    return _views.putIfAbsent(view, () => HybridCanvasViewRasterizer(view, this));
  }

  // The export surface is shared across views. Serialize resize, render and
  // commit together, rather than allowing another view to resize it mid-frame.
  Future<void> _draw(Future<void> Function() draw) {
    final Future<void> result = _pendingFrame.then((_) => draw());
    _pendingFrame = result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }

  OffscreenSurface get _export => _exportSurface ??= _surfaceProvider.createSurface();

  @override
  Surface createPictureToImageSurface() => _surfaceProvider.createSurface();

  @override
  void setResourceCacheMaxBytes(int bytes) {
    _resourceCacheMaxBytes = bytes;
    _surfaceProvider.setSkiaResourceCacheMaxBytes(bytes);
    for (final HybridCanvasViewRasterizer view in _views.values) {
      view._directProvider.setSkiaResourceCacheMaxBytes(bytes);
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final HybridCanvasViewRasterizer view in _views.values.toList()) {
      view.dispose();
    }
    // Native jobs must finish before their surfaces are destroyed.
    unawaited(_pendingFrame.then((_) => _surfaceProvider.dispose()));
  }
}

class HybridCanvasViewRasterizer extends ViewRasterizer {
  HybridCanvasViewRasterizer(super.view, this.rasterizer)
    : _directProvider = OnscreenSurfaceProvider(
        OnscreenCanvasProvider(),
        rasterizer.createOnscreenSurface,
      ) {
    final int? cacheBytes = rasterizer._resourceCacheMaxBytes;
    if (cacheBytes != null) {
      _directProvider.setSkiaResourceCacheMaxBytes(cacheBytes);
    }
    _stagingHost.style
      ..position = 'absolute'
      ..visibility = 'hidden'
      ..pointerEvents = 'none';
  }

  final HybridCanvasRasterizer rasterizer;
  OnscreenSurfaceProvider _directProvider;
  DomDocument? _directDocument;
  final DomElement _stagingHost = createDomElement('flt-canvas-staging');
  OnscreenSurface? _directSurface;
  DomCanvasImageSource? _presentedSource;
  HybridDisplayCanvas? _directCanvas;
  HybridDisplayCanvas? _nextDirectCanvas;
  List<HybridDisplayCanvas> _nextCanvases = <HybridDisplayCanvas>[];
  List<DomImageBitmap> _nextBitmaps = <DomImageBitmap>[];
  BitmapSize? _lastSize;
  double? _lastDevicePixelRatio;
  DomDocument? _lastDocument;
  double? _frameDevicePixelRatio;
  DomDocument? _frameDocument;
  bool _promotionAttempted = false;
  bool _drawing = false;

  @override
  final DisplayCanvasFactory<HybridDisplayCanvas> displayFactory =
      DisplayCanvasFactory<HybridDisplayCanvas>(createCanvas: HybridDisplayCanvas.new);

  @visibleForTesting
  bool get debugIsDirect => _directCanvas != null;

  @visibleForTesting
  OnscreenSurface? get debugDirectSurface => _directSurface;

  @override
  Future<void> draw(LayerTree layerTree, FrameTimingRecorder? recorder) =>
      rasterizer._draw(() async {
        if (isDisposed) {
          return;
        }
        _drawing = true;
        try {
          await super.draw(layerTree, recorder);
        } finally {
          _discardPendingBitmaps();
          _drawing = false;
          if (isDisposed) {
            _directProvider.dispose();
          }
        }
      });

  @override
  Future<void> prepareToDraw() async {
    // Resizing the direct surface here could clear the currently visible frame
    // before we know whether the next composition needs bitmap export.
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    if (displayCanvases.length != pictures.length) {
      throw ArgumentError('Called rasterize() with a different number of canvases and pictures.');
    }
    _discardPendingBitmaps();
    _nextCanvases = displayCanvases.cast<HybridDisplayCanvas>();
    _nextDirectCanvas = null;
    final double dpr = EngineFlutterDisplay.instance.devicePixelRatio;
    _frameDevicePixelRatio = dpr;
    _frameDocument = sceneElement.ownerDocument;
    final bool metricsChanged =
        _lastSize != currentFrameSize ||
        _lastDevicePixelRatio != dpr ||
        _lastDocument != _frameDocument;
    final bool sourceChanged =
        _directSurface != null && _presentedSource != _directSurface!.canvasImageSource;
    final bool single =
        displayCanvases.length == 1 &&
        rasterizer._views.length == 1 &&
        !debugOverlayOptimizationBounds;
    if (metricsChanged || sourceChanged || !single) {
      _promotionAttempted = false;
    }
    recorder?.recordRasterStart();
    try {
      if (single &&
          identical(_directCanvas, displayCanvases.single) &&
          !metricsChanged &&
          !sourceChanged) {
        await _directSurface!.rasterizeToCanvas(pictures.single);
        _nextDirectCanvas = _directCanvas;
        return;
      }
      if (pictures.isEmpty || isDisposed) {
        return;
      }
      final OffscreenSurface export = rasterizer._export;
      await export.setSize(currentFrameSize);
      _nextBitmaps = await export.rasterizeToImageBitmaps(pictures);
      if (isDisposed) {
        return;
      }
      // An active direct surface must remain untouched through an exit or
      // resize. A following frame can attempt entry from the committed bitmap.
      if (single && _directCanvas == null && !_promotionAttempted && sceneElement.isConnected!) {
        _promotionAttempted = true;
        if (_directDocument != sceneElement.ownerDocument) {
          _directSurface?.hostElement.remove();
          _directProvider.dispose();
          _directDocument = sceneElement.ownerDocument;
          _directProvider = OnscreenSurfaceProvider(
            OnscreenCanvasProvider(ownerDocument: _directDocument),
            rasterizer.createOnscreenSurface,
          );
          final int? cacheBytes = rasterizer._resourceCacheMaxBytes;
          if (cacheBytes != null) {
            _directProvider.setSkiaResourceCacheMaxBytes(cacheBytes);
          }
          _directSurface = null;
        }
        final OnscreenSurface surface = _directSurface ??= _directProvider.createSurface();
        _stagingHost.append(surface.hostElement);
        sceneElement.append(_stagingHost);
        await surface.setSize(currentFrameSize);
        await surface.rasterizeToCanvas(pictures.single);
        _presentedSource = surface.canvasImageSource;
        // Bound placeholder observation separately from the native work we
        // have already awaited. Cold context initialization can exceed 100 ms.
        final deadline = Stopwatch()..start();
        if (await _isPlaceholderReady(surface, _nextBitmaps.single, deadline) && !isDisposed) {
          _nextDirectCanvas = _nextCanvases.single;
        }
      }
    } finally {
      recorder?.recordRasterFinish();
    }
  }

  // A native render callback and rAF are not presentation fences. Compare the
  // placeholder with the independently exported image before revealing it.
  Future<bool> _isPlaceholderReady(
    OnscreenSurface surface,
    DomImageBitmap expected,
    Stopwatch deadline,
  ) async {
    if (deadline.elapsedMilliseconds >= 100 || isDisposed) {
      return false;
    }
    final size = BitmapSize(expected.width, expected.height);
    final DomHTMLCanvasElement snapshot = createDomCanvasElement(
      width: size.width,
      height: size.height,
    );
    final context =
        snapshot.getContext('2d', <String, Object>{
              'alpha': true,
              'colorSpace': 'srgb',
              'willReadFrequently': true,
            })!
            as DomCanvasRenderingContext2D;
    context.globalCompositeOperation = 'copy';
    context.drawImage(expected, 0, 0);
    final Int32List reference = _readPixels(context, size);
    var reads = 0;
    try {
      while (!isDisposed && reads < 3 && deadline.elapsedMilliseconds < 100) {
        if (!await _nextObservation(Duration(milliseconds: 100 - deadline.elapsedMilliseconds))) {
          break;
        }
        final source = surface.canvasImageSource as DomHTMLCanvasElement;
        if (source.width != size.width || source.height != size.height) {
          continue;
        }
        reads++;
        context.drawImage(source, 0, 0);
        final Int32List observed = _readPixels(context, size);
        // Synchronous readback cannot be interrupted. Accept verified pixels
        // even if that observation finishes after the retry window expires.
        if (_samePixels(reference, observed)) {
          return true;
        }
      }
      return false;
    } finally {
      snapshot.width = snapshot.height = 0;
    }
  }

  Int32List _readPixels(DomCanvasRenderingContext2D context, BitmapSize size) {
    final Uint8ClampedList rgba = context.getImageData(0, 0, size.width, size.height).data;
    // Copy and compare all four channels as one word. Byte-wise Wasm interop
    // and generic list equality can exhaust the budget at desktop resolutions.
    return Int32List.fromList(rgba.buffer.asInt32List(rgba.offsetInBytes, rgba.lengthInBytes ~/ 4));
  }

  bool _samePixels(Int32List reference, Int32List observed) {
    final int length = reference.length;
    if (length != observed.length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (reference[i] != observed[i]) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _nextObservation(Duration budget) async {
    final completer = Completer<void>();
    final DomMessageChannel channel = createDomMessageChannel();
    final DomEventListener listener = createDomEventListener((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    channel.port1.addEventListener('message', listener);
    channel.port1.start();
    final double id = domWindow.requestAnimationFrame((_) => channel.port2.postMessage(null));
    try {
      await completer.future.timeout(budget);
      return true;
    } on TimeoutException {
      return false;
    } finally {
      domWindow.cancelAnimationFrame(id);
      channel.port1.removeEventListener('message', listener);
      channel.port1.close();
      channel.port2.close();
    }
  }

  @override
  void commitFrame() {
    if (isDisposed) {
      _discardPendingBitmaps();
      return;
    }
    try {
      for (var i = 0; i < _nextBitmaps.length; i++) {
        _nextCanvases[i].render(_nextBitmaps[i]);
      }
      if (!identical(_directCanvas, _nextDirectCanvas)) {
        _directCanvas?.canvasElement.style.removeProperty('visibility');
        if (_nextDirectCanvas == null) {
          if (_directSurface != null) {
            _stagingHost.append(_directSurface!.hostElement);
          }
        } else {
          final OnscreenSurface surface = _directSurface!;
          surface.setIsOverlay(_nextDirectCanvas!._isOverlay);
          _nextDirectCanvas!.hostElement.append(surface.hostElement);
          _nextDirectCanvas!.canvasElement.style.visibility = 'hidden';
          _presentedSource = surface.canvasImageSource;
        }
        _directCanvas = _nextDirectCanvas;
      }
      if (_directCanvas != null) {
        _directSurface!.setIsOverlay(_directCanvas!._isOverlay);
      }
      _lastSize = currentFrameSize;
      // Changes arriving during native work belong to the next frame. Reading
      // live metrics here would hide them from that frame's change detection.
      _lastDevicePixelRatio = _frameDevicePixelRatio;
      _lastDocument = _frameDocument;
    } finally {
      _discardPendingBitmaps();
    }
  }

  void _discardPendingBitmaps() {
    for (final DomImageBitmap bitmap in _nextBitmaps) {
      bitmap.close();
    }
    _nextBitmaps = <DomImageBitmap>[];
  }

  @override
  void dispose() {
    if (isDisposed) {
      return;
    }
    super.dispose();
    rasterizer._views.remove(view);
    _stagingHost.remove();
    _directSurface?.hostElement.remove();
    if (!_drawing) {
      _discardPendingBitmaps();
      _directProvider.dispose();
    }
  }
}

class HybridDisplayCanvas extends RenderCanvas {
  bool _isOverlay = false;

  @override
  void setIsOverlay(bool isOverlay) {
    _isOverlay = isOverlay;
  }
}
