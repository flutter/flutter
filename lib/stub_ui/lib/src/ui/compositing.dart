// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

/// When `true` prints statistics about what happened to the surface tree when
/// it was composited.
///
/// Also paints an on-screen overlay with the numbers visualized as a timeline.
const _debugExplainSurfaceStats = false;

/// When `true` shows an overlay that contains stats about canvas reuse.
///
/// The overlay also includes a button to reset the stats.
const _debugShowCanvasReuseStats = false;

/// When `true` renders the outlines of clip layers on the screen instead of
/// clipping the contents.
///
/// This is useful when visually debugging clipping behavior.
bool debugShowClipLayers = false;

/// The threshold for the canvas pixel count to screen pixel count ratio, beyond
/// which in debug mode a warning is issued to the console.
///
/// As we improve canvas utilization we should decrease this number. It is
/// unlikely that we will hit 1.0, but something around 3.0 should be
/// reasonable.
const _kScreenPixelRatioWarningThreshold = 6.0;

/// Whether we've already warned the user about the lack of the performance
/// overlay or not.
///
/// We use this to avoid spamming the console with redundant warning messages.
bool _webOnlyDidWarnAboutPerformanceOverlay = false;

/// An opaque object representing a composited scene.
///
/// To create a Scene object, use a [SceneBuilder].
///
/// Scene objects can be displayed on the screen using the
/// [Window.render] method.
class Scene {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a Scene object, use a [SceneBuilder].
  Scene._(this.webOnlyRootElement);

  final html.Element webOnlyRootElement;

  /// Creates a raster image representation of the current state of the scene.
  /// This is a slow operation that is performed on a background thread.
  Future<Image> toImage(int width, int height) {
    if (width <= 0 || height <= 0)
      throw new Exception('Invalid image dimensions.');
    throw UnsupportedError('toImage is not supported on the Web');
    // TODO(flutter_web): Implement [_toImage].
    // return futurize(
    //     (Callback<Image> callback) => _toImage(width, height, callback));
  }

  // String _toImage(int width, int height, Callback<Image> callback) => null;

  /// Releases the resources used by this scene.
  ///
  /// After calling this function, the scene is cannot be used further.
  void dispose() {}
}

/// Builds a [Scene] containing the given visuals.
///
/// A [Scene] can then be rendered using [Window.render].
///
/// To draw graphical operations onto a [Scene], first create a
/// [Picture] using a [PictureRecorder] and a [Canvas], and then add
/// it to the scene using [addPicture].
class SceneBuilder {
  static const webOnlyUseLayerSceneBuilder = false;

  /// Creates an empty [SceneBuilder] object.
  factory SceneBuilder() {
    if (webOnlyUseLayerSceneBuilder) {
      return engine.LayerSceneBuilder();
    } else {
      return SceneBuilder._();
    }
  }
  SceneBuilder._() {
    _surfaceStack.add(PersistedScene());
  }

  factory SceneBuilder.layer() = engine.LayerSceneBuilder;

  final List<PersistedContainerSurface> _surfaceStack =
      <PersistedContainerSurface>[];

  /// The scene built by this scene builder.
  ///
  /// This getter should only be called after all surfaces are built.
  PersistedScene get _persistedScene {
    assert(() {
      if (_surfaceStack.length != 1) {
        final surfacePrintout =
            _surfaceStack.map((l) => l.runtimeType).toList().join(', ');
        throw Exception('Incorrect sequence of push/pop operations while '
            'building scene surfaces. After building the scene the persisted '
            'surface stack must contain a single element which corresponds '
            'to the scene itself (_PersistedScene). All other surfaces '
            'should have been popped off the stack. Found the following '
            'surfaces in the stack:\n${surfacePrintout}');
      }
      return true;
    }());
    return _surfaceStack.first;
  }

  /// The surface currently being built.
  PersistedContainerSurface get _currentSurface => _surfaceStack.last;

  EngineLayer _pushSurface(PersistedContainerSurface surface) {
    _adoptSurface(surface);
    _surfaceStack.add(surface);
    return surface;
  }

  void _addSurface(PersistedSurface surface) {
    _adoptSurface(surface);
  }

  void _adoptSurface(PersistedSurface surface) {
    _currentSurface.appendChild(surface);
  }

  /// Pushes an offset operation onto the operation stack.
  ///
  /// This is equivalent to [pushTransform] with a matrix with only translation.
  ///
  /// See [pop] for details about the operation stack.
  EngineLayer pushOffset(double dx, double dy) {
    return _pushSurface(PersistedOffset(null, dx, dy));
  }

  /// Pushes a transform operation onto the operation stack.
  ///
  /// The objects are transformed by the given matrix before rasterization.
  ///
  /// See [pop] for details about the operation stack.
  EngineLayer pushTransform(Float64List matrix4) {
    if (matrix4 == null)
      throw new ArgumentError('"matrix4" argument cannot be null');
    if (matrix4.length != 16)
      throw new ArgumentError('"matrix4" must have 16 entries.');
    return _pushSurface(PersistedTransform(null, matrix4));
  }

  /// Pushes a rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rectangle is discarded.
  ///
  /// See [pop] for details about the operation stack, and [Clip] for different clip modes.
  /// By default, the clip will be anti-aliased (clip = [Clip.antiAlias]).
  EngineLayer pushClipRect(Rect rect,
      {Clip clipBehavior = Clip.antiAlias, }) {
    assert(clipBehavior != null);
    assert(clipBehavior != Clip.none);
    return _pushSurface(PersistedClipRect(null, rect));
  }

  /// Pushes a rounded-rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rounded rectangle is discarded.
  ///
  /// See [pop] for details about the operation stack.
  EngineLayer pushClipRRect(RRect rrect,
      {Clip clipBehavior, }) {
    return _pushSurface(
        PersistedClipRRect(null, rrect, clipBehavior));
  }

  /// Pushes a path clip operation onto the operation stack.
  ///
  /// Rasterization outside the given path is discarded.
  ///
  /// See [pop] for details about the operation stack.
  EngineLayer pushClipPath(Path path,
      {Clip clipBehavior = Clip.antiAlias, }) {
    assert(clipBehavior != null);
    assert(clipBehavior != Clip.none);
    return _pushSurface(
        _PersistedClipPath(null, path, clipBehavior));
  }

  /// Pushes an opacity operation onto the operation stack.
  ///
  /// The given alpha value is blended into the alpha value of the objects'
  /// rasterization. An alpha value of 0 makes the objects entirely invisible.
  /// An alpha value of 255 has no effect (i.e., the objects retain the current
  /// opacity).
  ///
  /// See [pop] for details about the operation stack.
  EngineLayer pushOpacity(int alpha,
      {Offset offset = Offset.zero}) {
    return _pushSurface(PersistedOpacity(null, alpha, offset));
  }

  /// Pushes a color filter operation onto the operation stack.
  ///
  /// The given color is applied to the objects' rasterization using the given
  /// blend mode.
  ///
  /// See [pop] for details about the operation stack.
  EngineLayer pushColorFilter(Color color, BlendMode blendMode) {
    throw new UnimplementedError();
  }

  /// Pushes a backdrop filter operation onto the operation stack.
  ///
  /// The given filter is applied to the current contents of the scene prior to
  /// rasterizing the given objects.
  ///
  /// See [pop] for details about the operation stack.
  EngineLayer pushBackdropFilter(ImageFilter filter) {
    throw new UnimplementedError();
  }

  /// Pushes a shader mask operation onto the operation stack.
  ///
  /// The given shader is applied to the object's rasterization in the given
  /// rectangle using the given blend mode.
  ///
  /// See [pop] for details about the operation stack.
  EngineLayer pushShaderMask(Shader shader, Rect maskRect, BlendMode blendMode) {
    throw new UnimplementedError();
  }

  /// Pushes a physical layer operation for an arbitrary shape onto the
  /// operation stack.
  ///
  /// By default, the layer's content will not be clipped (clip = [Clip.none]).
  /// If clip equals [Clip.hardEdge], [Clip.antiAlias], or [Clip.antiAliasWithSaveLayer],
  /// then the content is clipped to the given shape defined by [path].
  ///
  /// If [elevation] is greater than 0.0, then a shadow is drawn around the layer.
  /// [shadowColor] defines the color of the shadow if present and [color] defines the
  /// color of the layer background.
  ///
  /// See [pop] for details about the operation stack, and [Clip] for different clip modes.
  EngineLayer pushPhysicalShape({
    Path path,
    double elevation,
    Color color,
    Color shadowColor,
    Clip clipBehavior = Clip.none,
  }) {
    return _pushSurface(PersistedPhysicalShape(
      null,
      path,
      elevation,
      color.value,
      shadowColor?.value ?? 0xFF000000,
      clipBehavior,
    ));
  }

  /// Add a retained engine layer subtree from previous frames.
  ///
  /// All the engine layers that are in the subtree of the retained layer will
  /// be automatically appended to the current engine layer tree.
  ///
  /// Therefore, when implementing a subclass of the [Layer] concept defined in
  /// the rendering layer of Flutter's framework, once this is called, there's
  /// no need to call [addToScene] for its children layers.
  void addRetained(EngineLayer retainedLayer) {
    PersistedContainerSurface retainedSurface = retainedLayer;

    // Request that the layer is retained only if it hasn't been recycled yet.
    if (retainedSurface.rootElement != null) {
      retainedSurface.reuseStrategy = PersistedSurfaceReuseStrategy.retain;
    }
    _adoptSurface(retainedSurface);
  }

  /// Ends the effect of the most recently pushed operation.
  ///
  /// Internally the scene builder maintains a stack of operations. Each of the
  /// operations in the stack applies to each of the objects added to the scene.
  /// Calling this function removes the most recently added operation from the
  /// stack.
  void pop() {
    assert(_surfaceStack.isNotEmpty);
    _surfaceStack.removeLast();
  }

  /// Adds an object to the scene that displays performance statistics.
  ///
  /// Useful during development to assess the performance of the application.
  /// The enabledOptions controls which statistics are displayed. The bounds
  /// controls where the statistics are displayed.
  ///
  /// enabledOptions is a bit field with the following bits defined:
  ///  - 0x01: displayRasterizerStatistics - show GPU thread frame time
  ///  - 0x02: visualizeRasterizerStatistics - graph GPU thread frame times
  ///  - 0x04: displayEngineStatistics - show UI thread frame time
  ///  - 0x08: visualizeEngineStatistics - graph UI thread frame times
  /// Set enabledOptions to 0x0F to enable all the currently defined features.
  ///
  /// The "UI thread" is the thread that includes all the execution of
  /// the main Dart isolate (the isolate that can call
  /// [Window.render]). The UI thread frame time is the total time
  /// spent executing the [Window.onBeginFrame] callback. The "GPU
  /// thread" is the thread (running on the CPU) that subsequently
  /// processes the [Scene] provided by the Dart code to turn it into
  /// GPU commands and send it to the GPU.
  ///
  /// See also the [PerformanceOverlayOption] enum in the rendering library.
  /// for more details.
  void addPerformanceOverlay(int enabledOptions, Rect bounds) {
    _addPerformanceOverlay(enabledOptions, bounds.left, bounds.right,
        bounds.top, bounds.bottom, null);
  }

