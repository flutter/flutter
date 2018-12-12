// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui show EngineLayer, Image, ImageFilter, Picture, Scene, SceneBuilder;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

import 'debug.dart';

/// A composited layer.
///
/// During painting, the render tree generates a tree of composited layers that
/// are uploaded into the engine and displayed by the compositor. This class is
/// the base class for all composited layers.
///
/// Most layers can have their properties mutated, and layers can be moved to
/// different parents. The scene must be explicitly recomposited after such
/// changes are made; the layer tree does not maintain its own dirty state.
///
/// To composite the tree, create a [SceneBuilder] object, pass it to the
/// root [Layer] object's [addToScene] method, and then call
/// [SceneBuilder.build] to obtain a [Scene]. A [Scene] can then be painted
/// using [Window.render].
///
/// See also:
///
///  * [RenderView.compositeFrame], which implements this recomposition protocol
///    for painting [RenderObject] trees on the display.
abstract class Layer extends AbstractNode with DiagnosticableTreeMixin {
  /// This layer's parent in the layer tree.
  ///
  /// The [parent] of the root node in the layer tree is null.
  ///
  /// Only subclasses of [ContainerLayer] can have children in the layer tree.
  /// All other layer classes are used for leaves in the layer tree.
  @override
  ContainerLayer get parent => super.parent;

  // Whether this layer has any changes since its last call to [addToScene].
  //
  // Initialized to true as a new layer has never called [addToScene].
  bool _needsAddToScene = true;

  /// Mark that this layer has changed and [addToScene] needs to be called.
  @protected
  void markNeedsAddToScene() {
    _needsAddToScene = true;
  }

  /// Mark that this layer is in sync with engine.
  ///
  /// This is only for debug and test purpose only.
  @visibleForTesting
  void debugMarkClean() {
    assert((){
      _needsAddToScene = false;
      return true;
    }());
  }

  /// Subclasses may override this to true to disable retained rendering.
  @protected
  bool get alwaysNeedsAddToScene => false;

  bool _subtreeNeedsAddToScene;

  /// Whether any layer in the subtree needs [addToScene].
  ///
  /// This is for debug and test purpose only. It only becomes valid after
  /// calling [updateSubtreeNeedsAddToScene].
  @visibleForTesting
  bool get debugSubtreeNeedsAddToScene {
    bool result;
    assert((){
      result = _subtreeNeedsAddToScene;
      return true;
    }());
    return result;
  }

  ui.EngineLayer _engineLayer;

  /// Traverse the layer tree and compute if any subtree needs [addToScene].
  ///
  /// A subtree needs [addToScene] if any of its layer needs [addToScene].
  /// The [ContainerLayer] will override this to respect its children.
  @protected
  void updateSubtreeNeedsAddToScene() {
    _subtreeNeedsAddToScene = _needsAddToScene || alwaysNeedsAddToScene;
  }

  /// This layer's next sibling in the parent layer's child list.
  Layer get nextSibling => _nextSibling;
  Layer _nextSibling;

  /// This layer's previous sibling in the parent layer's child list.
  Layer get previousSibling => _previousSibling;
  Layer _previousSibling;

  @override
  void dropChild(AbstractNode child) {
    markNeedsAddToScene();
    super.dropChild(child);
  }

  @override
  void adoptChild(AbstractNode child) {
    markNeedsAddToScene();
    super.adoptChild(child);
  }

  /// Removes this layer from its parent layer's child list.
  ///
  /// This has no effect if the layer's parent is already null.
  @mustCallSuper
  void remove() {
    parent?._removeChild(this);
  }

  /// Replaces this layer with the given layer in the parent layer's child list.
  void replaceWith(Layer newLayer) {
    assert(parent != null);
    assert(attached == parent.attached);
    assert(newLayer.parent == null);
    assert(newLayer._nextSibling == null);
    assert(newLayer._previousSibling == null);
    assert(!newLayer.attached);
    newLayer._nextSibling = nextSibling;
    if (_nextSibling != null)
      _nextSibling._previousSibling = newLayer;
    newLayer._previousSibling = previousSibling;
    if (_previousSibling != null)
      _previousSibling._nextSibling = newLayer;
    assert(() {
      Layer node = this;
      while (node.parent != null)
        node = node.parent;
      assert(node != newLayer); // indicates we are about to create a cycle
      return true;
    }());
    parent.adoptChild(newLayer);
    assert(newLayer.attached == parent.attached);
    if (parent.firstChild == this)
      parent._firstChild = newLayer;
    if (parent.lastChild == this)
      parent._lastChild = newLayer;
    _nextSibling = null;
    _previousSibling = null;
    parent.dropChild(this);
    assert(!attached);
  }

  /// Returns the value of [S] that corresponds to the point described by
  /// [regionOffset].
  ///
  /// Returns null if no matching region is found.
  ///
  /// The main way for a value to be assigned here is by pushing an
  /// [AnnotatedRegionLayer] into the layer tree.
  ///
  /// See also:
  ///
  ///   * [AnnotatedRegionLayer], for placing values in the layer tree.
  S find<S>(Offset regionOffset);

  /// Override this method to upload this layer to the engine.
  ///
  /// Return the engine layer for retained rendering. When there's no
  /// corresponding engine layer, null is returned.
  @protected
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]);

  void _addToSceneWithRetainedRendering(ui.SceneBuilder builder) {
    // There can't be a loop by adding a retained layer subtree whose
    // _subtreeNeedsAddToScene is false.
    //
    // Proof by contradiction:
    //
    // If we introduce a loop, this retained layer must be appended to one of
    // its descendent layers, say A. That means the child structure of A has
    // changed so A's _needsAddToScene is true. This contradicts
    // _subtreeNeedsAddToScene being false.
    if (!_subtreeNeedsAddToScene && _engineLayer != null) {
      builder.addRetained(_engineLayer);
      return;
    }
    _engineLayer = addToScene(builder);
    _needsAddToScene = false;
  }

  /// The object responsible for creating this layer.
  ///
  /// Defaults to the value of [RenderObject.debugCreator] for the render object
  /// that created this layer. Used in debug messages.
  dynamic debugCreator;

  @override
  String toStringShort() => '${super.toStringShort()}${ owner == null ? " DETACHED" : ""}';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('owner', owner, level: parent != null ? DiagnosticLevel.hidden : DiagnosticLevel.info, defaultValue: null));
    properties.add(DiagnosticsProperty<dynamic>('creator', debugCreator, defaultValue: null, level: DiagnosticLevel.debug));
  }
}

