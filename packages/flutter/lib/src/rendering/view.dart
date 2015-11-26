// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'debug.dart';
import 'layer.dart';
import 'object.dart';

/// The layout constraints for the root render object
class ViewConstraints {
  const ViewConstraints({
    this.size: Size.zero,
    this.orientation
  });

  /// The size of the output surface
  final Size size;

  /// The orientation of the output surface (aspirational)
  final int orientation;

  String toString() => '$size';
}

/// The root of the render tree
///
/// The view represents the total output surface of the render tree and handles
/// bootstraping the rendering pipeline. The view has a unique child
/// [RenderBox], which is required to fill the entire output surface.
class RenderView extends RenderObject with RenderObjectWithChildMixin<RenderBox> {
  RenderView({
    RenderBox child,
    this.timeForRotation: const Duration(microseconds: 83333)
  }) {
    this.child = child;
  }

  /// The amount of time the screen rotation animation should last (aspirational)
  Duration timeForRotation;

  /// The current layout size of the view
  Size get size => _size;
  Size _size = Size.zero;

  /// The current orientation of the view (aspirational)
  int get orientation => _orientation;
  int _orientation; // 0..3

  /// The constraints used for the root layout
  ViewConstraints get rootConstraints => _rootConstraints;
  ViewConstraints _rootConstraints;
  void set rootConstraints(ViewConstraints value) {
    if (rootConstraints == value)
      return;
    _rootConstraints = value;
    markNeedsLayout();
  }

  Matrix4 get _logicalToDeviceTransform {
    double devicePixelRatio = ui.window.devicePixelRatio;
    return new Matrix4.diagonal3Values(devicePixelRatio, devicePixelRatio, 1.0);
  }

  /// Bootstrap the rendering pipeline by scheduling the first frame
  void scheduleInitialFrame() {
    scheduleInitialLayout();
    scheduleInitialPaint(new TransformLayer(transform: _logicalToDeviceTransform));
    scheduler.ensureVisualUpdate();
  }

  // We never call layout() on this class, so this should never get
  // checked. (This class is laid out using scheduleInitialLayout().)
  bool debugDoesMeetConstraints() { assert(false); return false; }

  void performResize() {
    assert(false);
  }

  void performLayout() {
    if (rootConstraints.orientation != _orientation) {
      if (_orientation != null && child != null)
        child.rotate(oldAngle: _orientation, newAngle: rootConstraints.orientation, time: timeForRotation);
      _orientation = rootConstraints.orientation;
    }
    _size = rootConstraints.size;
    assert(!_size.isInfinite);

    if (child != null)
      child.layout(new BoxConstraints.tight(_size));
  }

  void rotate({ int oldAngle, int newAngle, Duration time }) {
    assert(false); // nobody tells the screen to rotate, the whole rotate() dance is started from our performResize()
  }

  bool hitTest(HitTestResult result, { Point position }) {
    if (child != null)
      child.hitTest(result, position: position);
    result.add(new HitTestEntry(this));
    return true;
  }

  bool get hasLayer => true;

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset);
  }

  /// Uploads the composited layer tree to the engine
  ///
  /// Actually causes the output of the rendering pipeline to appear on screen.
  void compositeFrame() {
    Timeline.startSync('Composite');
    try {
      final TransformLayer transformLayer = layer;
      transformLayer.transform = _logicalToDeviceTransform;
      Rect bounds = Point.origin & (size * ui.window.devicePixelRatio);
      ui.SceneBuilder builder = new ui.SceneBuilder(bounds);
      transformLayer.addToScene(builder, Offset.zero);
      assert(layer == transformLayer);
      ui.Scene scene = builder.build();
      ui.window.render(scene);
      scene.dispose();
      assert(() {
        if (debugEnableRepaintRainbox)
          debugCurrentRepaintColor = debugCurrentRepaintColor.withHue(debugCurrentRepaintColor.hue + debugRepaintRainboxHueIncrement);
        return true;
      });
    } finally {
      Timeline.finishSync();
    }
  }

  Rect get paintBounds => Point.origin & size;

  void debugDescribeSettings(List<String> settings) {
    // call to ${super.debugDescribeSettings(prefix)} is omitted because the root superclasses don't include any interesting information for this class
    settings.add('window size: ${ui.window.size} (in device pixels)');
    settings.add('device pixel ratio: ${ui.window.devicePixelRatio} (device pixels per logical pixel)');
    settings.add('root constraints: $rootConstraints (in logical pixels)');
  }
}