  void _addPerformanceOverlay(int enabledOptions, double left, double right,
      double top, double bottom, Object webOnlyPaintedBy) {
    if (!_webOnlyDidWarnAboutPerformanceOverlay) {
      _webOnlyDidWarnAboutPerformanceOverlay = true;
      html.window.console
          .warn('The performance overlay isn\'t supported on the web');
    }
  }

  /// Adds a [Picture] to the scene.
  ///
  /// The picture is rasterized at the given offset.
  void addPicture(Offset offset, Picture picture,
      {bool isComplexHint = false,
      bool willChangeHint = false,
      }) {
    int hints = 0;
    if (isComplexHint) hints |= 1;
    if (willChangeHint) hints |= 2;
    _addPicture(offset.dx, offset.dy, picture, hints);
  }

  void _addPicture(double dx, double dy, Picture picture, int hints) {
    _addSurface(
        persistedPictureFactory(null, dx, dy, picture, hints));
  }

  /// Adds a backend texture to the scene.
  ///
  /// The texture is scaled to the given size and rasterized at the given
  /// offset.
  void addTexture(int textureId,
      {Offset offset = Offset.zero,
      double width = 0.0,
      double height = 0.0,
      bool freeze = false,
      }) {
    assert(offset != null, 'Offset argument was null');
    _addTexture(
        offset.dx, offset.dy, width, height, textureId, null);
  }

  void _addTexture(double dx, double dy, double width, double height,
      int textureId, Object webOnlyPaintedBy) {
    throw new UnimplementedError();
  }

  /// Adds a platform view (e.g an iOS UIView) to the scene.
  ///
  /// Only supported on iOS, this is currently a no-op on other platforms.
  ///
  /// On iOS this layer splits the current output surface into two surfaces, one for the scene nodes
  /// preceding the platform view, and one for the scene nodes following the platform view.
  ///
  /// ## Performance impact
  ///
  /// Adding an additional surface doubles the amount of graphics memory directly used by Flutter
  /// for output buffers. Quartz might allocated extra buffers for compositing the Flutter surfaces
  /// and the platform view.
  ///
  /// With a platform view in the scene, Quartz has to composite the two Flutter surfaces and the
  /// embedded UIView. In addition to that, on iOS versions greater than 9, the Flutter frames are
  /// synchronized with the UIView frames adding additional performance overhead.
  void addPlatformView(int viewId,
      {Offset offset = Offset.zero, double width = 0.0, double height = 0.0}) {
    assert(offset != null, 'Offset argument was null');
    _addPlatformView(offset.dx, offset.dy, width, height, viewId);
  }

  void _addPlatformView(
      double dx, double dy, double width, double height, int viewId) {
    throw new UnimplementedError();
  }

  /// (Fuchsia-only) Adds a scene rendered by another application to the scene
  /// for this application.
  void addChildScene(
      {Offset offset = Offset.zero,
      double width = 0.0,
      double height = 0.0,
      SceneHost sceneHost,
      bool hitTestable = true}) {
    _addChildScene(offset.dx, offset.dy, width, height, sceneHost, hitTestable);
  }

  void _addChildScene(double dx, double dy, double width, double height,
      SceneHost sceneHost, bool hitTestable) {
    throw new UnimplementedError();
  }

  /// Sets a threshold after which additional debugging information should be
  /// recorded.
  ///
  /// Currently this interface is difficult to use by end-developers. If you're
  /// interested in using this feature, please contact [flutter-dev](https://groups.google.com/forum/#!forum/flutter-dev).
  /// We'll hopefully be able to figure out how to make this feature more useful
  /// to you.
  void setRasterizerTracingThreshold(int frameInterval) {}

  /// Sets whether the raster cache should checkerboard cached entries. This is
  /// only useful for debugging purposes.
  ///
  /// The compositor can sometimes decide to cache certain portions of the
  /// widget hierarchy. Such portions typically don't change often from frame to
  /// frame and are expensive to render. This can speed up overall rendering.
  /// However, there is certain upfront cost to constructing these cache
  /// entries. And, if the cache entries are not used very often, this cost may
  /// not be worth the speedup in rendering of subsequent frames. If the
  /// developer wants to be certain that populating the raster cache is not
  /// causing stutters, this option can be set. Depending on the observations
  /// made, hints can be provided to the compositor that aid it in making better
  /// decisions about caching.
  ///
  /// Currently this interface is difficult to use by end-developers. If you're
  /// interested in using this feature, please contact [flutter-dev](https://groups.google.com/forum/#!forum/flutter-dev).
  void setCheckerboardRasterCacheImages(bool checkerboard) {}

  /// Sets whether the compositor should checkerboard layers that are rendered
  /// to offscreen bitmaps.
  ///
  /// This is only useful for debugging purposes.
  void setCheckerboardOffscreenLayers(bool checkerboard) {}

  /// The scene recorded in the last frame.
  ///
  /// This is a surface tree that holds onto the DOM elements that can be reused
  /// on the next frame.
  static PersistedScene _lastFrameScene;

  /// Returns the computed persisted scene graph recorded in the last frame.
  ///
  /// This is only available in debug mode. It returns `null` in profile and
  /// release modes.
  static PersistedScene get debugLastFrameScene {
    PersistedScene result;
    assert(() {
      result = _lastFrameScene;
      return true;
    }());
    return result;
  }

  /// Discards information about previously rendered frames, including DOM
  /// elements and cached canvases.
  ///
  /// After calling this function new canvases will be created for the
  /// subsequent scene. This is useful when tests need predictable canvas
  /// sizes. If the cache is not cleared, then canvases allocated in one test
  /// may be reused in another test.
  static void debugForgetFrameScene() {
    _lastFrameScene?.rootElement?.remove();
    _lastFrameScene = null;
    _clipCounter = 0;
    _recycledCanvases.clear();
  }

  static int _debugFrameNumber = 0;

  /// Finishes building the scene.
  ///
  /// Returns a [Scene] containing the objects that have been added to
  /// this scene builder. The [Scene] can then be displayed on the
  /// screen with [Window.render].
  ///
  /// After calling this function, the scene builder object is invalid and
  /// cannot be used further.
  Scene build() {
    assert(() {
      _debugFrameNumber++;
      return true;
    }());
    if (_lastFrameScene == null) {
      _persistedScene.build();
    } else {
      _persistedScene.update(_lastFrameScene);
    }
    if (_paintQueue.isNotEmpty) {
      if (_paintQueue.length > 1) {
        // Sort paint requests in decreasing canvas size order. Paint requests
        // attempt to reuse canvases. For efficiency we want the biggest pictures
        // to find canvases before the smaller ones claim them.
        _paintQueue.sort((_PaintRequest a, _PaintRequest b) {
          final double aSize = a.canvasSize.height * a.canvasSize.width;
          final double bSize = b.canvasSize.height * b.canvasSize.width;
          return bSize.compareTo(aSize);
        });
      }

      for (_PaintRequest request in _paintQueue) {
        request.paintCallback();
      }
      _paintQueue = <_PaintRequest>[];
    }

    // Reset reuse strategy back to matching. Retain requests are one-time. In
    // order to retain the same layer again the framework must call addRetained
    // again. If addRetained is not called the engine will recycle the surfaces.
    // Calling addRetained on a layer whose surface has been recycled will
    // rebuild the surfaces as if it was a brand new layer.
    if (_retainedSurfaces.isNotEmpty) {
      for (int i = 0; i < _retainedSurfaces.length; i++) {
        _retainedSurfaces[i].reuseStrategy =
            PersistedSurfaceReuseStrategy.match;
      }
      _retainedSurfaces = <PersistedSurface>[];
    }
    if (_debugExplainSurfaceStats) {
      _debugPrintSurfaceStats(_persistedScene, _debugFrameNumber);
      _debugRepaintSurfaceStatsOverlay(_persistedScene);
    }
    assert(() {
      final validationErrors = <String>[];
      _persistedScene.debugValidate(validationErrors);
      if (validationErrors.isNotEmpty) {
        print('ENGINE LAYER TREE INCONSISTENT:\n'
            '${validationErrors.map((e) => '  - $e\n').join()}');
      }
      return true;
    }());
    _lastFrameScene = _persistedScene;
    if (_debugExplainSurfaceStats) {
      _surfaceStats = <PersistedSurface, _DebugSurfaceStats>{};
    }
    return new Scene._(_persistedScene.rootElement);
  }
}

/// Compositor information collected for one frame useful for assessing the
/// efficiency of constructing the frame.
///
/// This information is only available in debug mode.
///
/// For stats pertaining to a single surface the numeric counter fields are
/// typically either 0 or 1. For aggregated stats, the numbers can be >1.
class _DebugSurfaceStats {
  _DebugSurfaceStats(this.surface);

  /// The surface these stats are for, or `null` if these are aggregated stats.
  final PersistedSurface surface;

  /// How many times a surface was retained from a previously rendered frame.
  int retainSurfaceCount = 0;

  /// How many times a surface reused an HTML element from a previously rendered
  /// surface.
  int reuseElementCount = 0;

  /// If a surface is a [PersistedPicture], how many times it painted.
  int paintCount = 0;

  /// If a surface is a [PersistedPicture], how many pixels it painted.
  int paintPixelCount = 0;

  /// If a surface is a [PersistedPicture], how many times it reused a
  /// previously allocated `<canvas>` element when it painted.
  int reuseCanvasCount = 0;

  /// If a surface is a [PersistedPicture], how many times it allocated a new
  /// bitmap canvas.
  int allocateBitmapCanvasCount = 0;

  /// If a surface is a [PersistedPicture], how many pixels it allocated for
  /// the bitmap.
  ///
  /// For aggregated stats, this is the total sum of all pixels across all
  /// canvases.
  int allocatedBitmapSizeInPixels = 0;

  /// The number of HTML DOM nodes a surface allocated.
  ///
  /// For aggregated stats, this is the total sum of all DOM nodes across all
  /// surfaces.
  int allocatedDomNodeCount = 0;

  /// Adds all counters of [oneSurfaceStats] into this object.
  void aggregate(_DebugSurfaceStats oneSurfaceStats) {
    retainSurfaceCount += oneSurfaceStats.retainSurfaceCount;
    reuseElementCount += oneSurfaceStats.reuseElementCount;
    paintCount += oneSurfaceStats.paintCount;
    paintPixelCount += oneSurfaceStats.paintPixelCount;
    reuseCanvasCount += oneSurfaceStats.reuseCanvasCount;
    allocateBitmapCanvasCount += oneSurfaceStats.allocateBitmapCanvasCount;
    allocatedBitmapSizeInPixels += oneSurfaceStats.allocatedBitmapSizeInPixels;
    allocatedDomNodeCount += oneSurfaceStats.allocatedDomNodeCount;
  }
}

