// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// import 'rendering_tester.dart';

void main() {
  FlutterError.presentError = (FlutterErrorDetails details) {
    // Make tests fail on exceptions.
    throw details.exception;
  };
  // TestRenderingFlutterBinding.ensureInitialized();

  test('onNeedVisualUpdate takes precedence over manifold', () {
    final TestPipelineManifold manifold = TestPipelineManifold();

    int rootOnNeedVisualUpdateCallCount = 0;
    final TestRenderObject rootRenderObject = TestRenderObject();
    final PipelineOwner root = PipelineOwner(
        onNeedVisualUpdate: () {
          rootOnNeedVisualUpdateCallCount += 1;
        },
    );
    root.rootNode = rootRenderObject;
    rootRenderObject.scheduleInitialLayout();

    int child1OnNeedVisualUpdateCallCount = 0;
    final TestRenderObject child1RenderObject = TestRenderObject();
    final PipelineOwner child1 = PipelineOwner(
      onNeedVisualUpdate: () {
        child1OnNeedVisualUpdateCallCount += 1;
      },
    );
    child1.rootNode = child1RenderObject;
    child1RenderObject.scheduleInitialLayout();

    final TestRenderObject child2RenderObject = TestRenderObject();
    final PipelineOwner child2 = PipelineOwner();
    child2.rootNode = child2RenderObject;
    child2RenderObject.scheduleInitialLayout();

    root.adoptChild(child1);
    root.adoptChild(child2);
    root.attach(manifold);
    root.flushLayout();
    manifold.requestVisualUpdateCount = 0;

    rootRenderObject.markNeedsLayout();
    expect(manifold.requestVisualUpdateCount, 0);
    expect(rootOnNeedVisualUpdateCallCount, 1);
    expect(child1OnNeedVisualUpdateCallCount, 0);

    child1RenderObject.markNeedsLayout();
    expect(manifold.requestVisualUpdateCount, 0);
    expect(rootOnNeedVisualUpdateCallCount, 1);
    expect(child1OnNeedVisualUpdateCallCount, 1);

    child2RenderObject.markNeedsLayout();
    expect(manifold.requestVisualUpdateCount, 1);
    expect(rootOnNeedVisualUpdateCallCount, 1);
    expect(child1OnNeedVisualUpdateCallCount, 1);
  });

  test("parent's render objects are laid out before child's render objects", () {
    final TestPipelineManifold manifold = TestPipelineManifold();
    final List<String> log = <String>[];

    final TestRenderObject rootRenderObject = TestRenderObject(
      onLayout: () {
        log.add('layout parent');
      },
    );
    final PipelineOwner root = PipelineOwner();
    root.rootNode = rootRenderObject;
    rootRenderObject.scheduleInitialLayout();

    final TestRenderObject childRenderObject = TestRenderObject(
      onLayout: () {
        log.add('layout child');
      },
    );
    final PipelineOwner child = PipelineOwner();
    child.rootNode = childRenderObject;
    childRenderObject.scheduleInitialLayout();

    root.adoptChild(child);
    root.attach(manifold);
    expect(log, isEmpty);

    root.flushLayout();
    expect(log, <String>['layout parent', 'layout child']);
  });

  test("child cannot dirty parent's render object during flushLayout", () {
    final TestPipelineManifold manifold = TestPipelineManifold();

    final TestRenderObject rootRenderObject = TestRenderObject();
    final PipelineOwner root = PipelineOwner();
    root.rootNode = rootRenderObject;
    rootRenderObject.scheduleInitialLayout();

    bool childLayoutExecuted = false;
    final TestRenderObject childRenderObject = TestRenderObject(
      onLayout: () {
        childLayoutExecuted = true;
        expect(() => rootRenderObject.markNeedsLayout(), throwsFlutterError);
      },
    );
    final PipelineOwner child = PipelineOwner();
    child.rootNode = childRenderObject;
    childRenderObject.scheduleInitialLayout();

    root.adoptChild(child);
    root.attach(manifold);


    root.flushLayout();
    expect(childLayoutExecuted, isTrue);
  });

  test('updates compositing bits on children', () {
    final TestPipelineManifold manifold = TestPipelineManifold();

    final TestRenderObject rootRenderObject = TestRenderObject();
    final PipelineOwner root = PipelineOwner();
    root.rootNode = rootRenderObject;
    rootRenderObject.markNeedsCompositingBitsUpdate();

    final TestRenderObject childRenderObject = TestRenderObject();
    final PipelineOwner child = PipelineOwner();
    child.rootNode = childRenderObject;
    childRenderObject.markNeedsCompositingBitsUpdate();

    root.adoptChild(child);
    root.attach(manifold);
    expect(() => rootRenderObject.needsCompositing, throwsAssertionError);
    expect(() => childRenderObject.needsCompositing, throwsAssertionError);

    root.flushCompositingBits();
    expect(rootRenderObject.needsCompositing, isTrue);
    expect(childRenderObject.needsCompositing, isTrue);
  });

  test("parent's render objects are painted before child's render objects", () {
    final TestPipelineManifold manifold = TestPipelineManifold();
    final List<String> log = <String>[];

    final TestRenderObject rootRenderObject = TestRenderObject(
      onPaint: () {
        log.add('paint parent');
      },
    );
    final PipelineOwner root = PipelineOwner();
    root.rootNode = rootRenderObject;
    final OffsetLayer rootLayer = OffsetLayer();
    rootLayer.attach(rootRenderObject);
    rootRenderObject.scheduleInitialLayout();
    rootRenderObject.scheduleInitialPaint(rootLayer);

    final TestRenderObject childRenderObject = TestRenderObject(
      onPaint: () {
        log.add('paint child');
      },
    );
    final PipelineOwner child = PipelineOwner();
    child.rootNode = childRenderObject;
    final OffsetLayer childLayer = OffsetLayer();
    childLayer.attach(childRenderObject);
    childRenderObject.scheduleInitialLayout();
    childRenderObject.scheduleInitialPaint(childLayer);

    root.adoptChild(child);
    root.attach(manifold);
    root.flushLayout(); // Can't paint with invalid layout.
    expect(log, isEmpty);

    root.flushPaint();
    expect(log, <String>['paint parent', 'paint child']);
  });

  test("child paint cannot dirty parent's render object", () {
    final TestPipelineManifold manifold = TestPipelineManifold();

    final TestRenderObject rootRenderObject = TestRenderObject();
    final PipelineOwner root = PipelineOwner();
    root.rootNode = rootRenderObject;
    final OffsetLayer rootLayer = OffsetLayer();
    rootLayer.attach(rootRenderObject);
    rootRenderObject.scheduleInitialLayout();
    rootRenderObject.scheduleInitialPaint(rootLayer);

    bool childPaintExecuted = false;
    final TestRenderObject childRenderObject = TestRenderObject(
      onPaint: () {
        childPaintExecuted = true;
        expect(() => rootRenderObject.markNeedsPaint(), throwsAssertionError);
      },
    );
    final PipelineOwner child = PipelineOwner();
    child.rootNode = childRenderObject;
    final OffsetLayer childLayer = OffsetLayer();
    childLayer.attach(childRenderObject);
    childRenderObject.scheduleInitialLayout();
    childRenderObject.scheduleInitialPaint(childLayer);

    root.adoptChild(child);
    root.attach(manifold);
    root.flushLayout(); // Can't paint with invalid layout.
    root.flushPaint();
    expect(childPaintExecuted, isTrue);
  });

  test("parent's render objects do semantics before child's render objects", () {
    final TestPipelineManifold manifold = TestPipelineManifold()
      ..semanticsEnabled = true;
    final List<String> log = <String>[];

    final TestRenderObject rootRenderObject = TestRenderObject(
      onSemantics: () {
        log.add('semantics parent');
      },
    );
    final PipelineOwner root = PipelineOwner(
      onSemanticsOwnerCreated: () {
        rootRenderObject.scheduleInitialSemantics();
      },
      onSemanticsUpdate: (SemanticsUpdate update) { },
    );
    root.rootNode = rootRenderObject;

    final TestRenderObject childRenderObject = TestRenderObject(
      onSemantics: () {
        log.add('semantics child');
      },
    );
    final PipelineOwner child = PipelineOwner(
      onSemanticsOwnerCreated: () {
        childRenderObject.scheduleInitialSemantics();
      },
      onSemanticsUpdate: (SemanticsUpdate update) { },
    );
    child.rootNode = childRenderObject;

    root.adoptChild(child);
    root.attach(manifold);
    log.clear();

    rootRenderObject.markNeedsSemanticsUpdate();
    childRenderObject.markNeedsSemanticsUpdate();
    root.flushSemantics();
    expect(log, <String>['semantics parent', 'semantics child']);
  });

  test("child cannot mark parent's render object dirty during flushSemantics", () {
    final TestPipelineManifold manifold = TestPipelineManifold()
      ..semanticsEnabled = true;

    final TestRenderObject rootRenderObject = TestRenderObject();
    final PipelineOwner root = PipelineOwner(
      onSemanticsOwnerCreated: () {
        rootRenderObject.scheduleInitialSemantics();
      },
      onSemanticsUpdate: (SemanticsUpdate update) { },
    );
    root.rootNode = rootRenderObject;

    bool childSemanticsCalled = false;
    final TestRenderObject childRenderObject = TestRenderObject(
      onSemantics: () {
        childSemanticsCalled = true;
        rootRenderObject.markNeedsSemanticsUpdate();
      },
    );
    final PipelineOwner child = PipelineOwner(
      onSemanticsOwnerCreated: () {
        childRenderObject.scheduleInitialSemantics();
      },
      onSemanticsUpdate: (SemanticsUpdate update) { },
    );
    child.rootNode = childRenderObject;

    root.adoptChild(child);
    root.attach(manifold);
    rootRenderObject.markNeedsSemanticsUpdate();
    childRenderObject.markNeedsSemanticsUpdate();
    root.flushSemantics();

    expect(childSemanticsCalled, isTrue);
  });
}

// TODO(goderbauer): enabeling semantics
// TODO(goderbauer): tree management
// TODO(goderbauer): Can change children during own layout

class TestPipelineManifold extends ChangeNotifier implements PipelineManifold {
  int requestVisualUpdateCount = 0;

  @override
  void requestVisualUpdate() {
    requestVisualUpdateCount++;
  }

  @override
  bool get semanticsEnabled => _semanticsEnabled;
  bool _semanticsEnabled = false;
  set semanticsEnabled(bool value) {
    if (value == _semanticsEnabled) {
      return;
    }
    _semanticsEnabled = value;
    notifyListeners();
  }
}

class TestRenderObject extends RenderObject {
  TestRenderObject({this.onLayout, this.onPaint, this.onSemantics});

  final VoidCallback? onLayout;
  final VoidCallback? onPaint;
  final VoidCallback? onSemantics;

  @override
  bool get isRepaintBoundary => true;

  @override
  void debugAssertDoesMeetConstraints() { }

  @override
  Rect get paintBounds => Rect.zero;

  @override
  void performLayout() {
    onLayout?.call();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    onPaint?.call();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    onSemantics?.call();
  }

  @override
  void performResize() { }

  @override
  Rect get semanticBounds => Rect.zero;
}
