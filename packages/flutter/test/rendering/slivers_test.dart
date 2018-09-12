// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'rendering_tester.dart';

void main() {
  test('RenderViewport basic test - no children', () {
    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
    );
    expect(root, hasAGoodToStringDeep);
    expect(
      root.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderViewport#00000 NEEDS-LAYOUT NEEDS-PAINT DETACHED\n'
        '   parentData: MISSING\n'
        '   constraints: MISSING\n'
        '   size: MISSING\n'
        '   axisDirection: down\n'
        '   crossAxisDirection: right\n'
        '   offset: _FixedViewportOffset#00000(offset: 0.0)\n'
        '   anchor: 0.0\n'
      ),
    );
    layout(root);
    root.offset = ViewportOffset.fixed(900.0);
    expect(root, hasAGoodToStringDeep);
    expect(
      root.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderViewport#00000 NEEDS-LAYOUT NEEDS-PAINT\n'
        '   parentData: <none>\n'
        '   constraints: BoxConstraints(w=800.0, h=600.0)\n'
        '   size: Size(800.0, 600.0)\n'
        '   axisDirection: down\n'
        '   crossAxisDirection: right\n'
        '   offset: _FixedViewportOffset#00000(offset: 900.0)\n'
        '   anchor: 0.0\n',
      ),
    );

    pumpFrame();
  });

  test('RenderViewport basic test - down', () {
    RenderBox a, b, c, d, e;
    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        RenderSliverToBoxAdapter(child: a = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: b = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: c = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: d = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: e = RenderSizedBox(const Size(100.0, 400.0))),
      ],
    );
    expect(root, hasAGoodToStringDeep);
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(root, hasAGoodToStringDeep);
    expect(
      root.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderViewport#00000 NEEDS-PAINT\n'
        ' │ parentData: <none>\n'
        ' │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' │ size: Size(800.0, 600.0)\n'
        ' │ axisDirection: down\n'
        ' │ crossAxisDirection: right\n'
        ' │ offset: _FixedViewportOffset#00000(offset: 0.0)\n'
        ' │ anchor: 0.0\n'
        ' │\n'
        ' ├─center child: RenderSliverToBoxAdapter#00000 relayoutBoundary=up1 NEEDS-PAINT\n'
        ' │ │ parentData: paintOffset=Offset(0.0, 0.0) (can use size)\n'
        ' │ │ constraints: SliverConstraints(AxisDirection.down,\n'
        ' │ │   GrowthDirection.forward, ScrollDirection.idle, scrollOffset:\n'
        ' │ │   0.0, remainingPaintExtent: 600.0, crossAxisExtent: 800.0,\n'
        ' │ │   crossAxisDirection: AxisDirection.right,\n'
        ' │ │   viewportMainAxisExtent: 600.0, remainingCacheExtent: 850.0\n'
        ' │ │   cacheOrigin: 0.0 )\n'
        ' │ │ geometry: SliverGeometry(scrollExtent: 400.0, paintExtent: 400.0,\n'
        ' │ │   maxPaintExtent: 400.0, cacheExtent: 400.0)\n'
        ' │ │\n'
        ' │ └─child: RenderSizedBox#00000 NEEDS-PAINT\n'
        ' │     parentData: paintOffset=Offset(0.0, -0.0) (can use size)\n'
        ' │     constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        ' │     size: Size(800.0, 400.0)\n'
        ' │\n'
        ' ├─child 1: RenderSliverToBoxAdapter#00000 relayoutBoundary=up1 NEEDS-PAINT\n'
        ' │ │ parentData: paintOffset=Offset(0.0, 400.0) (can use size)\n'
        ' │ │ constraints: SliverConstraints(AxisDirection.down,\n'
        ' │ │   GrowthDirection.forward, ScrollDirection.idle, scrollOffset:\n'
        ' │ │   0.0, remainingPaintExtent: 200.0, crossAxisExtent: 800.0,\n'
        ' │ │   crossAxisDirection: AxisDirection.right,\n'
        ' │ │   viewportMainAxisExtent: 600.0, remainingCacheExtent: 450.0\n'
        ' │ │   cacheOrigin: 0.0 )\n'
        ' │ │ geometry: SliverGeometry(scrollExtent: 400.0, paintExtent: 200.0,\n'
        ' │ │   maxPaintExtent: 400.0, hasVisualOverflow: true, cacheExtent:\n'
        ' │ │   400.0)\n'
        ' │ │\n'
        ' │ └─child: RenderSizedBox#00000 NEEDS-PAINT\n'
        ' │     parentData: paintOffset=Offset(0.0, -0.0) (can use size)\n'
        ' │     constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        ' │     size: Size(800.0, 400.0)\n'
        ' │\n'
        ' ├─child 2: RenderSliverToBoxAdapter#00000 relayoutBoundary=up1 NEEDS-PAINT\n'
        ' │ │ parentData: paintOffset=Offset(0.0, 800.0) (can use size)\n'
        ' │ │ constraints: SliverConstraints(AxisDirection.down,\n'
        ' │ │   GrowthDirection.forward, ScrollDirection.idle, scrollOffset:\n'
        ' │ │   0.0, remainingPaintExtent: 0.0, crossAxisExtent: 800.0,\n'
        ' │ │   crossAxisDirection: AxisDirection.right,\n'
        ' │ │   viewportMainAxisExtent: 600.0, remainingCacheExtent: 50.0\n'
        ' │ │   cacheOrigin: 0.0 )\n'
        ' │ │ geometry: SliverGeometry(scrollExtent: 400.0, hidden,\n'
        ' │ │   maxPaintExtent: 400.0, hasVisualOverflow: true, cacheExtent:\n'
        ' │ │   50.0)\n'
        ' │ │\n'
        ' │ └─child: RenderSizedBox#00000 NEEDS-PAINT\n'
        ' │     parentData: paintOffset=Offset(0.0, -0.0) (can use size)\n'
        ' │     constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        ' │     size: Size(800.0, 400.0)\n'
        ' │\n'
        ' ├─child 3: RenderSliverToBoxAdapter#00000 relayoutBoundary=up1 NEEDS-PAINT\n'
        ' │ │ parentData: paintOffset=Offset(0.0, 1200.0) (can use size)\n'
        ' │ │ constraints: SliverConstraints(AxisDirection.down,\n'
        ' │ │   GrowthDirection.forward, ScrollDirection.idle, scrollOffset:\n'
        ' │ │   0.0, remainingPaintExtent: 0.0, crossAxisExtent: 800.0,\n'
        ' │ │   crossAxisDirection: AxisDirection.right,\n'
        ' │ │   viewportMainAxisExtent: 600.0, remainingCacheExtent: 0.0\n'
        ' │ │   cacheOrigin: 0.0 )\n'
        ' │ │ geometry: SliverGeometry(scrollExtent: 400.0, hidden,\n'
        ' │ │   maxPaintExtent: 400.0, hasVisualOverflow: true)\n'
        ' │ │\n'
        ' │ └─child: RenderSizedBox#00000 NEEDS-PAINT\n'
        ' │     parentData: paintOffset=Offset(0.0, -0.0) (can use size)\n'
        ' │     constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        ' │     size: Size(800.0, 400.0)\n'
        ' │\n'
        ' └─child 4: RenderSliverToBoxAdapter#00000 relayoutBoundary=up1 NEEDS-PAINT\n'
        '   │ parentData: paintOffset=Offset(0.0, 1600.0) (can use size)\n'
        '   │ constraints: SliverConstraints(AxisDirection.down,\n'
        '   │   GrowthDirection.forward, ScrollDirection.idle, scrollOffset:\n'
        '   │   0.0, remainingPaintExtent: 0.0, crossAxisExtent: 800.0,\n'
        '   │   crossAxisDirection: AxisDirection.right,\n'
        '   │   viewportMainAxisExtent: 600.0, remainingCacheExtent: 0.0\n'
        '   │   cacheOrigin: 0.0 )\n'
        '   │ geometry: SliverGeometry(scrollExtent: 400.0, hidden,\n'
        '   │   maxPaintExtent: 400.0, hasVisualOverflow: true)\n'
        '   │\n'
        '   └─child: RenderSizedBox#00000 NEEDS-PAINT\n'
        '       parentData: paintOffset=Offset(0.0, -0.0) (can use size)\n'
        '       constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        '       size: Size(800.0, 400.0)\n'
      ),
    );
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 800.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1200.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1600.0));

    expect(a.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 400.0));
    expect(b.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 800.0));
    expect(c.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1200.0));
    expect(d.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1600.0));
    expect(e.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 2000.0));

    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1000.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1400.0));

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -600.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1000.0));

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -900.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -500.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 700.0));

    final HitTestResult result = HitTestResult();
    root.hitTest(result, position: const Offset(130.0, 150.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderViewport basic test - up', () {
    RenderBox a, b, c, d, e;
    final RenderViewport root = RenderViewport(
      axisDirection: AxisDirection.up,
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        RenderSliverToBoxAdapter(child: a = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: b = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: c = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: d = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: e = RenderSizedBox(const Size(100.0, 400.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -600.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -1000.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -1400.0));

    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -800.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -1200.0));

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 800.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -800.0));

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1100.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 700.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -500.0));

    final HitTestResult result = HitTestResult();
    root.hitTest(result, position: const Offset(150.0, 350.0));
    expect(result.path.first.target, equals(c));
  });

  Offset _getPaintOrigin(RenderObject render) {
    final Vector3 transformed3 = render.getTransformTo(null).perspectiveTransform(Vector3(0.0, 0.0, 0.0));
    return Offset(transformed3.x, transformed3.y);
  }

  test('RenderViewport basic test - right', () {
    RenderBox a, b, c, d, e;
    final RenderViewport root = RenderViewport(
      axisDirection: AxisDirection.right,
      crossAxisDirection: AxisDirection.down,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        RenderSliverToBoxAdapter(child: a = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: b = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: c = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: d = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: e = RenderSizedBox(const Size(400.0, 100.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    final RenderSliver sliverA = a.parent;
    final RenderSliver sliverB = b.parent;
    final RenderSliver sliverC = c.parent;
    final RenderSliver sliverD = d.parent;
    final RenderSliver sliverE = e.parent;

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(400.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(1200.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(1600.0, 0.0));

    expect(_getPaintOrigin(sliverA), const Offset(0.0, 0.0));
    expect(_getPaintOrigin(sliverB), const Offset(400.0, 0.0));
    expect(_getPaintOrigin(sliverC), const Offset(800.0, 0.0));
    expect(_getPaintOrigin(sliverD), const Offset(1200.0, 0.0));
    expect(_getPaintOrigin(sliverE), const Offset(1600.0, 0.0));

    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(1000.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(1400.0, 0.0));

    expect(_getPaintOrigin(sliverA), const Offset(000.0, 0.0));
    expect(_getPaintOrigin(sliverB), const Offset(200.0, 0.0));
    expect(_getPaintOrigin(sliverC), const Offset(600.0, 0.0));
    expect(_getPaintOrigin(sliverD), const Offset(1000.0, 0.0));
    expect(_getPaintOrigin(sliverE), const Offset(1400.0, 0.0));

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-600.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(1000.0, 0.0));

    expect(_getPaintOrigin(sliverA), const Offset(000.0, 0.0));
    expect(_getPaintOrigin(sliverB), const Offset(000.0, 0.0));
    expect(_getPaintOrigin(sliverC), const Offset(200.0, 0.0));
    expect(_getPaintOrigin(sliverD), const Offset(600.0, 0.0));
    expect(_getPaintOrigin(sliverE), const Offset(1000.0, 0.0));

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-900.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(-500.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-100.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(300.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 0.0));

    expect(_getPaintOrigin(sliverA), const Offset(000.0, 0.0));
    expect(_getPaintOrigin(sliverB), const Offset(000.0, 0.0));
    expect(_getPaintOrigin(sliverC), const Offset(000.0, 0.0));
    expect(_getPaintOrigin(sliverD), const Offset(300.0, 0.0));
    expect(_getPaintOrigin(sliverE), const Offset(700.0, 0.0));

    final HitTestResult result = HitTestResult();
    root.hitTest(result, position: const Offset(150.0, 450.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderViewport basic test - left', () {
    RenderBox a, b, c, d, e;
    final RenderViewport root = RenderViewport(
      axisDirection: AxisDirection.left,
      crossAxisDirection: AxisDirection.down,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        RenderSliverToBoxAdapter(child: a = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: b = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: c = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: d = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: e = RenderSizedBox(const Size(400.0, 100.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(400.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-800.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-1200.0, 0.0));

    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-600.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-1000.0, 0.0));

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(1000.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-600.0, 0.0));

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(1300.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(900.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(100.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-300.0, 0.0));

    final HitTestResult result = HitTestResult();
    root.hitTest(result, position: const Offset(550.0, 150.0));
    expect(result.path.first.target, equals(c));
  });

  // TODO(ianh): test anchor
  // TODO(ianh): test center
  // TODO(ianh): test semantics

  test('RenderShrinkWrappingViewport basic test - no children', () {
    final RenderShrinkWrappingViewport root = RenderShrinkWrappingViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
    );
    expect(root, hasAGoodToStringDeep);
    layout(root);
    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
  });

  test('RenderShrinkWrappingViewport basic test - down', () {
    RenderBox a, b, c, d, e;
    final RenderShrinkWrappingViewport root = RenderShrinkWrappingViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        RenderSliverToBoxAdapter(child: a = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: b = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: c = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: d = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: e = RenderSizedBox(const Size(100.0, 400.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 800.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1200.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1600.0));

    expect(a.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 400.0));
    expect(b.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 800.0));
    expect(c.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1200.0));
    expect(d.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1600.0));
    expect(e.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 2000.0));

    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1000.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1400.0));

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -600.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1000.0));

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -900.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -500.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 700.0));

    final HitTestResult result = HitTestResult();
    root.hitTest(result, position: const Offset(130.0, 150.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderShrinkWrappingViewport basic test - up', () {
    RenderBox a, b, c, d, e;
    final RenderShrinkWrappingViewport root = RenderShrinkWrappingViewport(
      axisDirection: AxisDirection.up,
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        RenderSliverToBoxAdapter(child: a = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: b = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: c = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: d = RenderSizedBox(const Size(100.0, 400.0))),
        RenderSliverToBoxAdapter(child: e = RenderSizedBox(const Size(100.0, 400.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -600.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -1000.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -1400.0));

    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -800.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -1200.0));

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 800.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -800.0));

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1100.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 700.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -500.0));

    final HitTestResult result = HitTestResult();
    root.hitTest(result, position: const Offset(150.0, 350.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderShrinkWrappingViewport basic test - right', () {
    RenderBox a, b, c, d, e;
    final RenderShrinkWrappingViewport root = RenderShrinkWrappingViewport(
      axisDirection: AxisDirection.right,
      crossAxisDirection: AxisDirection.down,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        RenderSliverToBoxAdapter(child: a = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: b = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: c = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: d = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: e = RenderSizedBox(const Size(400.0, 100.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(400.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(1200.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(1600.0, 0.0));

    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(1000.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(1400.0, 0.0));

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-600.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(1000.0, 0.0));

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-900.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(-500.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-100.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(300.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 0.0));

    final HitTestResult result = HitTestResult();
    root.hitTest(result, position: const Offset(150.0, 450.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderShrinkWrappingViewport basic test - left', () {
    RenderBox a, b, c, d, e;
    final RenderShrinkWrappingViewport root = RenderShrinkWrappingViewport(
      axisDirection: AxisDirection.left,
      crossAxisDirection: AxisDirection.down,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        RenderSliverToBoxAdapter(child: a = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: b = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: c = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: d = RenderSizedBox(const Size(400.0, 100.0))),
        RenderSliverToBoxAdapter(child: e = RenderSizedBox(const Size(400.0, 100.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(400.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-800.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-1200.0, 0.0));

    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-600.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-1000.0, 0.0));

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(1000.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-600.0, 0.0));

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(1300.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(900.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(100.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-300.0, 0.0));

    final HitTestResult result = HitTestResult();
    root.hitTest(result, position: const Offset(550.0, 150.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderShrinkWrappingViewport shrinkwrap test - 1 child', () {
    RenderBox child;
    final RenderBox root = RenderPositionedBox(
      child: child = RenderShrinkWrappingViewport(
        axisDirection: AxisDirection.left,
        crossAxisDirection: AxisDirection.down,
        offset: ViewportOffset.fixed(200.0),
        children: <RenderSliver>[
          RenderSliverToBoxAdapter(child: RenderSizedBox(const Size(400.0, 100.0))),
        ],
      ),
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));
    expect(child.size.width, equals(400.0));
    expect(child.size.height, equals(600.0));
  });

  test('RenderShrinkWrappingViewport shrinkwrap test - 2 children', () {
    RenderBox child;
    final RenderBox root = RenderPositionedBox(
      child: child = RenderShrinkWrappingViewport(
        axisDirection: AxisDirection.right,
        crossAxisDirection: AxisDirection.down,
        offset: ViewportOffset.fixed(200.0),
        children: <RenderSliver>[
          RenderSliverToBoxAdapter(child: RenderSizedBox(const Size(300.0, 100.0))),
          RenderSliverToBoxAdapter(child: RenderSizedBox(const Size(150.0, 100.0))),
        ],
      ),
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));
    expect(child.size.width, equals(450.0));
    expect(child.size.height, equals(600.0));
  });

  test('SliverGeometry toString', () {
    expect(
      const SliverGeometry().toString(),
      equals('SliverGeometry(scrollExtent: 0.0, hidden, maxPaintExtent: 0.0)'),
    );
    expect(
      const SliverGeometry(
        scrollExtent: 100.0,
        paintExtent: 50.0,
        layoutExtent: 20.0,
        visible: true,
      ).toString(),
      equals(
        'SliverGeometry(scrollExtent: 100.0, paintExtent: 50.0, layoutExtent: 20.0, maxPaintExtent: 0.0, cacheExtent: 20.0)',
      ),
    );
    expect(
      const SliverGeometry(
        scrollExtent: 100.0,
        paintExtent: 0.0,
        layoutExtent: 20.0,
      ).toString(),
      equals(
        'SliverGeometry(scrollExtent: 100.0, hidden, layoutExtent: 20.0, maxPaintExtent: 0.0, cacheExtent: 20.0)',
      ),
    );
  });

  test('Sliver paintBounds and semanticBounds - vertical', () {
    const double height = 150.0;

    final RenderSliver sliver = RenderSliverToBoxAdapter(
        child: RenderSizedBox(const Size(400.0, height)),
    );
    final RenderViewport root = RenderViewport(
      axisDirection: AxisDirection.down,
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        sliver,
      ],
    );
    layout(root);

    final Rect expectedRect = Rect.fromLTWH(0.0, 0.0, root.size.width, height);

    expect(sliver.paintBounds, expectedRect);
    expect(sliver.semanticBounds, expectedRect);
  });

  test('Sliver paintBounds and semanticBounds - horizontal', () {
    const double width = 150.0;

    final RenderSliver sliver = RenderSliverToBoxAdapter(
      child: RenderSizedBox(const Size(width, 400.0)),
    );
    final RenderViewport root = RenderViewport(
      axisDirection: AxisDirection.right,
      crossAxisDirection: AxisDirection.down,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        sliver,
      ],
    );
    layout(root);

    final Rect expectedRect = Rect.fromLTWH(0.0, 0.0, width, root.size.height);

    expect(sliver.paintBounds, expectedRect);
    expect(sliver.semanticBounds, expectedRect);
  });
}