/// Maps every surface currently active on the screen to debug statistics.
Map<PersistedSurface, _DebugSurfaceStats> _surfaceStats =
    <PersistedSurface, _DebugSurfaceStats>{};

List<Map<PersistedSurface, _DebugSurfaceStats>> _surfaceStatsTimeline =
    <Map<PersistedSurface, _DebugSurfaceStats>>[];

/// Returns debug statistics for the given [surface].
_DebugSurfaceStats _surfaceStatsFor(PersistedSurface surface) {
  if (!_debugExplainSurfaceStats) {
    throw new Exception(
        '_surfaceStatsFor is only available when _debugExplainSurfaceStats is set to true.');
  }
  return _surfaceStats.putIfAbsent(surface, () => _DebugSurfaceStats(surface));
}

html.CanvasRenderingContext2D _debugSurfaceStatsOverlayCtx;

void _debugRepaintSurfaceStatsOverlay(PersistedScene scene) {
  final int overlayWidth = html.window.innerWidth;
  final rowHeight = 30;
  final rowCount = 4;
  final int overlayHeight = rowHeight * rowCount;
  final int strokeWidth = 2;

  _surfaceStatsTimeline.add(_surfaceStats);

  while (_surfaceStatsTimeline.length > (overlayWidth / strokeWidth)) {
    _surfaceStatsTimeline.removeAt(0);
  }

  if (_debugSurfaceStatsOverlayCtx == null) {
    final html.CanvasElement _debugSurfaceStatsOverlay = html.CanvasElement(
      width: overlayWidth,
      height: overlayHeight,
    );
    _debugSurfaceStatsOverlay.style
      ..position = 'fixed'
      ..left = '0'
      ..top = '0'
      ..zIndex = '1000'
      ..opacity = '0.8';
    _debugSurfaceStatsOverlayCtx = _debugSurfaceStatsOverlay.context2D;
    html.document.body.append(_debugSurfaceStatsOverlay);
  }

  _debugSurfaceStatsOverlayCtx
    ..fillStyle = 'black'
    ..beginPath()
    ..rect(0, 0, overlayWidth, overlayHeight)
    ..fill();

  final double physicalScreenWidth =
      html.window.innerWidth * html.window.devicePixelRatio;
  final double physicalScreenHeight =
      html.window.innerHeight * html.window.devicePixelRatio;
  final double physicsScreenPixelCount =
      physicalScreenWidth * physicalScreenHeight;

  final int totalDomNodeCount = scene.rootElement.querySelectorAll('*').length;

  for (int i = 0; i < _surfaceStatsTimeline.length; i++) {
    final _DebugSurfaceStats totals = _DebugSurfaceStats(null);
    int pixelCount = 0;
    _surfaceStatsTimeline[i]
        .values
        .forEach((_DebugSurfaceStats oneSurfaceStats) {
      totals.aggregate(oneSurfaceStats);
      if (oneSurfaceStats.surface is PersistedPicture) {
        final PersistedPicture picture = oneSurfaceStats.surface;
        pixelCount += picture.bitmapPixelCount;
      }
    });

    final double repaintRate = totals.paintPixelCount / pixelCount;
    final double domAllocationRate =
        totals.allocatedDomNodeCount / totalDomNodeCount;
    final double bitmapAllocationRate =
        totals.allocatedBitmapSizeInPixels / physicsScreenPixelCount;
    final double surfaceRetainRate =
        totals.retainSurfaceCount / _surfaceStatsTimeline[i].length;

    // Repaints
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = strokeWidth
      ..strokeStyle = 'red'
      ..beginPath()
      ..moveTo(strokeWidth * i, rowHeight)
      ..lineTo(strokeWidth * i, rowHeight * (1 - repaintRate))
      ..stroke();

    // DOM allocations
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = strokeWidth
      ..strokeStyle = 'red'
      ..beginPath()
      ..moveTo(strokeWidth * i, 2 * rowHeight)
      ..lineTo(strokeWidth * i, rowHeight * (2 - domAllocationRate))
      ..stroke();

    // Bitmap allocations
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = strokeWidth
      ..strokeStyle = 'red'
      ..beginPath()
      ..moveTo(strokeWidth * i, 3 * rowHeight)
      ..lineTo(strokeWidth * i, rowHeight * (3 - bitmapAllocationRate))
      ..stroke();

    // Surface retentions
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = strokeWidth
      ..strokeStyle = 'green'
      ..beginPath()
      ..moveTo(strokeWidth * i, 4 * rowHeight)
      ..lineTo(strokeWidth * i, rowHeight * (4 - surfaceRetainRate))
      ..stroke();
  }

  _debugSurfaceStatsOverlayCtx
    ..font = 'normal normal 14px sans-serif'
    ..fillStyle = 'white'
    ..fillText('Repaint rate', 5, rowHeight - 5)
    ..fillText('DOM alloc rate', 5, 2 * rowHeight - 5)
    ..fillText('Bitmap alloc rate', 5, 3 * rowHeight - 5)
    ..fillText('Retain rate', 5, 4 * rowHeight - 5);

  for (int i = 1; i <= rowCount; i++) {
    _debugSurfaceStatsOverlayCtx
      ..lineWidth = 1
      ..strokeStyle = 'blue'
      ..beginPath()
      ..moveTo(0, overlayHeight - rowHeight * i)
      ..lineTo(overlayWidth, overlayHeight - rowHeight * i)
      ..stroke();
  }
}

/// Prints debug statistics for the current frame to the console.
void _debugPrintSurfaceStats(PersistedScene scene, int frameNumber) {
  int pictureCount = 0;
  int paintCount = 0;

  int bitmapCanvasCount = 0;
  int bitmapReuseCount = 0;
  int bitmapAllocationCount = 0;
  int bitmapPaintCount = 0;
  int bitmapPixelsAllocated = 0;

  int domCanvasCount = 0;
  int domPaintCount = 0;

  int surfaceRetainCount = 0;
  int elementReuseCount = 0;

  int totalAllocatedDomNodeCount = 0;

  void countReusesRecursively(PersistedSurface surface) {
    _DebugSurfaceStats stats = _surfaceStatsFor(surface);
    assert(stats != null);

    surfaceRetainCount += stats.retainSurfaceCount;
    elementReuseCount += stats.reuseElementCount;
    totalAllocatedDomNodeCount += stats.allocatedDomNodeCount;

    if (surface is PersistedStandardPicture) {
      pictureCount += 1;
      paintCount += stats.paintCount;

      if (surface._canvas is engine.DomCanvas) {
        domCanvasCount++;
        domPaintCount += stats.paintCount;
      }

      if (surface._canvas is engine.BitmapCanvas) {
        bitmapCanvasCount++;
        bitmapPaintCount += stats.paintCount;
      }

      bitmapReuseCount += stats.reuseCanvasCount;
      bitmapAllocationCount += stats.allocateBitmapCanvasCount;
      bitmapPixelsAllocated += stats.allocatedBitmapSizeInPixels;
    }

    surface.visitChildren(countReusesRecursively);
  }

  scene.visitChildren(countReusesRecursively);

  final StringBuffer buf = StringBuffer();
  buf
    ..writeln(
        '---------------------- FRAME #${frameNumber} -------------------------')
    ..writeln('Surfaces retained: $surfaceRetainCount')
    ..writeln('Elements reused: $elementReuseCount')
    ..writeln('Elements allocated: $totalAllocatedDomNodeCount')
    ..writeln('Pictures: $pictureCount')
    ..writeln('  Painted: $paintCount')
    ..writeln('  Skipped painting: ${pictureCount - paintCount}')
    ..writeln('DOM canvases:')
    ..writeln('  Painted: $domPaintCount')
    ..writeln('  Skipped painting: ${domCanvasCount - domPaintCount}')
    ..writeln('Bitmap canvases: ${bitmapCanvasCount}')
    ..writeln('  Painted: $bitmapPaintCount')
    ..writeln('  Skipped painting: ${bitmapCanvasCount - bitmapPaintCount}')
    ..writeln('  Reused: $bitmapReuseCount')
    ..writeln('  Allocated: $bitmapAllocationCount')
    ..writeln('  Allocated pixels: $bitmapPixelsAllocated')
    ..writeln('  Available for reuse: ${_recycledCanvases.length}');

  // A microtask will fire after the DOM is flushed, letting us probe into
  // actual <canvas> tags.
  scheduleMicrotask(() {
    final canvasElements = html.document.querySelectorAll('canvas');
    final StringBuffer canvasInfo = StringBuffer();
    final int pixelCount = canvasElements
        .cast<html.CanvasElement>()
        .map<int>((html.CanvasElement e) {
      final int pixels = e.width * e.height;
      canvasInfo.writeln('    - ${e.width} x ${e.height} = ${pixels} pixels');
      return pixels;
    }).fold(0, (int total, int pixels) => total + pixels);
    final double physicalScreenWidth =
        html.window.innerWidth * html.window.devicePixelRatio;
    final double physicalScreenHeight =
        html.window.innerHeight * html.window.devicePixelRatio;
    final double physicsScreenPixelCount =
        physicalScreenWidth * physicalScreenHeight;
    final double screenPixelRatio = pixelCount / physicsScreenPixelCount;
    final String screenDescription =
        '1 screen is ${physicalScreenWidth} x ${physicalScreenHeight} = ${physicsScreenPixelCount} pixels';
    final String canvasPixelDescription =
        '${pixelCount} (${screenPixelRatio.toStringAsFixed(2)} x screens';
    buf
      ..writeln('  Elements: ${canvasElements.length}')
      ..writeln(canvasInfo)
      ..writeln('  Pixels: $canvasPixelDescription; $screenDescription)')
      ..writeln('-----------------------------------------------------------');
    bool screenPixelRatioTooHigh =
        screenPixelRatio > _kScreenPixelRatioWarningThreshold;
    if (screenPixelRatioTooHigh) {
      print(
          'WARNING: pixel/screen ratio too high (${screenPixelRatio.toStringAsFixed(2)}x)');
    }
    print(buf);
  });
}

/// A handle for the framework to hold and retain an engine layer across frames.
class EngineLayer {}

/// (Fuchsia-only) Hosts content provided by another application.
class SceneHost {
  /// Creates a host for a child scene.
  ///
  /// The export token is bound to a scene graph node which acts as a container
  /// for the child's content.  The creator of the scene host is responsible for
  /// sending the corresponding import token (the other endpoint of the event
  /// pair) to the child.
  ///
  /// The export token is a dart:zircon Handle, but that type isn't
  /// available here. This is called by ChildViewConnection in
  /// //topaz/public/lib/ui/flutter/.
  ///
  /// The scene host takes ownership of the provided export token handle.
  SceneHost(dynamic exportTokenHandle);