/// A composited layer containing a [Picture].
///
/// Picture layers are always leaves in the layer tree.
class PictureLayer extends Layer {
  /// Creates a leaf layer for the layer tree.
  PictureLayer(this.canvasBounds);

  /// The bounds that were used for the canvas that drew this layer's [picture].
  ///
  /// This is purely advisory. It is included in the information dumped with
  /// [debugDumpLayerTree] (which can be triggered by pressing "L" when using
  /// "flutter run" at the console), which can help debug why certain drawing
  /// commands are being culled.
  final Rect canvasBounds;

  /// The picture recorded for this layer.
  ///
  /// The picture's coordinate system matches this layer's coordinate system.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ui.Picture get picture => _picture;
  ui.Picture _picture;
  set picture(ui.Picture picture) {
    _needsAddToScene = true;
    _picture = picture;
  }

  /// Hints that the painting in this layer is complex and would benefit from
  /// caching.
  ///
  /// If this hint is not set, the compositor will apply its own heuristics to
  /// decide whether the this layer is complex enough to benefit from caching.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  bool get isComplexHint => _isComplexHint;
  bool _isComplexHint = false;
  set isComplexHint(bool value) {
    if (value != _isComplexHint) {
      _isComplexHint = value;
      markNeedsAddToScene();
    }
  }

  /// Hints that the painting in this layer is likely to change next frame.
  ///
  /// This hint tells the compositor not to cache this layer because the cache
  /// will not be used in the future. If this hint is not set, the compositor
  /// will apply its own heuristics to decide whether this layer is likely to be
  /// reused in the future.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  bool get willChangeHint => _willChangeHint;
  bool _willChangeHint = false;
  set willChangeHint(bool value) {
    if (value != _willChangeHint) {
      _willChangeHint = value;
      markNeedsAddToScene();
    }
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    builder.addPicture(layerOffset, picture, isComplexHint: isComplexHint, willChangeHint: willChangeHint);
    return null; // this does not return an engine layer yet.
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Rect>('paint bounds', canvasBounds));
  }

  @override
  S find<S>(Offset regionOffset) => null;
}

/// A composited layer that maps a backend texture to a rectangle.
///
/// Backend textures are images that can be applied (mapped) to an area of the
/// Flutter view. They are created, managed, and updated using a
/// platform-specific texture registry. This is typically done by a plugin
/// that integrates with host platform video player, camera, or OpenGL APIs,
/// or similar image sources.
///
/// A texture layer refers to its backend texture using an integer ID. Texture
/// IDs are obtained from the texture registry and are scoped to the Flutter
/// view. Texture IDs may be reused after deregistration, at the discretion
/// of the registry. The use of texture IDs currently unknown to the registry
/// will silently result in a blank rectangle.
///
/// Once inserted into the layer tree, texture layers are repainted autonomously
/// as dictated by the backend (e.g. on arrival of a video frame). Such
/// repainting generally does not involve executing Dart code.
///
/// Texture layers are always leaves in the layer tree.
///
/// See also:
///
/// * <https://docs.flutter.io/javadoc/io/flutter/view/TextureRegistry.html>
///   for how to create and manage backend textures on Android.
/// * <https://docs.flutter.io/objcdoc/Protocols/FlutterTextureRegistry.html>
///   for how to create and manage backend textures on iOS.
class TextureLayer extends Layer {
  /// Creates a texture layer bounded by [rect] and with backend texture
  /// identified by [textureId], if [freeze] is true new texture frames will not be
  /// populated to the texture.
  TextureLayer({
    @required this.rect,
    @required this.textureId,
    this.freeze = false,
  }): assert(rect != null), assert(textureId != null);

  /// Bounding rectangle of this layer.
  final Rect rect;

  /// The identity of the backend texture.
  final int textureId;

  /// When true the texture that will not be updated with new frames.
  ///
  /// This is used when resizing an embedded  Android views: When resizing
  /// there is a short period during which the framework cannot tell
  /// if the newest texture frame has the previous or new size, to workaround this
  /// the framework "freezes" the texture just before resizing the Android view and unfreezes
  /// it when it is certain that a frame with the new size is ready.
  final bool freeze;

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    final Rect shiftedRect = rect.shift(layerOffset);
    builder.addTexture(
      textureId,
      offset: shiftedRect.topLeft,
      width: shiftedRect.width,
      height: shiftedRect.height,
      freeze: freeze,
    );
    return null; // this does not return an engine layer yet.
  }

  @override
  S find<S>(Offset regionOffset) => null;
}

/// A layer that shows an embedded [UIView](https://developer.apple.com/documentation/uikit/uiview)
/// on iOS.
class PlatformViewLayer extends Layer {
  /// Creates a platform view layer.
  ///
  /// The `rect` and `viewId` parameters must not be null.
  PlatformViewLayer({
    @required this.rect,
    @required this.viewId,
  }): assert(rect != null), assert(viewId != null);

  /// Bounding rectangle of this layer in the global coordinate space.
  final Rect rect;

  /// The unique identifier of the UIView displayed on this layer.
  ///
  /// A UIView with this identifier must have been created by [PlatformViewsServices.initUiKitView].
  final int viewId;

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    final Rect shiftedRect = rect.shift(layerOffset);
    builder.addPlatformView(
      viewId,
      offset: shiftedRect.topLeft,
      width: shiftedRect.width,
      height: shiftedRect.height,
    );
    return null;
  }

  @override
  S find<S>(Offset regionOffset) => null;
}

/// A layer that indicates to the compositor that it should display
/// certain performance statistics within it.
///
/// Performance overlay layers are always leaves in the layer tree.
class PerformanceOverlayLayer extends Layer {
  /// Creates a layer that displays a performance overlay.
  PerformanceOverlayLayer({
    @required Rect overlayRect,
    @required this.optionsMask,
    @required this.rasterizerThreshold,
    @required this.checkerboardRasterCacheImages,
    @required this.checkerboardOffscreenLayers,
  }) : _overlayRect = overlayRect;

  /// The rectangle in this layer's coordinate system that the overlay should occupy.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  Rect get overlayRect => _overlayRect;
  Rect _overlayRect;
  set overlayRect(Rect value) {
    if (value != _overlayRect) {
      _overlayRect = value;
      markNeedsAddToScene();
    }
  }

  /// The mask is created by shifting 1 by the index of the specific
  /// [PerformanceOverlayOption] to enable.
  final int optionsMask;

