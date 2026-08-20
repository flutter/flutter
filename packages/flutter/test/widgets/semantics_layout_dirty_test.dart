// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression tests for https://github.com/flutter/flutter/issues/191188.
//
// Semantics compilation used to assert that every child reachable through
// `visitChildrenForSemantics` had already been laid out. A render object that
// skips laying its child out (but still visits it for semantics) violated that
// assumption and crashed the framework with an assertion that had no message.
// The semantics phase now skips layout-dirty children, mirroring the paint
// phase; the subtree rejoins the semantics tree once it is laid out again.

/// A render object that independently controls whether it lays its child out
/// and whether it exposes the child via [visitChildrenForSemantics].
class Gate extends SingleChildRenderObjectWidget {
  const Gate({
    super.key,
    required this.layoutChild,
    this.includeInSemantics = true,
    this.boundary = false,
    required super.child,
  });

  final bool layoutChild;
  final bool includeInSemantics;
  final bool boundary;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderGate(
    layoutChild: layoutChild,
    includeInSemantics: includeInSemantics,
    boundary: boundary,
  );

  @override
  void updateRenderObject(BuildContext context, RenderGate renderObject) {
    renderObject
      ..layoutChild = layoutChild
      ..includeInSemantics = includeInSemantics;
  }
}

class RenderGate extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderGate({required bool layoutChild, required bool includeInSemantics, required bool boundary})
    : _layoutChild = layoutChild,
      _includeInSemantics = includeInSemantics,
      _boundary = boundary;

  bool _layoutChild;
  bool _includeInSemantics;
  final bool _boundary;

  bool get layoutChild => _layoutChild;
  set layoutChild(bool value) {
    if (_layoutChild == value) {
      return;
    }
    _layoutChild = value;
    markNeedsLayout();
  }

  bool get includeInSemantics => _includeInSemantics;
  set includeInSemantics(bool value) {
    if (_includeInSemantics == value) {
      return;
    }
    _includeInSemantics = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final RenderBox? child = this.child;
    if (_layoutChild && child != null) {
      child.layout(BoxConstraints.loose(constraints.biggest), parentUsesSize: true);
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    final RenderBox? child = this.child;
    if (_includeInSemantics && child != null) {
      visitor(child);
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = _boundary;
  }

  @override
  void paint(PaintingContext context, Offset offset) {}
}

void main() {
  testWidgets('semantics does not assert when a visited child stops being laid out', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    Widget app({required bool layoutChild}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Gate(
          layoutChild: layoutChild,
          child: Semantics(container: true, child: const SizedBox(width: 100, height: 100)),
        ),
      );
    }

    // 1. Everything is laid out and part of the semantics tree.
    await tester.pumpWidget(app(layoutChild: true));
    final RenderGate gate = tester.renderObject<RenderGate>(find.byType(Gate));
    final RenderBox child = gate.child!;

    // 2. The gate stops laying its child out, and the child is marked as needing
    //    layout. Nothing lays it out again, but it is still visited by
    //    `visitChildrenForSemantics`. This used to assert.
    await tester.pumpWidget(app(layoutChild: false));
    expect(gate.layoutChild, isFalse);
    child.markNeedsLayout();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(child.debugNeedsLayout, isTrue);
    handle.dispose();
  });

  testWidgets('semantics does not assert when a layout-dirty subtree is newly admitted', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    Widget app({required bool layoutMid, required bool includeLeaf}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Gate(
          layoutChild: layoutMid,
          boundary: true,
          child: Gate(
            layoutChild: true,
            includeInSemantics: includeLeaf,
            child: Semantics(container: true, child: const SizedBox(width: 100, height: 100)),
          ),
        ),
      );
    }

    // 1. Everything is laid out; the leaf is kept out of the semantics tree.
    await tester.pumpWidget(app(layoutMid: true, includeLeaf: false));

    final List<RenderGate> gates = tester.renderObjectList<RenderGate>(find.byType(Gate)).toList();
    final RenderGate boundary = gates.first;
    final RenderGate mid = gates.last;
    final RenderBox leaf = mid.child!;

    // 2. The outer gate stops laying the middle gate out, then both the middle
    //    gate and the leaf are marked as needing layout.
    await tester.pumpWidget(app(layoutMid: false, includeLeaf: false));
    mid.markNeedsLayout();
    leaf.markNeedsLayout();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(boundary.debugNeedsLayout, isFalse);
    expect(mid.debugNeedsLayout, isTrue);
    expect(leaf.debugNeedsLayout, isTrue);

    // 3. The middle gate exposes the layout-dirty leaf to the semantics tree.
    await tester.pumpWidget(app(layoutMid: false, includeLeaf: true));
    expect(mid.includeInSemantics, isTrue);

    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
