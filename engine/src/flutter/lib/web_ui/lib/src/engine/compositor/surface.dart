// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
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
  html.Element? htmlElement;
  SkGrContext? _grContext;
  int? _skiaCacheBytes;

  /// Specify the GPU resource cache limits.
  void setSkiaResourceCacheMaxBytes(int bytes) {
    _skiaCacheBytes = bytes;
    _syncCacheBytes();
  }

  void _syncCacheBytes() {
    if(_skiaCacheBytes != null) {
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
    final CkSurface surface = acquireRenderSurface(size);

    if (surface.context != null) {
      canvasKit.setCurrentContext(surface.context!);
    }
    SubmitCallback submitCallback =
        (SurfaceFrame surfaceFrame, CkCanvas canvas) {
      return _presentSurface();
    };

    return SurfaceFrame(surface, submitCallback);
  }

  CkSurface acquireRenderSurface(ui.Size size) {
    _createOrUpdateSurfaces(size);
    return _surface!;
  }

  void addToScene() {
    if (!_addedToScene) {
      skiaSceneHost!.children.insert(0, htmlElement!);
    }
    _addedToScene = true;
  }

  void _createOrUpdateSurfaces(ui.Size size) {
    if (size.isEmpty) {
      throw CanvasKitError('Cannot create surfaces of empty size.');
    }

    final CkSurface? currentSurface = _surface;
    if (currentSurface != null) {
      final bool isSameSize = size.width == currentSurface.width() &&
          size.height == currentSurface.height();
      if (isSameSize) {
        // The existing surface is still reusable.
        return;
      }
    }

    currentSurface?.dispose();
    _surface = null;
    htmlElement?.remove();
    htmlElement = null;
    _addedToScene = false;

    _surface = _wrapHtmlCanvas(size);
  }

  CkSurface _wrapHtmlCanvas(ui.Size size) {
    final ui.Size logicalSize = size / ui.window.devicePixelRatio;
    final html.CanvasElement htmlCanvas = html.CanvasElement(
        width: size.width.ceil(), height: size.height.ceil());
    htmlCanvas.style
      ..position = 'absolute'
      ..width = '${logicalSize.width.ceil()}px'
      ..height = '${logicalSize.height.ceil()}px';

    htmlElement = htmlCanvas;
    if (canvasKitForceCpuOnly) {
      return _makeSoftwareCanvasSurface(htmlCanvas);
    } else {
      // Try WebGL first.
      final int glContext = canvasKit.GetWebGLContext(
        htmlCanvas,
        SkWebGLContextOptions(
          // Default to no anti-aliasing. Paint commands can be explicitly
          // anti-aliased by setting their `Paint` object's `antialias` property.
          anitalias: 0,
        ),
      );

      if (glContext == 0) {
        return _makeSoftwareCanvasSurface(htmlCanvas);
      }

      _grContext = canvasKit.MakeGrContext(glContext);

      if (_grContext == null) {
        throw CanvasKitError('Failed to initialize CanvasKit. CanvasKit.MakeGrContext returned null.');
      }

      // Set the cache byte limit for this grContext, if not specified it will use
      // CanvasKit's default.
      _syncCacheBytes();

      SkSurface? skSurface = canvasKit.MakeOnScreenGLSurface(
        _grContext!,
        size.width,
        size.height,
        SkColorSpaceSRGB,
      );

      if (skSurface == null) {
        return _makeSoftwareCanvasSurface(htmlCanvas);
      }

      return CkSurface(skSurface, _grContext, glContext);
    }
  }

  static bool _didWarnAboutWebGlInitializationFailure = false;

  CkSurface _makeSoftwareCanvasSurface(html.CanvasElement htmlCanvas) {
    if (!_didWarnAboutWebGlInitializationFailure) {
      html.window.console.warn('WARNING: failed to initialize WebGL. Falling back to CPU-only rendering.');
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