  /// The rasterizer threshold is an integer specifying the number of frame
  /// intervals that the rasterizer must miss before it decides that the frame
  /// is suitable for capturing an SkPicture trace for further analysis.
  final int rasterizerThreshold;

  /// Whether the raster cache should checkerboard cached entries.
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
  final bool checkerboardRasterCacheImages;

  /// Whether the compositor should checkerboard layers that are rendered to offscreen
  /// bitmaps. This can be useful for debugging rendering performance.
  ///
  /// Render target switches are caused by using opacity layers (via a [FadeTransition] or
  /// [Opacity] widget), clips, shader mask layers, etc. Selecting a new render target
  /// and merging it with the rest of the scene has a performance cost. This can sometimes
  /// be avoided by using equivalent widgets that do not require these layers (for example,
  /// replacing an [Opacity] widget with an [widgets.Image] using a [BlendMode]).
  final bool checkerboardOffscreenLayers;

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(optionsMask != null);
    builder.addPerformanceOverlay(optionsMask, overlayRect.shift(layerOffset));
    builder.setRasterizerTracingThreshold(rasterizerThreshold);
    builder.setCheckerboardRasterCacheImages(checkerboardRasterCacheImages);
    builder.setCheckerboardOffscreenLayers(checkerboardOffscreenLayers);
    return null; // this does not return an engine layer yet.
  }

  @override
  S find<S>(Offset regionOffset) => null;
}

/// A composited layer that has a list of children.
///
/// A [ContainerLayer] instance merely takes a list of children and inserts them
/// into the composited rendering in order. There are subclasses of
/// [ContainerLayer] which apply more elaborate effects in the process.
class ContainerLayer extends Layer {
  /// The first composited layer in this layer's child list.
  Layer get firstChild => _firstChild;
  Layer _firstChild;

  /// The last composited layer in this layer's child list.
  Layer get lastChild => _lastChild;
  Layer _lastChild;

  bool _debugUltimatePreviousSiblingOf(Layer child, { Layer equals }) {
    assert(child.attached == attached);
    while (child.previousSibling != null) {
      assert(child.previousSibling != child);
      child = child.previousSibling;
      assert(child.attached == attached);
    }
    return child == equals;
  }

  bool _debugUltimateNextSiblingOf(Layer child, { Layer equals }) {
    assert(child.attached == attached);
    while (child._nextSibling != null) {
      assert(child._nextSibling != child);
      child = child._nextSibling;
      assert(child.attached == attached);
    }
    return child == equals;
  }

