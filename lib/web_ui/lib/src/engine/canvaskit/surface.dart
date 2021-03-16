// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

typedef SubmitCallback = bool Function(SurfaceFrame, CkCanvas);

/// A frame which contains a canvas to be drawn into.
class SurfaceFrame {
  final CkSurface skiaSurface;
  final SubmitCallback submitCallback;
  bool _submitted;

  SurfaceFrame(this.skiaSurface, this.submitCallback)
      : _submitted = false,
        assert(skiaSurface != null), // ignore: unnecessary_null_comparison
        assert(submitCallback != null); // ignore: unnecessary_null_comparison

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
  Surface(this.viewEmbedder);

  CkSurface? _surface;

  /// If true, forces a new WebGL context to be created, even if the window
  /// size is the same. This is used to restore the UI after the browser tab
  /// goes dormant and loses the GL context.
  bool _forceNewContext = true;
  bool get debugForceNewContext => _forceNewContext;

  SkGrContext? _grContext;
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
  final html.Element htmlElement = html.Element.tag('flt-canvas-container');

  /// The underlying `<canvas>` element used for this surface.
  html.CanvasElement? htmlCanvas;
  int _pixelWidth = -1;
  int _pixelHeight = -1;

  /// Specify the GPU resource cache limits.
  void setSkiaResourceCacheMaxBytes(int bytes) {
    _skiaCacheBytes = bytes;
    _syncCacheBytes();
  }

  void _syncCacheBytes() {
    if (_skiaCacheBytes != null) {
      _grContext?.setResourceCacheLimitBytes(_skiaCacheBytes!);
    }
  }

  bool _addedToScene = false;

  /// The default view embedder. Coordinates embedding platform views and
  /// overlaying subsequent draw operations on top.
  final HtmlViewEmbedder viewEmbedder;

  /// Acquire a frame of the given [size] containing a drawable canvas.
  ///
  /// The given [size] is in physical pixels.
  SurfaceFrame acquireFrame(ui.Size size) {
    final CkSurface surface = _createOrUpdateSurfaces(size);

    if (surface.context != null) {
      canvasKit.setCurrentContext(surface.context!);
    }
    SubmitCallback submitCallback =
        (SurfaceFrame surfaceFrame, CkCanvas canvas) {
      return _presentSurface();
    };

    return SurfaceFrame(surface, submitCallback);
  }

  void addToScene() {
    if (!_addedToScene) {
      skiaSceneHost!.children.insert(0, htmlElement);
    }
    _addedToScene = true;
  }

  ui.Size? _currentSize;
  double _currentDevicePixelRatio = -1;

  CkSurface _createOrUpdateSurfaces(ui.Size size) {
    if (size.isEmpty) {
      throw CanvasKitError('Cannot create surfaces of empty size.');
    }

    // Check if the window is shrinking in size, and if so, don't allocate a
    // new canvas as the previous canvas is big enough to fit everything.
    final ui.Size? previousSize = _currentSize;
    if (!_forceNewContext &&
        previousSize != null &&
        size.width <= previousSize.width &&
        size.height <= previousSize.height) {
      // The existing surface is still reusable.
      if (window.devicePixelRatio != _currentDevicePixelRatio) {
        _updateLogicalHtmlCanvasSize();
      }
      return _surface!;
    }

    _currentDevicePixelRatio = window.devicePixelRatio;
    _currentSize = _currentSize == null
        // First frame. Allocate a canvas of the exact size as the window. The
        // window is frequently never resized, particularly on mobile, so using
        // the exact size is most optimal.
        ? size
        // The window is growing. Overallocate to prevent frequent reallocations.
        : size * 1.4;

    _surface?.dispose();
    _surface = null;
    _addedToScene = false;

    return _surface = _createNewSurface(_currentSize!);
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
    final double logicalWidth = _pixelWidth / ui.window.devicePixelRatio;
    final double logicalHeight = _pixelHeight / ui.window.devicePixelRatio;
    htmlCanvas!.style
      ..width = '${logicalWidth}px'
      ..height = '${logicalHeight}px';
  }

