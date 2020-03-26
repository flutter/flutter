// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of dart.ui;

/// An opaque object representing a composited scene.
///
/// To create a Scene object, use a [SceneBuilder].
///
/// Scene objects can be displayed on the screen using the
/// [Window.render] method.
@pragma('vm:entry-point')
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
    if (width <= 0 || height <= 0) {
      throw Exception('Invalid image dimensions.');
    }
    return _futurize((_Callback<Image> callback) => _toImage(width, height, callback));
  }

  String _toImage(int width, int height, _Callback<Image> callback) native 'Scene_toImage';

  /// Releases the resources used by this scene.
  ///
  /// After calling this function, the scene is cannot be used further.
  void dispose() native 'Scene_dispose';
}

// Lightweight wrapper of a native layer object.
//
// This is used to provide a typed API for engine layers to prevent
// incompatible layers from being passed to [SceneBuilder]'s push methods.
// For example, this prevents a layer returned from `pushOpacity` from being
// passed as `oldLayer` to `pushTransform`. This is achieved by having one
// concrete subclass of this class per push method.
abstract class _EngineLayerWrapper implements EngineLayer {
  _EngineLayerWrapper._(this._nativeLayer);

  EngineLayer _nativeLayer;

  // Children of this layer.
  //
  // Null if this layer has no children. This field is populated only in debug
  // mode.
  List<_EngineLayerWrapper> _debugChildren;

  // Whether this layer was used as `oldLayer` in a past frame.
  //
  // It is illegal to use a layer object again after it is passed as an
  // `oldLayer` argument.
  bool _debugWasUsedAsOldLayer = false;

  bool _debugCheckNotUsedAsOldLayer() {
    assert(
        !_debugWasUsedAsOldLayer,
        'Layer $runtimeType was previously used as oldLayer.\n'
        'Once a layer is used as oldLayer, it may not be used again. Instead, '
        'after calling one of the SceneBuilder.push* methods and passing an oldLayer '
        'to it, use the layer returned by the method as oldLayer in subsequent '
        'frames.');
    return true;
  }
}

/// An opaque handle to a transform engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushTransform].
///
/// {@template dart.ui.sceneBuilder.oldLayerCompatibility}
/// `oldLayer` parameter in [SceneBuilder] methods only accepts objects created
/// by the engine. [SceneBuilder] will throw an [AssertionError] if you pass it
/// a custom implementation of this class.
/// {@endtemplate}
class TransformEngineLayer extends _EngineLayerWrapper {
  TransformEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to an offset engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushOffset].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class OffsetEngineLayer extends _EngineLayerWrapper {
  OffsetEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to a clip rect engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushClipRect].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class ClipRectEngineLayer extends _EngineLayerWrapper {
  ClipRectEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to a clip rounded rect engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushClipRRect].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class ClipRRectEngineLayer extends _EngineLayerWrapper {
  ClipRRectEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to a clip path engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushClipPath].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class ClipPathEngineLayer extends _EngineLayerWrapper {
  ClipPathEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to an opacity engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushOpacity].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class OpacityEngineLayer extends _EngineLayerWrapper {
  OpacityEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to a color filter engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushColorFilter].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class ColorFilterEngineLayer extends _EngineLayerWrapper {
  ColorFilterEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to an image filter engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushImageFilter].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class ImageFilterEngineLayer extends _EngineLayerWrapper {
  ImageFilterEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to a backdrop filter engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushBackdropFilter].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class BackdropFilterEngineLayer extends _EngineLayerWrapper {
  BackdropFilterEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to a shader mask engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushShaderMask].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class ShaderMaskEngineLayer extends _EngineLayerWrapper {
  ShaderMaskEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
}

