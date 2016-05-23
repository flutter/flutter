// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

enum EnginePhase {
  layout,
  compositingBits,
  paint,
  composite,
  flushSemantics,
  sendSemanticsTree
}

class TestRenderingFlutterBinding extends BindingBase with SchedulerBinding, ServicesBinding, RendererBinding, GestureBinding {
  EnginePhase phase = EnginePhase.composite;

  @override
  void beginFrame() {
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
    if (SemanticsNode.hasListeners) {
      pipelineOwner.flushSemantics();
      if (phase == EnginePhase.flushSemantics)
        return;
      SemanticsNode.sendSemanticsTree();
    }
  }
}

TestRenderingFlutterBinding _renderer;
TestRenderingFlutterBinding get renderer => _renderer;

void layout(RenderBox box, { BoxConstraints constraints, EnginePhase phase: EnginePhase.layout }) {
  assert(box != null); // if you want to just repump the last box, call pumpFrame().

  _renderer ??= new TestRenderingFlutterBinding();

  renderer.renderView.child = null;
  if (constraints != null) {
    box = new RenderPositionedBox(
      child: new RenderConstrainedBox(
        additionalConstraints: constraints,
        child: box
      )
    );
  }
  renderer.renderView.child = box;

  pumpFrame(phase: phase);
}

void pumpFrame({ EnginePhase phase: EnginePhase.layout }) {
  assert(renderer != null);
  renderer.phase = phase;
  renderer.beginFrame();
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
  void performLayout() {
    size = constraints.constrain(_size);
  }
}