  /// This function is expensive.
  ///
  /// It's better to reuse surface if possible.
  CkSurface _createNewSurface(ui.Size physicalSize) {
    // Clear the container, if it's not empty. We're going to create a new <canvas>.
    this.htmlCanvas?.remove();

    // If `physicalSize` is not precise, use a slightly bigger canvas. This way
    // we ensure that the rendred picture covers the entire browser window.
    _pixelWidth = physicalSize.width.ceil();
    _pixelHeight = physicalSize.height.ceil();
    final html.CanvasElement htmlCanvas = html.CanvasElement(
      width: _pixelWidth,
      height: _pixelHeight,
    );
    this.htmlCanvas = htmlCanvas;
    htmlCanvas.style.position = 'absolute';
    _updateLogicalHtmlCanvasSize();

    // When the browser tab using WebGL goes dormant the browser and/or OS may
    // decide to clear GPU resources to let other tabs/programs use the GPU.
    // When this happens, the browser sends the "webglcontextlost" event as a
    // notification. When we receive this notification we force a new context.
    //
    // See also: https://www.khronos.org/webgl/wiki/HandlingContextLost
    htmlCanvas.addEventListener('webglcontextlost', (event) {
      print('Flutter: restoring WebGL context.');
      _forceNewContext = true;
      // Force the framework to rerender the frame.
      EnginePlatformDispatcher.instance.invokeOnMetricsChanged();
      event.stopPropagation();
      event.preventDefault();
    }, false);
    _forceNewContext = false;

    htmlElement.append(htmlCanvas);

    if (webGLVersion == -1) {
      return _makeSoftwareCanvasSurface(
          htmlCanvas, 'WebGL support not detected');
    } else if (canvasKitForceCpuOnly) {
      return _makeSoftwareCanvasSurface(
          htmlCanvas, 'CPU rendering forced by application');
    } else {
      // Try WebGL first.
      final int glContext = canvasKit.GetWebGLContext(
        htmlCanvas,
        SkWebGLContextOptions(
          // Default to no anti-aliasing. Paint commands can be explicitly
          // anti-aliased by setting their `Paint` object's `antialias` property.
          anitalias: 0,
          majorVersion: webGLVersion,
        ),
      );

      if (glContext == 0) {
        return _makeSoftwareCanvasSurface(
            htmlCanvas, 'Failed to initialize WebGL context');
      }

      _grContext = canvasKit.MakeGrContext(glContext);

      if (_grContext == null) {
        throw CanvasKitError(
            'Failed to initialize CanvasKit. CanvasKit.MakeGrContext returned null.');
      }

      // Set the cache byte limit for this grContext, if not specified it will use
      // CanvasKit's default.
      _syncCacheBytes();

      SkSurface? skSurface = canvasKit.MakeOnScreenGLSurface(
        _grContext!,
        _pixelWidth,
        _pixelHeight,
        SkColorSpaceSRGB,
      );

      if (skSurface == null) {
        return _makeSoftwareCanvasSurface(
            htmlCanvas, 'Failed to initialize WebGL surface');
      }

      return CkSurface(skSurface, _grContext, glContext);
    }
  }

  static bool _didWarnAboutWebGlInitializationFailure = false;

  CkSurface _makeSoftwareCanvasSurface(
      html.CanvasElement htmlCanvas, String reason) {
    if (!_didWarnAboutWebGlInitializationFailure) {
      printWarning('WARNING: Falling back to CPU-only rendering. $reason.');
      _didWarnAboutWebGlInitializationFailure = true;
    }
    return CkSurface(
      canvasKit.MakeSWCanvasSurface(htmlCanvas),
      null,
      null,
    );
  }

  bool _presentSurface() {
    if (_surface!.context != null) {
      canvasKit.setCurrentContext(_surface!.context!);
    }
    _surface!.flush();
    return true;
  }

  void dispose() {
    htmlElement.remove();
    _surface?.dispose();
  }
}

/// A Dart wrapper around Skia's CkSurface.
class CkSurface {
  final SkSurface _surface;
  final SkGrContext? _grContext;
  final int? _glContext;

  CkSurface(this._surface, this._grContext, this._glContext);

  CkCanvas getCanvas() {
    return CkCanvas(_surface.getCanvas());
  }

  /// Flushes the graphics to be rendered on screen.
  void flush() {
    _surface.flush();
  }

  int? get context => _glContext;

  int width() => _surface.width();
  int height() => _surface.height();

  void dispose() {
    if (_isDisposed) {
      return;
    }
    // Only resources from the current context can be disposed.
    if (_glContext != null) {
      canvasKit.setCurrentContext(_glContext!);
    }
    _surface.dispose();

    // In CPU-only mode there's no graphics context.
    if (_grContext != null) {
      _grContext!.releaseResourcesAndAbandonContext();
      _grContext!.delete();
    }
    _isDisposed = true;
  }

  bool _isDisposed = false;
}