  @override
  void updateSubtreeNeedsAddToScene() {
    super.updateSubtreeNeedsAddToScene();
    Layer child = firstChild;
    while (child != null) {
      child.updateSubtreeNeedsAddToScene();
      _subtreeNeedsAddToScene = _subtreeNeedsAddToScene || child._subtreeNeedsAddToScene;
      child = child.nextSibling;
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    Layer current = lastChild;
    while (current != null) {
      final Object value = current.find<S>(regionOffset);
      if (value != null) {
        return value;
      }
      current = current.previousSibling;
    }
    return null;
  }

  @override
  void attach(Object owner) {
    super.attach(owner);
    Layer child = firstChild;
    while (child != null) {
      child.attach(owner);
      child = child.nextSibling;
    }
  }

  @override
  void detach() {
    super.detach();
    Layer child = firstChild;
    while (child != null) {
      child.detach();
      child = child.nextSibling;
    }
  }

  /// Adds the given layer to the end of this layer's child list.
  void append(Layer child) {
    assert(child != this);
    assert(child != firstChild);
    assert(child != lastChild);
    assert(child.parent == null);
    assert(!child.attached);
    assert(child.nextSibling == null);
    assert(child.previousSibling == null);
    assert(() {
      Layer node = this;
      while (node.parent != null)
        node = node.parent;
      assert(node != child); // indicates we are about to create a cycle
      return true;
    }());
    adoptChild(child);
    child._previousSibling = lastChild;
    if (lastChild != null)
      lastChild._nextSibling = child;
    _lastChild = child;
    _firstChild ??= child;
    assert(child.attached == attached);
  }

  // Implementation of [Layer.remove].
  void _removeChild(Layer child) {
    assert(child.parent == this);
    assert(child.attached == attached);
    assert(_debugUltimatePreviousSiblingOf(child, equals: firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: lastChild));
    if (child._previousSibling == null) {
      assert(_firstChild == child);
      _firstChild = child._nextSibling;
    } else {
      child._previousSibling._nextSibling = child.nextSibling;
    }
    if (child._nextSibling == null) {
      assert(lastChild == child);
      _lastChild = child.previousSibling;
    } else {
      child.nextSibling._previousSibling = child.previousSibling;
    }
    assert((firstChild == null) == (lastChild == null));
    assert(firstChild == null || firstChild.attached == attached);
    assert(lastChild == null || lastChild.attached == attached);
    assert(firstChild == null || _debugUltimateNextSiblingOf(firstChild, equals: lastChild));
    assert(lastChild == null || _debugUltimatePreviousSiblingOf(lastChild, equals: firstChild));
    child._previousSibling = null;
    child._nextSibling = null;
    dropChild(child);
    assert(!child.attached);
  }

  /// Removes all of this layer's children from its child list.
  void removeAllChildren() {
    Layer child = firstChild;
    while (child != null) {
      final Layer next = child.nextSibling;
      child._previousSibling = null;
      child._nextSibling = null;
      assert(child.attached == attached);
      dropChild(child);
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    addChildrenToScene(builder, layerOffset);
    return null; // ContainerLayer does not have a corresponding engine layer
  }

  /// Uploads all of this layer's children to the engine.
  ///
  /// This method is typically used by [addToScene] to insert the children into
  /// the scene. Subclasses of [ContainerLayer] typically override [addToScene]
  /// to apply effects to the scene using the [SceneBuilder] API, then insert
  /// their children using [addChildrenToScene], then reverse the aforementioned
  /// effects before returning from [addToScene].
  void addChildrenToScene(ui.SceneBuilder builder, [Offset childOffset = Offset.zero]) {
    Layer child = firstChild;
    while (child != null) {
      if (childOffset == Offset.zero) {
        child._addToSceneWithRetainedRendering(builder);
      } else {
        child.addToScene(builder, childOffset);
      }
      child = child.nextSibling;
    }
  }

  /// Applies the transform that would be applied when compositing the given
  /// child to the given matrix.
  ///
  /// Specifically, this should apply the transform that is applied to child's
  /// _origin_. When using [applyTransform] with a chain of layers, results will
  /// be unreliable unless the deepest layer in the chain collapses the
  /// `layerOffset` in [addToScene] to zero, meaning that it passes
  /// [Offset.zero] to its children, and bakes any incoming `layerOffset` into
  /// the [SceneBuilder] as (for instance) a transform (which is then also
  /// included in the transformation applied by [applyTransform]).
  ///
  /// For example, if [addToScene] applies the `layerOffset` and then
  /// passes [Offset.zero] to the children, then it should be included in the
  /// transform applied here, whereas if [addToScene] just passes the
  /// `layerOffset` to the child, then it should not be included in the
  /// transform applied here.
  ///
  /// This method is only valid immediately after [addToScene] has been called,
  /// before any of the properties have been changed.
  ///
  /// The default implementation does nothing, since [ContainerLayer], by
  /// default, composites its children at the origin of the [ContainerLayer]
  /// itself.
  ///
  /// The `child` argument should generally not be null, since in principle a
  /// layer could transform each child independently. However, certain layers
  /// may explicitly allow null as a value, for example if they know that they
  /// transform all their children identically.
  ///
  /// The `transform` argument must not be null.
  ///
  /// Used by [FollowerLayer] to transform its child to a [LeaderLayer]'s
  /// position.
  void applyTransform(Layer child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (firstChild == null)
      return children;
    Layer child = firstChild;
    int count = 1;
    while (true) {
      children.add(child.toDiagnosticsNode(name: 'child $count'));
      if (child == lastChild)
        break;
      count += 1;
      child = child.nextSibling;
    }
    return children;
  }
}

/// A layer that is displayed at an offset from its parent layer.
///
/// Offset layers are key to efficient repainting because they are created by
/// repaint boundaries in the [RenderObject] tree (see
/// [RenderObject.isRepaintBoundary]). When a render object that is a repaint
/// boundary is asked to paint at given offset in a [PaintingContext], the
/// render object first checks whether it needs to repaint itself. If not, it
/// reuses its existing [OffsetLayer] (and its entire subtree) by mutating its
/// [offset] property, cutting off the paint walk.
class OffsetLayer extends ContainerLayer {
  /// Creates an offset layer.
  ///
  /// By default, [offset] is zero. It must be non-null before the compositing
  /// phase of the pipeline.
  OffsetLayer({ Offset offset = Offset.zero }) : _offset = offset;

  /// Offset from parent in the parent's coordinate system.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [offset] property must be non-null before the compositing phase of the
  /// pipeline.
  Offset get offset => _offset;
  Offset _offset;
  set offset(Offset value) {
    if (value != _offset) {
      markNeedsAddToScene();
    }
    _offset = value;
  }

  @override
  S find<S>(Offset regionOffset) {
    return super.find<S>(regionOffset - offset);
  }

  @override
  void applyTransform(Layer child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
    transform.multiply(Matrix4.translationValues(offset.dx, offset.dy, 0.0));
  }

  /// Consider this layer as the root and build a scene (a tree of layers)
  /// in the engine.
  ui.Scene buildScene(ui.SceneBuilder builder) {
    updateSubtreeNeedsAddToScene();
    addToScene(builder);
    return builder.build();
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    // Skia has a fast path for concatenating scale/translation only matrices.
    // Hence pushing a translation-only transform layer should be fast. For
    // retained rendering, we don't want to push the offset down to each leaf
    // node. Otherwise, changing an offset layer on the very high level could
    // cascade the change to too many leaves.
    final ui.EngineLayer engineLayer = builder.pushOffset(layerOffset.dx + offset.dx, layerOffset.dy + offset.dy);
    addChildrenToScene(builder);
    builder.pop();
    return engineLayer;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
  }

  /// Capture an image of the current state of this layer and its children.
  ///
  /// The returned [ui.Image] has uncompressed raw RGBA bytes, will be offset
  /// by the top-left corner of [bounds], and have dimensions equal to the size
  /// of [bounds] multiplied by [pixelRatio].
  ///
  /// The [pixelRatio] describes the scale between the logical pixels and the
  /// size of the output image. It is independent of the
  /// [window.devicePixelRatio] for the device, so specifying 1.0 (the default)
  /// will give you a 1:1 mapping between logical pixels and the output pixels
  /// in the image.
  ///
  /// See also:
  ///
  ///  * [RenderRepaintBoundary.toImage] for a similar API at the render object level.
  ///  * [dart:ui.Scene.toImage] for more information about the image returned.
  Future<ui.Image> toImage(Rect bounds, {double pixelRatio = 1.0}) async {
    assert(bounds != null);
    assert(pixelRatio != null);
    final ui.SceneBuilder builder = ui.SceneBuilder();
    final Matrix4 transform = Matrix4.translationValues(
      (-bounds.left  - offset.dx) * pixelRatio,
      (-bounds.top - offset.dy) * pixelRatio,
      0.0,
    );
    transform.scale(pixelRatio, pixelRatio);
    builder.pushTransform(transform.storage);
    final ui.Scene scene = buildScene(builder);
    try {
      // Size is rounded up to the next pixel to make sure we don't clip off
      // anything.
      return await scene.toImage(
        (pixelRatio * bounds.width).ceil(),
        (pixelRatio * bounds.height).ceil(),
      );
    } finally {
      scene.dispose();
    }
  }
}

/// A composite layer that clips its children using a rectangle.
///
/// When debugging, setting [debugDisableClipLayers] to true will cause this
/// layer to be skipped (directly replaced by its children). This can be helpful
/// to track down the cause of performance problems.
class ClipRectLayer extends ContainerLayer {
  /// Creates a layer with a rectangular clip.
  ///
  /// The [clipRect] property must be non-null before the compositing phase of
  /// the pipeline.
  ClipRectLayer({ @required Rect clipRect, Clip clipBehavior = Clip.hardEdge }) :
        _clipRect = clipRect, _clipBehavior = clipBehavior,
        assert(clipBehavior != null), assert(clipBehavior != Clip.none);

  /// The rectangle to clip in the parent's coordinate system.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  Rect get clipRect => _clipRect;
  Rect _clipRect;
  set clipRect(Rect value) {
    if (value != _clipRect) {
      _clipRect = value;
      markNeedsAddToScene();
    }
  }

  /// {@template flutter.clipper.clipBehavior}
  /// Controls how to clip (default to [Clip.antiAlias]).
  ///
  /// [Clip.none] is not allowed here.
  /// {@endtemplate}
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    assert(value != null);
    assert(value != Clip.none);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsAddToScene();
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    if (!clipRect.contains(regionOffset))
      return null;
    return super.find<S>(regionOffset);
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    bool enabled = true;
    assert(() {
      enabled = !debugDisableClipLayers;
      return true;
    }());
    if (enabled)
      builder.pushClipRect(clipRect.shift(layerOffset), clipBehavior: clipBehavior);
    addChildrenToScene(builder, layerOffset);
    if (enabled)
      builder.pop();
    return null; // this does not return an engine layer yet.
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Rect>('clipRect', clipRect));
  }
}

