// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

class SurfaceSceneBuilder implements ui.SceneBuilder {
  SurfaceSceneBuilder() {
    _surfaceStack.add(PersistedScene(_lastFrameScene));
  }

  final List<PersistedContainerSurface> _surfaceStack =
      <PersistedContainerSurface>[];

  /// The scene built by this scene builder.
  ///
  /// This getter should only be called after all surfaces are built.
  PersistedScene get _persistedScene {
    return _surfaceStack.first as PersistedScene;
  }

  /// The surface currently being built.
  PersistedContainerSurface get _currentSurface => _surfaceStack.last;

  ui.EngineLayer _pushSurface(PersistedContainerSurface surface) {
    // Only attempt to update if the update is requested and the surface is in
    // the live tree.
    if (surface.oldLayer != null) {
      assert(surface.oldLayer!.runtimeType == surface.runtimeType);
      assert(debugAssertSurfaceState(
          surface.oldLayer!, PersistedSurfaceState.active));
      surface.oldLayer!.state = PersistedSurfaceState.pendingUpdate;
    }
    _adoptSurface(surface);
    _surfaceStack.add(surface);
    return surface;
  }

  /// Adds [surface] to the surface tree.
  ///
  /// This is used by tests.
  void debugAddSurface(PersistedSurface surface) {
    if (assertionsEnabled) {
      _addSurface(surface);
    }
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
  @override
  ui.OffsetEngineLayer pushOffset(
    double dx,
    double dy, {
    ui.OffsetEngineLayer? oldLayer,
  }) {
    return _pushSurface(PersistedOffset(oldLayer as PersistedOffset?, dx, dy)) as ui.OffsetEngineLayer;
  }

  /// Pushes a transform operation onto the operation stack.
  ///
  /// The objects are transformed by the given matrix before rasterization.
  ///
  /// See [pop] for details about the operation stack.
  @override
  ui.TransformEngineLayer pushTransform(
    Float64List matrix4, {
    ui.TransformEngineLayer? oldLayer,
  }) {
    if (matrix4 == null) { // ignore: unnecessary_null_comparison
      throw ArgumentError('"matrix4" argument cannot be null');
    }
    if (matrix4.length != 16) {
      throw ArgumentError('"matrix4" must have 16 entries.');
    }

    // TODO(yjbanov): make this final after NNBD ships definite assignment.
    /*final*/ Float32List? matrix;
    if (_surfaceStack.length == 1) {
      // Top level transform contains view configuration to scale
      // scene to devicepixelratio. Use identity instead since CSS uses
      // logical device pixels.
      if (!ui.debugEmulateFlutterTesterEnvironment) {
        assert(matrix4[0] == window.devicePixelRatio &&
           matrix4[5] == window.devicePixelRatio);
      }
      matrix = Matrix4.identity().storage;
    } else {
      matrix = toMatrix32(matrix4);
    }
    return _pushSurface(PersistedTransform(oldLayer as PersistedTransform?, matrix)) as ui.TransformEngineLayer;
  }

  /// Pushes a rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rectangle is discarded.
  ///
  /// See [pop] for details about the operation stack, and [Clip] for different clip modes.
  /// By default, the clip will be anti-aliased (clip = [Clip.antiAlias]).
  @override
  ui.ClipRectEngineLayer pushClipRect(
    ui.Rect rect, {
    ui.Clip clipBehavior = ui.Clip.antiAlias,
    ui.ClipRectEngineLayer? oldLayer,
  }) {
    assert(clipBehavior != null); // ignore: unnecessary_null_comparison
    assert(clipBehavior != ui.Clip.none);
    return _pushSurface(PersistedClipRect(oldLayer as PersistedClipRect?, rect)) as ui.ClipRectEngineLayer;
  }

  /// Pushes a rounded-rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rounded rectangle is discarded.
  ///
  /// See [pop] for details about the operation stack.
  @override
  ui.ClipRRectEngineLayer pushClipRRect(
    ui.RRect rrect, {
    ui.Clip? clipBehavior,
    ui.ClipRRectEngineLayer? oldLayer,
  }) {
    return _pushSurface(PersistedClipRRect(oldLayer, rrect, clipBehavior)) as ui.ClipRRectEngineLayer;
  }

  /// Pushes a path clip operation onto the operation stack.
  ///
  /// Rasterization outside the given path is discarded.
  ///
  /// See [pop] for details about the operation stack.
  @override
  ui.ClipPathEngineLayer pushClipPath(
    ui.Path path, {
    ui.Clip clipBehavior = ui.Clip.antiAlias,
    ui.ClipPathEngineLayer? oldLayer,
  }) {
    assert(clipBehavior != null); // ignore: unnecessary_null_comparison
    assert(clipBehavior != ui.Clip.none);
    return _pushSurface(PersistedClipPath(oldLayer as PersistedClipPath?, path, clipBehavior)) as ui.ClipPathEngineLayer;
  }

  /// Pushes an opacity operation onto the operation stack.
  ///
  /// The given alpha value is blended into the alpha value of the objects'
  /// rasterization. An alpha value of 0 makes the objects entirely invisible.
  /// An alpha value of 255 has no effect (i.e., the objects retain the current
  /// opacity).
  ///
  /// See [pop] for details about the operation stack.
  @override
  ui.OpacityEngineLayer pushOpacity(
    int alpha, {
    ui.Offset offset = ui.Offset.zero,
    ui.OpacityEngineLayer? oldLayer,
  }) {
    return _pushSurface(PersistedOpacity(oldLayer as PersistedOpacity?, alpha, offset)) as ui.OpacityEngineLayer;
  }

  /// Pushes a color filter operation onto the operation stack.
  ///
  /// The given color is applied to the objects' rasterization using the given
  /// blend mode.
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack.
  @override
  ui.ColorFilterEngineLayer pushColorFilter(
    ui.ColorFilter filter, {
    ui.ColorFilterEngineLayer? oldLayer,
  }) {
    assert(filter != null); // ignore: unnecessary_null_comparison
    throw UnimplementedError();
  }

  /// Pushes an image filter operation onto the operation stack.
  ///
  /// The given filter is applied to the children's rasterization before compositing them into
  /// the scene.
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack.
  @override
  ui.ImageFilterEngineLayer pushImageFilter(
    ui.ImageFilter filter, {
    ui.ImageFilterEngineLayer? oldLayer,
  }) {
    assert(filter != null); // ignore: unnecessary_null_comparison
    return _pushSurface(PersistedImageFilter(oldLayer as PersistedImageFilter?, filter)) as ui.ImageFilterEngineLayer;
  }

  /// Pushes a backdrop filter operation onto the operation stack.
  ///
  /// The given filter is applied to the current contents of the scene prior to
  /// rasterizing the given objects.
  ///
  /// See [pop] for details about the operation stack.
  @override
  ui.BackdropFilterEngineLayer pushBackdropFilter(
    ui.ImageFilter filter, {
    ui.BackdropFilterEngineLayer? oldLayer,
  }) {
    return _pushSurface(PersistedBackdropFilter(oldLayer as PersistedBackdropFilter?, filter as EngineImageFilter)) as ui.BackdropFilterEngineLayer;
  }

  /// Pushes a shader mask operation onto the operation stack.
  ///
  /// The given shader is applied to the object's rasterization in the given
  /// rectangle using the given blend mode.
  ///
  /// See [pop] for details about the operation stack.
  @override
  ui.ShaderMaskEngineLayer pushShaderMask(
    ui.Shader shader,
    ui.Rect maskRect,
    ui.BlendMode blendMode, {
    ui.ShaderMaskEngineLayer? oldLayer,
  }) {
    throw UnimplementedError();
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
  @override
  ui.PhysicalShapeEngineLayer pushPhysicalShape({
    required ui.Path path,
    required double elevation,
    required ui.Color color,
    ui.Color? shadowColor,
    ui.Clip clipBehavior = ui.Clip.none,
    ui.PhysicalShapeEngineLayer? oldLayer,
  }) {
    assert(color != null, 'color must not be null'); // ignore: unnecessary_null_comparison
    return _pushSurface(PersistedPhysicalShape(
      oldLayer as PersistedPhysicalShape?,
      path as SurfacePath,
      elevation,
      color.value,
      shadowColor?.value ?? 0xFF000000,
      clipBehavior,
    )) as ui.PhysicalShapeEngineLayer;
  }

  /// Add a retained engine layer subtree from previous frames.
  ///
  /// All the engine layers that are in the subtree of the retained layer will
  /// be automatically appended to the current engine layer tree.
  ///
  /// Therefore, when implementing a subclass of the [Layer] concept defined in
  /// the rendering layer of Flutter's framework, once this is called, there's
  /// no need to call [addToScene] for its children layers.
  @override
  void addRetained(ui.EngineLayer retainedLayer) {
    final PersistedContainerSurface retainedSurface = retainedLayer as PersistedContainerSurface;
    if (assertionsEnabled) {
      assert(debugAssertSurfaceState(retainedSurface,
          PersistedSurfaceState.active, PersistedSurfaceState.released));
    }
    retainedSurface.tryRetain();
    _adoptSurface(retainedSurface);
  }

  /// Ends the effect of the most recently pushed operation.
  ///
  /// Internally the scene builder maintains a stack of operations. Each of the
  /// operations in the stack applies to each of the objects added to the scene.
  /// Calling this function removes the most recently added operation from the
  /// stack.
  @override
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
  ///  - 0x01: displayRasterizerStatistics - show raster thread frame time
  ///  - 0x02: visualizeRasterizerStatistics - graph raster thread frame times
  ///  - 0x04: displayEngineStatistics - show UI thread frame time
  ///  - 0x08: visualizeEngineStatistics - graph UI thread frame times
  /// Set enabledOptions to 0x0F to enable all the currently defined features.
  ///
  /// The "UI thread" is the thread that includes all the execution of
  /// the main Dart isolate (the isolate that can call
  /// [Window.render]). The UI thread frame time is the total time
  /// spent executing the [Window.onBeginFrame] callback. The "raster
  /// thread" is the thread (running on the CPU) that subsequently
  /// processes the [Scene] provided by the Dart code to turn it into
  /// GPU commands and send it to the GPU.
  ///
  /// See also the [PerformanceOverlayOption] enum in the rendering library.
  /// for more details.
  @override
  void addPerformanceOverlay(int enabledOptions, ui.Rect bounds) {
    _addPerformanceOverlay(
        enabledOptions, bounds.left, bounds.right, bounds.top, bounds.bottom);
  }

  /// Whether we've already warned the user about the lack of the performance
  /// overlay or not.
  ///
  /// We use this to avoid spamming the console with redundant warning messages.
  static bool _webOnlyDidWarnAboutPerformanceOverlay = false;

  void _addPerformanceOverlay(
    int enabledOptions,
    double left,
    double right,
    double top,
    double bottom,
  ) {
    if (!_webOnlyDidWarnAboutPerformanceOverlay) {
      _webOnlyDidWarnAboutPerformanceOverlay = true;
      html.window.console
          .warn('The performance overlay isn\'t supported on the web');
    }
  }

  /// Adds a [Picture] to the scene.
  ///
  /// The picture is rasterized at the given offset.
  @override
  void addPicture(
    ui.Offset offset,
    ui.Picture picture, {
    bool isComplexHint = false,
    bool willChangeHint = false,
  }) {
    int hints = 0;
    if (isComplexHint) {
      hints |= 1;
    }
    if (willChangeHint) {
      hints |= 2;
    }
    _addSurface(PersistedPicture(offset.dx, offset.dy, picture as EnginePicture, hints));
  }

  /// Adds a backend texture to the scene.
  ///
  /// The texture is scaled to the given size and rasterized at the given
  /// offset.
  @override
  void addTexture(
    int textureId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
    bool freeze = false,
    ui.FilterQuality filterQuality = ui.FilterQuality.low,
  }) {
    assert(offset != null, 'Offset argument was null'); // ignore: unnecessary_null_comparison
    _addTexture(offset.dx, offset.dy, width, height, textureId, filterQuality.index);
  }

  void _addTexture(
      double dx, double dy, double width, double height, int textureId, int filterQuality) {
    // In test mode, allow this to be a no-op.
    if (!ui.debugEmulateFlutterTesterEnvironment) {
      throw UnimplementedError('Textures are not supported in Flutter Web');
    }
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
  @override
  void addPlatformView(
    int viewId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
  }) {
    assert(offset != null, 'Offset argument was null'); // ignore: unnecessary_null_comparison
    _addPlatformView(offset.dx, offset.dy, width, height, viewId);
  }

  void _addPlatformView(
    double dx,
    double dy,
    double width,
    double height,
    int viewId,
  ) {
    _addSurface(PersistedPlatformView(viewId, dx, dy, width, height));
  }

  /// (Fuchsia-only) Adds a scene rendered by another application to the scene
  /// for this application.
  @override
  void addChildScene({
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
    ui.SceneHost? sceneHost,
    bool hitTestable = true,
  }) {
    _addChildScene(offset.dx, offset.dy, width, height, sceneHost, hitTestable);
  }

  void _addChildScene(
    double dx,
    double dy,
    double width,
    double height,
    ui.SceneHost? sceneHost,
    bool hitTestable,
  ) {
    throw UnimplementedError();
  }

  /// Sets a threshold after which additional debugging information should be
  /// recorded.
  ///
  /// Currently this interface is difficult to use by end-developers. If you're
  /// interested in using this feature, please contact [flutter-dev](https://groups.google.com/forum/#!forum/flutter-dev).
  /// We'll hopefully be able to figure out how to make this feature more useful
  /// to you.
  @override
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
  @override
  void setCheckerboardRasterCacheImages(bool checkerboard) {}

  /// Sets whether the compositor should checkerboard layers that are rendered
  /// to offscreen bitmaps.
  ///
  /// This is only useful for debugging purposes.
  @override
  void setCheckerboardOffscreenLayers(bool checkerboard) {}

  /// The scene recorded in the last frame.
  ///
  /// This is a surface tree that holds onto the DOM elements that can be reused
  /// on the next frame.
  static PersistedScene? _lastFrameScene;

  /// Returns the computed persisted scene graph recorded in the last frame.
  ///
  /// This is only available in debug mode. It returns `null` in profile and
  /// release modes.
  static PersistedScene? get debugLastFrameScene {
    PersistedScene? result;
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
    _clipIdCounter = 0;
    _recycledCanvases.clear();
  }

  /// Finishes building the scene.
  ///
  /// Returns a [Scene] containing the objects that have been added to
  /// this scene builder. The [Scene] can then be displayed on the
  /// screen with [Window.render].
  ///
  /// After calling this function, the scene builder object is invalid and
  /// cannot be used further.
  @override
  SurfaceScene build() {
    timeAction<void>(kProfilePrerollFrame, () {
      while (_surfaceStack.length > 1) {
        // Auto-pop layers that were pushed without a corresponding pop.
        pop();
      }
      _persistedScene.preroll();
    });
    return timeAction<SurfaceScene>(kProfileApplyFrame, () {
      if (_lastFrameScene == null) {
        _persistedScene.build();
      } else {
        _persistedScene.update(_lastFrameScene!);
      }
      commitScene(_persistedScene);
      _lastFrameScene = _persistedScene;
      return SurfaceScene(_persistedScene.rootElement);
    });
  }

  /// Set properties on the linked scene.  These properties include its bounds,
  /// as well as whether it can be the target of focus events or not.
  @override
  void setProperties(
    double width,
    double height,
    double insetTop,
    double insetRight,
    double insetBottom,
    double insetLeft,
    bool focusable,
  ) {
    throw UnimplementedError();
  }
}

// TODO(yjbanov): in HTML the blur looks too aggressive. The current
//                implementation was copied from the existing backdrop-filter
//                but probably needs a revision.
String _imageFilterToCss(EngineImageFilter filter) {
  return 'blur(${math.max(filter.sigmaX, filter.sigmaY) * 2}px)';
}
