// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:vector_math/vector_math_64.dart';

import 'basic_types.dart';

export 'basic_types.dart';

/// A composited layer
///
/// During painting, the render tree generates a tree of composited layers that
/// are uploaded into the engine and displayed by the compositor. This class is
/// the base class for all composited layers.
abstract class Layer {
  Layer({ this.offset: Offset.zero });

  /// Offset from parent in the parent's coordinate system.
  Offset offset;

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
  void detach() {
    if (_parent != null)
      _parent._remove(this);
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
    newLayer._parent = _parent;
    if (_parent._firstChild == this)
      _parent._firstChild = newLayer;
    if (_parent._lastChild == this)
      _parent._lastChild = newLayer;
    _nextSibling = null;
    _previousSibling = null;
    _parent = null;
    _dispose();
  }

  void _dispose() {
  }

  /// Override this function to upload this layer to the engine
  ///
  /// The layerOffset is the accumulated offset of this layer's parent from the
  /// origin of the builder's coordinate system.
  void addToScene(ui.SceneBuilder builder, Offset layerOffset);
}

/// A composited layer containing a [Picture]
class PictureLayer extends Layer {
  PictureLayer({ Offset offset: Offset.zero, this.paintBounds })
    : super(offset: offset);

  /// The rectangle in this layer's coodinate system that bounds the recording
  ///
  /// The paint bounds are used to decide how much graphics memory to allocate
  /// when rasterizing this layer.
  Rect paintBounds;

  /// The picture recorded for this layer
  ///
  /// The picture's coodinate system matches this layer's coodinate system
  ui.Picture picture;

  void _dispose() {
    super._dispose();
    picture.dispose();
  }

  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.addPicture(offset + layerOffset, picture, paintBounds);
  }

}

/// A layer that indicates to the compositor that it should display
/// certain statistics within it
class StatisticsLayer extends Layer {
  StatisticsLayer({
    Offset offset: Offset.zero,
    this.paintBounds,
    this.optionsMask,
    this.rasterizerThreshold
  }) : super(offset: offset);

  /// The rectangle in this layer's coodinate system that bounds the recording
  Rect paintBounds;

  /// A mask specifying the statistics to display
  final int optionsMask;

  final int rasterizerThreshold;

  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    assert(optionsMask != null);
    builder.addStatistics(optionsMask, paintBounds.shift(layerOffset));
    builder.setRasterizerTracingThreshold(rasterizerThreshold);
  }

}


/// A composited layer that has a list of children
class ContainerLayer extends Layer {
  ContainerLayer({ Offset offset: Offset.zero }) : super(offset: offset);

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
    child._dispose();
  }

  /// Removes all of this layer's children from its child list
  void removeAllChildren() {
    Layer child = _firstChild;
    while (child != null) {
      Layer next = child.nextSibling;
      child._previousSibling = null;
      child._nextSibling = null;
      child._parent = null;
      child._dispose();
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
  }

  void _dispose() {
    super._dispose();
    Layer child = _firstChild;
    while (child != null) {
      Layer next = child.nextSibling;
      child._dispose();
      child = next;
    }
  }

  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    addChildrenToScene(builder, offset + layerOffset);
  }

  /// Uploads all of this layer's children to the engine
  void addChildrenToScene(ui.SceneBuilder builder, Offset layerOffset) {
    Layer child = _firstChild;
    while (child != null) {
      child.addToScene(builder, layerOffset);
      child = child.nextSibling;
    }
  }

}

/// A composite layer that clips its children using a rectangle
class ClipRectLayer extends ContainerLayer {
  ClipRectLayer({ Offset offset: Offset.zero, this.clipRect }) : super(offset: offset);

  /// The rectangle to clip in the parent's coordinate system
  Rect clipRect;
  // TODO(abarth): Why is the rectangle in the parent's coordinate system
  // instead of in the coordinate system of this layer?

  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushClipRect(clipRect.shift(layerOffset));
    addChildrenToScene(builder, offset + layerOffset);
    builder.pop();
  }

}

/// A composite layer that clips its children using a rounded rectangle
class ClipRRectLayer extends ContainerLayer {
  ClipRRectLayer({ Offset offset: Offset.zero, this.bounds, this.clipRRect }) : super(offset: offset);

  /// Unused
  Rect bounds;
  // TODO(abarth): Remove.

  /// The rounded-rect to clip in the parent's coordinate system
  ui.RRect clipRRect;
  // TODO(abarth): Why is the rounded-rect in the parent's coordinate system
  // instead of in the coordinate system of this layer?

  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushClipRRect(clipRRect.shift(layerOffset), bounds.shift(layerOffset));
    addChildrenToScene(builder, offset + layerOffset);
    builder.pop();
  }

}

/// A composite layer that clips its children using a path
class ClipPathLayer extends ContainerLayer {
  ClipPathLayer({ Offset offset: Offset.zero, this.bounds, this.clipPath }) : super(offset: offset);

  /// Unused
  Rect bounds;
  // TODO(abarth): Remove.

  /// The path to clip in the parent's coordinate system
  Path clipPath;
  // TODO(abarth): Why is the path in the parent's coordinate system instead of
  // in the coordinate system of this layer?

  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushClipPath(clipPath.shift(layerOffset), bounds.shift(layerOffset));
    addChildrenToScene(builder, offset + layerOffset);
    builder.pop();
  }

}

/// A composited layer that applies a transformation matrix to its children
class TransformLayer extends ContainerLayer {
  TransformLayer({ Offset offset: Offset.zero, this.transform }) : super(offset: offset);

  /// The matrix to apply
  Matrix4 transform;

  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    Matrix4 offsetTransform = new Matrix4.identity();
    offsetTransform.translate(offset.dx + layerOffset.dx, offset.dy + layerOffset.dy);
    builder.pushTransform((offsetTransform * transform).storage);
    addChildrenToScene(builder, Offset.zero);
    builder.pop();
  }
}

/// A composited layer that makes its children partially transparent
class OpacityLayer extends ContainerLayer {
  OpacityLayer({ Offset offset: Offset.zero, this.bounds, this.alpha }) : super(offset: offset);

  /// Unused
  Rect bounds;
  // TODO(abarth): Remove.

  /// The amount to multiply into the alpha channel
  ///
  /// The opacity is expressed as an integer from 0 to 255, where 0 is fully
  /// transparent and 255 is fully opaque.
  int alpha;

  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    builder.pushOpacity(alpha, bounds?.shift(layerOffset));
    addChildrenToScene(builder, offset + layerOffset);
    builder.pop();
  }
}
