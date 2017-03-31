// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ImageFilter, Picture, SceneBuilder;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

import 'debug.dart';

/// A composited layer.
///
/// During painting, the render tree generates a tree of composited layers that
/// are uploaded into the engine and displayed by the compositor. This class is
/// the base class for all composited layers.
abstract class Layer extends Object with TreeDiagnosticsMixin {
  /// This layer's parent in the layer tree
  ContainerLayer get parent => _parent;
  ContainerLayer _parent;

  /// This layer's next sibling in the parent layer's child list
  Layer get nextSibling => _nextSibling;
  Layer _nextSibling;

  /// This layer's previous sibling in the parent layer's child list
  Layer get previousSibling => _previousSibling;
  Layer _previousSibling;

  /// Removes this layer from its parent layer's child list
  @mustCallSuper
  void detach() {
    _parent?._remove(this);
  }

  /// Replaces this layer with the given layer in the parent layer's child list
  void replaceWith(Layer newLayer) {
    assert(_parent != null);
    assert(newLayer._parent == null);
    assert(newLayer._nextSibling == null);
    assert(newLayer._previousSibling == null);
    newLayer._nextSibling = _nextSibling;
    if (_nextSibling != null)
      newLayer._nextSibling._previousSibling = newLayer;
    newLayer._previousSibling = _previousSibling;
    if (_previousSibling != null)
      newLayer._previousSibling._nextSibling = newLayer;
    assert(() {
      Layer node = this;
      while (node.parent != null)
        node = node.parent;
      assert(node != newLayer); // indicates we are about to create a cycle
      return true;
    });
    newLayer._parent = _parent;
    if (_parent._firstChild == this)
      _parent._firstChild = newLayer;
    if (_parent._lastChild == this)
      _parent._lastChild = newLayer;
    _nextSibling = null;
    _previousSibling = null;
    _parent = null;
  }

  /// Override this method to upload this layer to the engine
  ///
  /// The layerOffset is the accumulated offset of this layer's parent from the
  /// origin of the builder's coordinate system.
  void addToScene(ui.SceneBuilder builder, Offset layerOffset);

  /// The object responsible for creating this layer.
  ///
  /// Defaults to the value of [RenderObject.debugCreator] for the render object
  /// that created this layer. Used in debug messages.
  dynamic debugCreator;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (debugCreator != null)
      description.add('creator: $debugCreator');
  }
}

/// A composited layer containing a [Picture]
class PictureLayer extends Layer {
  /// The picture recorded for this layer
  ///
  /// The picture's coodinate system matches this layer's coodinate system
  ui.Picture picture;

  /// Hints that the painting in this layer is complex and would benefit from
  /// caching.
  ///
  /// If this hint is not set, the compositor will apply its own heuristics to
  /// decide whether the this layer is complex enough to benefit from caching.
  bool isComplexHint = false;

  /// Hints that the painting in this layer is likely to change next frame.
  ///
  /// This hint tells the compositor not to cache this layer because the cache
  /// will not be used in the future. If this hint is not set, the compositor
  /// will apply its own heuristics to decide whether this layer is likely to be
  /// reused in the future.
  bool willChangeHint = false;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.addPicture(layerOffset, picture, isComplexHint: isComplexHint, willChangeHint: willChangeHint);
  }
}

/// A layer that indicates to the compositor that it should display
/// certain performance statistics within it.
class PerformanceOverlayLayer extends Layer {
  /// Creates a layer that displays a performance overlay.
  PerformanceOverlayLayer({
    @required this.overlayRect,
    @required this.optionsMask,
    @required this.rasterizerThreshold,
    @required this.checkerboardRasterCacheImages,
  });

  /// The rectangle in this layer's coordinate system that the overlay should occupy.
  Rect overlayRect;

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

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    assert(optionsMask != null);
    builder.addPerformanceOverlay(optionsMask, overlayRect.shift(layerOffset));
    builder.setRasterizerTracingThreshold(rasterizerThreshold);
    builder.setCheckerboardRasterCacheImages(checkerboardRasterCacheImages);
  }
}

/// A composited layer that has a list of children
class ContainerLayer extends Layer {
  /// The first composited layer in this layer's child list
  Layer get firstChild => _firstChild;
  Layer _firstChild;

