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
    child.isSemanticBoundary = true;
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

  test('semantics blocksemantics corner case', () {
    final child = RenderTestLayoutSemanticsBoundary();
    final middle1 = RenderTestParent(child: child);
    middle1.isSemanticBoundary = true;
    middle1.explicitChildNode = true;
    final middle2 = RenderTestParent(child: middle1);
    final parent = RenderTestMultiChildParent(children: [middle2]);
    parent.explicitChildNode = true;

    TestRenderingFlutterBinding.instance.pipelineOwner.ensureSemantics();
    layout(parent, phase: EnginePhase.flushSemantics);

    // Verify initial state
    expect(child.size, const Size(100.0, 100.0));
    expect(child.debugSemantics!.rect, const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
    middle1.markNeedsLayout();
    middle2.markNeedsLayout();
    child.markNeedsLayout();

    final child2 = RenderBlockSemanticsBoundary();
    parent.add(child2);
    pumpFrame(phase: EnginePhase.flushSemantics);

    middle1.markNeedsLayout();
    child.markNeedsLayout();
    pumpFrame(phase: EnginePhase.flushSemantics);
    // Does not crash.
  });
}

class RenderTestParent extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderTestParent({RenderBox? child}) {
    this.child = child;
  }
  bool isSemanticBoundary = false;
  bool explicitChildNode = false;

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

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.explicitChildNodes = explicitChildNode;
    config.isSemanticBoundary = isSemanticBoundary;
    config.label = 'Test Parent';
    config.textDirection = TextDirection.ltr;
  }
}

class TestParentData extends ContainerBoxParentData<RenderBox> {}

class RenderTestMultiChildParent extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TestParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TestParentData> {
  RenderTestMultiChildParent({List<RenderBox>? children}) {
    if (children != null) {
      addAll(children);
    }
  }

  bool explicitChildNode = false;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TestParentData) {
      child.parentData = TestParentData();
    }
  }

  @override
  void performLayout() {
    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(constraints.loosen());
      child = childAfter(child);
    }
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.explicitChildNodes = explicitChildNode;
    config.label = 'Test Parent';
    config.textDirection = TextDirection.ltr;
  }
}

class RenderTestLayoutSemanticsBoundary extends RenderBox {
  Size targetSize = const Size(100.0, 100.0);

  bool isSemanticBoundary = false;

  @override
  void performLayout() {
    size = constraints.constrain(targetSize);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = isSemanticBoundary;
    config.label = 'Test Node';
    config.textDirection = TextDirection.ltr;
  }
}

class RenderBlockSemanticsBoundary extends RenderBox {
  @override
  void performLayout() {
    size = constraints.constrain(const Size(100, 100));
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.isBlockingSemanticsOfPreviouslyPaintedNodes = true;
    config.label = 'Test Node2';
    config.textDirection = TextDirection.ltr;
  }
}