  /// Releases the resources associated with the child scene host.
  ///
  /// After calling this function, the child scene host cannot be used further.
  void dispose() {}

  /// Set properties on the linked scene.  These properties include its bounds,
  /// as well as whether it can be the target of focus events or not.
  void setProperties(
    double width,
    double height,
    double insetTop,
    double insetRight,
    double insetBottom,
    double insetLeft,
    bool focusable) {
      throw UnimplementedError();
    }
}

/// Signature of a function that receives a [PersistedSurface].
///
/// This is used to traverse surfaces using [PersistedSurface.visitChildren].
typedef PersistedSurfaceVisitor = void Function(PersistedSurface);

/// Controls the algorithm used to reuse a previously rendered surface.
enum PersistedSurfaceReuseStrategy {
  /// This strategy matches a surface to a previously rendered surface using
  /// its type and descendants.
  match,

  /// This strategy reuses the surface as is.
  ///
  /// This strategy relies on Flutter's retained-mode layer system (see
  /// [EngineLayer]).
  retain,
}

/// A node in the tree built by [SceneBuilder] that contains information used to
/// compute the fewest amount of mutations necessary to update the browser DOM.
abstract class PersistedSurface implements EngineLayer {
  /// Creates a persisted surface.
  ///
  /// [paintedBy] points to the object that painted this surface.
  PersistedSurface(this.paintedBy) : assert(paintedBy != null);

  /// The strategy that should be used when attempting to reuse the resources
  /// owned by this surface.
  PersistedSurfaceReuseStrategy reuseStrategy =
      PersistedSurfaceReuseStrategy.match;

  /// The root element that renders this surface to the DOM.
  ///
  /// This element can be reused across frames. See also, [childContainer],
  /// which is the element used to manage child nodes.
  html.Element rootElement;

  /// The element that contains child surface elements.
  ///
  /// By default this is the same as the [rootElement]. However, specialized
  /// surface implementations may choose to override this and provide a
  /// different element for nesting children.
  html.Element get childContainer => rootElement;

  /// This surface's immediate parent.
  PersistedContainerSurface parent;

  /// The render object that painted this surface.
  ///
  /// Used to find a surface in the previous frame whose [element] can be
  /// reused.
  final Object paintedBy;

  /// Render objects that painted something in the subtree rooted at this node.
  ///
  /// Used to find a surface in the previous frame whose [element] can be
  /// reused.
  // TODO(yjbanov): consider benchmarking and potentially using a list that
  //                compiles to JSArray. We may never have duplicates here by
  //                construction. The only other use-case for Set is to perform
  //                an order-agnostic comparison.
  Set<Object> _descendants;

  /// Visits immediate children.
  ///
  /// Does not recurse.
  void visitChildren(PersistedSurfaceVisitor visitor);

  /// Creates a new element and sets the necessary HTML and CSS attributes.
  ///
  /// This is called when we failed to locate an existing DOM element to reuse,
  /// such as on the very first frame.
  @protected
  @mustCallSuper
  void build() {
    assert(rootElement == null);
    assert(reuseStrategy != PersistedSurfaceReuseStrategy.retain);
    recomputeTransformAndClip();
    rootElement = createElement();
    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this).allocatedDomNodeCount++;
    }
    apply();
  }

  /// Instructs this surface to adopt HTML DOM elements of another surface.
  ///
  /// This is done for efficiency. Instead of creating new DOM elements on every
  /// frame, we reuse old ones as much as possible. This method should only be
  /// called when [isTotalMatchFor] returns true for the [oldSurface]. Otherwise
  /// adopting the [oldSurface]'s elements could lead to correctness issues.
  @protected
  @mustCallSuper
  void adoptElements(covariant PersistedSurface oldSurface) {
    assert(oldSurface.rootElement != null);
    rootElement = oldSurface.rootElement;
    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this).reuseElementCount++;
    }
  }

  /// Updates the attributes of this surface's element.
  ///
  /// Attempts to reuse [oldSurface]'s DOM element, if possible. Otherwise,
  /// creates a new element by calling [build].
  @protected
  @mustCallSuper
  void update(covariant PersistedSurface oldSurface) {
    assert(oldSurface != null);
    assert(!identical(oldSurface, this));
    assert(reuseStrategy != PersistedSurfaceReuseStrategy.retain);
    assert(oldSurface.reuseStrategy != PersistedSurfaceReuseStrategy.retain);
    assert(isTotalMatchFor(oldSurface) || isFuzzyMatchFor(oldSurface));

    recomputeTransformAndClip();
    adoptElements(oldSurface);

    // We took ownership of the old element.
    oldSurface.rootElement = null;
    assert(rootElement != null);
  }

  /// Reuses a [PersistedSurface] rendered in the previous frame.
  ///
  /// This is different from [update], which reuses another surface's elements,
  /// i.e. it was not requested to be retained by the framework.
  ///
  /// This is also different from [build], which constructs a brand new surface
  /// sub-tree.
  @protected
  @mustCallSuper
  void retain() {
    assert(rootElement != null);
    recomputeTransformAndClip();
    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this).retainSurfaceCount++;
    }
  }

  /// Removes the [element] of this surface from the tree.
  ///
  /// This method may be overridden by concrete implementations, for example, to
  /// recycle the resources owned by this surface.
  @protected
  @mustCallSuper
  void recycle() {
    assert(reuseStrategy != PersistedSurfaceReuseStrategy.retain);
    rootElement.remove();
    rootElement = null;
  }

  @protected
  @mustCallSuper
  void debugValidate(List<String> validationErrors) {
    if (rootElement == null) {
      validationErrors.add('$runtimeType has null element.');
    }
    if (reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
      validationErrors.add('$runtimeType is still scheduled to be retained at '
          'the end of the frame.');
    }
  }

  /// A total match between two surfaces is when they are of the same type, were
  /// painted by the same render object, contain the same set of descendants,
  /// and do not have pending retain requests.
  ///
  /// If this method returns true it is safe to call [update] and pass `other`
  /// to it.
  bool isTotalMatchFor(PersistedSurface other) {
    assert(other != null);
    if (reuseStrategy == PersistedSurfaceReuseStrategy.retain ||
        other.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
      // If any of the nodes are being retained, do not match it. It is reused
      // directly.
      return false;
    }
    return other.runtimeType == runtimeType &&
        identical(other.paintedBy, paintedBy) &&
        _hasExactDescendants(other);
  }

  /// Whether `other` surface matches this surface by type and neither have
  /// pending request to be retained.
  ///
  /// If this method returns true it is safe to call [update] and pass `other`
  /// to it.
  bool isFuzzyMatchFor(PersistedSurface other) {
    assert(other != null);
    if (reuseStrategy == PersistedSurfaceReuseStrategy.retain ||
        other.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
      // If any of the nodes are being retained, do not match it. It is reused
      // directly.
      return false;
    }
    return other.runtimeType == runtimeType;
  }

  bool _hasExactDescendants(PersistedSurface other) {
    if ((_descendants == null || _descendants.isEmpty) &&
        (other._descendants == null || other._descendants.isEmpty)) {
      return true;
    } else if (_descendants == null || other._descendants == null) {
      return false;
    }

    if (_descendants.length != other._descendants.length) {
      return false;
    }

    return _descendants.containsAll(other._descendants);
  }

  /// Creates a DOM element for this surface.
  html.Element createElement();

  /// Creates a DOM element for this surface preconfigured with common
  /// attributes, such as absolute positioning and debug information.
  html.Element defaultCreateElement(String tagName) {
    final element = html.Element.tag(tagName);
    element.style.position = 'absolute';
    if (engine.assertionsEnabled) {
      element.setAttribute(
        'created-by',
        '${this.paintedBy.runtimeType}',
      );
    }
    return element;
  }

  /// Sets the HTML and CSS properties appropriate for this surface's
  /// implementation.
  ///
  /// For example, [PersistedTransform] sets the "transform" CSS attribute.
  void apply();

  /// The effective transform at this surface level.
  ///
  /// This value is computed by concatenating transforms of all ancestor
  /// transforms as well as this layer's transform (if any).
  ///
  /// The value is update by [recomputeTransformAndClip].
  engine.Matrix4 get transform => _transform;
  engine.Matrix4 _transform;

  /// The intersection at this surface level.
  ///
  /// This value is the intersection of clips in the ancestor chain, including
  /// the clip added by this layer (if any).
  ///
  /// The value is update by [recomputeTransformAndClip].
  Rect get globalClip => _globalClip;
  Rect _globalClip;

  /// Recomputes [transform] and [globalClip] fields.
  ///
  /// The default implementation inherits the values from the parent. Concrete
  /// surface implementations may override this with their custom transform and
  /// clip behaviors.
  ///
  /// This method is called by the [update] method. If a surface overrides this
  /// method it must make sure that all the parameters necessary for the
  /// computation are updated prior to calling `super.update`.
  @protected
  void recomputeTransformAndClip() {
    _transform = parent._transform;
    _globalClip = parent._globalClip;
  }

  /// Prints this surface into a [buffer] in a human-readable format.
  void debugPrint(StringBuffer buffer, int indent) {
    if (rootElement != null) {
      buffer.write('${'  ' * indent}<${rootElement.tagName.toLowerCase()} ');
    } else {
      buffer.write('${'  ' * indent}<$runtimeType recycled ');
    }
    debugPrintAttributes(buffer);
    buffer.writeln('>');
    debugPrintChildren(buffer, indent);
    if (rootElement != null) {
      buffer.writeln('${'  ' * indent}</${rootElement.tagName.toLowerCase()}>');
    } else {
      buffer.writeln('${'  ' * indent}</$runtimeType>');
    }
  }

  @protected
  @mustCallSuper
  void debugPrintAttributes(StringBuffer buffer) {
    if (rootElement != null) {
      buffer.write('@${rootElement.hashCode} ');
    }
    buffer.write('painted-by="${paintedBy.runtimeType}"');
  }

  @protected
  @mustCallSuper
  void debugPrintChildren(StringBuffer buffer, int indent) {}

  @override
  String toString() {
    if (engine.assertionsEnabled) {
      final log = StringBuffer();
      debugPrint(log, 0);
      return log.toString();
    } else {
      return super.toString();
    }
  }
}

/// A surface that doesn't have child surfaces.
abstract class PersistedLeafSurface extends PersistedSurface {
  PersistedLeafSurface(Object paintedBy) : super(paintedBy);

  @override
  void visitChildren(PersistedSurfaceVisitor visitor) {
    // Does not have children.
  }
}

/// A surface that has a flat list of child surfaces.
abstract class PersistedContainerSurface extends PersistedSurface {
  PersistedContainerSurface(Object paintedBy) : super(paintedBy);

  final List<PersistedSurface> _children = <PersistedSurface>[];

  @override
  void visitChildren(PersistedSurfaceVisitor visitor) {
    _children.forEach(visitor);
  }

