// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

import 'rendering_tester.dart';

class RenderFixedSize extends RenderBox {
  double dimension = 100.0;

  void grow() {
    dimension *= 2.0;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => dimension;
  @override
  double computeMaxIntrinsicWidth(double height) => dimension;
  @override
  double computeMinIntrinsicHeight(double width) => dimension;
  @override
  double computeMaxIntrinsicHeight(double width) => dimension;

  @override
  void performLayout() {
    size = Size.square(dimension);
  }
}

class RenderParentSize extends RenderProxyBox {
  RenderParentSize({ RenderBox child }) : super(child);

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    child.layout(constraints);
  }
}

class RenderIntrinsicSize extends RenderProxyBox {
  RenderIntrinsicSize({ RenderBox child }) : super(child);

  @override
  void performLayout() {
    child.layout(constraints);
    size = Size(
      child.getMinIntrinsicWidth(double.infinity),
      child.getMinIntrinsicHeight(double.infinity),
    );
  }
}

void main() {
  test('Whether using intrinsics means you get hooked into layout', () {
    RenderBox root;
    RenderFixedSize inner;
    layout(
      root = RenderIntrinsicSize(
        child: RenderParentSize(
          child: inner = RenderFixedSize()
        )
      ),
      constraints: const BoxConstraints(
        minWidth: 0.0,
        minHeight: 0.0,
        maxWidth: 1000.0,
        maxHeight: 1000.0,
      ),
    );
    expect(root.size, equals(inner.size));

    inner.grow();
    pumpFrame();
    expect(root.size, equals(inner.size));
  });
}
