// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

class TestBlockPainter extends RenderObjectPainter {
  @override
  void paint(PaintingContext context, Offset offset) { }
}

void main() {
  test('overlay painters can attach and detach', () {
    TestBlockPainter first = new TestBlockPainter();
    TestBlockPainter second = new TestBlockPainter();
    RenderList list = new RenderList(overlayPainter: first);

    // The first painter isn't attached because we haven't attached block.
    expect(first.renderObject, isNull);
    expect(second.renderObject, isNull);

    list.overlayPainter = second;

    expect(first.renderObject, isNull);
    expect(second.renderObject, isNull);

    layout(list);

    expect(first.renderObject, isNull);
    expect(second.renderObject, equals(list));

    list.overlayPainter = first;

    expect(first.renderObject, equals(list));
    expect(second.renderObject, isNull);
  });
}
