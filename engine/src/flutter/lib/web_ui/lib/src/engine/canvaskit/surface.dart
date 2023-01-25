// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../browser_detection.dart';
import '../configuration.dart';
import '../dom.dart';
import '../platform_dispatcher.dart';
import '../safe_browser_api.dart';
import '../util.dart';
import '../window.dart';
import 'canvas.dart';
import 'canvaskit_api.dart';
import 'renderer.dart';
import 'surface_factory.dart';
import 'util.dart';

// Only supported in profile/release mode. Allows Flutter to use MSAA but
// removes the ability for disabling AA on Paint objects.
const bool _kUsingMSAA = bool.fromEnvironment('flutter.canvaskit.msaa');

typedef SubmitCallback = bool Function(SurfaceFrame, CkCanvas);

/// A frame which contains a canvas to be drawn into.
class SurfaceFrame {
  SurfaceFrame(this.skiaSurface, this.submitCallback)
      : _submitted = false,
        assert(skiaSurface != null),
        assert(submitCallback != null);

  final CkSurface skiaSurface;
  final SubmitCallback submitCallback;
  final bool _submitted;

  /// Submit this frame to be drawn.
  bool submit() {
    if (_submitted) {
      return false;
    }
    return submitCallback(this, skiaCanvas);
  }

  CkCanvas get skiaCanvas => skiaSurface.getCanvas();
}

/// A surface which can be drawn into by the compositor.
///
/// The underlying representation is a [CkSurface], which can be reused by
/// successive frames if they are the same size. Otherwise, a new [CkSurface] is
/// created.
class Surface {
  Surface();

  CkSurface? _surface;

  /// If true, forces a new WebGL context to be created, even if the window
  /// size is the same. This is used to restore the UI after the browser tab
  /// goes dormant and loses the GL context.
  bool _forceNewContext = true;
  bool get debugForceNewContext => _forceNewContext;

  bool _contextLost = false;
  bool get debugContextLost => _contextLost;

  /// A cached copy of the most recently created `webglcontextlost` listener.
  ///
  /// We must cache this function because each time we access the tear-off it
  /// creates a new object, meaning we won't be able to remove this listener
  /// later.
  void Function(DomEvent)? _cachedContextLostListener;

  /// A cached copy of the most recently created `webglcontextrestored`
  /// listener.
  ///
  /// We must cache this function because each time we access the tear-off it
  /// creates a new object, meaning we won't be able to remove this listener
  /// later.
  void Function(DomEvent)? _cachedContextRestoredListener;

  SkGrContext? _grContext;
  int? _glContext;
  int? _skiaCacheBytes;

  /// The root HTML element for this surface.
  ///
  /// This element contains the canvas used to draw the UI. Unlike the canvas,
  /// this element is permanent. It is never replaced or deleted, until this
  /// surface is disposed of via [dispose].
  ///
  /// Conversely, the canvas that lives inside this element can be swapped, for
  /// example, when the screen size changes, or when the WebGL context is lost
  /// due to the browser tab becoming dormant.
  final DomElement htmlElement = createDomElement('flt-canvas-container');

  /// The underlying `<canvas>` element used for this surface.
  DomCanvasElement? htmlCanvas;
  int _pixelWidth = -1;
  int _pixelHeight = -1;
  int _sampleCount = -1;
  int _stencilBits = -1;

  /// Specify the GPU resource cache limits.
  void setSkiaResourceCacheMaxBytes(int bytes) {
    _skiaCacheBytes = bytes;
    _syncCacheBytes();
  }

  void _syncCacheBytes() {
    if (_skiaCacheBytes != null) {
      _grContext?.setResourceCacheLimitBytes(_skiaCacheBytes!.toDouble());
    }
  }

  bool _addedToScene = false;

  /// Acquire a frame of the given [size] containing a drawable canvas.
  ///
  /// The given [size] is in physical pixels.
  SurfaceFrame acquireFrame(ui.Size size) {
    final CkSurface surface = createOrUpdateSurface(size);

    // ignore: prefer_function_declarations_over_variables
    final SubmitCallback submitCallback =
        (SurfaceFrame surfaceFrame, CkCanvas canvas) {
      return _presentSurface();
    };

    return SurfaceFrame(surface, submitCallback);
  }

