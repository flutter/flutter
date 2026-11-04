// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

// Only supported in profile/release mode. Allows Flutter to use MSAA but
// removes the ability for disabling AA on Paint objects.
const bool _kUsingMSAA = bool.fromEnvironment('flutter.canvaskit.msaa');

/// The base class for CanvasKit surfaces, containing shared logic for context
/// management and Skia object creation.
abstract class CkSurface extends Surface {
  CkSurface(this._canvasProvider) {
    _canvas = _canvasProvider.acquireCanvas(_initialCanvasSize, onContextLost: onContextLost);
    _maybeAttachCanvasToDom();
    _initialize();
  }

  /// The size of the canvas acquired when the surface is created.
  static const BitmapSize _initialCanvasSize = BitmapSize(1, 1);

  final CanvasProvider _canvasProvider;

  @override
  bool get supportsPngEncoding => true;

  /// The underlying Skia surface object.
  SkSurface? get skSurface => _skSurface;
  SkSurface? _skSurface;

  /// Whether or not WebGl is supported.
  ///
  /// This defaults to true unless `canvasKitForceCpuOnly` is set to true or
  /// `webGLVersion` is -1. If Skia fails to create a GrContext, this will be
  /// set to false.
  @visibleForTesting
  bool get supportsWebGl {
    if (configuration.canvasKitForceCpuOnly) {
      _fallbackToSoftwareReason = 'canvasKitForceCpuOnly is set to true';
      return false;
    }
    if (webGLVersion == -1) {
      _fallbackToSoftwareReason = 'webGLVersion is -1';
      return false;
    }
    if (_failedToCreateGrContext) {
      return false;
    }
    return true;
  }

  /// Whether this surface is using software rendering.
  bool get isSoftware => !supportsWebGl;

  String? _fallbackToSoftwareReason;

  /// When true, the surface will fail to create a GL context and fall back to
  /// software rendering. This is useful for testing.
  @visibleForTesting
  static bool debugForceGLFailure = false;

  bool _failedToCreateGrContext = false;

  static bool _didWarnAboutWebGlInitializationFailure = false;

  /// The underlying GL context. Returns -1 if the context is not initialized.
  @override
  @visibleForTesting
  int get glContext => _glContext;
  int _glContext = -1;

  /// The canvas object that this surface is rendering to.
  @visibleForTesting
  DomEventTarget get canvas => _canvas;
  late DomEventTarget _canvas;

  /// Whether a WebGL context has been requested on the current [canvas].
  ///
  /// Per the HTML canvas specification, `getContext('2d')` returns `null` on a
  /// canvas that already has a WebGL context. When falling back to software
  /// rendering (which draws via a 2D context), [canvas] must be replaced if
  /// this is true.
  bool _canvasHasWebGlContext = false;

  void _maybeAttachCanvasToDom();

  /// Returns the WebGL context for [canvas].
  WebGLContext _webGlContextOf(DomEventTarget canvas);

  /// The current size of [canvas] in physical pixels.
  BitmapSize get _canvasSize;

  /// A [Future] which completes when the [Surface] is initialized and ready to
  /// render pictures.
  @override
  Future<void> get initialized => _initialized.future;
  final Completer<void> _initialized = Completer<void>();

  Completer<void>? _handledContextLostEvent;

  /// Creates the canvas object and initializes the graphics context.
  Future<void> _initialize() async {
    try {
      _createSkiaObjects();
    } catch (e, s) {
      printWarning('Failed to initialize CanvasKit surface: $e\n$s');
    } finally {
      // Always complete [initialized] so callers awaiting it do not hang if
      // surface creation fails.
      _initialized.complete();
    }
  }

  /// The underlying Skia graphics context.
  SkGrContext? _grContext;

  /// Handles the `webglcontextlost` event by acquiring a new canvas and
  /// recreating the Skia context and surface on it.
  ///
  /// [handledContextLossEvent] completes only once the graphics context has
  /// been recreated (or recovery has failed).
  void onContextLost() {
    if (isDisposed) {
      return;
    }
    assert(!isSoftware, 'Received a webglcontextlost event while in software rendering mode.');
    // Recover at the lost canvas's size, which may differ from the last
    // requested size if a resize failed.
    final BitmapSize size = _canvasSize;
    final DomEventTarget newCanvas = _canvasProvider.acquireCanvas(
      size,
      onContextLost: onContextLost,
    );
    try {
      _replaceCanvas(newCanvas);
    } catch (e, s) {
      printWarning('Error recovering from context loss: $e\n$s');
    } finally {
      if (_handledContextLostEvent?.isCompleted == false) {
        _handledContextLostEvent!.complete();
      }
    }
  }