  /// The last composited layer in this layer's child list
  Layer get lastChild => _lastChild;
  Layer _lastChild;

  bool _debugUltimatePreviousSiblingOf(Layer child, { Layer equals }) {
    while (child._previousSibling != null) {
      assert(child._previousSibling != child);
      child = child._previousSibling;
    }
    return child == equals;
  }

  bool _debugUltimateNextSiblingOf(Layer child, { Layer equals }) {
    while (child._nextSibling != null) {
      assert(child._nextSibling != child);
      child = child._nextSibling;
    }
    return child == equals;
  }

  /// Adds the given layer to the end of this layer's child list
  void append(Layer child) {
    assert(child != this);
    assert(child != _firstChild);
    assert(child != _lastChild);
    assert(child._parent == null);
    assert(child._nextSibling == null);
    assert(child._previousSibling == null);
    assert(() {
      Layer node = this;
      while (node.parent != null)
        node = node.parent;
      assert(node != child); // indicates we are about to create a cycle
      return true;
    });
    child._parent = this;
    child._previousSibling = _lastChild;
    if (_lastChild != null)
      _lastChild._nextSibling = child;
    _lastChild = child;
    if (_firstChild == null)
      _firstChild = child;
  }

  void _remove(Layer child) {
    assert(child._parent == this);
    assert(_debugUltimatePreviousSiblingOf(child, equals: _firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: _lastChild));
    if (child._previousSibling == null) {
      assert(_firstChild == child);
      _firstChild = child._nextSibling;
    } else {
      child._previousSibling._nextSibling = child._nextSibling;
    }
    if (child._nextSibling == null) {
      assert(_lastChild == child);
      _lastChild = child._previousSibling;
    } else {
      child._nextSibling._previousSibling = child._previousSibling;
    }
    child._previousSibling = null;
    child._nextSibling = null;
    child._parent = null;
  }

  /// Removes all of this layer's children from its child list
  void removeAllChildren() {
    Layer child = _firstChild;
    while (child != null) {
      final Layer next = child.nextSibling;
      child._previousSibling = null;
      child._nextSibling = null;
      child._parent = null;
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
  }

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    addChildrenToScene(builder, layerOffset);
  }

  /// Uploads all of this layer's children to the engine
  void addChildrenToScene(ui.SceneBuilder builder, Offset childOffset) {
    Layer child = _firstChild;
    while (child != null) {
      child.addToScene(builder, childOffset);
      child = child.nextSibling;
    }
  }

  @override
  String debugDescribeChildren(String prefix) {
    String result = '$prefix \u2502\n';
    if (_firstChild != null) {
      Layer child = _firstChild;
      int count = 1;
      while (child != _lastChild) {
        result += '${child.toStringDeep("$prefix \u251C\u2500child $count: ", "$prefix \u2502")}';
        count += 1;
        child = child._nextSibling;
      }
      if (child != null) {
        assert(child == _lastChild);
        result += '${child.toStringDeep("$prefix \u2514\u2500child $count: ", "$prefix  ")}';
      }
    }
    return result;
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
  /// By default, [offset] is zero.
  OffsetLayer({ this.offset: Offset.zero });

  /// Offset from parent in the parent's coordinate system.
  Offset offset;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    addChildrenToScene(builder, offset + layerOffset);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('offset: $offset');
  }
}


/// A composite layer that clips its children using a rectangle
class ClipRectLayer extends ContainerLayer {
  /// Creates a layer with a rectangular clip.
  ///
  /// The [clipRect] property must be non-null before the compositing phase of
  /// the pipeline.
  ClipRectLayer({ this.clipRect });

  /// The rectangle to clip in the parent's coordinate system
  Rect clipRect;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushClipRect(clipRect.shift(layerOffset));
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('clipRect: $clipRect');
  }
}

/// A composite layer that clips its children using a rounded rectangle
class ClipRRectLayer extends ContainerLayer {
  /// Creates a layer with a rounded-rectangular clip.
  ///
  /// The [clipRRect] property must be non-null before the compositing phase of
  /// the pipeline.
  ClipRRectLayer({ this.clipRRect });