/// A composite layer that clips its children using a rounded rectangle.
///
/// When debugging, setting [debugDisableClipLayers] to true will cause this
/// layer to be skipped (directly replaced by its children). This can be helpful
/// to track down the cause of performance problems.
class ClipRRectLayer extends ContainerLayer {
  /// Creates a layer with a rounded-rectangular clip.
  ///
  /// The [clipRRect] property must be non-null before the compositing phase of
  /// the pipeline.
  ClipRRectLayer({ @required RRect clipRRect, Clip clipBehavior = Clip.antiAlias }) :
        _clipRRect = clipRRect, _clipBehavior = clipBehavior,
        assert(clipBehavior != null), assert(clipBehavior != Clip.none);

  /// The rounded-rect to clip in the parent's coordinate system.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  RRect get clipRRect => _clipRRect;
  RRect _clipRRect;
  set clipRRect(RRect value) {
    if (value != _clipRRect) {
      _clipRRect = value;
      markNeedsAddToScene();
    }
  }

  /// {@macro flutter.clipper.clipBehavior}
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    assert(value != null);
    assert(value != Clip.none);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsAddToScene();
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    if (!clipRRect.contains(regionOffset))
      return null;
    return super.find<S>(regionOffset);
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    bool enabled = true;
    assert(() {
      enabled = !debugDisableClipLayers;
      return true;
    }());
    if (enabled)
      builder.pushClipRRect(clipRRect.shift(layerOffset), clipBehavior: clipBehavior);
    addChildrenToScene(builder, layerOffset);
    if (enabled)
      builder.pop();
    return null; // this does not return an engine layer yet.
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RRect>('clipRRect', clipRRect));
  }
}

/// A composite layer that clips its children using a path.
///
/// When debugging, setting [debugDisableClipLayers] to true will cause this
/// layer to be skipped (directly replaced by its children). This can be helpful
/// to track down the cause of performance problems.
class ClipPathLayer extends ContainerLayer {
  /// Creates a layer with a path-based clip.
  ///
  /// The [clipPath] property must be non-null before the compositing phase of
  /// the pipeline.
  ClipPathLayer({ @required Path clipPath, Clip clipBehavior = Clip.antiAlias }) :
        _clipPath = clipPath, _clipBehavior = clipBehavior,
        assert(clipBehavior != null), assert(clipBehavior != Clip.none);

  /// The path to clip in the parent's coordinate system.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  Path get clipPath => _clipPath;
  Path _clipPath;
  set clipPath(Path value) {
    if (value != _clipPath) {
      _clipPath = value;
      markNeedsAddToScene();
    }
  }

  /// {@macro flutter.clipper.clipBehavior}
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    assert(value != null);
    assert(value != Clip.none);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsAddToScene();
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    if (!clipPath.contains(regionOffset))
      return null;
    return super.find<S>(regionOffset);
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    bool enabled = true;
    assert(() {
      enabled = !debugDisableClipLayers;
      return true;
    }());
    if (enabled)
      builder.pushClipPath(clipPath.shift(layerOffset), clipBehavior: clipBehavior);
    addChildrenToScene(builder, layerOffset);
    if (enabled)
      builder.pop();
    return null; // this does not return an engine layer yet.
  }
}

/// A composited layer that applies a given transformation matrix to its
/// children.
///
/// This class inherits from [OffsetLayer] to make it one of the layers that
/// can be used at the root of a [RenderObject] hierarchy.
class TransformLayer extends OffsetLayer {
  /// Creates a transform layer.
  ///
  /// The [transform] and [offset] properties must be non-null before the
  /// compositing phase of the pipeline.
  TransformLayer({ Matrix4 transform, Offset offset = Offset.zero })
    : _transform = transform,
      super(offset: offset);

  /// The matrix to apply.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// This transform is applied before [offset], if both are set.
  ///
  /// The [transform] property must be non-null before the compositing phase of
  /// the pipeline.
  Matrix4 get transform => _transform;
  Matrix4 _transform;
  set transform(Matrix4 value) {
    if (value == _transform)
      return;
    _transform = value;
    _inverseDirty = true;
  }

  Matrix4 _lastEffectiveTransform;
  Matrix4 _invertedTransform;
  bool _inverseDirty = true;

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    _lastEffectiveTransform = transform;
    final Offset totalOffset = offset + layerOffset;
    if (totalOffset != Offset.zero) {
      _lastEffectiveTransform = Matrix4.translationValues(totalOffset.dx, totalOffset.dy, 0.0)
        ..multiply(_lastEffectiveTransform);
    }
    builder.pushTransform(_lastEffectiveTransform.storage);
    addChildrenToScene(builder);
    builder.pop();
    return null; // this does not return an engine layer yet.
  }

  @override
  S find<S>(Offset regionOffset) {
    if (_inverseDirty) {
      _invertedTransform = Matrix4.tryInvert(transform);
      _inverseDirty = false;
    }
    if (_invertedTransform == null)
      return null;
    final Vector4 vector = Vector4(regionOffset.dx, regionOffset.dy, 0.0, 1.0);
    final Vector4 result = _invertedTransform.transform(vector);
    return super.find<S>(Offset(result[0], result[1]));
  }

  @override
  void applyTransform(Layer child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
    transform.multiply(_lastEffectiveTransform);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(TransformProperty('transform', transform));
  }
}

/// A composited layer that makes its children partially transparent.
///
/// When debugging, setting [debugDisableOpacityLayers] to true will cause this
/// layer to be skipped (directly replaced by its children). This can be helpful
/// to track down the cause of performance problems.
class OpacityLayer extends ContainerLayer {
  /// Creates an opacity layer.
  ///
  /// The [alpha] property must be non-null before the compositing phase of
  /// the pipeline.
  OpacityLayer({ @required int alpha, Offset offset = Offset.zero })
      : _alpha = alpha, _offset = offset;

