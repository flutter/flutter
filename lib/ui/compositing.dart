// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

/// An opaque object representing a composited scene.
///
/// To create a Scene object, use a [SceneBuilder].
///
/// Scene objects can be displayed on the screen using the
/// [Window.render] method.
class Scene extends NativeFieldWrapperClass2 {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a Scene object, use a [SceneBuilder].
  @pragma('vm:entry-point')
  Scene._();


  /// Creates a raster image representation of the current state of the scene.
  /// This is a slow operation that is performed on a background thread.
  Future<Image> toImage(int width, int height) {
    if (width <= 0 || height <= 0)
      throw new Exception('Invalid image dimensions.');
    return _futurize(
      (_Callback<Image> callback) => _toImage(width, height, callback)
    );
  }

  String _toImage(int width, int height, _Callback<Image> callback) native 'Scene_toImage';

  /// Releases the resources used by this scene.
  ///
  /// After calling this function, the scene is cannot be used further.
  void dispose() native 'Scene_dispose';
}

/// Builds a [Scene] containing the given visuals.
///
/// A [Scene] can then be rendered using [Window.render].
///
/// To draw graphical operations onto a [Scene], first create a
/// [Picture] using a [PictureRecorder] and a [Canvas], and then add
/// it to the scene using [addPicture].
class SceneBuilder extends NativeFieldWrapperClass2 {
  /// Creates an empty [SceneBuilder] object.
  @pragma('vm:entry-point')
  SceneBuilder() { _constructor(); }
  void _constructor() native 'SceneBuilder_constructor';

  /// Pushes a transform operation onto the operation stack.
  ///
  /// The objects are transformed by the given matrix before rasterization.
  ///
  /// See [pop] for details about the operation stack.
  void pushTransform(Float64List matrix4) {
    if (matrix4 == null)
      throw new ArgumentError('"matrix4" argument cannot be null');
    if (matrix4.length != 16)
      throw new ArgumentError('"matrix4" must have 16 entries.');
    _pushTransform(matrix4);
  }
  void _pushTransform(Float64List matrix4) native 'SceneBuilder_pushTransform';

  /// Pushes an offset operation onto the operation stack.
  ///
  /// This is equivalent to [pushTransform] with a matrix with only translation.
  ///
  /// See [pop] for details about the operation stack.
  EngineLayer pushOffset(double dx, double dy) native 'SceneBuilder_pushOffset';

  /// Pushes a rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rectangle is discarded.
  ///
  /// See [pop] for details about the operation stack, and [Clip] for different clip modes.
  /// By default, the clip will be anti-aliased (clip = [Clip.antiAlias]).
  void pushClipRect(Rect rect, {Clip clipBehavior = Clip.antiAlias}) {
    assert(clipBehavior != null);
    assert(clipBehavior != Clip.none);
    _pushClipRect(rect.left, rect.right, rect.top, rect.bottom, clipBehavior.index);
  }
  void _pushClipRect(double left,
                     double right,
                     double top,
                     double bottom,
                     int clipBehavior) native 'SceneBuilder_pushClipRect';

  /// Pushes a rounded-rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rounded rectangle is discarded.
  ///
  /// See [pop] for details about the operation stack, and [Clip] for different clip modes.
  /// By default, the clip will be anti-aliased (clip = [Clip.antiAlias]).
  void pushClipRRect(RRect rrect, {Clip clipBehavior = Clip.antiAlias}) {
    assert(clipBehavior != null);
    assert(clipBehavior != Clip.none);
    _pushClipRRect(rrect._value, clipBehavior.index);
  }
  void _pushClipRRect(Float32List rrect, int clipBehavior) native 'SceneBuilder_pushClipRRect';

  /// Pushes a path clip operation onto the operation stack.
  ///
  /// Rasterization outside the given path is discarded.
  ///
  /// See [pop] for details about the operation stack. See [Clip] for different clip modes.
  /// By default, the clip will be anti-aliased (clip = [Clip.antiAlias]).
  void pushClipPath(Path path, {Clip clipBehavior = Clip.antiAlias}) {
    assert(clipBehavior != null);
    assert(clipBehavior != Clip.none);
    _pushClipPath(path, clipBehavior.index);
  }
  void _pushClipPath(Path path, int clipBehavior) native 'SceneBuilder_pushClipPath';