  /// The rounded-rect to clip in the parent's coordinate system
  RRect clipRRect;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushClipRRect(clipRRect.shift(layerOffset));
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('clipRRect: $clipRRect');
  }
}

/// A composite layer that clips its children using a path
class ClipPathLayer extends ContainerLayer {
  /// Creates a layer with a path-based clip.
  ///
  /// The [clipPath] property must be non-null before the compositing phase of
  /// the pipeline.
  ClipPathLayer({ this.clipPath });

  /// The path to clip in the parent's coordinate system
  Path clipPath;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushClipPath(clipPath.shift(layerOffset));
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('clipPath: $clipPath');
  }
}

/// A composited layer that applies a transformation matrix to its children
class TransformLayer extends OffsetLayer {
  /// Creates a transform layer.
  ///
  /// The [transform] property must be non-null before the compositing phase of
  /// the pipeline.
  TransformLayer({
    this.transform
  });

  /// The matrix to apply
  Matrix4 transform;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    assert(offset == Offset.zero);
    Matrix4 effectiveTransform = transform;
    if (layerOffset != Offset.zero) {
      effectiveTransform = new Matrix4.translationValues(layerOffset.dx, layerOffset.dy, 0.0)
        ..multiply(transform);
    }
    builder.pushTransform(effectiveTransform.storage);
    addChildrenToScene(builder, Offset.zero);
    builder.pop();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('transform:');
    description.addAll(debugDescribeTransform(transform));
  }
}

/// A composited layer that makes its children partially transparent
class OpacityLayer extends ContainerLayer {
  /// Creates an opacity layer.
  ///
  /// The [alpha] property must be non-null before the compositing phase of
  /// the pipeline.
  OpacityLayer({ this.alpha });

  /// The amount to multiply into the alpha channel
  ///
  /// The opacity is expressed as an integer from 0 to 255, where 0 is fully
  /// transparent and 255 is fully opaque.
  int alpha;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushOpacity(alpha);
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('alpha: $alpha');
  }
}

/// A composited layer that applies a shader to hits children.
class ShaderMaskLayer extends ContainerLayer {
  /// Creates a shader mask layer.
  ///
  /// The [shader], [maskRect], and [blendMode] properties must be non-null
  /// before the compositing phase of the pipeline.
  ShaderMaskLayer({ this.shader, this.maskRect, this.blendMode });

  /// The shader to apply to the children.
  Shader shader;

  /// The size of the shader.
  Rect maskRect;

  /// The blend mode to apply when blending the shader with the children.
  BlendMode blendMode;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushShaderMask(shader, maskRect.shift(layerOffset), blendMode);
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('shader: $shader');
    description.add('maskRect: $maskRect');
    description.add('blendMode: $blendMode');
  }
}

/// A composited layer that applies a filter to the existing contents of the scene.
class BackdropFilterLayer extends ContainerLayer {
  /// Creates a backdrop filter layer.
  ///
  /// The [filter] property must be non-null before the compositing phase of the
  /// pipeline.
  BackdropFilterLayer({ this.filter });

  /// The filter to apply to the existing contents of the scene.
  ui.ImageFilter filter;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushBackdropFilter(filter);
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }
}

/// A composited layer that uses a physical model to producing lighting effects.
///
/// For example, the layer casts a shadow according to its geometry and the
/// relative position of lights and other physically modelled objects in the
/// scene.
class PhysicalModelLayer extends ContainerLayer {
  /// Creates a composited layer that uses a physical model to producing
  /// lighting effects.
  ///
  /// The [clipRRect], [elevation], and [color] arguments must not be null.
  PhysicalModelLayer({
    @required this.clipRRect,
    @required this.elevation,
    @required this.color,
  }) {
    assert(clipRRect != null);
    assert(elevation != null);
    assert(color != null);
  }

  /// The rounded-rect to clip in the parent's coordinate system
  RRect clipRRect;

  /// The z-coordinate at which to place this physical object.
  int elevation;

  /// The background color.
  Color color;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushPhysicalModel(
      rrect: clipRRect.shift(layerOffset),
      elevation: elevation,
      color: color,
    );
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('clipRRect: $clipRRect');
  }
}
