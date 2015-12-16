// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

const Size _kTestViewSize = const Size(800.0, 600.0);

class TestRenderView extends RenderView {
  TestRenderView() {
    rootConstraints = new ViewConstraints(size: _kTestViewSize);
  }
  void scheduleInitialFrame() {
    scheduleInitialLayout();
    scheduleInitialPaint(new TransformLayer(transform: new Matrix4.identity()));
  }
}

enum EnginePhase {
  layout,
  paint,
  composite
}

class TestRenderingFlutterBinding extends BindingBase with Scheduler, Renderer, Gesturer {
  void initRenderView() {
    if (renderView == null) {
      renderView = new TestRenderView();
      renderView.scheduleInitialFrame();
    }
  }

  EnginePhase phase = EnginePhase.composite;

  void beginFrame() {
    RenderObject.flushLayout();
    if (phase == EnginePhase.layout)
      return;
    renderer.renderView.updateCompositingBits();
    RenderObject.flushPaint();
    if (phase == EnginePhase.paint)
      return;
    renderer.renderView.compositeFrame();
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

  void paint(Canvas canvas, Size size) {
    onPaint();
  }

  bool shouldRepaint(TestCallbackPainter oldPainter) => true;
}