  void appendChild(PersistedSurface child) {
    _children.add(child);
    child.parent = this;

    // Add the child to the list of descendants in all ancestors within the
    // current render object.
    //
    // We only reuse a DOM node when it is painted by the same RenderObject,
    // therefore we need to mark this surface and ancestors within the current
    // render object as having this child as a descendant. This allows us to
    // detect when children move within their list of siblings and reuse their
    // elements.
    if (!identical(child.paintedBy, paintedBy)) {
      PersistedSurface container = this;
      while (container != null && identical(container.paintedBy, paintedBy)) {
        container._descendants ??= Set<Object>();
        container._descendants.add(child.paintedBy);
        container = container.parent;
      }
    }
  }

  @override
  void build() {
    super.build();
    // Memoize length for efficiency.
    final len = _children.length;
    // Memoize container element for efficiency. [childContainer] is polymorphic
    final html.Element containerElement = childContainer;
    for (int i = 0; i < len; i++) {
      final PersistedSurface child = _children[i];
      if (child.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
        assert(child.rootElement != null);
        _retainSurface(child);
      } else {
        child.build();
      }
      containerElement.append(child.rootElement);
    }
  }

  void _updateChild(PersistedSurface newChild, PersistedSurface oldChild) {
    assert(newChild.rootElement == null);
    assert(oldChild.isTotalMatchFor(newChild) ||
        oldChild.isFuzzyMatchFor(newChild));
    final html.Element oldElement = oldChild.rootElement;
    assert(oldElement != null);
    newChild.update(oldChild);
    // When the new surface reuses an existing element it takes ownership of it
    // so we null it out in the old surface. This prevents the element from
    // being reused more than once, which would be a serious bug.
    assert(oldChild.rootElement == null);
    assert(identical(newChild.rootElement, oldElement));
  }

  @override
  void update(PersistedContainerSurface oldContainer) {
    assert(isTotalMatchFor(oldContainer) || isFuzzyMatchFor(oldContainer));
    super.update(oldContainer);

    // A simple algorithms that attempts to reuse DOM elements from the previous
    // frame:
    //
    // - Scans both the old list and the new list in reverse, updating matching
    //   child surfaces. The reason for iterating in reverse is so that we can
    //   move the child in a single call to `insertBefore`. Otherwise, we'd have
    //   to do a more complicated dance of finding the next sibling and special
    //   casing `append`.
    // - If non-match is found, performs a search (also in reverse) to locate a
    //   reusable element, then moves it towards the back.
    // - If no reusable element is found, creates a new one.

    int bottomInNew = _children.length - 1;
    int bottomInOld = oldContainer._children.length - 1;

    // Memoize container element for efficiency. [childContainer] is polymorphic
    final html.Element containerElement = childContainer;

    PersistedSurface nextSibling;

    // Inserts the DOM node of the child before the DOM node of the next sibling
    // if it has moved as a result of the update. Does nothing if the new child
    // is already in the right location in the DOM tree.
    void insertDomNodeIfMoved(PersistedSurface newChild) {
      assert(newChild.rootElement != null);
      assert(newChild.parent == this);
      final bool reparented = newChild.rootElement.parent != containerElement;
      // Do not check for sibling if reparented. It's obvious that we moved.
      final bool moved = reparented ||
          newChild.rootElement.nextElementSibling != nextSibling?.rootElement;
      if (moved) {
        if (nextSibling == null) {
          // We're at the end of the list.
          containerElement.append(newChild.rootElement);
        } else {
          // We're in the middle of the list.
          containerElement.insertBefore(
              newChild.rootElement, nextSibling.rootElement);
        }
      }
    }

    while (bottomInNew >= 0 && bottomInOld >= 0) {
      final PersistedSurface newChild = _children[bottomInNew];
      if (newChild.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
        insertDomNodeIfMoved(newChild);
        _retainSurface(newChild);
      } else {
        final PersistedSurface oldChild = oldContainer._children[bottomInOld];
        bool onlyChildren =
            _children.length == 1 && oldContainer._children.length == 1;
        if (onlyChildren && oldChild.isFuzzyMatchFor(newChild) ||
            oldChild.isTotalMatchFor(newChild)) {
          _updateChild(newChild, oldChild);
          bottomInOld--;
        } else {
          // Scan back for a matching old child, if any.
          int searchPointer = bottomInOld - 1;
          PersistedSurface match;

          // Searching by scanning the array backwards may seem inefficient, but
          // in practice we'll have single-digit child lists. It is better to scan
          // and not perform any allocations than utilize fancier data structures
          // (e.g. maps).
          while (searchPointer >= 0) {
            final candidate = oldContainer._children[searchPointer];
            final isNotYetReused = candidate.rootElement != null;
            if (isNotYetReused && candidate.isTotalMatchFor(newChild)) {
              match = candidate;
              break;
            }
            searchPointer--;
          }

          // If we found a match, reuse the element. Otherwise, create a new one.
          if (match != null) {
            _updateChild(newChild, match);
          } else {
            newChild.build();
          }

          insertDomNodeIfMoved(newChild);
        }
      }
      assert(newChild.rootElement != null);
      bottomInNew--;
      nextSibling = newChild;
    }

    while (bottomInNew >= 0) {
      // We scanned the old container and attempted to reuse as much as possible
      // but there are still elements in the new list that need to be updated.
      // Since there are no more old elements to reuse, we build new ones.
      assert(bottomInOld == -1);
      final newChild = _children[bottomInNew];

      if (newChild.reuseStrategy == PersistedSurfaceReuseStrategy.retain) {
        _retainSurface(newChild);
      } else {
        newChild.build();
      }

      insertDomNodeIfMoved(newChild);

      bottomInNew--;
      assert(newChild.rootElement != null);
      nextSibling = newChild;
    }

    // Remove elements that were not reused this frame.
    final len = oldContainer._children.length;
    for (int i = 0; i < len; i++) {
      PersistedSurface oldChild = oldContainer._children[i];

      // Only recycle nodes that still have DOM nodes and they have not been
      // retained.
      if (oldChild.rootElement != null &&
          oldChild.reuseStrategy != PersistedSurfaceReuseStrategy.retain) {
        oldChild.recycle();
      }
    }

    // At the end of this all children should have an element each, and it
    // should be attached to this container's element.
    assert(() {
      for (int i = 0; i < oldContainer._children.length; i++) {
        if (oldContainer._children[i].reuseStrategy !=
            PersistedSurfaceReuseStrategy.retain) {
          assert(oldContainer._children[i].rootElement == null);
          assert(oldContainer._children[i].childContainer == null);
        }
      }
      for (int i = 0; i < _children.length; i++) {
        assert(_children[i].rootElement != null);
        assert(_children[i].rootElement.parent == containerElement);
      }
      return true;
    }());
  }

  @override
  void retain() {
    super.retain();
    final int len = _children.length;
    for (int i = 0; i < len; i++) {
      _children[i].retain();
    }
  }

  @override
  void recycle() {
    for (int i = 0; i < _children.length; i++) {
      final PersistedSurface child = _children[i];
      if (child.reuseStrategy != PersistedSurfaceReuseStrategy.retain) {
        child.recycle();
      }
    }
    super.recycle();
  }

  @protected
  @mustCallSuper
  void debugValidate(List<String> validationErrors) {
    super.debugValidate(validationErrors);
    for (int i = 0; i < _children.length; i++) {
      _children[i].debugValidate(validationErrors);
    }
  }

  @override
  void debugPrintChildren(StringBuffer buffer, int indent) {
    super.debugPrintChildren(buffer, indent);
    for (int i = 0; i < _children.length; i++) {
      _children[i].debugPrint(buffer, indent + 1);
    }
  }
}

/// A surface that creates a DOM element for whole app.
class PersistedScene extends PersistedContainerSurface {
  PersistedScene() : super(const Object()) {
    _transform = engine.Matrix4.identity();
  }

  @override
  bool isTotalMatchFor(PersistedSurface other) {
    // The scene is a special-case kind of surface in that it is the only root
    // layer in the tree. Therefore it can always be updated from a previous
    // scene. There's no ambiguity about whether you can accidentally pick a
    // false match.
    assert(other is PersistedScene);
    return true;
  }

  @override
  void recomputeTransformAndClip() {
    // The scene clip is the size of the entire window.
    // TODO(yjbanov): in the add2app scenario where we might be hosted inside
    //                a custom element, this will be different. We will need to
    //                update this code when we add add2app support.
    final double screenWidth = html.window.innerWidth.toDouble();
    final double screenHeight = html.window.innerHeight.toDouble();
    _globalClip = Rect.fromLTRB(0, 0, screenWidth, screenHeight);
  }

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-scene');
  }

  @override
  void apply() {}
}

/// A surface that transforms its children using CSS transform.
class PersistedTransform extends PersistedContainerSurface {
  PersistedTransform(Object paintedBy, this.matrix4) : super(paintedBy);

  final Float64List matrix4;

  @override
  void recomputeTransformAndClip() {
    _transform =
        parent._transform.multiplied(engine.Matrix4.fromFloat64List(matrix4));
    _globalClip = parent._globalClip;
  }

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-transform')
      ..style.transformOrigin = '0 0 0';
  }

  @override
  void apply() {
    rootElement.style.transform = engine.float64ListToCssTransform(matrix4);
  }

  @override
  void update(PersistedTransform oldSurface) {
    super.update(oldSurface);

    if (identical(oldSurface.matrix4, matrix4)) {
      return;
    }

    bool matrixChanged = false;
    for (int i = 0; i < matrix4.length; i++) {
      if (matrix4[i] != oldSurface.matrix4[i]) {
        matrixChanged = true;
        break;
      }
    }

    if (matrixChanged) {
      apply();
    }
  }
}

/// A surface that translates its children using CSS transform and translate.
class PersistedOffset extends PersistedContainerSurface {
  PersistedOffset(Object paintedBy, this.dx, this.dy) : super(paintedBy);

  /// Horizontal displacement.
  final double dx;

  /// Vertical displacement.
  final double dy;

  @override
  void recomputeTransformAndClip() {
    _transform = parent._transform;
    if (dx != 0.0 || dy != 0.0) {
      _transform = _transform.clone();
      _transform.translate(dx, dy);
    }
    _globalClip = parent._globalClip;
  }

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-offset')..style.transformOrigin = '0 0 0';
  }

  @override
  void apply() {
    rootElement.style.transform = 'translate(${dx}px, ${dy}px)';
  }

  @override
  void update(PersistedOffset oldSurface) {
    super.update(oldSurface);

    if (oldSurface.dx != dx || oldSurface.dy != dy) {
      apply();
    }
  }
}

