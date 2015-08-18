// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:sky' show Point, Offset, Size, Rect, Color, Paint, Path;

import 'package:sky/base/debug.dart';
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

  // The paint() methods are temporary. Eventually, Layers won't have
  // a paint() method, the entire Layer hierarchy will be handed over
  // to the C++ side for processing. Until we implement that, though,
  // we instead have the layers paint themselves into a canvas at
  // paint time.
  void paint(sky.Canvas canvas);
}

class PictureLayer extends Layer {
  PictureLayer({ Offset offset: Offset.zero, this.paintBounds })
    : super(offset: offset);

  Rect paintBounds;
  sky.Picture picture;

  bool _debugPaintLayerBorder(sky.Canvas canvas) {
    if (debugPaintLayerBordersEnabled) {
      Paint border = new Paint()
        ..color = debugPaintLayerBordersColor
        ..strokeWidth = 2.0
        ..setStyle(sky.PaintingStyle.stroke);
      canvas.drawRect(paintBounds, border);
    }
    return true;
  }

  void paint(sky.Canvas canvas) {
    assert(picture != null);
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPicture(picture);
    assert(_debugPaintLayerBorder(canvas));
    canvas.translate(-offset.dx, -offset.dy);
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

  void paint(sky.Canvas canvas) {
    canvas.translate(offset.dx, offset.dy);
    paintChildren(canvas);
    canvas.translate(-offset.dx, -offset.dy);
  }

  void paintChildren(sky.Canvas canvas) {
    Layer child = firstChild;
    while (child != null) {
      child.paint(canvas);
      child = child.nextSibling;
    }
  }
}

class ClipRectLayer extends ContainerLayer {
  ClipRectLayer({ Offset offset: Offset.zero, this.clipRect }) : super(offset: offset);

  // clipRect is _not_ affected by given offset
  Rect clipRect;

  void paint(sky.Canvas canvas) {
    canvas.save();
    canvas.clipRect(clipRect);
    canvas.translate(offset.dx, offset.dy);
    paintChildren(canvas);
    canvas.restore();
  }
}

final Paint _disableAntialias = new Paint()..isAntiAlias = false;

class ClipRRectLayer extends ContainerLayer {
  ClipRRectLayer({ Offset offset: Offset.zero, this.bounds, this.clipRRect }) : super(offset: offset);

  // bounds and clipRRect are _not_ affected by given offset
  Rect bounds;
  sky.RRect clipRRect;

  void paint(sky.Canvas canvas) {
    canvas.saveLayer(bounds, _disableAntialias);
    canvas.clipRRect(clipRRect);
    canvas.translate(offset.dx, offset.dy);
    paintChildren(canvas);
    canvas.restore();
  }
}

class ClipPathLayer extends ContainerLayer {
  ClipPathLayer({ Offset offset: Offset.zero, this.bounds, this.clipPath }) : super(offset: offset);

  // bounds and clipPath are _not_ affected by given offset
  Rect bounds;
  Path clipPath;

  void paint(sky.Canvas canvas) {
    canvas.saveLayer(bounds, _disableAntialias);
    canvas.clipPath(clipPath);
    canvas.translate(offset.dx, offset.dy);
    paintChildren(canvas);
    canvas.restore();
  }
}

class TransformLayer extends ContainerLayer {
  TransformLayer({ Offset offset: Offset.zero, this.transform }) : super(offset: offset);

  Matrix4 transform;

  void paint(sky.Canvas canvas) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.concat(transform.storage);
    paintChildren(canvas);
    canvas.restore();
  }
}

class PaintLayer extends ContainerLayer {
  PaintLayer({ Offset offset: Offset.zero, this.bounds, this.paintSettings }) : super(offset: offset);

  // bounds is _not_ affected by given offset
  Rect bounds;
  Paint paintSettings; // TODO(ianh): rename this to 'paint' once paint() is gone

  void paint(sky.Canvas canvas) {
    canvas.saveLayer(bounds, paintSettings);
    canvas.translate(offset.dx, offset.dy);
    paintChildren(canvas);
    canvas.restore();
  }
}

class ColorFilterLayer extends ContainerLayer {
  ColorFilterLayer({
    Offset offset: Offset.zero,
    this.size,
    this.color,
    this.transferMode
  }) : super(offset: offset);

  Size size;
  Color color;
  sky.TransferMode transferMode;

  void paint(sky.Canvas canvas) {
    Paint paint = new Paint()
      ..color = color
      ..setTransferMode(transferMode);
    canvas.saveLayer(offset & size, paint);
    canvas.translate(offset.dx, offset.dy);
    paintChildren(canvas);
    canvas.restore();
  }
}