  void addToScene() {
    if (!_addedToScene) {
      CanvasKitRenderer.instance.sceneHost!.prepend(htmlElement);
    }
    _addedToScene = true;
  }

  ui.Size? _currentCanvasPhysicalSize;
  ui.Size? _currentSurfaceSize;
  double _currentDevicePixelRatio = -1;

  /// This is only valid after the first frame or if [ensureSurface] has been
  /// called
  bool get usingSoftwareBackend => _glContext == null ||
      _grContext == null || webGLVersion == -1 || configuration.canvasKitForceCpuOnly;

  /// Ensure that the initial surface exists and has a size of at least [size].
  ///
  /// If not provided, [size] defaults to 1x1.
  ///
  /// This also ensures that the gl/grcontext have been populated so
  /// that software rendering can be detected.
  void ensureSurface([ui.Size size = const ui.Size(1, 1)]) {
    // If the GrContext hasn't been setup yet then we need to force initialization
    // of the canvas and initial surface.
    if (_surface != null) {
      return;
    }
    // TODO(jonahwilliams): this is somewhat wasteful. We should probably
    // eagerly setup this surface instead of delaying until the first frame?
    // Or at least cache the estimated window size.
    createOrUpdateSurface(size);
  }

  /// This method is not supported if software rendering is used.
  CkSurface createRenderTargetSurface(ui.Size size) {
    assert(!usingSoftwareBackend);

    final SkSurface skSurface = canvasKit.MakeRenderTarget(
      _grContext!,
      size.width.ceil(),
      size.height.ceil(),
    )!;
    return CkSurface(skSurface, _glContext);
  }

  /// Creates a <canvas> and SkSurface for the given [size].
  CkSurface createOrUpdateSurface(ui.Size size) {
    if (size.isEmpty) {
      throw CanvasKitError('Cannot create surfaces of empty size.');
    }

    if (!_forceNewContext) {
      // Check if the window is the same size as before, and if so, don't allocate
      // a new canvas as the previous canvas is big enough to fit everything.
      final ui.Size? previousSurfaceSize = _currentSurfaceSize;
      if (previousSurfaceSize != null &&
          size.width == previousSurfaceSize.width &&
          size.height == previousSurfaceSize.height) {
        // The existing surface is still reusable.
        if (window.devicePixelRatio != _currentDevicePixelRatio) {
          _updateLogicalHtmlCanvasSize();
          _translateCanvas();
        }
        return _surface!;
      }

      final ui.Size? previousCanvasSize = _currentCanvasPhysicalSize;
      // Initialize a new, larger, canvas. If the size is growing, then make the
      // new canvas larger than required to avoid many canvas creations.
      if (previousCanvasSize != null &&
          (size.width > previousCanvasSize.width ||
              size.height > previousCanvasSize.height)) {
        final ui.Size newSize = size * 1.4;
        _surface?.dispose();
        _surface = null;
        htmlCanvas!.width = newSize.width;
        htmlCanvas!.height = newSize.height;
        _currentCanvasPhysicalSize = newSize;
        _pixelWidth = newSize.width.ceil();
        _pixelHeight = newSize.height.ceil();
        _updateLogicalHtmlCanvasSize();
      }
    }

    // Either a new context is being forced or we've never had one.
    if (_forceNewContext || _currentCanvasPhysicalSize == null) {
      _surface?.dispose();
      _surface = null;
      _addedToScene = false;
      _grContext?.releaseResourcesAndAbandonContext();
      _grContext?.delete();
      _grContext = null;

      _createNewCanvas(size);
      _currentCanvasPhysicalSize = size;
    } else if (window.devicePixelRatio != _currentDevicePixelRatio) {
      _updateLogicalHtmlCanvasSize();
    }

    _currentDevicePixelRatio = window.devicePixelRatio;
    _currentSurfaceSize = size;
    _translateCanvas();
    _surface?.dispose();
    _surface = _createNewSurface(size);
    return _surface!;
  }