  /// Recreates the [SkSurface] for the current [canvas], falling back to
  /// software rendering if WebGL fails.
  void _recreateSkSurface() {
    if (supportsWebGl) {
      try {
        _recreateWebGlSkSurface();
      } catch (e) {
        _markWebGlFailed('failed to create GrContext. Error: $e');
        _recreateSoftwareSkSurface();
      }
    } else {
      _recreateSoftwareSkSurface();
    }
  }

  /// Permanently switches this surface to software rendering.
  void _markWebGlFailed(String reason) {
    _failedToCreateGrContext = true;
    _fallbackToSoftwareReason = reason;
  }

  /// Creates the GL context and the Skia `GrContext`.
  void _createGrContext() {
    if (debugForceGLFailure) {
      _markWebGlFailed('debugForceGLFailure is true');
      return;
    }
    final options = SkWebGLContextOptions(
      antialias: _kUsingMSAA ? 1 : 0,
      majorVersion: webGLVersion.toDouble(),
    );
    // Record that a WebGL context was requested before calling into CanvasKit
    // so the canvas is still replaced if `_getGlContext` throws after binding
    // a context.
    _canvasHasWebGlContext = true;
    _glContext = _getGlContext(options);
    // CanvasKit returns 0 when the browser refuses to create a WebGL context.
    if (_glContext <= 0) {
      _markWebGlFailed('failed to create WebGL context (id: $_glContext).');
      return;
    }
    _grContext = canvasKit.MakeGrContext(_glContext.toDouble());
    if (_grContext == null) {
      _markWebGlFailed('failed to create GrContext.');
    }
  }

  /// Creates the underlying GL context for the canvas.
  ///
  /// This method is implemented by subclasses to handle their specific
  /// canvas types.
  int _getGlContext(SkWebGLContextOptions options);

  /// Creates the Skia objects that are backed by the canvas.
  ///
  /// This method is responsible for creating the `SkGrContext` and the
  /// `SkSurface`.
  void _createSkiaObjects() {
    try {
      if (supportsWebGl) {
        _createGrContext();
      }
    } catch (e) {
      _markWebGlFailed('failed to create GrContext. Error: $e');
    }
    _recreateSkSurface();
  }

  /// Disposes the current [_skSurface], if any.
  void _disposeSkSurface() {
    // Clear the field before disposing so it never retains a deleted handle,
    // even if `dispose` throws.
    final SkSurface? previousSurface = _skSurface;
    _skSurface = null;
    if (previousSurface == null) {
      return;
    }
    try {
      previousSurface.dispose();
    } catch (e) {
      // CanvasKit may throw bare JavaScript values (such as strings), which
      // are not Dart errors. Convert those to a StateError and let Dart
      // errors and exceptions propagate unchanged.
      if (e is Error || e is Exception) {
        rethrow;
      }
      throw StateError('Failed to dispose CanvasKit SkSurface: $e');
    }
  }

  /// Replaces the current [_skSurface] with the surface returned by
  /// [createSurface].
  void _replaceSkSurface(SkSurface? Function() createSurface) {
    _disposeSkSurface();
    final SkSurface? newSurface;
    try {
      newSurface = createSurface();
    } catch (e) {
      // As in `_disposeSkSurface`, convert bare JavaScript throwables to a
      // StateError.
      if (e is Error || e is Exception) {
        rethrow;
      }
      throw StateError('Failed to create CanvasKit SkSurface: $e');
    }
    if (newSurface == null) {
      throw StateError('Failed to initialize CanvasKit SkSurface.');
    }
    _skSurface = newSurface;
  }

  /// Replaces the current [_skSurface] with a WebGL-backed surface sized to
  /// [canvas].
  void _recreateWebGlSkSurface() {
    final BitmapSize size = _canvasSize;
    _replaceSkSurface(
      () => canvasKit.MakeOnScreenGLSurface(
        _grContext!,
        size.width.toDouble(),
        size.height.toDouble(),
        SkColorSpaceSRGB,
        0,
        0,
      ),
    );
  }

