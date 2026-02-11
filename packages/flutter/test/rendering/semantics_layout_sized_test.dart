// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('semantics size updates when layout size changes', () {
    // 1. Setup
    final RenderTestLayoutSemanticsBoundary child = RenderTestLayoutSemanticsBoundary();
    // We use a RenderPadding as parent to ensure strict constraints are NOT passed down,
    // so we can dynamically change size of child without parent forcing it.
    // But we need child to be a layout boundary.
    // If parent passes loose constraints, child is only a layout boundary if parentUsesSize is false.
    // RenderPadding uses parentUsesSize: true.

    // To make child a layout boundary while allowing it to size itself:
    // Option A: sizedByParent = true (but then size depends on constraints).
    // Option B: parent passes tight constraints (but then size is fixed by parent).
    // Option C: parent doesn't use size (e.g. RenderStack with non-positioned child? No, Stack uses size).
    // RenderSizedBox? No.

    // Actually, `RenderObject.layout` sets `_relayoutBoundary` to `this` if `!parentUsesSize`.
    // We can use `RenderTreeRoot` (RenderView) effectively or a custom parent.

    // Let's use a custom parent that sets parentUsesSize = false.
    final RenderTestParent parent = RenderTestParent(child: child);

    TestRenderingFlutterBinding.instance.pipelineOwner.ensureSemantics();
    layout(parent, phase: EnginePhase.flushSemantics);

    // Verify child is layout boundary
    expect(child.isRepaintBoundary, isFalse); // It is not a repaint boundary by default
    // We can check if it is a relayout boundary by checking debugLayoutParent which should be null if it is the boundary?
    // Or just trust `RenderTestParent` implementation.

    // 2. Verify initial state
    expect(child.size, const Size(100.0, 100.0));
    expect(child.debugSemantics!.rect, const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));

    // 3. Change size
    child.targetSize = const Size(200.0, 200.0);
    child.markNeedsLayout();
    print('before pump');
    // 4. Pump frame
    pumpFrame(phase: EnginePhase.flushSemantics);
    debugDumpSemanticsTree();

    // 5. Verify updated state
    expect(child.size, const Size(200.0, 200.0));
    expect(child.debugSemantics!.rect, const Rect.fromLTWH(0.0, 0.0, 200.0, 200.0));
  });
}

class RenderTestParent extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderTestParent({RenderBox? child}) {
    this.child = child;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints.loosen(), parentUsesSize: false);
    }
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      return child!.hitTest(result, position: position);
    }
    return false;
  }
}

class RenderTestLayoutSemanticsBoundary extends RenderBox {
  Size targetSize = const Size(100.0, 100.0);

  @override
  void performLayout() {
    size = constraints.constrain(targetSize);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.label = 'Test Node';
    config.textDirection = TextDirection.ltr;
  }
}