  /// The amount to multiply into the alpha channel.
  ///
  /// The opacity is expressed as an integer from 0 to 255, where 0 is fully
  /// transparent and 255 is fully opaque.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  int get alpha => _alpha;
  int _alpha;
  set alpha(int value) {
    if (value != _alpha) {
      _alpha = value;
      markNeedsAddToScene();
    }
  }

  /// Offset from parent in the parent's coordinate system.
  Offset get offset => _offset;
  Offset _offset;
  set offset(Offset value) {
    if (value != _offset) {
      _offset = value;
      markNeedsAddToScene();
    }
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    bool enabled = true;
    assert(() {
      enabled = !debugDisableOpacityLayers;
      return true;
    }());
    if (enabled)
      builder.pushOpacity(alpha, offset: offset + layerOffset);
    addChildrenToScene(builder);
    if (enabled)
      builder.pop();
    return null; // this does not return an engine layer yet.
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('alpha', alpha));
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
  }
}

/// A composited layer that applies a shader to its children.
class ShaderMaskLayer extends ContainerLayer {
  /// Creates a shader mask layer.
  ///
  /// The [shader], [maskRect], and [blendMode] properties must be non-null
  /// before the compositing phase of the pipeline.
  ShaderMaskLayer({ @required Shader shader, @required Rect maskRect, @required BlendMode blendMode })
      : _shader = shader, _maskRect = maskRect, _blendMode = blendMode;

  /// The shader to apply to the children.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  Shader get shader => _shader;
  Shader _shader;
  set shader(Shader value) {
    if (value != _shader) {
      _shader = value;
      markNeedsAddToScene();
    }
  }

  /// The size of the shader.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  Rect get maskRect => _maskRect;
  Rect _maskRect;
  set maskRect(Rect value) {
    if (value != _maskRect) {
      _maskRect = value;
      markNeedsAddToScene();
    }
  }

  /// The blend mode to apply when blending the shader with the children.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  BlendMode get blendMode => _blendMode;
  BlendMode _blendMode;
  set blendMode(BlendMode value) {
    if (value != _blendMode) {
      _blendMode = value;
      markNeedsAddToScene();
    }
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    builder.pushShaderMask(shader, maskRect.shift(layerOffset), blendMode);
    addChildrenToScene(builder, layerOffset);
    builder.pop();
    return null; // this does not return an engine layer yet.
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Shader>('shader', shader));
    properties.add(DiagnosticsProperty<Rect>('maskRect', maskRect));
    properties.add(DiagnosticsProperty<BlendMode>('blendMode', blendMode));
  }
}

/// A composited layer that applies a filter to the existing contents of the scene.
class BackdropFilterLayer extends ContainerLayer {
  /// Creates a backdrop filter layer.
  ///
  /// The [filter] property must be non-null before the compositing phase of the
  /// pipeline.
  BackdropFilterLayer({ @required ui.ImageFilter filter }) : _filter = filter;

  /// The filter to apply to the existing contents of the scene.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ui.ImageFilter get filter => _filter;
  ui.ImageFilter _filter;
  set filter(ui.ImageFilter value) {
    if (value != _filter) {
      _filter = value;
      markNeedsAddToScene();
    }
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    builder.pushBackdropFilter(filter);
    addChildrenToScene(builder, layerOffset);
    builder.pop();
    return null; // this does not return an engine layer yet.
  }
}

/// A composited layer that uses a physical model to producing lighting effects.
///
/// For example, the layer casts a shadow according to its geometry and the
/// relative position of lights and other physically modelled objects in the
/// scene.
///
/// When debugging, setting [debugDisablePhysicalShapeLayers] to true will cause this
/// layer to be skipped (directly replaced by its children). This can be helpful
/// to track down the cause of performance problems.
class PhysicalModelLayer extends ContainerLayer {
  /// Creates a composited layer that uses a physical model to producing
  /// lighting effects.
  ///
  /// The [clipPath], [elevation], and [color] arguments must not be null.
  PhysicalModelLayer({
    @required Path clipPath,
    Clip clipBehavior = Clip.none,
    @required double elevation,
    @required Color color,
    @required Color shadowColor,
  }) : assert(clipPath != null),
       assert(clipBehavior != null),
       assert(elevation != null),
       assert(color != null),
       assert(shadowColor != null),
       _clipPath = clipPath,
       _clipBehavior = clipBehavior,
       _elevation = elevation,
       _color = color,
       _shadowColor = shadowColor;

  /// The path to clip in the parent's coordinate system.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  Path get clipPath => _clipPath;
  Path _clipPath;
  set clipPath(Path value) {
    if (value != _clipPath) {
      _clipPath = value;
      markNeedsAddToScene();
    }
  }

  /// {@macro flutter.widgets.Clip}
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsAddToScene();
    }
  }

  /// The z-coordinate at which to place this physical object.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// In tests, the [debugDisableShadows] flag is set to true by default.
  /// Several widgets and render objects force all elevations to zero when this
  /// flag is set. For this reason, this property will often be set to zero in
  /// tests even if the layer should be raised. To verify the actual value,
  /// consider setting [debugDisableShadows] to false in your test.
  double get elevation => _elevation;
  double _elevation;
  set elevation(double value) {
    if (value != _elevation) {
      _elevation = value;
      markNeedsAddToScene();
    }
  }

  /// The background color.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value != _color) {
      _color = value;
      markNeedsAddToScene();
    }
  }

  /// The shadow color.
  Color get shadowColor => _shadowColor;
  Color _shadowColor;
  set shadowColor(Color value) {
    if (value != _shadowColor) {
      _shadowColor = value;
      markNeedsAddToScene();
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    if (!clipPath.contains(regionOffset))
      return null;
    return super.find<S>(regionOffset);
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    ui.EngineLayer engineLayer;
    bool enabled = true;
    assert(() {
      enabled = !debugDisablePhysicalShapeLayers;
      return true;
    }());
    if (enabled) {
      engineLayer = builder.pushPhysicalShape(
        path: clipPath.shift(layerOffset),
        elevation: elevation,
        color: color,
        shadowColor: shadowColor,
        clipBehavior: clipBehavior,
      );
    }
    addChildrenToScene(builder, layerOffset);
    if (enabled)
      builder.pop();
    return engineLayer;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(DiagnosticsProperty<Color>('color', color));
  }
}