  /// Sets the CSS size of the canvas so that canvas pixels are 1:1 with device
  /// pixels.
  ///
  /// The logical size of the canvas is not based on the size of the window
  /// but on the size of the canvas, which, due to `ceil()` above, may not be
  /// the same as the window. We do not round/floor/ceil the logical size as
  /// CSS pixels can contain more than one physical pixel and therefore to
  /// match the size of the window precisely we use the most precise floating
  /// point value we can get.
  void _updateLogicalHtmlCanvasSize() {
    final double logicalWidth = _pixelWidth / window.devicePixelRatio;
    final double logicalHeight = _pixelHeight / window.devicePixelRatio;
    final DomCSSStyleDeclaration style = htmlCanvas!.style;
    style.width = '${logicalWidth}px';
    style.height = '${logicalHeight}px';
  }

  /// Translate the canvas so the surface covers the visible portion of the
  /// screen.
  ///
  /// The <canvas> may be larger than the visible screen, but the SkSurface is
  /// exactly the size of the visible screen. Unfortunately, the SkSurface is
  /// drawn in the lower left corner of the <canvas>, and without translation,
  /// only the top left of the <canvas> is visible. So we shift the canvas up so
  /// the bottom left corner is visible.
  void _translateCanvas() {
    final int surfaceHeight = _currentSurfaceSize!.height.ceil();
    final double offset =
        (_pixelHeight - surfaceHeight) / window.devicePixelRatio;
    htmlCanvas!.style.transform = 'translate(0, -${offset}px)';
  }

  void _contextRestoredListener(DomEvent event) {
    assert(
        _contextLost,
        'Received "webglcontextrestored" event but never received '
        'a "webglcontextlost" event.');
    _contextLost = false;
    // Force the framework to rerender the frame.
    EnginePlatformDispatcher.instance.invokeOnMetricsChanged();
    event.stopPropagation();
    event.preventDefault();
  }

  void _contextLostListener(DomEvent event) {
    assert(event.target == htmlCanvas,
        'Received a context lost event for a disposed canvas');
    final SurfaceFactory factory = SurfaceFactory.instance;
    _contextLost = true;
    if (factory.isLive(this)) {
      _forceNewContext = true;
      event.preventDefault();
    } else {
      dispose();
    }
  }

  /// This function is expensive.
  ///
  /// It's better to reuse canvas if possible.
  void _createNewCanvas(ui.Size physicalSize) {
    // Clear the container, if it's not empty. We're going to create a new <canvas>.
    if (this.htmlCanvas != null) {
      this.htmlCanvas!.removeEventListener(
            'webglcontextrestored',
            _cachedContextRestoredListener,
            false,
          );
      this.htmlCanvas!.removeEventListener(
            'webglcontextlost',
            _cachedContextLostListener,
            false,
          );
      this.htmlCanvas!.remove();
      _cachedContextRestoredListener = null;
      _cachedContextLostListener = null;
    }

    // If `physicalSize` is not precise, use a slightly bigger canvas. This way
    // we ensure that the rendred picture covers the entire browser window.
    _pixelWidth = physicalSize.width.ceil();
    _pixelHeight = physicalSize.height.ceil();
    final DomCanvasElement htmlCanvas = createDomCanvasElement(
      width: _pixelWidth,
      height: _pixelHeight,
    );
    this.htmlCanvas = htmlCanvas;

    // The DOM elements used to render pictures are used purely to put pixels on
    // the screen. They have no semantic information. If an assistive technology
    // attempts to scan picture content it will look like garbage and confuse
    // users. UI semantics are exported as a separate DOM tree rendered parallel
    // to pictures.
    //
    // Why are layer and scene elements not hidden from ARIA? Because those
    // elements may contain platform views, and platform views must be
    // accessible.
    htmlCanvas.setAttribute('aria-hidden', 'true');

    htmlCanvas.style.position = 'absolute';
    _updateLogicalHtmlCanvasSize();

    // When the browser tab using WebGL goes dormant the browser and/or OS may
    // decide to clear GPU resources to let other tabs/programs use the GPU.
    // When this happens, the browser sends the "webglcontextlost" event as a
    // notification. When we receive this notification we force a new context.
    //
    // See also: https://www.khronos.org/webgl/wiki/HandlingContextLost
    _cachedContextRestoredListener = allowInterop(_contextRestoredListener);
    _cachedContextLostListener = allowInterop(_contextLostListener);
    htmlCanvas.addEventListener(
      'webglcontextlost',
      _cachedContextLostListener,
      false,
    );
    htmlCanvas.addEventListener(
      'webglcontextrestored',
      _cachedContextRestoredListener,
      false,
    );
    _forceNewContext = false;
    _contextLost = false;

    if (webGLVersion != -1 && !configuration.canvasKitForceCpuOnly) {
      final int glContext = canvasKit.GetWebGLContext(
        htmlCanvas,
        SkWebGLContextOptions(
          // Default to no anti-aliasing. Paint commands can be explicitly
          // anti-aliased by setting their `Paint` object's `antialias` property.
          antialias: _kUsingMSAA ? 1 : 0,
          majorVersion: webGLVersion.toDouble(),
        ),
      ).toInt();

      _glContext = glContext;

      if (_glContext != 0) {
        _grContext = canvasKit.MakeGrContext(glContext.toDouble());
        if (_grContext == null) {
          throw CanvasKitError('Failed to initialize CanvasKit. '
              'CanvasKit.MakeGrContext returned null.');
        }
        if (_sampleCount == -1 || _stencilBits == -1) {
          _initWebglParams();
        }
        // Set the cache byte limit for this grContext, if not specified it will
        // use CanvasKit's default.
        _syncCacheBytes();
      }
    }

    htmlElement.append(htmlCanvas);
  }