  /// Creates a software-rendered [SkSurface], replacing [canvas] first if it
  /// already has a WebGL context.
  void _recreateSoftwareSkSurface() {
    if (_canvasHasWebGlContext) {
      _swapCanvasForSoftwareRendering();
    }
    if (!_didWarnAboutWebGlInitializationFailure) {
      _didWarnAboutWebGlInitializationFailure = true;
      printWarning(
        'WARNING: Falling back to CPU-only rendering. Reason: $_fallbackToSoftwareReason',
      );
    }
    _replaceSkSurface(_createSoftwareSkSurface);
  }

  /// Creates an SkSurface for software rendering. This is used when WebGl is not
  /// supported or when it fails to initialize.
  SkSurface? _createSoftwareSkSurface();

  /// Releases [canvas] and acquires a fresh one without a WebGL context so
  /// CanvasKit's software backend can obtain a 2D rendering context on it.
  void _swapCanvasForSoftwareRendering() {
    // Read the size before releasing the current canvas.
    final BitmapSize size = _canvasSize;
    _releaseCanvas();
    _canvas = _canvasProvider.acquireCanvas(size, onContextLost: onContextLost);
    _maybeAttachCanvasToDom();
  }

  /// Releases the current [canvas], along with its WebGL context and the Skia
  /// objects backed by it.
  void _releaseCanvas() {
    try {
      _disposeSkSurface();
    } catch (_) {
      // Releasing the canvas must complete even if disposing the surface
      // throws; `_disposeSkSurface` has already cleared the field.
    }
    try {
      _grContext?.releaseResourcesAndAbandonContext();
      _grContext?.delete();
    } catch (_) {
      // Releasing GPU resources may throw if the WebGL context was already
      // lost (for example, when called from `onContextLost`).
    }
    _grContext = null;

    final DomEventTarget oldCanvas = _canvas;
    // Unregister the `webglcontextlost` listener (and detach an onscreen
    // canvas from the DOM) before explicitly losing the WebGL context below,
    // so losing it does not trigger `onContextLost`.
    _canvasProvider.releaseCanvas(oldCanvas);
    // Only free a context that CanvasKit actually created; calling
    // `getContext` when initial context creation failed could allocate a new
    // WebGL context just to lose it.
    if (_glContext > 0) {
      _destroyGlContext(oldCanvas);
      // Remove the context from CanvasKit's context table so CanvasKit doesn't
      // keep the canvas alive.
      canvasKit.deleteContext(_glContext.toDouble());
    }
    _glContext = -1;
    _canvasHasWebGlContext = false;
  }

  /// Explicitly loses [oldCanvas]'s WebGL context so the browser reclaims it
  /// immediately instead of waiting for garbage collection.
  void _destroyGlContext(DomEventTarget oldCanvas) {
    try {
      final WebGLContext gl = _webGlContextOf(oldCanvas);
      if (!gl.isContextLost()) {
        gl.loseContextExtension.loseContext();
      }
    } catch (_) {
      // `getGlContext` or `loseContextExtension` throws if the browser does
      // not expose `WEBGL_lose_context`.
    }
  }

  double _currentDevicePixelRatio = -1;

  @override
  void setSize(BitmapSize size) {
    final double devicePixelRatio = EngineFlutterDisplay.instance.devicePixelRatio;
    // A zero-sized canvas cannot back a WebGL SkSurface and would force the
    // surface into a permanent software fallback, so never go below 1x1.
    final clampedSize = BitmapSize(math.max(1, size.width), math.max(1, size.height));
    final SkSurface? surface = _skSurface;
    if (surface != null &&
        surface.width().toInt() == clampedSize.width &&
        surface.height().toInt() == clampedSize.height &&
        devicePixelRatio == _currentDevicePixelRatio) {
      return;
    }
    final BitmapSize previousSize = _canvasSize;
    try {
      _resizeCanvas(clampedSize, previousSize);
    } catch (e) {
      // If the failure occurred during resize (and was not rejected upfront as
      // unsupported before touching any resources), dispose the SkSurface so it
      // never disagrees with its canvas or retains an invalid handle.
      if (e is! UnsupportedError) {
        try {
          _disposeSkSurface();
        } catch (_) {
          // Preserve the primary resize error.
        }
      }
      rethrow;
    }
    _currentDevicePixelRatio = devicePixelRatio;
  }

  /// Resizes the underlying canvas to [size] and recreates the Skia surface.
  ///
  /// [previousSize] is the size the surface had before this call. If this
  /// method throws, the surface must be left usable at [previousSize].
  ///
  /// Subclasses in this library may override this if their underlying canvas
  /// type requires re-allocation or context recreation instead of in-place
  /// dimension updates.
  void _resizeCanvas(BitmapSize size, BitmapSize previousSize) {
    _canvasProvider.resizeCanvas(canvas, size);
    _recreateSkSurface();
  }