/// An object that a [LeaderLayer] can register with.
///
/// An instance of this class should be provided as the [LeaderLayer.link] and
/// the [FollowerLayer.link] properties to cause the [FollowerLayer] to follow
/// the [LeaderLayer].
///
/// See also:
///
///  * [CompositedTransformTarget], the widget that creates a [LeaderLayer].
///  * [CompositedTransformFollower], the widget that creates a [FollowerLayer].
///  * [RenderLeaderLayer] and [RenderFollowerLayer], the corresponding
///    render objects.
class LayerLink {
  /// The currently-registered [LeaderLayer], if any.
  LeaderLayer get leader => _leader;
  LeaderLayer _leader;

  @override
  String toString() => '${describeIdentity(this)}(${ _leader != null ? "<linked>" : "<dangling>" })';
}

/// A composited layer that can be followed by a [FollowerLayer].
///
/// This layer collapses the accumulated offset into a transform and passes
/// [Offset.zero] to its child layers in the [addToScene]/[addChildrenToScene]
/// methods, so that [applyTransform] will work reliably.
class LeaderLayer extends ContainerLayer {
  /// Creates a leader layer.
  ///
  /// The [link] property must not be null, and must not have been provided to
  /// any other [LeaderLayer] layers that are [attached] to the layer tree at
  /// the same time.
  ///
  /// The [offset] property must be non-null before the compositing phase of the
  /// pipeline.
  LeaderLayer({ @required this.link, this.offset = Offset.zero }) : assert(link != null);

  /// The object with which this layer should register.
  ///
  /// The link will be established when this layer is [attach]ed, and will be
  /// cleared when this layer is [detach]ed.
  final LayerLink link;

  /// Offset from parent in the parent's coordinate system.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [offset] property must be non-null before the compositing phase of the
  /// pipeline.
  Offset offset;

  /// {@macro flutter.leaderFollower.alwaysNeedsAddToScene}
  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void attach(Object owner) {
    super.attach(owner);
    assert(link.leader == null);
    _lastOffset = null;
    link._leader = this;
  }

  @override
  void detach() {
    assert(link.leader == this);
    link._leader = null;
    _lastOffset = null;
    super.detach();
  }

  /// The offset the last time this layer was composited.
  ///
  /// This is reset to null when the layer is attached or detached, to help
  /// catch cases where the follower layer ends up before the leader layer, but
  /// not every case can be detected.
  Offset _lastOffset;

  @override
  S find<S>(Offset regionOffset) {
    return super.find<S>(regionOffset - offset);
  }

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(offset != null);
    _lastOffset = offset + layerOffset;
    if (_lastOffset != Offset.zero)
      builder.pushTransform(Matrix4.translationValues(_lastOffset.dx, _lastOffset.dy, 0.0).storage);
    addChildrenToScene(builder);
    if (_lastOffset != Offset.zero)
      builder.pop();
    return null; // this does not have an engine layer.
  }

  /// Applies the transform that would be applied when compositing the given
  /// child to the given matrix.
  ///
  /// See [ContainerLayer.applyTransform] for details.
  ///
  /// The `child` argument may be null, as the same transform is applied to all
  /// children.
  @override
  void applyTransform(Layer child, Matrix4 transform) {
    assert(_lastOffset != null);
    if (_lastOffset != Offset.zero)
      transform.translate(_lastOffset.dx, _lastOffset.dy);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
  }
}

/// A composited layer that applies a transformation matrix to its children such
/// that they are positioned to match a [LeaderLayer].
///
/// If any of the ancestors of this layer have a degenerate matrix (e.g. scaling
/// by zero), then the [FollowerLayer] will not be able to transform its child
/// to the coordinate space of the [LeaderLayer].
///
/// A [linkedOffset] property can be provided to further offset the child layer
/// from the leader layer, for example if the child is to follow the linked
/// layer at a distance rather than directly overlapping it.
class FollowerLayer extends ContainerLayer {
  /// Creates a follower layer.
  ///
  /// The [link] property must not be null.
  ///
  /// The [unlinkedOffset], [linkedOffset], and [showWhenUnlinked] properties
  /// must be non-null before the compositing phase of the pipeline.
  FollowerLayer({
    @required this.link,
    this.showWhenUnlinked = true,
    this.unlinkedOffset = Offset.zero,
    this.linkedOffset = Offset.zero,
  }) : assert(link != null);

  /// The link to the [LeaderLayer].
  ///
  /// The same object should be provided to a [LeaderLayer] that is earlier in
  /// the layer tree. When this layer is composited, it will apply a transform
  /// that moves its children to match the position of the [LeaderLayer].
  final LayerLink link;

  /// Whether to show the layer's contents when the [link] does not point to a
  /// [LeaderLayer].
  ///
  /// When the layer is linked, children layers are positioned such that they
  /// have the same global position as the linked [LeaderLayer].
  ///
  /// When the layer is not linked, then: if [showWhenUnlinked] is true,
  /// children are positioned as if the [FollowerLayer] was a [ContainerLayer];
  /// if it is false, then children are hidden.
  ///
  /// The [showWhenUnlinked] property must be non-null before the compositing
  /// phase of the pipeline.
  bool showWhenUnlinked;

  /// Offset from parent in the parent's coordinate system, used when the layer
  /// is not linked to a [LeaderLayer].
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [unlinkedOffset] property must be non-null before the compositing
  /// phase of the pipeline.
  ///
  /// See also:
  ///
  ///  * [linkedOffset], for when the layers are linked.
  Offset unlinkedOffset;

  /// Offset from the origin of the leader layer to the origin of the child
  /// layers, used when the layer is linked to a [LeaderLayer].
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [linkedOffset] property must be non-null before the compositing phase
  /// of the pipeline.
  ///
  /// See also:
  ///
  ///  * [unlinkedOffset], for when the layer is not linked.
  Offset linkedOffset;

  Offset _lastOffset;
  Matrix4 _lastTransform;
  Matrix4 _invertedTransform;
  bool _inverseDirty = true;

  @override
  S find<S>(Offset regionOffset) {
    if (link.leader == null) {
      return showWhenUnlinked ? super.find<S>(regionOffset - unlinkedOffset) : null;
    }
    if (_inverseDirty) {
      _invertedTransform = Matrix4.tryInvert(getLastTransform());
      _inverseDirty = false;
    }
    if (_invertedTransform == null)
      return null;
    final Vector4 vector = Vector4(regionOffset.dx, regionOffset.dy, 0.0, 1.0);
    final Vector4 result = _invertedTransform.transform(vector);
    return super.find<S>(Offset(result[0] - linkedOffset.dx, result[1] - linkedOffset.dy));
  }