  /// Pushes an opacity operation onto the operation stack.
  ///
  /// The given alpha value is blended into the alpha value of the objects'
  /// rasterization. An alpha value of 0 makes the objects entirely invisible.
  /// An alpha value of 255 has no effect (i.e., the objects retain the current
  /// opacity).
  ///
  /// See [pop] for details about the operation stack.
  void pushOpacity(int alpha) native 'SceneBuilder_pushOpacity';

  /// Pushes a color filter operation onto the operation stack.
  ///
  /// The given color is applied to the objects' rasterization using the given
  /// blend mode.
  ///
  /// See [pop] for details about the operation stack.
  void pushColorFilter(Color color, BlendMode blendMode) {
    _pushColorFilter(color.value, blendMode.index);
  }
  void _pushColorFilter(int color, int blendMode) native 'SceneBuilder_pushColorFilter';

  /// Pushes a backdrop filter operation onto the operation stack.
  ///
  /// The given filter is applied to the current contents of the scene prior to
  /// rasterizing the given objects.
  ///
  /// See [pop] for details about the operation stack.
  void pushBackdropFilter(ImageFilter filter) native 'SceneBuilder_pushBackdropFilter';

  /// Pushes a shader mask operation onto the operation stack.
  ///
  /// The given shader is applied to the object's rasterization in the given
  /// rectangle using the given blend mode.
  ///
  /// See [pop] for details about the operation stack.
  void pushShaderMask(Shader shader, Rect maskRect, BlendMode blendMode) {
    _pushShaderMask(shader,
                    maskRect.left,
                    maskRect.right,
                    maskRect.top,
                    maskRect.bottom,
                    blendMode.index);
  }
  void _pushShaderMask(Shader shader,
                       double maskRectLeft,
                       double maskRectRight,
                       double maskRectTop,
                       double maskRectBottom,
                       int blendMode) native 'SceneBuilder_pushShaderMask';

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
  // ignore: deprecated_member_use
  EngineLayer pushPhysicalShape({ Path path, double elevation, Color color, Color shadowColor, Clip clipBehavior = defaultClipBehavior}) {
    return _pushPhysicalShape(path, elevation, color.value, shadowColor?.value ?? 0xFF000000, clipBehavior.index);
  }
  EngineLayer _pushPhysicalShape(Path path, double elevation, int color, int shadowColor, int clipBehavior) native
    'SceneBuilder_pushPhysicalShape';

  /// Ends the effect of the most recently pushed operation.
  ///
  /// Internally the scene builder maintains a stack of operations. Each of the
  /// operations in the stack applies to each of the objects added to the scene.
  /// Calling this function removes the most recently added operation from the
  /// stack.
  void pop() native 'SceneBuilder_pop';

  /// Add a retained engine layer subtree from previous frames.
  ///
  /// All the engine layers that are in the subtree of the retained layer will
  /// be automatically appended to the current engine layer tree. Therefore,
  /// once this is called, there's no need to call [addToScene] for its children
  /// layers.
  EngineLayer addRetained(EngineLayer retainedLayer) native 'SceneBuilder_addRetained';

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
  // Values above must match constants in //engine/src/sky/compositor/performance_overlay_layer.h
  void addPerformanceOverlay(int enabledOptions, Rect bounds) {
    _addPerformanceOverlay(enabledOptions,
                           bounds.left,
                           bounds.right,
                           bounds.top,
                           bounds.bottom);
  }
  void _addPerformanceOverlay(int enabledOptions,
                              double left,
                              double right,
                              double top,
                              double bottom) native 'SceneBuilder_addPerformanceOverlay';

  /// Adds a [Picture] to the scene.
  ///
  /// The picture is rasterized at the given offset.
  void addPicture(Offset offset, Picture picture, { bool isComplexHint: false, bool willChangeHint: false }) {
    int hints = 0;
    if (isComplexHint)
      hints |= 1;
    if (willChangeHint)
      hints |= 2;
    _addPicture(offset.dx, offset.dy, picture, hints);
  }
  void _addPicture(double dx, double dy, Picture picture, int hints) native 'SceneBuilder_addPicture';

