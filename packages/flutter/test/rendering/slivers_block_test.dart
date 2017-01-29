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

  RenderSliverBlock _renderObject;
  List<RenderBox> children;

  RenderSliverBlock createRenderObject() {
    assert(_renderObject == null);
    _renderObject = new RenderSliverBlock(childManager: this);
    return _renderObject;
  }

  @override
  void createChild(int index, { @required RenderBox after }) {
    assert(index >= 0);
    if (index < 0 || index >= children.length)
      return null;
    _renderObject.insert(children[index], after: after);
  }

  @override
  void removeChild(RenderBox child) {
    _renderObject.remove(child);
  }

  @override
  double estimateScrollOffsetExtent({
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    assert(lastIndex >= firstIndex);
    return children.length * (trailingScrollOffset - leadingScrollOffset) / (lastIndex - firstIndex + 1);
  }
}

void main() {
  test('RenderSliverBlock basic test - down', () {
    RenderObject inner;
    RenderBox a, b, c, d, e;
    TestRenderSliverBoxChildManager childManager = new TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = new RenderSizedBox(const Size(100.0, 400.0)),
        b = new RenderSizedBox(const Size(100.0, 400.0)),
        c = new RenderSizedBox(const Size(100.0, 400.0)),
        d = new RenderSizedBox(const Size(100.0, 400.0)),
        e = new RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    RenderViewport2 root = new RenderViewport2(
      axisDirection: AxisDirection.down,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        inner = childManager.createRenderObject(),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 0.0));
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 400.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // make sure that layout is stable by laying out again
    inner.markNeedsLayout();
    pumpFrame();
    expect(a.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 0.0));
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 400.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // now try various scroll offsets
    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, -200.0));
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, -200.0));
    expect(c.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 200.0));
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.attached, false);
    expect(c.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, -100.0));
    expect(d.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 300.0));
    expect(e.attached, false);

    // try going back up
    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, -200.0));
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);
  });

  test('RenderSliverBlock basic test - up', () {
    RenderObject inner;
    RenderBox a, b, c, d, e;
    TestRenderSliverBoxChildManager childManager = new TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = new RenderSizedBox(const Size(100.0, 400.0)),
        b = new RenderSizedBox(const Size(100.0, 400.0)),
        c = new RenderSizedBox(const Size(100.0, 400.0)),
        d = new RenderSizedBox(const Size(100.0, 400.0)),
        e = new RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    RenderViewport2 root = new RenderViewport2(
      axisDirection: AxisDirection.up,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        inner = childManager.createRenderObject(),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 200.0));
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, -200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // make sure that layout is stable by laying out again
    inner.markNeedsLayout();
    pumpFrame();
    expect(a.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 200.0));
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, -200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // now try various scroll offsets
    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 400.0));
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 0.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 400.0));
    expect(c.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 0.0));
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.attached, false);
    expect(c.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 300.0));
    expect(d.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, -100.0));
    expect(e.attached, false);

    // try going back up
    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 400.0));
    expect(b.localToGlobal(const Point(0.0, 0.0)), const Point(0.0, 0.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);
  });

}