  /// The transform that was used during the last composition phase.
  ///
  /// If the [link] was not linked to a [LeaderLayer], or if this layer has
  /// a degenerate matrix applied, then this will be null.
  ///
  /// This method returns a new [Matrix4] instance each time it is invoked.
  Matrix4 getLastTransform() {
    if (_lastTransform == null)
      return null;
    final Matrix4 result = Matrix4.translationValues(-_lastOffset.dx, -_lastOffset.dy, 0.0);
    result.multiply(_lastTransform);
    return result;
  }

  /// Call [applyTransform] for each layer in the provided list.
  ///
  /// The list is in reverse order (deepest first). The first layer will be
  /// treated as the child of the second, and so forth. The first layer in the
  /// list won't have [applyTransform] called on it. The first layer may be
  /// null.
  Matrix4 _collectTransformForLayerChain(List<ContainerLayer> layers) {
    // Initialize our result matrix.
    final Matrix4 result = Matrix4.identity();
    // Apply each layer to the matrix in turn, starting from the last layer,
    // and providing the previous layer as the child.
    for (int index = layers.length - 1; index > 0; index -= 1)
      layers[index].applyTransform(layers[index - 1], result);
    return result;
  }

  /// Populate [_lastTransform] given the current state of the tree.
  void _establishTransform() {
    assert(link != null);
    _lastTransform = null;
    // Check to see if we are linked.
    if (link.leader == null)
      return;
    // If we're linked, check the link is valid.
    assert(link.leader.owner == owner, 'Linked LeaderLayer anchor is not in the same layer tree as the FollowerLayer.');
    assert(link.leader._lastOffset != null, 'LeaderLayer anchor must come before FollowerLayer in paint order, but the reverse was true.');
    // Collect all our ancestors into a Set so we can recognize them.
    final Set<Layer> ancestors = HashSet<Layer>();
    Layer ancestor = parent;
    while (ancestor != null) {
      ancestors.add(ancestor);
      ancestor = ancestor.parent;
    }
    // Collect all the layers from a hypothetical child (null) of the target
    // layer up to the common ancestor layer.
    ContainerLayer layer = link.leader;
    final List<ContainerLayer> forwardLayers = <ContainerLayer>[null, layer];
    do {
      layer = layer.parent;
      forwardLayers.add(layer);
    } while (!ancestors.contains(layer));
    ancestor = layer;
    // Collect all the layers from this layer up to the common ancestor layer.
    layer = this;
    final List<ContainerLayer> inverseLayers = <ContainerLayer>[layer];
    do {
      layer = layer.parent;
      inverseLayers.add(layer);
    } while (layer != ancestor);
    // Establish the forward and backward matrices given these lists of layers.
    final Matrix4 forwardTransform = _collectTransformForLayerChain(forwardLayers);
    final Matrix4 inverseTransform = _collectTransformForLayerChain(inverseLayers);
    if (inverseTransform.invert() == 0.0) {
      // We are in a degenerate transform, so there's not much we can do.
      return;
    }
    // Combine the matrices and store the result.
    inverseTransform.multiply(forwardTransform);
    inverseTransform.translate(linkedOffset.dx, linkedOffset.dy);
    _lastTransform = inverseTransform;
    _inverseDirty = true;
  }

  /// {@template flutter.leaderFollower.alwaysNeedsAddToScene}
  /// This disables retained rendering for Leader/FollowerLayer.
  ///
  /// A FollowerLayer copies changes from a LeaderLayer that could be anywhere
  /// in the Layer tree, and that LeaderLayer could change without notifying the
  /// FollowerLayer. Therefore we have to always call a FollowerLayer's
  /// [addToScene]. In order to call FollowerLayer's [addToScene], LeaderLayer's
  /// [addToScene] must be called first so LeaderLayer must also be considered
  /// as [alwaysNeedsAddToScene].
  /// {@endtemplate}
  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  ui.EngineLayer addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(link != null);
    assert(showWhenUnlinked != null);
    if (link.leader == null && !showWhenUnlinked) {
      _lastTransform = null;
      _lastOffset = null;
      _inverseDirty = true;
      return null; // this does not have an engine layer.
    }
    _establishTransform();
    if (_lastTransform != null) {
      builder.pushTransform(_lastTransform.storage);
      addChildrenToScene(builder);
      builder.pop();
      _lastOffset = unlinkedOffset + layerOffset;
    } else {
      _lastOffset = null;
      final Matrix4 matrix = Matrix4.translationValues(unlinkedOffset.dx, unlinkedOffset.dy, .0);
      builder.pushTransform(matrix.storage);
      addChildrenToScene(builder);
      builder.pop();
    }
    _inverseDirty = true;
    return null; // this does not have an engine layer.
  }

  @override
  void applyTransform(Layer child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
    if (_lastTransform != null) {
      transform.multiply(_lastTransform);
    } else {
      transform.multiply(Matrix4.translationValues(unlinkedOffset.dx, unlinkedOffset.dy, .0));
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties.add(TransformProperty('transform', getLastTransform(), defaultValue: null));
  }
}

/// A composited layer which annotates its children with a value.
///
/// These values can be retrieved using [Layer.find] with a given [Offset]. If
/// a [Size] is provided to this layer, then find will check if the provided
/// offset is within the bounds of the layer.
class AnnotatedRegionLayer<T> extends ContainerLayer {
  /// Creates a new layer annotated with [value] that clips to [size] if provided.
  ///
  /// The value provided cannot be null.
  AnnotatedRegionLayer(this.value, {this.size}) : assert(value != null);

  /// The value returned by [find] if the offset is contained within this layer.
  final T value;

  /// The [size] is optionally used to clip the hit-testing of [find].
  ///
  /// If not provided, all offsets are considered to be contained within this
  /// layer, unless an ancestor layer applies a clip.
  final Size size;

  @override
  S find<S>(Offset regionOffset) {
    final S result = super.find<S>(regionOffset);
    if (result != null)
      return result;
    if (size != null && !size.contains(regionOffset))
      return null;
    if (T == S) {
      final Object untypedResult = value;
      final S typedResult = untypedResult;
      return typedResult;
    }
    return super.find<S>(regionOffset);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('value', value));
    properties.add(DiagnosticsProperty<Size>('size', size, defaultValue: null));
  }
}