/// An opaque handle to a physical shape engine layer.
///
/// Instances of this class are created by [SceneBuilder.pushPhysicalShape].
///
/// {@macro dart.ui.sceneBuilder.oldLayerCompatibility}
class PhysicalShapeEngineLayer extends _EngineLayerWrapper {
  PhysicalShapeEngineLayer._(EngineLayer nativeLayer) : super._(nativeLayer);
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
  SceneBuilder() {
    _constructor();
  }
  void _constructor() native 'SceneBuilder_constructor';

  // Layers used in this scene.
  //
  // The key is the layer used. The value is the description of what the layer
  // is used for, e.g. "pushOpacity" or "addRetained".
  Map<EngineLayer, String> _usedLayers = <EngineLayer, String>{};

  // In debug mode checks that the `layer` is only used once in a given scene.
  bool _debugCheckUsedOnce(EngineLayer layer, String usage) {
    assert(() {
      if (layer == null) {
        return true;
      }

      assert(
          !_usedLayers.containsKey(layer),
          'Layer ${layer.runtimeType} already used.\n'
          'The layer is already being used as ${_usedLayers[layer]} in this scene.\n'
          'A layer may only be used once in a given scene.');

      _usedLayers[layer] = usage;
      return true;
    }());

    return true;
  }

  bool _debugCheckCanBeUsedAsOldLayer(_EngineLayerWrapper layer, String methodName) {
    assert(() {
      if (layer == null) {
        return true;
      }
      layer._debugCheckNotUsedAsOldLayer();
      assert(_debugCheckUsedOnce(layer, 'oldLayer in $methodName'));
      layer._debugWasUsedAsOldLayer = true;
      return true;
    }());
    return true;
  }

  final List<_EngineLayerWrapper> _layerStack = <_EngineLayerWrapper>[];

  // Pushes the `newLayer` onto the `_layerStack` and adds it to the
  // `_debugChildren` of the current layer in the stack, if any.
  bool _debugPushLayer(_EngineLayerWrapper newLayer) {
    assert(() {
      if (_layerStack.isNotEmpty) {
        final _EngineLayerWrapper currentLayer = _layerStack.last;
        currentLayer._debugChildren ??= <_EngineLayerWrapper>[];
        currentLayer._debugChildren.add(newLayer);
      }
      _layerStack.add(newLayer);
      return true;
    }());
    return true;
  }