/// Mixin used by surfaces that clip their contents using an overflowing DOM
/// element.
mixin _DomClip on PersistedContainerSurface {
  /// The dedicated child container element that's separate from the
  /// [rootElement] is used to compensate for the coordinate system shift
  /// introduced by the [rootElement] translation.
  @override
  html.Element get childContainer => _childContainer;
  html.Element _childContainer;

  @override
  void adoptElements(_DomClip oldSurface) {
    super.adoptElements(oldSurface);
    _childContainer = oldSurface._childContainer;
    oldSurface._childContainer = null;
  }

  @override
  html.Element createElement() {
    final html.Element element = defaultCreateElement('flt-clip');
    if (!debugShowClipLayers) {
      // Hide overflow in production mode. When debugging we want to see the
      // clipped picture in full.
      element.style.overflow = 'hidden';
    } else {
      // Display the outline of the clipping region. When debugShowClipLayers is
      // `true` we don't hide clip overflow (see above). This outline helps
      // visualizing clip areas.
      element.style.boxShadow = 'inset 0 0 10px green';
    }
    _childContainer = html.Element.tag('flt-clip-interior');
    if (_debugExplainSurfaceStats) {
      // This creates an additional interior element. Count it too.
      _surfaceStatsFor(this).allocatedDomNodeCount++;
    }
    _childContainer.style.position = 'absolute';
    element.append(_childContainer);
    return element;
  }

  @override
  void recycle() {
    super.recycle();

    // Do not detach the child container from the root. It is permanently
    // attached. The elements are reused together and are detached from the DOM
    // together.
    _childContainer = null;
  }
}

/// A surface that creates a rectangular clip.
class PersistedClipRect extends PersistedContainerSurface with _DomClip {
  PersistedClipRect(Object paintedBy, this.rect) : super(paintedBy);

  final Rect rect;

  @override
  void recomputeTransformAndClip() {
    _transform = parent._transform;
    _globalClip = parent._globalClip.intersect(engine.localClipRectToGlobalClip(
      localClip: rect,
      transform: _transform,
    ));
  }

  @override
  html.Element createElement() {
    return super.createElement()..setAttribute('clip-type', 'rect');
  }

  @override
  void apply() {
    rootElement.style
      ..transform = 'translate(${rect.left}px, ${rect.top}px)'
      ..width = '${rect.right - rect.left}px'
      ..height = '${rect.bottom - rect.top}px';

    // Translate the child container in the opposite direction to compensate for
    // the shift in the coordinate system introduced by the translation of the
    // rootElement. Clipping in Flutter has no effect on the coordinate system.
    childContainer.style.transform =
        'translate(${-rect.left}px, ${-rect.top}px)';
  }

  @override
  void update(PersistedClipRect oldSurface) {
    super.update(oldSurface);
    if (rect != oldSurface.rect) {
      apply();
    }
  }
}

/// A surface that creates a rounded rectangular clip.
class PersistedClipRRect extends PersistedContainerSurface with _DomClip {
  PersistedClipRRect(Object paintedBy, this.rrect, this.clipBehavior)
      : super(paintedBy);

  final RRect rrect;
  // TODO(yjbanov): can this be controlled in the browser?
  final Clip clipBehavior;

  @override
  void recomputeTransformAndClip() {
    _transform = parent._transform;
    _globalClip = parent._globalClip.intersect(engine.localClipRectToGlobalClip(
      localClip: rrect.outerRect,
      transform: _transform,
    ));
  }

  @override
  html.Element createElement() {
    return super.createElement()..setAttribute('clip-type', 'rrect');
  }

  @override
  void apply() {
    rootElement.style
      ..transform = 'translate(${rrect.left}px, ${rrect.top}px)'
      ..width = '${rrect.width}px'
      ..height = '${rrect.height}px'
      ..borderTopLeftRadius = '${rrect.tlRadiusX}px'
      ..borderTopRightRadius = '${rrect.trRadiusX}px'
      ..borderBottomRightRadius = '${rrect.brRadiusX}px'
      ..borderBottomLeftRadius = '${rrect.blRadiusX}px';

    // Translate the child container in the opposite direction to compensate for
    // the shift in the coordinate system introduced by the translation of the
    // rootElement. Clipping in Flutter has no effect on the coordinate system.
    childContainer.style.transform =
        'translate(${-rrect.left}px, ${-rrect.top}px)';
  }

  @override
  void update(PersistedClipRRect oldSurface) {
    super.update(oldSurface);
    if (rrect != oldSurface.rrect) {
      apply();
    }
  }
}

/// A surface that makes its children transparent.
class PersistedOpacity extends PersistedContainerSurface {
  PersistedOpacity(Object paintedBy, this.alpha, this.offset)
      : super(paintedBy);

  final int alpha;
  final Offset offset;

  @override
  void recomputeTransformAndClip() {
    _transform = parent._transform;

    final double dx = offset.dx;
    final double dy = offset.dy;

    if (dx != 0.0 || dy != 0.0) {
      _transform = _transform.clone();
      _transform.translate(dx, dy);
    }

    _globalClip = parent._globalClip;
  }

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-opacity')..style.transformOrigin = '0 0 0';
  }

  @override
  void apply() {
    // TODO(yjbanov): evaluate using `filter: opacity(X)`. It is a longer string
    //                but it reportedly has better hardware acceleration, so may
    //                be worth the trade-off.
    rootElement.style.opacity = '${alpha / 255}';
    rootElement.style.transform = 'translate(${offset.dx}px, ${offset.dy}px)';
  }

  @override
  void update(PersistedOpacity oldSurface) {
    super.update(oldSurface);
    if (alpha != oldSurface.alpha || offset != oldSurface.offset) {
      apply();
    }
  }
}

// Counter used for generating clip path id inside an svg <defs> tag.
int _clipCounter = 0;

/// A surface that clips it's children.
class _PersistedClipPath extends PersistedContainerSurface {
  _PersistedClipPath(Object paintedBy, this.clipPath, this.clipBehavior)
      : super(paintedBy);

  final Path clipPath;
  final Clip clipBehavior;
  html.Element _clipElement;

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-clippath');
  }

  @override
  void apply() {
    if (clipPath == null) {
      if (_clipElement != null) {
        engine.domRenderer.setElementStyle(childContainer, 'clip-path', '');
        engine.domRenderer
            .setElementStyle(childContainer, '-webkit-clip-path', '');
        _clipElement.remove();
        _clipElement = null;
      }
      return;
    }
    String svgClipPath = _pathToSvgClipPath(clipPath);
    _clipElement?.remove();
    _clipElement =
        html.Element.html(svgClipPath, treeSanitizer: _NullTreeSanitizer());
    engine.domRenderer.append(childContainer, _clipElement);
    engine.domRenderer.setElementStyle(
        childContainer, 'clip-path', 'url(#svgClip${_clipCounter})');
    engine.domRenderer.setElementStyle(
        childContainer, '-webkit-clip-path', 'url(#svgClip${_clipCounter})');
  }

  @override
  void update(_PersistedClipPath oldSurface) {
    super.update(oldSurface);
    if (oldSurface.clipPath != clipPath) {
      oldSurface._clipElement?.remove();
      apply();
    } else {
      _clipElement = oldSurface._clipElement;
    }
    oldSurface._clipElement = null;
  }

  @override
  void recycle() {
    _clipElement?.remove();
    _clipElement = null;
    super.recycle();
  }
}

class _NullTreeSanitizer implements html.NodeTreeSanitizer {
  void sanitizeTree(html.Node node) {}
}

// TODO(yjbanov): this is currently very naive. We probably want to cache
//                fewer large canvases than small canvases. We could also
//                improve cache hit count if we did not require exact canvas
//                size match, but instead could choose a canvas that's big
//                enough. The optimal heuristic will need to be figured out.
//                For example, we probably don't want to pick a full-screen
//                canvas to draw a 10x10 picture. Let's revisit this after
//                Harry's layer merging refactor.
/// The maximum number canvases cached.
const _kCanvasCacheSize = 30;

/// Canvases available for reuse, capped at [_kCanvasCacheSize].
final List<engine.BitmapCanvas> _recycledCanvases = <engine.BitmapCanvas>[];

/// A request to repaint a canvas.
///
/// Paint requests are prioritized such that the larger pictures go first. This
/// makes canvas allocation more efficient by letting large pictures claim
/// larger recycled canvases. Otherwise, small pictures would claim the large
/// canvases forcing us to allocate new large canvases.
class _PaintRequest {
  _PaintRequest({
    this.canvasSize,
    this.paintCallback,
  })  : assert(canvasSize != null),
        assert(paintCallback != null);

  final Size canvasSize;
  final VoidCallback paintCallback;
}

/// Repaint requests produced by [PersistedPicture]s that actually paint on the
/// canvas. Painting is delayed until the layer tree is updated to maximize
/// the number of reusable canvases.
List<_PaintRequest> _paintQueue = <_PaintRequest>[];

/// Surfaces that were retained this frame.
///
/// Surfaces should be added to this list directly. Instead, if a surface needs
/// to be retained call [_retainSurface].
List<PersistedSurface> get debugRetainedSurfaces => _retainedSurfaces;
List<PersistedSurface> _retainedSurfaces = <PersistedSurface>[];

/// Marks the subtree of surfaces rooted at [surface] as retained.
void _retainSurface(PersistedSurface surface) {
  _retainedSurfaces.add(surface);
  surface.retain();
}

void _recycleCanvas(engine.EngineCanvas canvas) {
  if (canvas is engine.BitmapCanvas && canvas.isReusable()) {
    _recycledCanvases.add(canvas);
    if (_recycledCanvases.length > _kCanvasCacheSize) {
      final engine.BitmapCanvas removedCanvas = _recycledCanvases.removeAt(0);
      removedCanvas.dispose();
      if (_debugShowCanvasReuseStats) {
        DebugCanvasReuseOverlay.instance.disposedCount++;
      }
    }
    if (_debugShowCanvasReuseStats) {
      DebugCanvasReuseOverlay.instance.inRecycleCount =
          _recycledCanvases.length;
    }
  }
}

/// Signature of a function that instantiates a [PersistedPicture].
typedef PersistedPictureFactory = PersistedPicture Function(
    Object webOnlyPaintedBy, double dx, double dy, Picture picture, int hints);

/// Function used by the [SceneBuilder] to instantiate a picture layer.
PersistedPictureFactory persistedPictureFactory = standardPictureFactory;

/// Instantiates an implementation of a picture layer that uses DOM, CSS, and
/// 2D canvas for painting.
PersistedStandardPicture standardPictureFactory(
    Object webOnlyPaintedBy, double dx, double dy, Picture picture, int hints) {
  return PersistedStandardPicture(webOnlyPaintedBy, dx, dy, picture, hints);
}

/// Instantiates an implementation of a picture layer that uses CSS Paint API
/// (part of Houdini) for painting.
PersistedHoudiniPicture houdiniPictureFactory(
    Object webOnlyPaintedBy, double dx, double dy, Picture picture, int hints) {
  return PersistedHoudiniPicture(webOnlyPaintedBy, dx, dy, picture, hints);
}

