// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
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
    _canvas = _canvasProvider.acquireCanvas(_currentSize, onContextLost: onContextLost);
    _maybeAttachCanvasToDom();
    _initialize();
  }

  final CanvasProvider _canvasProvider;

  BitmapSize _currentSize = const BitmapSize(1, 1);

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

  void _maybeAttachCanvasToDom();

  /// A [Future] which completes when the [Surface] is initialized and ready to
  /// render pictures.
  @override
  Future<void> get initialized => _initialized.future;
  final Completer<void> _initialized = Completer<void>();

  late Completer<void>? _handledContextLostEvent;

  /// Creates the canvas object and initializes the graphics context.
  Future<void> _initialize() async {
    _createSkiaObjects();
    _initialized.complete();
  }

  /// The underlying Skia graphics context.
  SkGrContext? _grContext;

  /// Handles the context lost event by acquiring a new canvas and recreating
  /// the graphics context.
  void onContextLost() {
    _handledContextLostEvent?.complete();
    final DomEventTarget newCanvas = _canvasProvider.acquireCanvas(
      _currentSize,
      onContextLost: onContextLost,
    );
    recreateContextForCanvas(newCanvas);
  }

  void _recreateSkSurface() {
    if (supportsWebGl) {
      try {
        _recreateWebGlSkSurface();
      } catch (e) {
        _failedToCreateGrContext = true;
        _fallbackToSoftwareReason = 'failed to create GrContext. Error: $e';
        _recreateSoftwareSkSurface();
      }
    } else {
      _recreateSoftwareSkSurface();
    }
  }

  /// Creates the GL context and the Skia `GrContext`.
  void _createGrContext() {
    if (debugForceGLFailure) {
      _failedToCreateGrContext = true;
      _fallbackToSoftwareReason = 'debugForceGLFailure is true';
      return;
    }
    final options = SkWebGLContextOptions(
      antialias: _kUsingMSAA ? 1 : 0,
      majorVersion: webGLVersion.toDouble(),
    );
    _glContext = _getGlContext(options);
    _grContext = canvasKit.MakeGrContext(_glContext.toDouble());
    if (_grContext == null) {
      _failedToCreateGrContext = true;
      _fallbackToSoftwareReason = 'failed to create GrContext.';
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
    if (supportsWebGl) {
      _createGrContext();
    }
    _recreateSkSurface();
  }

  void _recreateWebGlSkSurface() {
    _skSurface?.dispose();
    _skSurface = canvasKit.MakeOnScreenGLSurface(
      _grContext!,
      _currentSize.width.toDouble(),
      _currentSize.height.toDouble(),
      SkColorSpaceSRGB,
      0,
      0,
    );
    if (_skSurface == null) {
      throw Exception('Failed to initialize CanvasKit SkSurface.');
    }
  }

  void _recreateSoftwareSkSurface() {
    if (!_didWarnAboutWebGlInitializationFailure) {
      _didWarnAboutWebGlInitializationFailure = true;
      printWarning(
        'WARNING: Falling back to CPU-only rendering. Reason: $_fallbackToSoftwareReason',
      );
    }
    _skSurface?.dispose();
    _skSurface = _createSoftwareSkSurface();
    if (_skSurface == null) {
      throw Exception('Failed to initialize CanvasKit SkSurface.');
    }
  }

  /// Creates an SkSurface for software rendering. This is used when WebGl is not
  /// supported or when it fails to initialize.
  SkSurface _createSoftwareSkSurface();

  double _currentDevicePixelRatio = -1;

  @override
  void setSize(BitmapSize size) {
    final double devicePixelRatio = EngineFlutterDisplay.instance.devicePixelRatio;
    if (_skSurface != null &&
        _currentSize == size &&
        devicePixelRatio == _currentDevicePixelRatio) {
      return;
    }
    _currentDevicePixelRatio = devicePixelRatio;
    _currentSize = size;
    _canvasProvider.resizeCanvas(canvas, size);
    _recreateSkSurface();
  }

  @override
  Future<void> recreateContextForCanvas(DomEventTarget newCanvas) async {
    // The old Skia surface is now invalid and should be disposed.
    _skSurface?.dispose();
    _skSurface = null;

    // The GrContext is also invalid and will be recreated by `_createSkiaObjects`.
    _grContext = null;

    _canvas = newCanvas;
    _maybeAttachCanvasToDom();
    _createSkiaObjects();
  }

  @override
  void dispose() {
    _skSurface?.dispose();
  }

  @override
  void setSkiaResourceCacheMaxBytes(int bytes) {
    _grContext?.setResourceCacheLimitBytes(bytes.toDouble());
  }

  @override
  Future<ByteData?> rasterizeImage(ui.Image image, ui.ImageByteFormat format) async {
    await _initialized.future;
    final ckImage = image as CkImage;
    final SkSurface skSurface = _skSurface!;
    final canvas = CkCanvas.fromSkCanvas(skSurface.getCanvas());
    canvas.drawImage(ckImage, ui.Offset.zero, ui.Paint());
    final SkImage snapshot = skSurface.makeImageSnapshot();
    final Uint8List? bytes = snapshot.encodeToBytes();
    snapshot.delete();
    return bytes?.buffer.asByteData();
  }

  @override
  DomCanvasImageSource get canvasImageSource => canvas as DomCanvasImageSource;

  @override
  Future<void> rasterizeToCanvas(ui.Picture picture) async {
    await _initialized.future;
    final canvas = CkCanvas.fromSkCanvas(_skSurface!.getCanvas());
    final ckPicture = picture as CkPicture;
    canvas.clear(const ui.Color(0x00000000));
    canvas.drawPicture(ckPicture);
    _skSurface!.flush();
  }

  @override
  Future<void> triggerContextLoss();

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
  SkSurface _createSoftwareSkSurface() {
    return canvasKit.MakeOffscreenSWCanvasSurface(canvas as DomOffscreenCanvas);
  }

  @override
  Future<List<DomImageBitmap>> rasterizeToImageBitmaps(List<ui.Picture> pictures) async {
    await _initialized.future;
    final bitmaps = <DomImageBitmap>[];
    for (final picture in pictures) {
      await rasterizeToCanvas(picture);
      bitmaps.add(await createImageBitmap(_canvas));
    }
    return bitmaps;
  }

  @override
  void _maybeAttachCanvasToDom() {
    // Do not attach the OffscreenCanvas to the DOM.
  }

  @override
  Future<void> triggerContextLoss() async {
    _handledContextLostEvent = Completer<void>();
    final WebGLContext gl = (canvas as DomOffscreenCanvas).getGlContext(webGLVersion);
    gl.loseContextExtension.loseContext();
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
  SkSurface _createSoftwareSkSurface() {
    return canvasKit.MakeSWCanvasSurface(canvas as DomHTMLCanvasElement);
  }

  final DomElement _hostElement = createDomElement('flt-canvas-container');

  @override
  DomElement get hostElement => _hostElement;

  @override
  void _maybeAttachCanvasToDom() {
    hostElement.appendChild(canvas as DomHTMLCanvasElement);
  }

  @override
  bool get isConnected =>
      ((canvas as JSAny?).isA<DomHTMLCanvasElement>()) &&
      (canvas as DomHTMLCanvasElement).isConnected!;

  @override
  void initialize() {
    // No extra initialization is required.
  }

  @override
  Future<void> triggerContextLoss() async {
    _handledContextLostEvent = Completer<void>();
    final WebGLContext gl = (canvas as DomHTMLCanvasElement).getGlContext(webGLVersion);
    gl.loseContextExtension.loseContext();
  }
}
