// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('RenderBox.performResize uses cached dry layout size if already computed', () async {
    // The intrinsics checker causes additional calls to computeDryLayout.
    final bool previousDebugCheckIntrinsicSizes = debugCheckIntrinsicSizes;
    debugCheckIntrinsicSizes = false;

    final RenderChild child = RenderChild();
    final RenderParent parent = RenderParent(child: child, useDryLayoutOfChild: true);
    expect(child.dryLayoutComputed, 0);
    layout(parent);
    expect(child.dryLayoutComputed, 1);

    debugCheckIntrinsicSizes = previousDebugCheckIntrinsicSizes;
  });

  test('RenderBox.performResize does not cause parent to become dirty on markNeedsLayout', () async {
    final RenderChild child = RenderChild();
    final RenderParent parent = RenderParent(child: child, useDryLayoutOfChild: false);
    layout(parent);

    parent.needsLayoutCalls = 0;
    child.markNeedsLayout();
    expect(parent.needsLayoutCalls, 0);
  });
}

class RenderParent extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderParent({ required RenderBox child, required this.useDryLayoutOfChild }) {
    this.child = child;
  }

  final bool useDryLayoutOfChild;

  @override
  void performLayout() {
    if (useDryLayoutOfChild) {
      child!.getDryLayout(constraints);
    }
    size = constraints.biggest;
    child!.layout(constraints);
  }

  int needsLayoutCalls = 0;

  @override
  void markNeedsLayout() {
    needsLayoutCalls++;
    super.markNeedsLayout();
  }
}

class RenderChild extends RenderBox {
  @override
  bool get sizedByParent => true;

  int dryLayoutComputed = 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    dryLayoutComputed++;
    return constraints.biggest;
  }
}