class PersistedHoudiniPicture extends PersistedPicture {
  PersistedHoudiniPicture(
      Object paintedBy, double dx, double dy, Picture picture, int hints)
      : super(paintedBy, dx, dy, picture, hints) {
    if (!_cssPainterRegistered) {
      _registerCssPainter();
    }
  }

  static bool _cssPainterRegistered = false;

  static void _registerCssPainter() {
    _cssPainterRegistered = true;
    final dynamic css = js_util.getProperty(html.window, 'CSS');
    final dynamic paintWorklet = js_util.getProperty(css, 'paintWorklet');
    if (paintWorklet == null) {
      html.window.console.warn(
          'WARNING: CSS.paintWorklet not available. Paint worklets are only '
          'supported on sites served from https:// or http://localhost.');
      return;
    }
    js_util.callMethod(
      paintWorklet,
      'addModule',
      [
        '/packages/flutter_web/assets/houdini_painter.js',
      ],
    );
  }

  /// Houdini does not paint to bitmap.
  @override
  int get bitmapPixelCount => 0;

  @override
  void applyPaint(engine.EngineCanvas oldCanvas) {
    _recycleCanvas(oldCanvas);
    final engine.HoudiniCanvas canvas = engine.HoudiniCanvas(_localCullRect);
    _canvas = canvas;
    engine.domRenderer.clearDom(rootElement);
    rootElement.append(_canvas.rootElement);
    picture.recordingCanvas.apply(_canvas);
    canvas.commit();
  }
}

class PersistedStandardPicture extends PersistedPicture {
  PersistedStandardPicture(
      Object paintedBy, double dx, double dy, Picture picture, int hints)
      : super(paintedBy, dx, dy, picture, hints);

  @override
  int get bitmapPixelCount {
    if (_canvas is! engine.BitmapCanvas) {
      return 0;
    }

    final engine.BitmapCanvas bitmapCanvas = _canvas;
    return bitmapCanvas.bitmapPixelCount;
  }

  @override
  void applyPaint(engine.EngineCanvas oldCanvas) {
    if (picture.recordingCanvas.hasArbitraryPaint) {
      _applyBitmapPaint(oldCanvas);
    } else {
      _applyDomPaint(oldCanvas);
    }
  }

  void _applyDomPaint(engine.EngineCanvas oldCanvas) {
    _recycleCanvas(oldCanvas);
    _canvas = engine.DomCanvas();
    engine.domRenderer.clearDom(rootElement);
    rootElement.append(_canvas.rootElement);
    picture.recordingCanvas.apply(_canvas);
  }

  bool _doesCanvasFitBounds(engine.BitmapCanvas canvas, Rect newBounds) {
    final Rect canvasBounds = canvas.bounds;
    return canvasBounds.width >= newBounds.width &&
        canvasBounds.height >= newBounds.height;
  }

  void _applyBitmapPaint(engine.EngineCanvas oldCanvas) {
    if (oldCanvas is engine.BitmapCanvas &&
        _doesCanvasFitBounds(oldCanvas, _localCullRect) &&
        oldCanvas.isReusable()) {
      if (_debugShowCanvasReuseStats) {
        DebugCanvasReuseOverlay.instance.keptCount++;
      }
      oldCanvas.bounds = _localCullRect;
      _canvas = oldCanvas;
      _canvas.clear();
      picture.recordingCanvas.apply(_canvas);
    } else {
      // We can't use the old canvas because the size has changed, so we put
      // it in a cache for later reuse.
      _recycleCanvas(oldCanvas);
      // We cannot paint immediately because not all canvases that we may be
      // able to reuse have been released yet. So instead we enqueue this
      // picture to be painted after the update cycle is done syncing the layer
      // tree then reuse canvases that were freed up.
      _paintQueue.add(_PaintRequest(
        canvasSize: _localCullRect.size,
        paintCallback: () {
          _canvas = _findOrCreateCanvas(_localCullRect);
          if (_debugExplainSurfaceStats) {
            _surfaceStatsFor(this).paintPixelCount +=
                (_canvas as engine.BitmapCanvas).bitmapPixelCount;
          }
          engine.domRenderer.clearDom(rootElement);
          rootElement.append(_canvas.rootElement);
          _canvas.clear();
          picture.recordingCanvas.apply(_canvas);
        },
      ));
    }
  }

  /// Attempts to reuse a canvas from the [_recycledCanvases]. Allocates a new
  /// one if unable to reuse.
  ///
  /// The best recycled canvas is one that:
  ///
  /// - Fits the requested [canvasSize]. This is a hard requirement. Otherwise
  ///   we risk clipping the picture.
  /// - Is the smallest among all possible reusable canvases. This makes canvas
  ///   reuse more efficient.
  /// - Contains no more than twice the number of requested pixels. This makes
  ///   sure we do not use too much memory for small canvases.
  engine.BitmapCanvas _findOrCreateCanvas(Rect bounds) {
    Size canvasSize = bounds.size;
    engine.BitmapCanvas bestRecycledCanvas;
    double lastPixelCount = double.infinity;

    for (int i = 0; i < _recycledCanvases.length; i++) {
      engine.BitmapCanvas candidate = _recycledCanvases[i];
      if (!candidate.isReusable()) {
        continue;
      }

      Size candidateSize = candidate.size;
      double candidatePixelCount = candidateSize.width * candidateSize.height;

      final bool fits = _doesCanvasFitBounds(candidate, bounds);
      final bool isSmaller = candidatePixelCount < lastPixelCount;
      if (fits && isSmaller) {
        bestRecycledCanvas = candidate;
        lastPixelCount = candidatePixelCount;
        final bool fitsExactly = candidateSize.width == canvasSize.width &&
            candidateSize.height == canvasSize.height;
        if (fitsExactly) {
          // No need to keep looking any more.
          break;
        }
      }
    }

    if (bestRecycledCanvas != null) {
      if (_debugExplainSurfaceStats) {
        _surfaceStatsFor(this).reuseCanvasCount++;
      }
      _recycledCanvases.remove(bestRecycledCanvas);
      if (_debugShowCanvasReuseStats) {
        DebugCanvasReuseOverlay.instance.inRecycleCount =
            _recycledCanvases.length;
      }
      if (_debugShowCanvasReuseStats) {
        DebugCanvasReuseOverlay.instance.reusedCount++;
      }
      bestRecycledCanvas.bounds = bounds;
      return bestRecycledCanvas;
    }

    if (_debugShowCanvasReuseStats) {
      DebugCanvasReuseOverlay.instance.createdCount++;
    }
    final engine.BitmapCanvas canvas = engine.BitmapCanvas(bounds);
    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this)
        ..allocateBitmapCanvasCount += 1
        ..allocatedBitmapSizeInPixels =
            canvas.widthInBitmapPixels * canvas.heightInBitmapPixels;
    }
    return canvas;
  }
}

/// A surface that uses a combination of `<canvas>`, `<div>` and `<p>` elements
/// to draw shapes and text.
abstract class PersistedPicture extends PersistedLeafSurface {
  PersistedPicture(Object paintedBy, this.dx, this.dy, this.picture, this.hints)
      : localPaintBounds = picture.recordingCanvas.computePaintBounds(),
        super(paintedBy);

  engine.EngineCanvas _canvas;

