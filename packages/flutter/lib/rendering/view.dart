// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/rendering/layer.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/box.dart';
import 'package:vector_math/vector_math.dart';

class ViewConstraints {
  const ViewConstraints({
    this.size: Size.zero,
    this.orientation
  });
  final Size size;
  final int orientation;
}

class RenderView extends RenderObject with RenderObjectWithChildMixin<RenderBox> {
  RenderView({
    RenderBox child,
    this.timeForRotation: const Duration(microseconds: 83333)
  }) {
    this.child = child;
  }

  Size _size = Size.zero;
  Size get size => _size;

  int _orientation; // 0..3
  int get orientation => _orientation;
  Duration timeForRotation;

  ViewConstraints _rootConstraints;
  ViewConstraints get rootConstraints => _rootConstraints;
  void set rootConstraints(ViewConstraints value) {
    if (_rootConstraints == value)
      return;
    _rootConstraints = value;
    markNeedsLayout();
  }

  ContainerLayer _rootLayer;

  // We never call layout() on this class, so this should never get
  // checked. (This class is laid out using scheduleInitialLayout().)
  bool debugDoesMeetConstraints() { assert(false); return false; }

  void performResize() {
    assert(false);
  }

  void performLayout() {
    if (_rootConstraints.orientation != _orientation) {
      if (_orientation != null && child != null)
        child.rotate(oldAngle: _orientation, newAngle: _rootConstraints.orientation, time: timeForRotation);
      _orientation = _rootConstraints.orientation;
    }
    _size = _rootConstraints.size;
    assert(!_size.isInfinite);

    if (child != null)
      child.layout(new BoxConstraints.tight(_size));
  }

  void rotate({ int oldAngle, int newAngle, Duration time }) {
    assert(false); // nobody tells the screen to rotate, the whole rotate() dance is started from our performResize()
  }

  bool hitTest(HitTestResult result, { Point position }) {
    if (child != null) {
      Rect childBounds = Point.origin & child.size;
      if (childBounds.contains(position))
        child.hitTest(result, position: position);
    }
    result.add(new HitTestEntry(this));
    return true;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset.toPoint());
  }

  void paintFrame() {
    sky.tracing.begin('RenderView.paintFrame');
    try {
      final double devicePixelRatio = sky.view.devicePixelRatio;
      Matrix4 transform = new Matrix4.diagonal3Values(devicePixelRatio, devicePixelRatio, 1.0);
      _rootLayer = new TransformLayer(transform: transform);
      PaintingContext context = new PaintingContext(Offset.zero, size);
      _rootLayer.add(context.layer);
      context.paintChild(child, Point.origin);
      context.endRecording();
    } finally {
      sky.tracing.end('RenderView.paintFrame');
    }
  }

  void compositeFrame() {
    sky.tracing.begin('RenderView.compositeFrame');
    try {
      sky.PictureRecorder recorder = new sky.PictureRecorder();
      sky.Canvas canvas = new sky.Canvas(recorder, Point.origin & (size * sky.view.devicePixelRatio));
      _rootLayer.paint(canvas);
      sky.view.picture = recorder.endRecording();
    } finally {
      sky.tracing.end('RenderView.compositeFrame');
    }
  }

  Rect get paintBounds => Point.origin & size;
}