  void _initWebglParams() {
    final WebGLContext gl = htmlCanvas!.getGlContext(webGLVersion);
    _sampleCount = gl.getParameter(gl.samples);
    _stencilBits = gl.getParameter(gl.stencilBits);
  }

  CkSurface _createNewSurface(ui.Size size) {
    assert(htmlCanvas != null);
    if (webGLVersion == -1) {
      return _makeSoftwareCanvasSurface(
          htmlCanvas!, 'WebGL support not detected');
    } else if (configuration.canvasKitForceCpuOnly) {
      return _makeSoftwareCanvasSurface(
          htmlCanvas!, 'CPU rendering forced by application');
    } else if (_glContext == 0) {
      return _makeSoftwareCanvasSurface(
          htmlCanvas!, 'Failed to initialize WebGL context');
    } else {
      final SkSurface? skSurface = canvasKit.MakeOnScreenGLSurface(
        _grContext!,
        size.width.roundToDouble(),
        size.height.roundToDouble(),
        SkColorSpaceSRGB,
        _sampleCount,
        _stencilBits
      );

      if (skSurface == null) {
        return _makeSoftwareCanvasSurface(
            htmlCanvas!, 'Failed to initialize WebGL surface');
      }

      return CkSurface(skSurface, _glContext);
    }
  }

  static bool _didWarnAboutWebGlInitializationFailure = false;

  CkSurface _makeSoftwareCanvasSurface(
      DomCanvasElement htmlCanvas, String reason) {
    if (!_didWarnAboutWebGlInitializationFailure) {
      printWarning('WARNING: Falling back to CPU-only rendering. $reason.');
      _didWarnAboutWebGlInitializationFailure = true;
    }
    return CkSurface(
      canvasKit.MakeSWCanvasSurface(htmlCanvas),
      null,
    );
  }

  bool _presentSurface() {
    _surface!.flush();
    return true;
  }

  void dispose() {
    htmlCanvas?.removeEventListener(
        'webglcontextlost', _cachedContextLostListener, false);
    htmlCanvas?.removeEventListener(
        'webglcontextrestored', _cachedContextRestoredListener, false);
    _cachedContextLostListener = null;
    _cachedContextRestoredListener = null;
    htmlElement.remove();
    _surface?.dispose();
  }
}

/// A Dart wrapper around Skia's CkSurface.
class CkSurface {
  CkSurface(this.surface, this._glContext);

  CkCanvas getCanvas() {
    assert(!_isDisposed, 'Attempting to use the canvas of a disposed surface');
    return CkCanvas(surface.getCanvas());
  }

  /// The underlying CanvasKit surface object.
  ///
  /// Only borrow this value temporarily. Do not store it as it may be deleted
  /// at any moment. Storing it may lead to dangling pointer bugs.
  final SkSurface surface;

  final int? _glContext;

  /// Flushes the graphics to be rendered on screen.
  void flush() {
    surface.flush();
  }

  int? get context => _glContext;

  int width() => surface.width().round();
  int height() => surface.height().round();

  void dispose() {
    if (_isDisposed) {
      return;
    }
    surface.dispose();
    _isDisposed = true;
  }

  bool _isDisposed = false;
}
