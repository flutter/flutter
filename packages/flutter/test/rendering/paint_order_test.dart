// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('paint RenderObjects from top to bottom to avoid duplicated layer tree walks', () {
    // Historic Background: The order in which dirty nodes are processed for paint
    // in [PipelineOwner.flushPaint] was changed from shallowest first to
    // deepest first in August 2015, see https://github.com/flutter/flutter/commit/654fc7346eb79780aadeb9c2883ea9938d5f0bd3#diff-d06e00032e4d722205a2189ffbab26c1d8f5e13652efebc849583d0a1359fec9R612.
    // The reasons for this change are lost in history. In February 2022 it
    // was determined that deepest first actually caused additional unnecessary
    // walks of the layer tree. To avoid those, the processing order was changed
    // back to deepest first (which is also the order used by all other flush-methods on
    // PipelineOwner). The test below encodes that the framework is not doing
    // these unnecessary layer tree walks during paint that would occur during
    // deepest first processing.

    late RenderPositionedBox outer, inner;
    late TestRenderBox testBox;

    outer = RenderPositionedBox(
      child: RenderRepaintBoundary(
        child: inner = RenderPositionedBox(
          child: testBox = TestRenderBox(),
        ),
      ),
    );

    // Paint the tree for the first time; Our TestLayer is attached exactly once.
    expect((testBox.debugLayer! as TestLayer).attachCount, 0);
    expect((testBox.debugLayer! as TestLayer).detachCount, 0);
    layout(outer, phase: EnginePhase.paint);
    expect((testBox.debugLayer! as TestLayer).attachCount, 1);
    expect((testBox.debugLayer! as TestLayer).detachCount, 0);

    // Repaint RenderObjects outside and inside the RepaintBoundary.
    outer.markNeedsPaint();
    inner.markNeedsPaint();
    expect((testBox.debugLayer! as TestLayer).attachCount, 1);
    expect((testBox.debugLayer! as TestLayer).detachCount, 0);
    pumpFrame(phase: EnginePhase.paint);

    // The TestLayer should be detached and reattached exactly once during the
    // paint process. More attach/detach would indicate unnecessary
    // additional walks of the layer tree.
    expect((testBox.debugLayer! as TestLayer).attachCount, 2);
    expect((testBox.debugLayer! as TestLayer).detachCount, 1);
  });
}

class TestRenderBox extends RenderProxyBoxWithHitTestBehavior {
  TestRenderBox() {
    layer = TestLayer();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.addLayer(layer!);
  }
}

class TestLayer extends OffsetLayer {
  int attachCount = 0;
  int detachCount = 0;

  @override
  void attach(Object owner) {
    super.attach(owner);
    attachCount++;
  }

  @override
  void detach() {
    super.detach();
    detachCount++;
  }
}