  final double dx;
  final double dy;
  final Picture picture;
  final Rect localPaintBounds;
  final int hints;

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-picture');
  }

  @override
  void recomputeTransformAndClip() {
    _transform = parent._transform;
    if (dx != 0.0 || dy != 0.0) {
      _transform = _transform.clone();
      _transform.translate(dx, dy);
    }
    _globalClip = parent._globalClip;
  }

  /// The rectangle that contains all visible pixels drawn by [picture] inside
  /// the current layer hierarchy in local coordinates.
  ///
  /// This value is a conservative estimate, i.e. it must be big enough to
  /// contain everything that's visible, but it may be bigger than necessary.
  /// Therefore it should not be used for clipping. It is meant to be used for
  /// optimizing canvas allocation.
  Rect get localCullRect => _localCullRect;
  Rect _localCullRect;

  /// Same as [localCullRect] but in screen coordinate system.
  Rect get debugGlobalCullRect => _globalCullRect;
  Rect _globalCullRect;

  /// Computes the canvas paint bounds based on the estimated paint bounds and
  /// the scaling produced by transformations.
  ///
  /// Return `true` if the local cull rect changed, indicating that a repaint
  /// may be required. Returns `false` otherwise. Global cull rect changes do
  /// not necessarily incur repaints. For example, if the layer sub-tree was
  /// translated from one frame to another we may not need to repaint, just
  /// translate the canvas.
  bool _recomputeCullRect() {
    assert(transform != null);
    assert(localPaintBounds != null);
    final Rect globalPaintBounds = engine.localClipRectToGlobalClip(
        localClip: localPaintBounds, transform: transform);

    // The exact cull rect required in screen coordinates.
    Rect tightGlobalCullRect = globalPaintBounds.intersect(_globalClip);

    // The exact cull rect required in local coordinates.
    Rect tightLocalCullRect;
    if (tightGlobalCullRect.width <= 0 || tightGlobalCullRect.height <= 0) {
      tightGlobalCullRect = Rect.zero;
      tightLocalCullRect = Rect.zero;
    } else {
      final engine.Matrix4 invertedTransform =
          engine.Matrix4.fromFloat64List(Float64List(16));

      // TODO(yjbanov): When we move to our own vector math library, rewrite
      //                this to check for the case of simple transform before
      //                inverting. Inversion of simple transforms can be made
      //                much cheaper.
      final double det = invertedTransform.copyInverse(transform);
      if (det == 0) {
        // Determinant is zero, which means the transform is not invertible.
        tightGlobalCullRect = Rect.zero;
        tightLocalCullRect = Rect.zero;
      } else {
        tightLocalCullRect = engine.localClipRectToGlobalClip(
            localClip: tightGlobalCullRect, transform: invertedTransform);
      }
    }

    assert(tightLocalCullRect != null);

    if (_localCullRect == null) {
      // This is the first time we are painting this picture. Use the minimal
      // cull rect size because we don't know what the framework's intention is
      // w.r.t. to the clip. Let's start with the smallest canvas possible to
      // save memory. Subsequent repaints will provide more info later.
      _localCullRect = tightLocalCullRect;
      _globalCullRect = tightGlobalCullRect;
      return true;
    } else if (tightLocalCullRect == Rect.zero) {
      // The clip collapsed into a zero-sized rectangle.
      final bool wasZero = _localCullRect == Rect.zero;
      _localCullRect = Rect.zero;
      _globalCullRect = Rect.zero;

      // If it was already zero, no need to signal cull rect change.
      return !wasZero;
    } else if (engine.rectContainsOther(_localCullRect, tightLocalCullRect)) {
      // The cull rect we computed in the past contains the newly computed cull
      // rect. This can happen, for example, when the picture is being shrunk by
      // a clip when it is scrolled out of the screen. In this case we do not
      // repaint the picture. We just let it be shrunk by the outer clip.
      return false;
    } else {
      // The new cull rect contains area not covered by a previous rect. Perhaps
      // the clip is growing, moving around the picture, or both. In this case
      // a part of the picture may not been painted. We will need to
      // request a new canvas and paint the picture on it. However, this is also
      // a strong signal that the clip will continue growing as typically
      // Flutter uses animated transitions. So instead of allocating the canvas
      // the size of the currently visible area, we try to allocate a canvas of
      // a bigger size. This will prevent any further repaints as future frames
      // will hit the above case where the new cull rect is fully contained
      // within the cull rect we compute now.

      // If any of the borders moved.
      const double kPredictedGrowthFactor = 3.0;
      final double leftwardTrend = kPredictedGrowthFactor *
          math.max(_localCullRect.left - tightLocalCullRect.left, 0);
      final double upwardTrend = kPredictedGrowthFactor *
          math.max(_localCullRect.top - tightLocalCullRect.top, 0);
      final double rightwardTrend = kPredictedGrowthFactor *
          math.max(tightLocalCullRect.right - _localCullRect.right, 0);
      final double bottomwardTrend = kPredictedGrowthFactor *
          math.max(tightLocalCullRect.bottom - _localCullRect.bottom, 0);

      Rect newLocalCullRect = Rect.fromLTRB(
        _localCullRect.left - leftwardTrend,
        _localCullRect.top - upwardTrend,
        _localCullRect.right + rightwardTrend,
        _localCullRect.bottom + bottomwardTrend,
      ).intersect(localPaintBounds);

      final bool localCullRectChanged = _localCullRect != newLocalCullRect;
      _localCullRect = newLocalCullRect;
      _globalCullRect = tightGlobalCullRect;
      return localCullRectChanged;
    }
  }

  /// Number of bitmap pixel painted by this picture.
  ///
  /// If the implementation does not paint onto a bitmap canvas, it should
  /// return zero.
  int get bitmapPixelCount;

  void _applyPaint(engine.EngineCanvas oldCanvas) {
    if (!picture.recordingCanvas.didDraw) {
      _recycleCanvas(oldCanvas);
      engine.domRenderer.clearDom(rootElement);
      return;
    }

    if (_debugExplainSurfaceStats) {
      _surfaceStatsFor(this).paintCount++;
    }

    applyPaint(oldCanvas);
  }

  /// Concrete implementations implement this method to do actual painting.
  void applyPaint(engine.EngineCanvas oldCanvas);

  void _applyTranslate() {
    rootElement.style.transform = 'translate(${dx}px, ${dy}px)';
  }

  @override
  void apply() {
    _recomputeCullRect();
    _applyTranslate();
    _applyPaint(null);
  }

  @override
  void update(PersistedPicture oldSurface) {
    super.update(oldSurface);

    if (dx != oldSurface.dx || dy != oldSurface.dy) {
      _applyTranslate();
    }

    // We need to inherit the previous cull rects to allow [_recomputeCullRect]
    // to be smarter.
    _localCullRect = oldSurface._localCullRect;
    _globalCullRect = oldSurface._globalCullRect;
    if (identical(picture, oldSurface.picture)) {
      // The picture is the same. Attempt to avoid repaint.
      if (_recomputeCullRect()) {
        // Cull rect changed such that a repaint is still necessary.
        _applyPaint(oldSurface._canvas);
      } else {
        // Cull rect did not change, or changed such in a way that does not
        // require a repaint (e.g. it shrunk).
        _canvas = oldSurface._canvas;
      }
    } else {
      // We have a new picture. Repaint.
      _recomputeCullRect();
      _applyPaint(oldSurface._canvas);
    }
  }

  @override
  void retain() {
    super.retain();
    if (_recomputeCullRect()) {
      _applyPaint(_canvas);
    }
  }

  @override
  void recycle() {
    _recycleCanvas(_canvas);
    super.recycle();
  }

  @override
  void debugPrintChildren(StringBuffer buffer, int indent) {
    super.debugPrintChildren(buffer, indent);
    if (rootElement != null && rootElement.firstChild != null) {
      final canvasTag =
          (rootElement.firstChild as html.Element).tagName.toLowerCase();
      final canvasHash = rootElement.firstChild.hashCode;
      buffer.writeln('${'  ' * (indent + 1)}<$canvasTag @$canvasHash />');
    } else if (rootElement != null) {
      buffer.writeln(
          '${'  ' * (indent + 1)}<${rootElement.tagName.toLowerCase()} @$hashCode />');
    } else {
      buffer.writeln('${'  ' * (indent + 1)}<canvas recycled />');
    }
  }
}

class PersistedPhysicalShape extends PersistedContainerSurface with _DomClip {
  PersistedPhysicalShape(Object paintedBy, this.path, this.elevation, int color,
      int shadowColor, this.clipBehavior)
      : this.color = Color(color),
        this.shadowColor = Color(shadowColor),
        super(paintedBy);

  final Path path;
  final double elevation;
  final Color color;
  final Color shadowColor;
  final Clip clipBehavior;
  html.Element _clipElement;

  @override
  void recomputeTransformAndClip() {
    _transform = parent._transform;

    final RRect roundRect = path.webOnlyPathAsRoundedRect;
    if (roundRect != null) {
      _globalClip =
          parent._globalClip.intersect(engine.localClipRectToGlobalClip(
        localClip: roundRect.outerRect,
        transform: transform,
      ));
    } else {
      Rect rect = path.webOnlyPathAsRect;
      if (rect != null) {
        _globalClip =
            parent._globalClip.intersect(engine.localClipRectToGlobalClip(
          localClip: rect,
          transform: transform,
        ));
      } else {
        _globalClip = parent._globalClip;
      }
    }
  }

  void _applyColor() {
    rootElement.style.backgroundColor = color.toCssString();
  }

  void _applyShadow() {
    engine.ElevationShadow.applyShadow(
        rootElement.style, elevation, shadowColor);
  }

  @override
  html.Element createElement() {
    return super.createElement()..setAttribute('clip-type', 'physical-shape');
  }

  @override
  void apply() {
    _applyColor();
    _applyShadow();
    _applyShape();
  }

  void _applyShape() {
    if (path == null) return;
    // Handle special case of round rect physical shape mapping to
    // rounded div.
    final RRect roundRect = path.webOnlyPathAsRoundedRect;
    if (roundRect != null) {
      final borderRadius = '${roundRect.tlRadiusX}px ${roundRect.trRadiusX}px '
          '${roundRect.brRadiusX}px ${roundRect.blRadiusX}px';
      var style = rootElement.style;
      style
        ..transform = 'translate(${roundRect.left}px, ${roundRect.top}px)'
        ..width = '${roundRect.width}px'
        ..height = '${roundRect.height}px'
        ..borderRadius = borderRadius;
      childContainer.style.transform =
          'translate(${-roundRect.left}px, ${-roundRect.top}px)';
      if (clipBehavior != Clip.none) {
        style.overflow = 'hidden';
      }
      return;
    } else {
      Rect rect = path.webOnlyPathAsRect;
      if (rect != null) {
        final style = rootElement.style;
        style
          ..transform = 'translate(${rect.left}px, ${rect.top}px)'
          ..width = '${rect.width}px'
          ..height = '${rect.height}px'
          ..borderRadius = '';
        childContainer.style.transform =
            'translate(${-rect.left}px, ${-rect.top}px)';
        if (clipBehavior != Clip.none) {
          style.overflow = 'hidden';
        }
        return;
      } else {
        engine.Ellipse ellipse = path.webOnlyPathAsCircle;
        if (ellipse != null) {
          final double rx = ellipse.radiusX;
          final double ry = ellipse.radiusY;
          final borderRadius = rx == ry ? '${rx}px ' : '${rx}px ${ry}px ';
          var style = rootElement.style;
          final double left = ellipse.x - rx;
          final double top = ellipse.y - ry;
          style
            ..transform = 'translate(${left}px, ${top}px)'
            ..width = '${rx * 2}px'
            ..height = '${ry * 2}px'
            ..borderRadius = borderRadius;
          childContainer.style.transform = 'translate(${-left}px, ${-top}px)';
          if (clipBehavior != Clip.none) {
            style.overflow = 'hidden';
          }
          return;
        }
      }
    }

    Rect bounds = path.getBounds();
    String svgClipPath =
        _pathToSvgClipPath(path, offsetX: -bounds.left, offsetY: -bounds.top);
    assert(_clipElement == null);
    _clipElement =
        html.Element.html(svgClipPath, treeSanitizer: _NullTreeSanitizer());
    engine.domRenderer.append(rootElement, _clipElement);
    engine.domRenderer.setElementStyle(
        rootElement, 'clip-path', 'url(#svgClip${_clipCounter})');
    engine.domRenderer.setElementStyle(
        rootElement, '-webkit-clip-path', 'url(#svgClip${_clipCounter})');
    final html.CssStyleDeclaration rootElementStyle = rootElement.style;
    rootElementStyle
      ..overflow = ''
      ..transform = 'translate(${bounds.left}px, ${bounds.top}px)'
      ..width = '${bounds.width}px'
      ..height = '${bounds.height}px'
      ..borderRadius = '';
    childContainer.style.transform =
        'translate(${-bounds.left}px, ${-bounds.top}px)';
  }

  @override
  void update(PersistedPhysicalShape oldSurface) {
    super.update(oldSurface);
    if (oldSurface.color != color) {
      _applyColor();
    }
    if (oldSurface.elevation != elevation ||
        oldSurface.shadowColor != shadowColor) {
      _applyShadow();
    }
    if (oldSurface.path != path) {
      oldSurface._clipElement?.remove();
      // Reset style on prior element since we may have switched between
      // rect/rrect and arbitrary path.
      var style = rootElement.style;
      style.transform = '';
      style.borderRadius = '';
      engine.domRenderer.setElementStyle(rootElement, 'clip-path', '');
      engine.domRenderer.setElementStyle(rootElement, '-webkit-clip-path', '');
      _applyShape();
    } else {
      _clipElement = oldSurface._clipElement;
    }
    oldSurface._clipElement = null;
  }
}

/// Converts Path to svg element that contains a clip-path definition.
String _pathToSvgClipPath(Path path, {double offsetX = 0, double offsetY = 0}) {
  Rect bounds = path.getBounds();
  StringBuffer sb = new StringBuffer();
  sb.write('<svg width="${bounds.right}" height="${bounds.bottom}" '
      'style="position:absolute">');
  sb.write('<defs>');

  String clipId = 'svgClip${++_clipCounter}';
  sb.write('<clipPath id=${clipId}>');

  sb.write('<path fill="#FFFFFF" d="');
  engine.pathToSvg(path, sb, offsetX: offsetX, offsetY: offsetY);
  sb.write('"></path></clipPath></defs></svg');
  return sb.toString();
}
