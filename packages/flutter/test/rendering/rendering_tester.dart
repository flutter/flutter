// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart' show EnginePhase;
export 'package:flutter_test/flutter_test.dart' show EnginePhase;

class TestRenderingFlutterBinding extends BindingBase with ServicesBinding, GestureBinding, SchedulerBinding, PaintingBinding, SemanticsBinding, RendererBinding {
  EnginePhase phase = EnginePhase.composite;

  @override
  void drawFrame() {
    assert(phase != EnginePhase.build, 'rendering_tester does not support testing the build phase; use flutter_test instead');
    pipelineOwner.flushLayout();
    if (phase == EnginePhase.layout)
      return;
    pipelineOwner.flushCompositingBits();
    if (phase == EnginePhase.compositingBits)
      return;
    pipelineOwner.flushPaint();
    if (phase == EnginePhase.paint)
      return;
    renderView.compositeFrame();
    if (phase == EnginePhase.composite)
      return;
    pipelineOwner.flushSemantics();
    if (phase == EnginePhase.flushSemantics)
      return;
    assert(phase == EnginePhase.flushSemantics ||
           phase == EnginePhase.sendSemanticsUpdate);
  }
}

TestRenderingFlutterBinding _renderer;
TestRenderingFlutterBinding get renderer {
  _renderer ??= TestRenderingFlutterBinding();
  return _renderer;
}

/// Place the box in the render tree, at the given size and with the given
/// alignment on the screen.
///
/// If you've updated `box` and want to lay it out again, use [pumpFrame].
///
/// Once a particular [RenderBox] has been passed to [layout], it cannot easily
/// be put in a different place in the tree or passed to [layout] again, because
/// [layout] places the given object into another [RenderBox] which you would
/// need to unparent it from (but that box isn't itself made available).
///
/// The EnginePhase must not be [EnginePhase.build], since the rendering layer
/// has no build phase.
void layout(RenderBox box, {
  BoxConstraints constraints,
  Alignment alignment = Alignment.center,
  EnginePhase phase = EnginePhase.layout,
}) {
  assert(box != null); // If you want to just repump the last box, call pumpFrame().
  assert(box.parent == null); // We stick the box in another, so you can't reuse it easily, sorry.

  renderer.renderView.child = null;
  if (constraints != null) {
    box = RenderPositionedBox(
      alignment: alignment,
      child: RenderConstrainedBox(
        additionalConstraints: constraints,
        child: box
      )
    );
  }
  renderer.renderView.child = box;

  pumpFrame(phase: phase);
}

void pumpFrame({ EnginePhase phase = EnginePhase.layout }) {
  assert(renderer != null);
  assert(renderer.renderView != null);
  assert(renderer.renderView.child != null); // call layout() first!
  renderer.phase = phase;
  renderer.drawFrame();
}

class TestCallbackPainter extends CustomPainter {
  const TestCallbackPainter({ this.onPaint });

  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) {
    onPaint();
  }

  @override
  bool shouldRepaint(TestCallbackPainter oldPainter) => true;
}


class RenderSizedBox extends RenderBox {
  RenderSizedBox(this._size);

  final Size _size;

  @override
  double computeMinIntrinsicWidth(double height) {
    return _size.width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _size.width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _size.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _size.height;
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.constrain(_size);
  }

  @override
  void performLayout() { }

  @override
  bool hitTestSelf(Offset position) => true;
}
