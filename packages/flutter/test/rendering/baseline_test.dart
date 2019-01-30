// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

import 'rendering_tester.dart';

void main() {
  test('RenderBaseline', () {
    RenderBaseline parent;
    RenderSizedBox child;
    final RenderBox root = RenderPositionedBox(
      alignment: Alignment.topLeft,
      child: parent = RenderBaseline(
        baseline: 0.0,
        baselineType: TextBaseline.alphabetic,
        child: child = RenderSizedBox(const Size(100.0, 100.0))
      )
    );
    final BoxParentData childParentData = child.parentData;

    layout(root, phase: EnginePhase.layout);
    expect(childParentData.offset.dx, equals(0.0));
    expect(childParentData.offset.dy, equals(-100.0));
    expect(parent.size, equals(const Size(100.0, 0.0)));

    parent.baseline = 25.0;
    pumpFrame(phase: EnginePhase.layout);
    expect(childParentData.offset.dx, equals(0.0));
    expect(childParentData.offset.dy, equals(-75.0));
    expect(parent.size, equals(const Size(100.0, 25.0)));

    parent.baseline = 90.0;
    pumpFrame(phase: EnginePhase.layout);
    expect(childParentData.offset.dx, equals(0.0));
    expect(childParentData.offset.dy, equals(-10.0));
    expect(parent.size, equals(const Size(100.0, 90.0)));

    parent.baseline = 100.0;
    pumpFrame(phase: EnginePhase.layout);
    expect(childParentData.offset.dx, equals(0.0));
    expect(childParentData.offset.dy, equals(0.0));
    expect(parent.size, equals(const Size(100.0, 100.0)));

    parent.baseline = 110.0;
    pumpFrame(phase: EnginePhase.layout);
    expect(childParentData.offset.dx, equals(0.0));
    expect(childParentData.offset.dy, equals(10.0));
    expect(parent.size, equals(const Size(100.0, 110.0)));
  });
}
