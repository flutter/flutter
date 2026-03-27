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

    // Verify initial state.
    expect(child.size, const Size(100.0, 100.0));
    expect(child.debugSemantics!.rect, const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));

    // Change size.
    child.targetSize = const Size(200.0, 200.0);
    child.markNeedsLayout();

    pumpFrame(phase: EnginePhase.flushSemantics);

    // Verify updated state.
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

    // Verify initial state.
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

  test('semantics size updates to zero size', () {
    final child = RenderTestLayoutSemanticsBoundary();
    child.isSemanticBoundary = true;
    final parent = RenderTestParent(child: child);
    parent.isSemanticBoundary = true;

    TestRenderingFlutterBinding.instance.pipelineOwner.ensureSemantics();
    layout(parent, phase: EnginePhase.flushSemantics);

    // Verify initial state.
    expect(child.size, const Size(100.0, 100.0));
    expect(child.debugSemantics!.rect, const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));

    // Change size.
    child.targetSize = Size.zero;
    child.markNeedsLayout();

    pumpFrame(phase: EnginePhase.flushSemantics);
  });

  test('semantics updates when child changes in RenderTestLastChildSemanticsMultiChildParent', () {
    final childOfChild = RenderTestLayoutSemanticsBoundary();
    final originalChild = RenderTestParent(child: childOfChild);
    originalChild.isSemanticBoundary = true;
    originalChild.explicitChildNode = true;

    final parent = RenderTestLastChildSemanticsMultiChildParent(
      children: <RenderBox>[originalChild],
    );
    parent.explicitChildNode = true;

    TestRenderingFlutterBinding.instance.pipelineOwner.ensureSemantics();
    // RenderTestLastChildSemanticsMultiChildParent is the parent.
    layout(parent, phase: EnginePhase.flushSemantics);

    final SemanticsNode parentSemantics = parent.debugSemantics!;

    // Initial state: exposes originalChild.
    expect(parentSemantics.childrenCount, 1);

    // Add new child.
    final newChild = RenderTestLayoutSemanticsBoundary();
    newChild.isSemanticBoundary = true;
    parent.add(newChild);

    pumpFrame(phase: EnginePhase.flushSemantics);

    // This adds originalChild to the dirty list, but shouldn't be updated.
    childOfChild.markNeedsLayout();
    pumpFrame(phase: EnginePhase.flushSemantics);

    // Remove the new child.
    parent.remove(newChild);

    pumpFrame(phase: EnginePhase.flushSemantics);

    // State after removal: exposes originalChild again.
    expect(parentSemantics.childrenCount, 1);
  });

  test('Skip update for invisible child being dropped from tree', () {
    final child = RenderTestLayoutSemanticsBoundary();
    child.isSemanticBoundary = true;
    child.targetSize = Size.zero; // Geometry will be invisible.

    final parent = RenderTestParentUsesSize(child: child);
    parent.isSemanticBoundary = true;
    parent.explicitChildNode = true;

    final grandParent = RenderTestLastChildSemanticsMultiChildParent(children: <RenderBox>[parent]);
    grandParent.explicitChildNode = true;

    TestRenderingFlutterBinding.instance.pipelineOwner.ensureSemantics();
    layout(grandParent, phase: EnginePhase.flushSemantics);

    // Initial state: grandParent visits parent (because parent is the last child).
    // parent visits child. Thus all nodes are in the semantics tree.
    expect(grandParent.debugSemantics!.childrenCount, 1);

    // To trigger the scenario, we need grandParent to drop parent,
    // explicitly marking parent and child as needing semantics update.
    parent.markNeedsLayout();
    child.markNeedsLayout();

    // Adding a new child to grandParent makes it the new `lastChild`.
    // Because grandParent only visits `lastChild` in `visitChildrenForSemantics`,
    // the original `parent` and `child` will be dropped from the semantics tree
    // without their parentDataDirty flags being cleared during the update phase.
    final newChild = RenderTestLayoutSemanticsBoundary();
    newChild.isSemanticBoundary = true;
    grandParent.add(newChild);

    pumpFrame(phase: EnginePhase.flushSemantics);
  });
}

class RenderTestParentUsesSize extends RenderTestParent {
  RenderTestParentUsesSize({super.child});

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints.loosen(), parentUsesSize: true);
    }
    size = constraints.biggest;
  }
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

class RenderTestLastChildSemanticsMultiChildParent extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TestParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TestParentData> {
  RenderTestLastChildSemanticsMultiChildParent({List<RenderBox>? children}) {
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

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (lastChild != null) {
      visitor(lastChild!);
    }
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