  @override
  Future<void> recreateContextForCanvas(DomEventTarget newCanvas) async {
    _replaceCanvas(newCanvas);
  }

  /// Releases the current [canvas] and initializes Skia objects on [newCanvas].
  void _replaceCanvas(DomEventTarget newCanvas) {
    _releaseCanvas();
    _canvas = newCanvas;
    _maybeAttachCanvasToDom();
    _createSkiaObjects();
  }

  @override
  void disposeResources() {
    _releaseCanvas();
  }

  @override
  void setSkiaResourceCacheMaxBytes(int bytes) {
    _grContext?.setResourceCacheLimitBytes(bytes.toDouble());
  }

  @override
  Future<ByteData?> rasterizeImage(ui.Image image, ui.ImageByteFormat format) async {
    await _initialized.future;

    final EngineImage engineImage;
    final SkImage skImage;
    if (image case EngineImage(backendImage: CkImageDelegate(skImage: final imageRef))) {
      engineImage = image;
      skImage = imageRef;
    } else {
      throw ArgumentError('The image being rasterized must be a CanvasKit image.');
    }

    final SkAlphaType alphaType = format == ui.ImageByteFormat.rawStraightRgba
        ? canvasKit.AlphaType.Unpremul
        : canvasKit.AlphaType.Premul;

    Uint8List? bytes;
    if (format == ui.ImageByteFormat.rawRgba || format == ui.ImageByteFormat.rawStraightRgba) {
      final imageInfo = SkImageInfo(
        alphaType: alphaType,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
        width: skImage.width(),
        height: skImage.height(),
      );
      bytes = skImage.readPixels(0, 0, imageInfo);
    } else {
      bytes = skImage.encodeToBytes(); // defaults to PNG 100%
    }

    if (bytes != null) {
      return bytes.buffer.asByteData();
    }

    setSize(BitmapSize(engineImage.width, engineImage.height));
    final SkSurface skSurface = _skSurface!;
    final canvas = EngineCanvas(CkCanvas(skSurface.getCanvas()));

    canvas.clear(const ui.Color(0x00000000));
    final paint = ui.Paint();

    canvas.drawImage(engineImage, ui.Offset.zero, paint);
    final SkImage snapshot = skSurface.makeImageSnapshot();

    try {
      if (format == ui.ImageByteFormat.rawRgba || format == ui.ImageByteFormat.rawStraightRgba) {
        final imageInfo = SkImageInfo(
          alphaType: alphaType,
          colorType: canvasKit.ColorType.RGBA_8888,
          colorSpace: SkColorSpaceSRGB,
          width: engineImage.width.toDouble(),
          height: engineImage.height.toDouble(),
        );
        bytes = snapshot.readPixels(0, 0, imageInfo);
      } else {
        bytes = snapshot.encodeToBytes();
      }
    } finally {
      snapshot.delete();
    }

    return bytes?.buffer.asByteData();
  }

  @override
  DomCanvasImageSource get canvasImageSource => canvas as DomCanvasImageSource;

  @override
  Future<void> rasterizeToCanvas(ui.Picture picture) async {
    await _initialized.future;
    if (isDisposed) {
      return;
    }
    _drawPicture(picture as CkPicture);
  }

  /// Synchronously clears the surface, draws [picture] into it, and flushes.
  void _drawPicture(CkPicture picture) {
    final canvas = EngineCanvas(CkCanvas(_skSurface!.getCanvas()));
    canvas.clear(const ui.Color(0x00000000));
    canvas.drawPicture(picture);
    _skSurface!.flush();
  }

  @override
  Future<void> triggerContextLoss() async {
    _handledContextLostEvent = Completer<void>();
    final WebGLContext gl = _webGlContextOf(canvas);
    if (!gl.isContextLost()) {
      gl.loseContextExtension.loseContext();
    }
  }

  @override
  Future<void> get handledContextLossEvent => _handledContextLostEvent!.future;
}

/// The CanvasKit implementation of [OffscreenSurface].
class CkOffscreenSurface extends CkSurface implements OffscreenSurface {
  CkOffscreenSurface(OffscreenCanvasProvider super.canvasProvider);

  @override
  int _getGlContext(SkWebGLContextOptions options) {
    return canvasKit.GetOffscreenWebGLContext(canvas as DomOffscreenCanvas, options).toInt();
  }

