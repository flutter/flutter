// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

class TestRenderSliverBoxChildManager extends RenderSliverBoxChildManager {
  TestRenderSliverBoxChildManager({
    this.children,
  });

  RenderSliverList _renderObject;
  List<RenderBox> children;

  RenderSliverList createRenderObject() {
    assert(_renderObject == null);
    _renderObject = new RenderSliverList(childManager: this);
    return _renderObject;
  }

  int _currentlyUpdatingChildIndex;

  @override
  void createChild(int index, { @required RenderBox after }) {
    if (index < 0 || index >= children.length)
      return null;
    try {
      _currentlyUpdatingChildIndex = index;
      _renderObject.insert(children[index], after: after);
    } finally {
      _currentlyUpdatingChildIndex = null;
    }
  }

  @override
  void removeChild(RenderBox child) {
    _renderObject.remove(child);
  }

  @override
  double estimateMaxScrollOffset(SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    assert(lastIndex >= firstIndex);
    return children.length * (trailingScrollOffset - leadingScrollOffset) / (lastIndex - firstIndex + 1);
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  @override
  void setDidUnderflow(bool value) { }
}

void main() {
  test('RenderSliverList basic test - down', () {
    RenderObject inner;
    RenderBox a, b, c, d, e;
    final TestRenderSliverBoxChildManager childManager = new TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = new RenderSizedBox(const Size(100.0, 400.0)),
        b = new RenderSizedBox(const Size(100.0, 400.0)),
        c = new RenderSizedBox(const Size(100.0, 400.0)),
        d = new RenderSizedBox(const Size(100.0, 400.0)),
        e = new RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    final RenderViewport root = new RenderViewport(
      axisDirection: AxisDirection.down,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        inner = childManager.createRenderObject(),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // make sure that layout is stable by laying out again
    inner.markNeedsLayout();
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // now try various scroll offsets
    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.attached, false);
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(e.attached, false);

    // try going back up
    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);
  });

  test('RenderSliverList basic test - up', () {
    RenderObject inner;
    RenderBox a, b, c, d, e;
    final TestRenderSliverBoxChildManager childManager = new TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = new RenderSizedBox(const Size(100.0, 400.0)),
        b = new RenderSizedBox(const Size(100.0, 400.0)),
        c = new RenderSizedBox(const Size(100.0, 400.0)),
        d = new RenderSizedBox(const Size(100.0, 400.0)),
        e = new RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    final RenderViewport root = new RenderViewport(
      axisDirection: AxisDirection.up,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        inner = childManager.createRenderObject(),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // make sure that layout is stable by laying out again
    inner.markNeedsLayout();
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // now try various scroll offsets
    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.attached, false);
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(e.attached, false);

    // try going back up
    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);
  });

  test('SliverList - no zero scroll offset correction', () {
    RenderSliverList inner;
    RenderBox a;
    final TestRenderSliverBoxChildManager childManager = new TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = new RenderSizedBox(const Size(100.0, 400.0)),
        new RenderSizedBox(const Size(100.0, 400.0)),
        new RenderSizedBox(const Size(100.0, 400.0)),
        new RenderSizedBox(const Size(100.0, 400.0)),
        new RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    final RenderViewport root = new RenderViewport(
      axisDirection: AxisDirection.down,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        inner = childManager.createRenderObject(),
      ],
    );
    layout(root);

    final SliverMultiBoxAdaptorParentData parentData = a.parentData;
    parentData.layoutOffset = 0.001;

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();

    root.offset = new ViewportOffset.fixed(0.0);
    pumpFrame();

    expect(inner.geometry.scrollOffsetCorrection, isNull);
  });
}