  /// Pushes a transform operation onto the operation stack.
  ///
  /// The objects are transformed by the given matrix before rasterization.
  ///
  /// {@template dart.ui.sceneBuilder.oldLayer}
  /// If `oldLayer` is not null the engine will attempt to reuse the resources
  /// allocated for the old layer when rendering the new layer. This is purely
  /// an optimization. It has no effect on the correctness of rendering.
  /// {@endtemplate}
  ///
  /// {@template dart.ui.sceneBuilder.oldLayerVsRetained}
  /// Passing a layer to [addRetained] or as `oldLayer` argument to a push
  /// method counts as _usage_. A layer can be used no more than once in a scene.
  /// For example, it may not be passed simultaneously to two push methods, or
  /// to a push method and to `addRetained`.
  ///
  /// When a layer is passed to [addRetained] all descendant layers are also
  /// considered as used in this scene. The same single-usage restriction
  /// applies to descendants.
  ///
  /// When a layer is passed as an `oldLayer` argument to a push method, it may
  /// no longer be used in subsequent frames. If you would like to continue
  /// reusing the resources associated with the layer, store the layer object
  /// returned by the push method and use that in the next frame instead of the
  /// original object.
  /// {@endtemplate}
  ///
  /// See [pop] for details about the operation stack.
  TransformEngineLayer pushTransform(
    Float64List matrix4, {
    TransformEngineLayer oldLayer,
  }) {
    assert(_matrix4IsValid(matrix4));
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushTransform'));
    final EngineLayer engineLayer = EngineLayer._();
    _pushTransform(engineLayer, matrix4);
    final TransformEngineLayer layer = TransformEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  void _pushTransform(EngineLayer layer, Float64List matrix4) native 'SceneBuilder_pushTransform';

  /// Pushes an offset operation onto the operation stack.
  ///
  /// This is equivalent to [pushTransform] with a matrix with only translation.
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack.
  OffsetEngineLayer pushOffset(
    double dx,
    double dy, {
    OffsetEngineLayer oldLayer,
  }) {
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushOffset'));
    final EngineLayer engineLayer = EngineLayer._();
    _pushOffset(engineLayer, dx, dy);
    final OffsetEngineLayer layer = OffsetEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  void _pushOffset(EngineLayer layer, double dx, double dy) native 'SceneBuilder_pushOffset';

  /// Pushes a rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rectangle is discarded.
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack, and [Clip] for different clip modes.
  /// By default, the clip will be anti-aliased (clip = [Clip.antiAlias]).
  ClipRectEngineLayer pushClipRect(
    Rect rect, {
    Clip clipBehavior = Clip.antiAlias,
    ClipRectEngineLayer oldLayer,
  }) {
    assert(clipBehavior != null);
    assert(clipBehavior != Clip.none);
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushClipRect'));
    final EngineLayer engineLayer = EngineLayer._();
    _pushClipRect(engineLayer, rect.left, rect.right, rect.top, rect.bottom, clipBehavior.index);
    final ClipRectEngineLayer layer = ClipRectEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  void _pushClipRect(EngineLayer outEngineLayer, double left, double right, double top, double bottom, int clipBehavior)
      native 'SceneBuilder_pushClipRect';

  /// Pushes a rounded-rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rounded rectangle is discarded.
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack, and [Clip] for different clip modes.
  /// By default, the clip will be anti-aliased (clip = [Clip.antiAlias]).
  ClipRRectEngineLayer pushClipRRect(
    RRect rrect, {
    Clip clipBehavior = Clip.antiAlias,
    ClipRRectEngineLayer oldLayer,
  }) {
    assert(clipBehavior != null);
    assert(clipBehavior != Clip.none);
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushClipRRect'));
    final EngineLayer engineLayer = EngineLayer._();
    _pushClipRRect(engineLayer, rrect._value32, clipBehavior.index);
    final ClipRRectEngineLayer layer = ClipRRectEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  void _pushClipRRect(EngineLayer layer, Float32List rrect, int clipBehavior)
      native 'SceneBuilder_pushClipRRect';

  /// Pushes a path clip operation onto the operation stack.
  ///
  /// Rasterization outside the given path is discarded.
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack. See [Clip] for different clip modes.
  /// By default, the clip will be anti-aliased (clip = [Clip.antiAlias]).
  ClipPathEngineLayer pushClipPath(
    Path path, {
    Clip clipBehavior = Clip.antiAlias,
    ClipPathEngineLayer oldLayer,
  }) {
    assert(clipBehavior != null);
    assert(clipBehavior != Clip.none);
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushClipPath'));
    final EngineLayer engineLayer = EngineLayer._();
    _pushClipPath(engineLayer, path, clipBehavior.index);
    final ClipPathEngineLayer layer = ClipPathEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  void _pushClipPath(EngineLayer layer, Path path, int clipBehavior) native 'SceneBuilder_pushClipPath';

  /// Pushes an opacity operation onto the operation stack.
  ///
  /// The given alpha value is blended into the alpha value of the objects'
  /// rasterization. An alpha value of 0 makes the objects entirely invisible.
  /// An alpha value of 255 has no effect (i.e., the objects retain the current
  /// opacity).
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack.
  OpacityEngineLayer pushOpacity(
    int alpha, {
    Offset offset = Offset.zero,
    OpacityEngineLayer oldLayer,
  }) {
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushOpacity'));
    final EngineLayer engineLayer = EngineLayer._();
    _pushOpacity(engineLayer, alpha, offset.dx, offset.dy);
    final OpacityEngineLayer layer = OpacityEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  void _pushOpacity(EngineLayer layer, int alpha, double dx, double dy) native 'SceneBuilder_pushOpacity';

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
  ColorFilterEngineLayer pushColorFilter(
    ColorFilter filter, {
    ColorFilterEngineLayer oldLayer,
  }) {
    assert(filter != null);
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushColorFilter'));
    final _ColorFilter nativeFilter = filter._toNativeColorFilter();
    assert(nativeFilter != null);
    final EngineLayer engineLayer = EngineLayer._();
    _pushColorFilter(engineLayer, nativeFilter);
    final ColorFilterEngineLayer layer = ColorFilterEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  void _pushColorFilter(EngineLayer layer, _ColorFilter filter) native 'SceneBuilder_pushColorFilter';

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
  ImageFilterEngineLayer pushImageFilter(
    ImageFilter filter, {
    ImageFilterEngineLayer oldLayer,
  }) {
    assert(filter != null);
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushImageFilter'));
    final _ImageFilter nativeFilter = filter._toNativeImageFilter();
    assert(nativeFilter != null);
    final EngineLayer engineLayer = EngineLayer._();
    _pushImageFilter(engineLayer, nativeFilter);
    final ImageFilterEngineLayer layer = ImageFilterEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  void _pushImageFilter(EngineLayer outEngineLayer, _ImageFilter filter) native 'SceneBuilder_pushImageFilter';

  /// Pushes a backdrop filter operation onto the operation stack.
  ///
  /// The given filter is applied to the current contents of the scene prior to
  /// rasterizing the given objects.
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack.
  BackdropFilterEngineLayer pushBackdropFilter(
    ImageFilter filter, {
    BackdropFilterEngineLayer oldLayer,
  }) {
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushBackdropFilter'));
    final EngineLayer engineLayer = EngineLayer._();
    _pushBackdropFilter(engineLayer, filter._toNativeImageFilter());
    final BackdropFilterEngineLayer layer = BackdropFilterEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  void _pushBackdropFilter(EngineLayer outEngineLayer, _ImageFilter filter) native 'SceneBuilder_pushBackdropFilter';

  /// Pushes a shader mask operation onto the operation stack.
  ///
  /// The given shader is applied to the object's rasterization in the given
  /// rectangle using the given blend mode.
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack.
  ShaderMaskEngineLayer pushShaderMask(
    Shader shader,
    Rect maskRect,
    BlendMode blendMode, {
    ShaderMaskEngineLayer oldLayer,
  }) {
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushShaderMask'));
    final EngineLayer engineLayer = EngineLayer._();
    _pushShaderMask(
      engineLayer,
      shader,
      maskRect.left,
      maskRect.right,
      maskRect.top,
      maskRect.bottom,
      blendMode.index,
    );
    final ShaderMaskEngineLayer layer = ShaderMaskEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  EngineLayer _pushShaderMask(
      EngineLayer engineLayer,
      Shader shader,
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
  /// {@macro dart.ui.sceneBuilder.oldLayer}
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  ///
  /// See [pop] for details about the operation stack, and [Clip] for different clip modes.
  // ignore: deprecated_member_use
  PhysicalShapeEngineLayer pushPhysicalShape({
    Path path,
    double elevation,
    Color color,
    Color shadowColor,
    Clip clipBehavior = Clip.none,
    PhysicalShapeEngineLayer oldLayer,
  }) {
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushPhysicalShape'));
    final EngineLayer engineLayer = EngineLayer._();
    _pushPhysicalShape(
      engineLayer,
      path,
      elevation,
      color.value,
      shadowColor?.value ?? 0xFF000000,
      clipBehavior.index,
    );
    final PhysicalShapeEngineLayer layer = PhysicalShapeEngineLayer._(engineLayer);
    assert(_debugPushLayer(layer));
    return layer;
  }

  EngineLayer _pushPhysicalShape(EngineLayer outEngineLayer, Path path, double elevation, int color, int shadowColor,
      int clipBehavior) native 'SceneBuilder_pushPhysicalShape';

  /// Ends the effect of the most recently pushed operation.
  ///
  /// Internally the scene builder maintains a stack of operations. Each of the
  /// operations in the stack applies to each of the objects added to the scene.
  /// Calling this function removes the most recently added operation from the
  /// stack.
  void pop() {
    if (_layerStack.isNotEmpty) {
      _layerStack.removeLast();
    }
    _pop();
  }

  void _pop() native 'SceneBuilder_pop';

  /// Add a retained engine layer subtree from previous frames.
  ///
  /// All the engine layers that are in the subtree of the retained layer will
  /// be automatically appended to the current engine layer tree.
  ///
  /// Therefore, when implementing a subclass of the [Layer] concept defined in
  /// the rendering layer of Flutter's framework, once this is called, there's
  /// no need to call [addToScene] for its children layers.
  ///
  /// {@macro dart.ui.sceneBuilder.oldLayerVsRetained}
  void addRetained(EngineLayer retainedLayer) {
    assert(retainedLayer is _EngineLayerWrapper);
    assert(() {
      final _EngineLayerWrapper layer = retainedLayer as _EngineLayerWrapper;

      void recursivelyCheckChildrenUsedOnce(_EngineLayerWrapper parentLayer) {
        _debugCheckUsedOnce(parentLayer, 'retained layer');
        parentLayer._debugCheckNotUsedAsOldLayer();

        if (parentLayer._debugChildren == null || parentLayer._debugChildren.isEmpty) {
          return;
        }

        parentLayer._debugChildren.forEach(recursivelyCheckChildrenUsedOnce);
      }

      recursivelyCheckChildrenUsedOnce(layer);

      return true;
    }());

    final _EngineLayerWrapper wrapper = retainedLayer as _EngineLayerWrapper;
    _addRetained(wrapper._nativeLayer);
  }

  void _addRetained(EngineLayer retainedLayer) native 'SceneBuilder_addRetained';

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
  // Values above must match constants in //engine/src/sky/compositor/performance_overlay_layer.h
  void addPerformanceOverlay(int enabledOptions, Rect bounds) {
    _addPerformanceOverlay(enabledOptions, bounds.left, bounds.right, bounds.top, bounds.bottom);
  }

  void _addPerformanceOverlay(
    int enabledOptions,
    double left,
    double right,
    double top,
    double bottom,
  ) native 'SceneBuilder_addPerformanceOverlay';

  /// Adds a [Picture] to the scene.
  ///
  /// The picture is rasterized at the given offset.
  void addPicture(
    Offset offset,
    Picture picture, {
    bool isComplexHint = false,
    bool willChangeHint = false,
  }) {
    final int hints = (isComplexHint ? 1 : 0) | (willChangeHint ? 2 : 0);
    _addPicture(offset.dx, offset.dy, picture, hints);
  }

  void _addPicture(double dx, double dy, Picture picture, int hints)
      native 'SceneBuilder_addPicture';

  /// Adds a backend texture to the scene.
  ///
  /// The texture is scaled to the given size and rasterized at the given offset.
  ///
  /// If `freeze` is true the texture that is added to the scene will not
  /// be updated with new frames. `freeze` is used when resizing an embedded
  /// Android view: When resizing an Android view there is a short period during
  /// which the framework cannot tell if the newest texture frame has the
  /// previous or new size, to workaround this the framework "freezes" the
  /// texture just before resizing the Android view and un-freezes it when it is
  /// certain that a frame with the new size is ready.
  void addTexture(
    int textureId, {
    Offset offset = Offset.zero,
    double width = 0.0,
    double height = 0.0,
    bool freeze = false,
  }) {
    assert(offset != null, 'Offset argument was null');
    _addTexture(offset.dx, offset.dy, width, height, textureId, freeze);
  }

  void _addTexture(double dx, double dy, double width, double height, int textureId, bool freeze)
      native 'SceneBuilder_addTexture';

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
  void addPlatformView(
    int viewId, {
    Offset offset = Offset.zero,
    double width = 0.0,
    double height = 0.0,
  }) {
    assert(offset != null, 'Offset argument was null');
    _addPlatformView(offset.dx, offset.dy, width, height, viewId);
  }

  void _addPlatformView(double dx, double dy, double width, double height, int viewId)
      native 'SceneBuilder_addPlatformView';

  /// (Fuchsia-only) Adds a scene rendered by another application to the scene
  /// for this application.
  void addChildScene({
    Offset offset = Offset.zero,
    double width = 0.0,
    double height = 0.0,
    SceneHost sceneHost,
    bool hitTestable = true,
  }) {
    _addChildScene(offset.dx, offset.dy, width, height, sceneHost, hitTestable);
  }

  void _addChildScene(double dx, double dy, double width, double height, SceneHost sceneHost,
      bool hitTestable) native 'SceneBuilder_addChildScene';

  /// Sets a threshold after which additional debugging information should be recorded.
  ///
  /// Currently this interface is difficult to use by end-developers. If you're
  /// interested in using this feature, please contact [flutter-dev](https://groups.google.com/forum/#!forum/flutter-dev).
  /// We'll hopefully be able to figure out how to make this feature more useful
  /// to you.
  void setRasterizerTracingThreshold(int frameInterval)
      native 'SceneBuilder_setRasterizerTracingThreshold';

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
  void setCheckerboardRasterCacheImages(bool checkerboard)
      native 'SceneBuilder_setCheckerboardRasterCacheImages';

  /// Sets whether the compositor should checkerboard layers that are rendered
  /// to offscreen bitmaps.
  ///
  /// This is only useful for debugging purposes.
  void setCheckerboardOffscreenLayers(bool checkerboard)
      native 'SceneBuilder_setCheckerboardOffscreenLayers';

  /// Finishes building the scene.
  ///
  /// Returns a [Scene] containing the objects that have been added to
  /// this scene builder. The [Scene] can then be displayed on the
  /// screen with [Window.render].
  ///
  /// After calling this function, the scene builder object is invalid and
  /// cannot be used further.
  Scene build() {
    final Scene scene = Scene._();
    _build(scene);
    return scene;
  }

  void _build(Scene outScene) native 'SceneBuilder_build';
}

/// (Fuchsia-only) Hosts content provided by another application.
class SceneHost extends NativeFieldWrapperClass2 {
  /// Creates a host for a child scene's content.
  ///
  /// The ViewHolder token is bound to a ViewHolder scene graph node which acts
  /// as a container for the child's content.  The creator of the SceneHost is
  /// responsible for sending the corresponding ViewToken to the child.
  ///
  /// The ViewHolder token is a dart:zircon Handle, but that type isn't
  /// available here. This is called by ChildViewConnection in
  /// //topaz/public/dart/fuchsia_scenic_flutter/.
  ///
  /// The SceneHost takes ownership of the provided ViewHolder token.
  SceneHost(
    dynamic viewHolderToken,
    void Function() viewConnectedCallback,
    void Function() viewDisconnectedCallback,
    void Function(bool) viewStateChangedCallback,
  ) {
    _constructor(
        viewHolderToken, viewConnectedCallback, viewDisconnectedCallback, viewStateChangedCallback);
  }

  void _constructor(
    dynamic viewHolderToken,
    void Function() viewConnectedCallback,
    void Function() viewDisconnectedCallback,
    void Function(bool) viewStateChangedCallbac,
  ) native 'SceneHost_constructor';

  /// Releases the resources associated with the SceneHost.
  ///
  /// After calling this function, the SceneHost cannot be used further.
  void dispose() native 'SceneHost_dispose';

  /// Set properties on the linked scene.  These properties include its bounds,
  /// as well as whether it can be the target of focus events or not.
  void setProperties(
    double width,
    double height,
    double insetTop,
    double insetRight,
    double insetBottom,
    double insetLeft,
    bool focusable,
  ) native 'SceneHost_setProperties';
}
