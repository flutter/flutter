// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:sky' show Point, Offset, Size, Rect, Color, Paint, Path;

import 'package:vector_math/vector_math.dart';

abstract class Layer {
  Layer({ this.offset: Offset.zero });

  Offset offset; // From parent, in parent's coordinate system.

  ContainerLayer _parent;
  ContainerLayer get parent => _parent;

  Layer _nextSibling;
  Layer get nextSibling => _nextSibling;

  Layer _previousSibling;
  Layer get previousSibling => _previousSibling;

  void detach() {
    if (_parent != null)
      _parent.remove(this);
  }
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
  }

  void addToScene(sky.SceneBuilder builder, Offset layerOffset);
}

class PictureLayer extends Layer {
  PictureLayer({ Offset offset: Offset.zero, this.paintBounds })
    : super(offset: offset);

  Rect paintBounds;
  sky.Picture picture;

  void addToScene(sky.SceneBuilder builder, Offset layerOffset) {
    builder.addPicture(offset + layerOffset, picture, paintBounds);
  }

}

class ContainerLayer extends Layer {
  ContainerLayer({ Offset offset: Offset.zero }) : super(offset: offset);

  // TODO(ianh): hide firstChild since nobody uses it
  Layer _firstChild;
  Layer get firstChild => _firstChild;

  // TODO(ianh): remove _lastChild since nobody uses it
  Layer _lastChild;
  Layer get lastChild => _lastChild;

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

  // TODO(ianh): Remove 'before' and rename the function to 'append' since nobody uses 'before'
  void add(Layer child, { Layer before }) {
    assert(child != this);
    assert(before != this);
    assert(child != before);
    assert(child != _firstChild);
    assert(child != _lastChild);
    assert(child._parent == null);
    assert(child._nextSibling == null);
    assert(child._previousSibling == null);
    child._parent = this;
    if (before == null) {
      child._previousSibling = _lastChild;
      if (_lastChild != null)
        _lastChild._nextSibling = child;
      _lastChild = child;
      if (_firstChild == null)
        _firstChild = child;
    } else {
      assert(_firstChild != null);
      assert(_lastChild != null);
      assert(_debugUltimatePreviousSiblingOf(before, equals: _firstChild));
      assert(_debugUltimateNextSiblingOf(before, equals: _lastChild));
      if (before._previousSibling == null) {
        assert(before == _firstChild);
        child._nextSibling = before;
        before._previousSibling = child;
        _firstChild = child;
      } else {
        child._previousSibling = before._previousSibling;
        child._nextSibling = before;
        child._previousSibling._nextSibling = child;
        child._nextSibling._previousSibling = child;
        assert(before._previousSibling == child);
      }
    }
  }

  // TODO(ianh): Hide this function since only detach() uses it
  void remove(Layer child) {
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

  void removeAllChildren() {
    Layer child = _firstChild;
    while (child != null) {
      Layer next = child.nextSibling;
      child._previousSibling = null;
      child._nextSibling = null;
      child._parent = null;
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
  }

  void addToScene(sky.SceneBuilder builder, Offset layerOffset) {
    addChildrenToScene(builder, offset + layerOffset);
  }

  void addChildrenToScene(sky.SceneBuilder builder, Offset layerOffset) {
    Layer child = firstChild;
    while (child != null) {
      child.addToScene(builder, layerOffset);
      child = child.nextSibling;
    }
  }

}

class ClipRectLayer extends ContainerLayer {
  ClipRectLayer({ Offset offset: Offset.zero, this.clipRect }) : super(offset: offset);

  // clipRect is _not_ affected by given offset
  Rect clipRect;

  void addToScene(sky.SceneBuilder builder, Offset layerOffset) {
    builder.pushClipRect(clipRect.shift(layerOffset));
    addChildrenToScene(builder, offset + layerOffset);
    builder.pop();
  }

}

class ClipRRectLayer extends ContainerLayer {
  ClipRRectLayer({ Offset offset: Offset.zero, this.bounds, this.clipRRect }) : super(offset: offset);

  // bounds and clipRRect are _not_ affected by given offset
  Rect bounds;
  sky.RRect clipRRect;

  void addToScene(sky.SceneBuilder builder, Offset layerOffset) {
    builder.pushClipRRect(clipRRect.shift(layerOffset), bounds.shift(layerOffset));
    addChildrenToScene(builder, offset + layerOffset);
    builder.pop();
  }

}

class ClipPathLayer extends ContainerLayer {
  ClipPathLayer({ Offset offset: Offset.zero, this.bounds, this.clipPath }) : super(offset: offset);

  // bounds and clipPath are _not_ affected by given offset
  Rect bounds;
  Path clipPath;

  void addToScene(sky.SceneBuilder builder, Offset layerOffset) {
    builder.pushClipPath(clipPath.shift(layerOffset), bounds.shift(layerOffset));
    addChildrenToScene(builder, offset + layerOffset);
    builder.pop();
  }

}

class TransformLayer extends ContainerLayer {
  TransformLayer({ Offset offset: Offset.zero, this.transform }) : super(offset: offset);

  Matrix4 transform;

  void addToScene(sky.SceneBuilder builder, Offset layerOffset) {
    Matrix4 offsetTransform = new Matrix4.identity();
    offsetTransform.translate(offset.dx + layerOffset.dx, offset.dy + layerOffset.dy);
    builder.pushTransform((offsetTransform * transform).storage);
    addChildrenToScene(builder, Offset.zero);
    builder.pop();
  }
}

class OpacityLayer extends ContainerLayer {
  OpacityLayer({ Offset offset: Offset.zero, this.bounds, this.alpha }) : super(offset: offset);

  // bounds is _not_ affected by given offset
  Rect bounds;
  int alpha;

  void addToScene(sky.SceneBuilder builder, Offset layerOffset) {
    builder.pushOpacity(alpha, bounds == null ? null : bounds.shift(layerOffset));
    addChildrenToScene(builder, offset + layerOffset);
    builder.pop();
  }
}

class ColorFilterLayer extends ContainerLayer {
  ColorFilterLayer({
    Offset offset: Offset.zero,
    this.bounds,
    this.color,
    this.transferMode
  }) : super(offset: offset);

  // bounds is _not_ affected by given offset
  Rect bounds;
  Color color;
  sky.TransferMode transferMode;

  void addToScene(sky.SceneBuilder builder, Offset layerOffset) {
    builder.pushColorFilter(color, transferMode, bounds.shift(offset));
    addChildrenToScene(builder, offset + layerOffset);
    builder.pop();
  }
}
