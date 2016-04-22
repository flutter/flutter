// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:ui' as ui show Scene, SceneBuilder, window;

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'debug.dart';
import 'layer.dart';
import 'object.dart';
import 'binding.dart';

/// The layout constraints for the root render object.
class ViewConfiguration {
  const ViewConfiguration({
    this.size: Size.zero,
    this.orientation
  });

  /// The size of the output surface.
  final Size size;

  /// The orientation of the output surface (aspirational).
  final int orientation;

  @override
  String toString() => '$size';
}

/// The root of the render tree.
///
/// The view represents the total output surface of the render tree and handles
/// bootstrapping the rendering pipeline. The view has a unique child
/// [RenderBox], which is required to fill the entire output surface.
class RenderView extends RenderObject with RenderObjectWithChildMixin<RenderBox> {
  RenderView({
    RenderBox child,
    this.timeForRotation: const Duration(microseconds: 83333)
  }) {
    this.child = child;
  }

  /// The amount of time the screen rotation animation should last (aspirational).
  Duration timeForRotation;

  /// The current layout size of the view.
  Size get size => _size;
  Size _size = Size.zero;

  /// The current orientation of the view (aspirational).
  int get orientation => _orientation;
  int _orientation; // 0..3

  /// The constraints used for the root layout.
  ViewConfiguration get configuration => _configuration;
  ViewConfiguration _configuration;
  void set configuration(ViewConfiguration value) {
    if (configuration == value)
      return;
    _configuration = value;
    markNeedsLayout();
  }

  Matrix4 get _logicalToDeviceTransform {
    double devicePixelRatio = ui.window.devicePixelRatio;
    return new Matrix4.diagonal3Values(devicePixelRatio, devicePixelRatio, 1.0);
  }

  /// Bootstrap the rendering pipeline by scheduling the first frame.
  void scheduleInitialFrame() {
    scheduleInitialLayout();
    scheduleInitialPaint(new TransformLayer(transform: _logicalToDeviceTransform));
    RendererBinding.instance.ensureVisualUpdate();
  }

  // We never call layout() on this class, so this should never get
  // checked. (This class is laid out using scheduleInitialLayout().)
  @override
  void debugAssertDoesMeetConstraints() { assert(false); }

  @override
  void performResize() {
    assert(false);
  }

  @override
  void performLayout() {
    if (configuration.orientation != _orientation) {
      if (_orientation != null && child != null)
        child.rotate(oldAngle: _orientation, newAngle: configuration.orientation, time: timeForRotation);
      _orientation = configuration.orientation;
    }
    _size = configuration.size;
    assert(!_size.isInfinite);

    if (child != null)
      child.layout(new BoxConstraints.tight(_size));
  }

  @override
  void rotate({ int oldAngle, int newAngle, Duration time }) {
    assert(false); // nobody tells the screen to rotate, the whole rotate() dance is started from our performResize()
  }

  bool hitTest(HitTestResult result, { Point position }) {
    if (child != null)
      child.hitTest(result, position: position);
    result.add(new HitTestEntry(this));
    return true;
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset);
  }

  /// Uploads the composited layer tree to the engine.
  ///
  /// Actually causes the output of the rendering pipeline to appear on screen.
  void compositeFrame() {
    Timeline.startSync('Compositing');
    try {
      final TransformLayer transformLayer = layer;
      transformLayer.transform = _logicalToDeviceTransform;
      ui.SceneBuilder builder = new ui.SceneBuilder();
      transformLayer.addToScene(builder, Offset.zero);
      assert(layer == transformLayer);
      ui.Scene scene = builder.build();
      ui.window.render(scene);
      scene.dispose();
      assert(() {
        if (debugRepaintRainbowEnabled)
          debugCurrentRepaintColor = debugCurrentRepaintColor.withHue(debugCurrentRepaintColor.hue + debugRepaintRainbowHueIncrement);
        return true;
      });
    } finally {
      Timeline.finishSync();
    }
  }

  @override
  Rect get paintBounds => Point.origin & size;

  @override
  Rect get semanticBounds => Point.origin & size;

  @override
  void debugFillDescription(List<String> description) {
    // call to ${super.debugFillDescription(prefix)} is omitted because the root superclasses don't include any interesting information for this class
    description.add('window size: ${ui.window.size} (in device pixels)');
    description.add('device pixel ratio: ${ui.window.devicePixelRatio} (device pixels per logical pixel)');
    description.add('configuration: $configuration (in logical pixels)');
  }
}