  /// Adds a backend texture to the scene.
  ///
  /// The texture is scaled to the given size and rasterized at the given offset.
  ///
  /// If `freeze` is true the texture that is added to the scene will not
  /// be updated with new frames. `freeze` is used when resizing an embedded
  /// Android view: When resizing an Android view there is a short period during
  /// which the framework cannot tell if the newest texture frame has the
  /// previous or new size, to workaround this the framework "freezes" the
  /// texture just before resizing the Android view and unfreezes it when it is
  /// certain that a frame with the new size is ready.
  void addTexture(int textureId, { Offset offset: Offset.zero, double width: 0.0, double height: 0.0 , bool freeze: false}) {
    assert(offset != null, 'Offset argument was null');
    _addTexture(offset.dx, offset.dy, width, height, textureId, freeze);
  }
  void _addTexture(double dx, double dy, double width, double height, int textureId, bool freeze) native 'SceneBuilder_addTexture';

  /// (Fuchsia-only) Adds a scene rendered by another application to the scene
  /// for this application.
  void addChildScene({
    Offset offset: Offset.zero,
    double width: 0.0,
    double height: 0.0,
    SceneHost sceneHost,
    bool hitTestable: true
  }) {
    _addChildScene(offset.dx,
                   offset.dy,
                   width,
                   height,
                   sceneHost,
                   hitTestable);
  }
  void _addChildScene(double dx,
                      double dy,
                      double width,
                      double height,
                      SceneHost sceneHost,
                      bool hitTestable) native 'SceneBuilder_addChildScene';

  /// Sets a threshold after which additional debugging information should be recorded.
  ///
  /// Currently this interface is difficult to use by end-developers. If you're
  /// interested in using this feature, please contact [flutter-dev](https://groups.google.com/forum/#!forum/flutter-dev).
  /// We'll hopefully be able to figure out how to make this feature more useful
  /// to you.
  void setRasterizerTracingThreshold(int frameInterval) native 'SceneBuilder_setRasterizerTracingThreshold';

  /// Sets whether the raster cache should checkerboard cached entries. This is
  /// only useful for debugging purposes.
  ///
  /// The compositor can sometimes decide to cache certain portions of the
  /// widget hierarchy. Such portions typically don't change often from frame to
  /// frame and are expensive to render. This can speed up overall rendering. However,
  /// there is certain upfront cost to constructing these cache entries. And, if
  /// the cache entries are not used very often, this cost may not be worth the
  /// speedup in rendering of subsequent frames. If the developer wants to be certain
  /// that populating the raster cache is not causing stutters, this option can be
  /// set. Depending on the observations made, hints can be provided to the compositor
  /// that aid it in making better decisions about caching.
  ///
  /// Currently this interface is difficult to use by end-developers. If you're
  /// interested in using this feature, please contact [flutter-dev](https://groups.google.com/forum/#!forum/flutter-dev).
  void setCheckerboardRasterCacheImages(bool checkerboard) native 'SceneBuilder_setCheckerboardRasterCacheImages';

  /// Sets whether the compositor should checkerboard layers that are rendered
  /// to offscreen bitmaps.
  ///
  /// This is only useful for debugging purposes.
  void setCheckerboardOffscreenLayers(bool checkerboard) native 'SceneBuilder_setCheckerboardOffscreenLayers';

  /// Finishes building the scene.
  ///
  /// Returns a [Scene] containing the objects that have been added to
  /// this scene builder. The [Scene] can then be displayed on the
  /// screen with [Window.render].
  ///
  /// After calling this function, the scene builder object is invalid and
  /// cannot be used further.
  Scene build() native 'SceneBuilder_build';
}

/// (Fuchsia-only) Hosts content provided by another application.
class SceneHost extends NativeFieldWrapperClass2 {
  /// Creates a host for a child scene.
  ///
  /// The export token is bound to a scene graph node which acts as a container
  /// for the child's content.  The creator of the scene host is responsible for
  /// sending the corresponding import token (the other endpoint of the event pair)
  /// to the child.
  ///
  /// The export token is a dart:zircon Handle, but that type isn't
  /// available here. This is called by ChildViewConnection in
  /// //topaz/public/lib/ui/flutter/.
  ///
  /// The scene host takes ownership of the provided export token handle.
  SceneHost(dynamic exportTokenHandle) {
    _constructor(exportTokenHandle);
  }
  void _constructor(dynamic exportTokenHandle) native 'SceneHost_constructor';

  /// Releases the resources associated with the child scene host.
  ///
  /// After calling this function, the child scene host cannot be used further.
  void dispose() native 'SceneHost_dispose';
}
