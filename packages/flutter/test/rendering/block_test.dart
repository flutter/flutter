// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

class TestBlockPainter extends Painter {
  void paint(PaintingContext context, Offset offset) { }
}

void main() {
  test('overlay painters can attach and detach', () {
    TestBlockPainter first = new TestBlockPainter();
    TestBlockPainter second = new TestBlockPainter();
    RenderBlockViewport block = new RenderBlockViewport(overlayPainter: first);

    // The first painter isn't attached because we haven't attached block.
    expect(first.renderObject, isNull);
    expect(second.renderObject, isNull);

    block.overlayPainter = second;

    expect(first.renderObject, isNull);
    expect(second.renderObject, isNull);

    layout(block);

    expect(first.renderObject, isNull);
    expect(second.renderObject, equals(block));

    block.overlayPainter = first;

    expect(first.renderObject, equals(block));
    expect(second.renderObject, isNull);
  });
}
