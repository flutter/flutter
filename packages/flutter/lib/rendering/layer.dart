// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:sky' show Point, Offset, Size, Rect, Color, Paint, Path;

import 'package:vector_math/vector_math.dart';

class Layer {
  Layer({ this.bounds });

  Rect bounds;

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
}

class PictureLayer extends Layer {
  PictureLayer({ Rect bounds })
    : super(bounds: bounds);

  sky.Picture picture;
}

class ContainerLayer extends Layer {
  ContainerLayer({ Rect bounds }) : super(bounds: bounds);

  Layer _firstChild;
  Layer get firstChild => _firstChild;

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

  void remove(Layer child) {
    assert(_debugUltimatePreviousSiblingOf(child, equals: _firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: _lastChild));
    assert(child._parent == this);
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
}

class TransformLayer extends ContainerLayer {
  TransformLayer({ this.transform, Rect bounds }) : super(bounds: bounds);

  Matrix4 transform;
}

class ClipLayer extends ContainerLayer {
  ClipLayer({ Rect bounds }) : super(bounds: bounds);
}

class ColorFilterLayer extends ContainerLayer {
  ColorFilterLayer({
    Rect bounds,
    this.color,
    this.transferMode
  }) : super(bounds: bounds);

  Color color;
  sky.TransferMode transferMode;
}