  @override
  SkSurface? _createSoftwareSkSurface() {
    return canvasKit._makeOffscreenSWCanvasSurface(canvas as DomOffscreenCanvas);
  }

  @override
  Future<List<DomImageBitmap>> rasterizeToImageBitmaps(
    BitmapSize size,
    List<ui.Picture> pictures,
  ) async {
    await _initialized.future;
    // Everything from here until all bitmaps have been requested must be
    // synchronous so that no other operation can resize or draw into the
    // canvas in between. `createImageBitmap` copies the canvas contents at the
    // time it is called; only the resolution of the returned promise is
    // asynchronous.
    setSize(size);
    final bitmapFutures = <Future<DomImageBitmap>>[];
    for (final picture in pictures) {
      _drawPicture(picture as CkPicture);
      bitmapFutures.add(createImageBitmap(_canvas));
    }
    return Future.wait(bitmapFutures);
  }

  @override
  Future<void> rasterizeToCanvasSource(
    BitmapSize size,
    List<ui.Picture> pictures,
    void Function(int index, DomCanvasImageSource source) onRendered,
  ) async {
    await _initialized.future;
    // Everything from here on must be synchronous so that no other operation
    // can resize or draw into the canvas while `onRendered` reads from it.
    setSize(size);
    for (var i = 0; i < pictures.length; i++) {
      _drawPicture(pictures[i] as CkPicture);
      onRendered(i, canvasImageSource);
    }
  }

  @override
  void _maybeAttachCanvasToDom() {
    // Do not attach the OffscreenCanvas to the DOM.
  }

  @override
  WebGLContext _webGlContextOf(DomEventTarget canvas) =>
      (canvas as DomOffscreenCanvas).getGlContext(webGLVersion);

  /// Resizes the offscreen canvas to [size], preserving fast in-place resizing
  /// unless the browser's physical WebGL drawing buffer is clamped.
  ///
  /// The requested dimensions are first validated against the context's
  /// `GL_MAX_TEXTURE_SIZE`. If either dimension exceeds it, an
  /// [UnsupportedError] is thrown before the canvas is touched, so the
  /// existing surface remains usable at its previous size.
  ///
  /// For standard sizes, modifying `canvas.width` and `canvas.height` in-place
  /// updates the drawing buffer without recreating the WebGL context or
  /// churning GPU resources.
  ///
  /// However, when an existing context is resized, Chromium caps the drawing
  /// buffer's area at 5760x5760 and scales both dimensions down to fit (e.g.
  /// 4960x7016 becomes 4843x6850, see
  /// https://github.com/flutter/flutter/issues/182476). A newly created context
  /// is not subject to this cap, although other browser or GPU limits may still
  /// give it a smaller buffer, which is checked below.
  ///
  /// When a drawing buffer clamp is detected, the old canvas is replaced with a
  /// brand-new [DomOffscreenCanvas] and a fresh WebGL context (see
  /// [_replaceCanvasWithSize]), allowing the browser to allocate the full buffer
  /// upfront. A context that is already lost (e.g. its `webglcontextlost`
  /// event is still pending) reports a zero-sized drawing buffer and is
  /// recovered the same way.
  ///
  /// If the fresh context's drawing buffer is still smaller than [size], the
  /// surface is moved to another fresh canvas at [previousSize] and an
  /// [UnsupportedError] is thrown instead of silently rendering clipped
  /// output.
  @override
  void _resizeCanvas(BitmapSize size, BitmapSize previousSize) {
    if (!supportsWebGl) {
      super._resizeCanvas(size, previousSize);
      return;
    }

    final DomEventTarget oldCanvas = canvas;
    final WebGLContext initialGl = (oldCanvas as DomOffscreenCanvas).getGlContext(webGLVersion);
    // A lost context reports no parameters; skip validation and let the
    // zero-sized drawing buffer below route to recovery on a fresh canvas.
    if (!initialGl.isContextLost()) {
      final int maxTextureSize = initialGl.getParameter(initialGl.maxTextureSize);
      if (size.width > maxTextureSize || size.height > maxTextureSize) {
        throw UnsupportedError(
          'Requested dimensions ${size.width}x${size.height} exceed '
          'GL_MAX_TEXTURE_SIZE ($maxTextureSize).',
        );
      }
    }

    _canvasProvider.resizeCanvas(oldCanvas, size);
    final WebGLContext gl = oldCanvas.getGlContext(webGLVersion);

    if (gl.drawingBufferWidth >= size.width && gl.drawingBufferHeight >= size.height) {
      _recreateSkSurface();
      return;
    }

    _replaceCanvasWithSize(size);

    // If creating the new context failed, the surface has fallen back to
    // software rendering, which has no drawing buffer to check.
    if (supportsWebGl) {
      final WebGLContext newGl = (canvas as DomOffscreenCanvas).getGlContext(webGLVersion);
      final int bufferWidth = newGl.drawingBufferWidth;
      final int bufferHeight = newGl.drawingBufferHeight;
      if (bufferWidth < size.width || bufferHeight < size.height) {
        // Use another fresh canvas rather than shrinking this one in place, so
        // that a previous size above the resize cap is not clamped either.
        _replaceCanvasWithSize(previousSize);
        throw UnsupportedError(
          'Requested dimensions ${size.width}x${size.height} exceed the WebGL '
          'drawing buffer allocated by the browser (${bufferWidth}x$bufferHeight).',
        );
      }
    }
  }


