// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('semantics size updates when layout size changes', () {
    // The parent won't use child's size, so child is a relayout boundary.
    // The child also sets itself as a semantic boundary.
    final child = RenderTestLayoutSemanticsBoundary();
    final parent = RenderTestParent(child: child);

    TestRenderingFlutterBinding.instance.pipelineOwner.ensureSemantics();
    layout(parent, phase: EnginePhase.flushSemantics);

    // Verify initial state
    expect(child.size, const Size(100.0, 100.0));
    expect(child.debugSemantics!.rect, const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));

    // Change size
    child.targetSize = const Size(200.0, 200.0);
    child.markNeedsLayout();

    pumpFrame(phase: EnginePhase.flushSemantics);

    // Verify updated state
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
      child!.layout(constraints.loosen());
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