  /// Replaces the current canvas with a new one of [size] and attempts to
  /// create a fresh WebGL context for it, falling back to software rendering
  /// if that fails.
  ///
  /// The old canvas and its context are torn down by [_releaseCanvas] before
  /// the new canvas is acquired.
  void _replaceCanvasWithSize(BitmapSize size) {
    _releaseCanvas();

    _canvas = _canvasProvider.acquireCanvas(size, onContextLost: onContextLost);
    _maybeAttachCanvasToDom();
    _createSkiaObjects();
  }

  @override
  BitmapSize get _canvasSize {
    final offscreenCanvas = canvas as DomOffscreenCanvas;
    return BitmapSize((offscreenCanvas.width ?? 0).toInt(), (offscreenCanvas.height ?? 0).toInt());
  }
}

/// The CanvasKit implementation of [OnscreenSurface].
class CkOnscreenSurface extends CkSurface implements OnscreenSurface {
  CkOnscreenSurface(OnscreenCanvasProvider super.canvasProvider);

  @override
  int _getGlContext(SkWebGLContextOptions options) {
    return canvasKit.GetWebGLContext(canvas as DomHTMLCanvasElement, options).toInt();
  }

  @override
  SkSurface? _createSoftwareSkSurface() {
    return canvasKit._makeSWCanvasSurface(canvas as DomHTMLCanvasElement);
  }

  final DomElement _hostElement = createDomElement('flt-canvas-container');

  @override
  DomElement get hostElement => _hostElement;

  @override
  void _maybeAttachCanvasToDom() {
    hostElement.appendChild(canvas as DomHTMLCanvasElement);
    _applyOverlayStyle();
  }

  @override
  WebGLContext _webGlContextOf(DomEventTarget canvas) =>
      (canvas as DomHTMLCanvasElement).getGlContext(webGLVersion);

  @override
  BitmapSize get _canvasSize {
    final htmlCanvas = canvas as DomHTMLCanvasElement;
    return BitmapSize((htmlCanvas.width ?? 0).toInt(), (htmlCanvas.height ?? 0).toInt());
  }

  @override
  bool get isConnected =>
      (canvas as JSAny?).isA<DomHTMLCanvasElement>() &&
      (canvas as DomHTMLCanvasElement).isConnected!;

  @override
  void initialize() {
    // No extra initialization is required.
  }

  bool _isOverlay = false;

  @override
  void setIsOverlay(bool isOverlay) {
    _isOverlay = isOverlay;
    _applyOverlayStyle();
  }

  /// Applies overlay positioning to [canvas] so that it is preserved when
  /// [canvas] is replaced.
  void _applyOverlayStyle() {
    final DomCSSStyleDeclaration style = (canvas as DomHTMLCanvasElement).style;
    if (_isOverlay) {
      if (style.position != 'absolute') {
        style.position = 'absolute';
      }
    } else if (style.position == 'absolute') {
      style.removeProperty('position');
    }
  }
}

/// Nullable bindings for `CanvasKit.MakeSWCanvasSurface`, which returns `null`
/// when 2D context acquisition fails despite the non-nullable declaration in
/// `canvaskit_api.dart`.
extension _CanvasKitSoftwareSurfaceExtension on CanvasKit {
  @JS('MakeSWCanvasSurface')
  external SkSurface? _makeSWCanvasSurface(DomHTMLCanvasElement canvas);

  @JS('MakeSWCanvasSurface')
  external SkSurface? _makeOffscreenSWCanvasSurface(DomOffscreenCanvas canvas);
}
