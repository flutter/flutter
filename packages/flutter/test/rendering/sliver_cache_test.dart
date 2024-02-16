// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('RenderViewport calculates correct constraints, RenderSliverToBoxAdapter calculates correct geometry', () {
    final List<RenderSliver> children = List<RenderSliver>.generate(30, (int index) {
      return RenderSliverToBoxAdapter(
        child: RenderSizedBox(const Size(400.0, 100.0)),
      );
    });

    // Viewport is 800x600, can show 6 children at a time.

    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 250.0,
      children: children,
    );
    layout(root);

    RenderSliver firstVisible = children[0];
    expectSliverConstraints(
      sliver: firstVisible,
      cacheOrigin: 0.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 600.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: firstVisible,
      paintExtent: 100.0,
      cacheExtent: 100.0,
      visible: true,
    );

    RenderSliver lastVisible = children[5];
    expectSliverConstraints(
      sliver: lastVisible,
      cacheOrigin: 0.0,
      remainingPaintExtent: 100.0,
      remainingCacheExtent: 350.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastVisible,
      paintExtent: 100.0,
      cacheExtent: 100.0,
      visible: true,
    );

    RenderSliver firstInCache = children[6];
    expectSliverConstraints(
      sliver: firstInCache,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: firstInCache,
      paintExtent: 0.0,
      cacheExtent: 100.0,
      visible: false,
    );

    RenderSliver lastInCache = children[8];
    expectSliverConstraints(
      sliver: lastInCache,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 50.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastInCache,
      paintExtent: 0.0,
      cacheExtent: 50.0,
      visible: false,
    );

    RenderSliver outsideCache = children[9];
    expectSliverConstraints(
      sliver: outsideCache,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 0.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: outsideCache,
      paintExtent: 0.0,
      cacheExtent: 0.0,
      visible: false,
    );

    // scroll down half a sliver
    root.offset = ViewportOffset.fixed(50.0);
    pumpFrame();

    firstVisible = children[0];
    expectSliverConstraints(
      sliver: firstVisible,
      cacheOrigin: -50.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 50.0 + 600.0 + 250.0,
      scrollOffset: 50.0,
    );
    expectSliverGeometry(
      sliver: firstVisible,
      paintExtent: 50.0,
      cacheExtent: 100.0,
      visible: true,
    );

    lastVisible = children[6];
    expectSliverConstraints(
      sliver: lastVisible,
      cacheOrigin: 0.0,
      remainingPaintExtent: 50.0,
      remainingCacheExtent: 300.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastVisible,
      paintExtent: 50.0,
      cacheExtent: 100.0,
      visible: true,
    );

    firstInCache = children[7];
    expectSliverConstraints(
      sliver: firstInCache,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 200.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: firstInCache,
      paintExtent: 0.0,
      cacheExtent: 100.0,
      visible: false,
    );

    lastInCache = children[8];
    expectSliverConstraints(
      sliver: lastInCache,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 100.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastInCache,
      paintExtent: 0.0,
      cacheExtent: 100.0,
      visible: false,
    );

    outsideCache = children[9];
    expectSliverConstraints(
      sliver: outsideCache,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 0.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: outsideCache,
      paintExtent: 0.0,
      cacheExtent: 0.0,
      visible: false,
    );

    // scroll down 1.5 slivers
    root.offset = ViewportOffset.fixed(150.0);
    pumpFrame();

    RenderSliver firstInPreCache = children[0];
    expectSliverConstraints(
      sliver: firstInPreCache,
      cacheOrigin: -150.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 150.0 + 600.0 + 250.0,
      scrollOffset: 150.0,
    );
    expectSliverGeometry(
      sliver: firstInPreCache,
      paintExtent: 0.0,
      cacheExtent: 100.0,
      visible: false,
    );

    firstVisible = children[1];
    expectSliverConstraints(
      sliver: firstVisible,
      cacheOrigin: -50.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 50.0 + 600.0 + 250.0,
      scrollOffset: 50.0,
    );
    expectSliverGeometry(
      sliver: firstVisible,
      paintExtent: 50.0,
      cacheExtent: 100.0,
      visible: true,
    );

    // scroll down 10 slivers
    root.offset = ViewportOffset.fixed(1000.0);
    pumpFrame();

    final RenderSliver first = children[0];
    expectSliverConstraints(
      sliver: first,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 1000.0,
    );
    expectSliverGeometry(
      sliver: first,
      paintExtent: 0.0,
      cacheExtent: 0.0,
      visible: false,
    );

    firstInPreCache = children[7];
    expectSliverConstraints(
      sliver: firstInPreCache,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 300.0,
    );
    expectSliverGeometry(
      sliver: firstInPreCache,
      paintExtent: 0.0,
      cacheExtent: 50.0,
      visible: false,
    );

    final RenderSliver lastInPreCache = children[9];
    expectSliverConstraints(
      sliver: lastInPreCache,
      cacheOrigin: -100.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 100.0 + 600.0 + 250.0,
      scrollOffset: 100.0,
    );
    expectSliverGeometry(
      sliver: lastInPreCache,
      paintExtent: 0.0,
      cacheExtent: 100.0,
      visible: false,
    );

    firstVisible = children[10];
    expectSliverConstraints(
      sliver: firstVisible,
      cacheOrigin: 0.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 600.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: firstVisible,
      paintExtent: 100.0,
      cacheExtent: 100.0,
      visible: true,
    );
  });

  test('RenderSliverFixedExtentList calculates correct geometry', () {
    // Viewport is 800x600, can show 6 full children at a time
    final List<RenderBox> children = List<RenderBox>.generate(30, (int index) {
      return RenderSizedBox(const Size(400.0, 100.0));
    });
    final TestRenderSliverBoxChildManager childManager = TestRenderSliverBoxChildManager(
      children: children,
    );
    RenderSliverFixedExtentList inner;
    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 250.0,
      children: <RenderSliver>[
        inner = childManager.createRenderSliverFixedExtentList(),
      ],
    );
    layout(root);

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: 0.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 600.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 850.0,
      visible: true,
    );
    expect(children.sublist(0, 9).every((RenderBox r) => r.attached), true);
    expect(children.sublist(9, 30).any((RenderBox r) => r.attached), false);

    // scroll half an item down
    root.offset = ViewportOffset.fixed(50.0);
    pumpFrame();

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: -50.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 50.0 + 600.0 + 250.0,
      scrollOffset: 50.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 900.0,
      visible: true,
    );
    expect(children.sublist(0, 9).every((RenderBox r) => r.attached), true);
    expect(children.sublist(9, 30).any((RenderBox r) => r.attached), false);


    // scroll to the middle
    root.offset = ViewportOffset.fixed(1500.0);
    pumpFrame();

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 1500.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 1100.0,
      visible: true,
    );

    expect(children.sublist(0, 12).any((RenderBox r) => r.attached), false);
    expect(children.sublist(12, 24).every((RenderBox r) => r.attached), true);
    expect(children.sublist(24, 30).any((RenderBox r) => r.attached), false);

    // scroll to the end
    root.offset = ViewportOffset.fixed(2400.0);
    pumpFrame();

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 2400.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 850.0,
      visible: true,
    );
    expect(children.sublist(0, 21).any((RenderBox r) => r.attached), false);
    expect(children.sublist(21, 30).every((RenderBox r) => r.attached), true);
  });

  test('RenderSliverList calculates correct geometry', () {
    // Viewport is 800x600, can show 6 full children at a time
    final List<RenderBox> children = List<RenderBox>.generate(30, (int index) {
      return RenderSizedBox(const Size(400.0, 100.0));
    });
    final TestRenderSliverBoxChildManager childManager = TestRenderSliverBoxChildManager(
      children: children,
    );
    RenderSliverList inner;
    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 250.0,
      children: <RenderSliver>[
        inner = childManager.createRenderSliverList(),
      ],
    );
    layout(root);

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: 0.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 600.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 850.0,
      visible: true,
    );
    expect(children.sublist(0, 9).every((RenderBox r) => r.attached), true);
    expect(children.sublist(9, 30).any((RenderBox r) => r.attached), false);

    // scroll half an item down
    root.offset = ViewportOffset.fixed(50.0);
    pumpFrame();

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: -50.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 50.0 + 600.0 + 250.0,
      scrollOffset: 50.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 900.0,
      visible: true,
    );
    expect(children.sublist(0, 9).every((RenderBox r) => r.attached), true);
    expect(children.sublist(9, 30).any((RenderBox r) => r.attached), false);


    // scroll to the middle
    root.offset = ViewportOffset.fixed(1500.0);
    pumpFrame();

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 1500.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 1100.0,
      visible: true,
    );

    expect(children.sublist(0, 12).any((RenderBox r) => r.attached), false);
    expect(children.sublist(12, 24).every((RenderBox r) => r.attached), true);
    expect(children.sublist(24, 30).any((RenderBox r) => r.attached), false);

    // scroll to the end
    root.offset = ViewportOffset.fixed(2400.0);
    pumpFrame();

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 2400.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 850.0,
      visible: true,
    );
    expect(children.sublist(0, 21).any((RenderBox r) => r.attached), false);
    expect(children.sublist(21, 30).every((RenderBox r) => r.attached), true);
  });

  test('RenderSliverGrid calculates correct geometry', () {
    // Viewport is 800x600, each grid element is 400x100, giving us space for 12 visible children
    final List<RenderBox> children = List<RenderBox>.generate(60, (int index) {
      return RenderSizedBox(const Size(400.0, 100.0));
    });
    final TestRenderSliverBoxChildManager childManager = TestRenderSliverBoxChildManager(
      children: children,
    );
    RenderSliverGrid inner;
    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 250.0,
      children: <RenderSliver>[
        inner = childManager.createRenderSliverGrid(),
      ],
    );
    layout(root);

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: 0.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 600.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 850.0,
      visible: true,
    );
    expect(children.sublist(0, 18).every((RenderBox r) => r.attached), true);
    expect(children.sublist(18, 60).any((RenderBox r) => r.attached), false);

    // scroll half an item down
    root.offset = ViewportOffset.fixed(50.0);
    pumpFrame();

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: -50.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 50.0 + 600.0 + 250.0,
      scrollOffset: 50.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 900.0,
      visible: true,
    );
    expect(children.sublist(0, 18).every((RenderBox r) => r.attached), true);
    expect(children.sublist(18, 60).any((RenderBox r) => r.attached), false);


    // scroll to the middle
    root.offset = ViewportOffset.fixed(1500.0);
    pumpFrame();

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 1500.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 1100.0,
      visible: true,
    );

    expect(children.sublist(0, 24).any((RenderBox r) => r.attached), false);
    expect(children.sublist(24, 48).every((RenderBox r) => r.attached), true);
    expect(children.sublist(48, 60).any((RenderBox r) => r.attached), false);

    // scroll to the end
    root.offset = ViewportOffset.fixed(2400.0);
    pumpFrame();

    expectSliverConstraints(
      sliver: inner,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 2400.0,
    );
    expectSliverGeometry(
      sliver: inner,
      paintExtent: 600.0,
      cacheExtent: 850.0,
      visible: true,
    );
    expect(children.sublist(0, 42).any((RenderBox r) => r.attached), false);
    expect(children.sublist(42, 60).every((RenderBox r) => r.attached), true);
  });

  test('RenderSliverPadding calculates correct geometry', () {
    // Viewport is 800x600, each item is 100px high with 50px before and after = 200px

    final List<RenderSliverToBoxAdapter> adapters = <RenderSliverToBoxAdapter>[];
    final List<RenderSliverPadding> paddings = List<RenderSliverPadding>.generate(30, (int index) {
      RenderSliverToBoxAdapter adapter;
      final RenderSliverPadding padding = RenderSliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 50.0),
        child: adapter = RenderSliverToBoxAdapter(
          child: RenderSizedBox(const Size(400.0, 100.0)),
        ),
      );
      adapters.add(adapter);
      return padding;
    });


    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 250.0,
      children: paddings,
    );
    layout(root);

    RenderSliverPadding firstVisiblePadding = paddings[0];
    expectSliverConstraints(
      sliver: firstVisiblePadding,
      cacheOrigin: 0.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 600.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: firstVisiblePadding,
      paintExtent: 200.0,
      cacheExtent: 200.0,
      visible: true,
    );
    RenderSliverToBoxAdapter firstVisiblePadded = adapters[0];
    expectSliverConstraints(
      sliver: firstVisiblePadded,
      cacheOrigin: 0.0,
      remainingPaintExtent: 550.0,
      remainingCacheExtent: 600.0 + 250.0 - 50.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: firstVisiblePadded,
      paintExtent: 100.0,
      cacheExtent: 100.0,
      visible: true,
    );

    RenderSliverPadding lastVisiblePadding = paddings[2];
    expectSliverConstraints(
      sliver: lastVisiblePadding,
      cacheOrigin: 0.0,
      remainingPaintExtent: 200.0,
      remainingCacheExtent: 200.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastVisiblePadding,
      paintExtent: 200.0,
      cacheExtent: 200.0,
      visible: true,
    );
    RenderSliverToBoxAdapter lastVisiblePadded = adapters[2];
    expectSliverConstraints(
      sliver: lastVisiblePadded,
      cacheOrigin: 0.0,
      remainingPaintExtent: 150.0,
      remainingCacheExtent: 200.0 + 250.0 - 50.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastVisiblePadded,
      paintExtent: 100.0,
      cacheExtent: 100.0,
      visible: true,
    );

    final RenderSliverPadding firstCachePadding = paddings[3];
    expectSliverConstraints(
      sliver: firstCachePadding,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: firstCachePadding,
      paintExtent: 0.0,
      cacheExtent: 200.0,
      visible: false,
    );
    final RenderSliverToBoxAdapter firstCachePadded = adapters[3];
    expectSliverConstraints(
      sliver: firstCachePadded,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 250.0 - 50.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: firstCachePadded,
      paintExtent: 0.0,
      cacheExtent: 100.0,
      visible: false,
    );

    final RenderSliverPadding lastCachePadding = paddings[4];
    expectSliverConstraints(
      sliver: lastCachePadding,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 50.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastCachePadding,
      paintExtent: 0.0,
      cacheExtent: 50.0,
      visible: false,
    );
    final RenderSliverToBoxAdapter lastCachePadded = adapters[4];
    expectSliverConstraints(
      sliver: lastCachePadded,
      cacheOrigin: 0.0,
      remainingPaintExtent: 0.0,
      remainingCacheExtent: 0.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastCachePadded,
      paintExtent: 0.0,
      cacheExtent: 0.0,
      visible: false,
    );

    // scroll first padding off screen
    root.offset = ViewportOffset.fixed(50.0);
    pumpFrame();

    firstVisiblePadding = paddings[0];
    expectSliverConstraints(
      sliver: firstVisiblePadding,
      cacheOrigin: -50.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 50.0 + 600.0 + 250.0,
      scrollOffset: 50.0,
    );
    expectSliverGeometry(
      sliver: firstVisiblePadding,
      paintExtent: 150.0,
      cacheExtent: 200.0,
      visible: true,
    );
    firstVisiblePadded = adapters[0];
    expectSliverConstraints(
      sliver: firstVisiblePadded,
      cacheOrigin: 0.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 600.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: firstVisiblePadded,
      paintExtent: 100.0,
      cacheExtent: 100.0,
      visible: true,
    );

    // scroll to the end
    root.offset = ViewportOffset.fixed(5400.0);
    pumpFrame();


    final RenderSliverPadding firstPadding = paddings[0];
    expectSliverConstraints(
      sliver: firstPadding,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 5400.0,
    );
    expectSliverGeometry(
      sliver: firstPadding,
      paintExtent: 0.0,
      cacheExtent: 0.0,
      visible: false,
    );
    final RenderSliverToBoxAdapter firstPadded = adapters[0];
    expectSliverConstraints(
      sliver: firstPadded,
      cacheOrigin: -200.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 5350.0,
    );
    expectSliverGeometry(
      sliver: firstPadded,
      paintExtent: 0.0,
      cacheExtent: 0.0,
      visible: false,
    );

    final RenderSliverPadding firstPreCachePadding = paddings[25];
    expectSliverConstraints(
      sliver: firstPreCachePadding,
      cacheOrigin: -250.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 400.0,
    );
    expectSliverGeometry(
      sliver: firstPreCachePadding,
      paintExtent: 0.0,
      cacheExtent: 50.0,
      visible: false,
    );
    final RenderSliverToBoxAdapter firstPreCachePadded = adapters[25];
    expectSliverConstraints(
      sliver: firstPreCachePadded,
      cacheOrigin: -200.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 250.0 + 600.0 + 250.0,
      scrollOffset: 350.0,
    );
    expectSliverGeometry(
      sliver: firstPreCachePadded,
      paintExtent: 0.0,
      cacheExtent: 0.0,
      visible: false,
    );

    final RenderSliverPadding lastPreCachePadding = paddings[26];
    expectSliverConstraints(
      sliver: lastPreCachePadding,
      cacheOrigin: -200.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 200.0 + 600.0 + 250.0,
      scrollOffset: 200.0,
    );
    expectSliverGeometry(
      sliver: lastPreCachePadding,
      paintExtent: 0.0,
      cacheExtent: 200.0,
      visible: false,
    );
    final RenderSliverToBoxAdapter lastPreCachePadded = adapters[26];
    expectSliverConstraints(
      sliver: lastPreCachePadded,
      cacheOrigin: -150.0,
      remainingPaintExtent: 600.0,
      remainingCacheExtent: 150.0 + 600.0 + 250.0,
      scrollOffset: 150.0,
    );
    expectSliverGeometry(
      sliver: lastPreCachePadded,
      paintExtent: 0.0,
      cacheExtent: 100.0,
      visible: false,
    );

    lastVisiblePadding = paddings[29];
    expectSliverConstraints(
      sliver: lastVisiblePadding,
      cacheOrigin: 0.0,
      remainingPaintExtent: 200.0,
      remainingCacheExtent: 200.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastVisiblePadding,
      paintExtent: 200.0,
      cacheExtent: 200.0,
      visible: true,
    );
    lastVisiblePadded = adapters[29];
    expectSliverConstraints(
      sliver: lastVisiblePadded,
      cacheOrigin: 0.0,
      remainingPaintExtent: 150.0,
      remainingCacheExtent: 150.0 + 250.0,
      scrollOffset: 0.0,
    );
    expectSliverGeometry(
      sliver: lastVisiblePadded,
      paintExtent: 100.0,
      cacheExtent: 100.0,
      visible: true,
    );
  });

  group('RenderSliverFillRemaining calculates correct geometry', () {
    test('when initially in view', () {
      // Viewport is 800x600
      const double viewportHeight = 600;
      const double cacheExtent = 250.0;
      const double beginningViewportCacheExtent = viewportHeight + cacheExtent;
      const double firstSliverHeight = 400;
      const double sliverFillRemainingChildHeight = 100.0;

      final List<RenderSliver> slivers = <RenderSliver>[
        RenderSliverToBoxAdapter(
          child: RenderSizedBox(const Size(400.0, firstSliverHeight)),
        ),
        RenderSliverFillRemaining(
          child: RenderSizedBox(const Size(100.0, sliverFillRemainingChildHeight)),
        )
      ];

      final RenderViewport root = RenderViewport(
        crossAxisDirection: AxisDirection.right,
        offset: ViewportOffset.zero(),
        cacheExtent: cacheExtent,
        children: slivers,
      );
      layout(root);

      final RenderSliver firstVisibleSliver = slivers[0];
      expectSliverConstraints(
        sliver: firstVisibleSliver,
        cacheOrigin: 0.0,
        remainingPaintExtent: viewportHeight,
        remainingCacheExtent: beginningViewportCacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: firstVisibleSliver,
        paintExtent: firstSliverHeight,
        cacheExtent: firstSliverHeight,
        visible: true,
      );

      // When RenderSliverFillRemaining is initially completely within the
      // viewport, its paintExtent fills the remainingPaintExtent and it's
      // visible. The cacheExtent is the same as the paintExtent.
      final RenderSliver sliverFillRemaining = slivers[1];
      const double remainingPaintExtentAfterFirstSliver = viewportHeight - firstSliverHeight;
      const double remainingCacheExtentAfterFirstSliver = beginningViewportCacheExtent - firstSliverHeight;
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: remainingPaintExtentAfterFirstSliver,
        remainingCacheExtent: remainingCacheExtentAfterFirstSliver,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: remainingPaintExtentAfterFirstSliver,
        cacheExtent: remainingPaintExtentAfterFirstSliver,
        visible: true,
      );

      // Overscroll
      root.offset = ViewportOffset.fixed(50);
      pumpFrame();

      // When you overscroll, the RenderSliverFillRemaining's paintExtent and
      // cacheExtent do not change to fill remainingPaintExtent.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: remainingPaintExtentAfterFirstSliver + 50,
        remainingCacheExtent: remainingCacheExtentAfterFirstSliver + 50,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: remainingPaintExtentAfterFirstSliver,
        cacheExtent: remainingPaintExtentAfterFirstSliver,
        visible: true,
      );
    });

    test('when scrolled into view', () {
      // Viewport is 800x600
      const double viewportHeight = 600;
      const double cacheExtent = 250.0;
      const double beginningViewportCacheExtent = viewportHeight + cacheExtent;
      const double firstSliverHeight = beginningViewportCacheExtent;
      const double sliverFillRemainingChildHeight = 100.0;

      final List<RenderSliver> slivers = <RenderSliver>[
        RenderSliverToBoxAdapter(
          child: RenderSizedBox(const Size(400.0, firstSliverHeight)),
        ),
        RenderSliverFillRemaining(
          child: RenderSizedBox(const Size(100.0, sliverFillRemainingChildHeight)),
        )
      ];

      final RenderViewport root = RenderViewport(
        crossAxisDirection: AxisDirection.right,
        offset: ViewportOffset.zero(),
        cacheExtent: cacheExtent,
        children: slivers,
      );
      layout(root);

      final RenderSliver firstVisibleSliver = slivers[0];
      expectSliverConstraints(
        sliver: firstVisibleSliver,
        cacheOrigin: 0.0,
        remainingPaintExtent: viewportHeight,
        remainingCacheExtent: beginningViewportCacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: firstVisibleSliver,
        paintExtent: viewportHeight,
        cacheExtent: firstSliverHeight,
        visible: true,
      );

      // When RenderSliverFillRemaining is completely outside the viewport, it
      // has no paintExtent and is not visible. When it's outside of the
      // remainingCacheExtent, it does not have a cacheExtent.
      final RenderSliver sliverFillRemaining = slivers[1];
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: 0.0,
        remainingCacheExtent: 0.0,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: 0.0,
        cacheExtent: 0.0,
        visible: false,
      );

      // Scroll so RenderSliverFillRemaining is not within viewport, but is
      // within remainingCacheExtent.
      root.offset = ViewportOffset.fixed(cacheExtent);
      pumpFrame();

      // When RenderSliverFillRemaining is completely outside the viewport, it
      // has no paintExtent and is not visible. When it's scrolled within the
      // remainingCacheExtent, the cacheExtent is either the size of the child
      // or the remainingCacheExtent, whichever is smaller.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: 0.0,
        remainingCacheExtent: cacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: 0.0,
        cacheExtent: sliverFillRemainingChildHeight,
        visible: false,
      );

      // Scroll so RenderSliverFillRemaining is partially within viewport.
      root.offset = ViewportOffset.fixed(cacheExtent + 50);
      pumpFrame();

      // When RenderSliverFillRemaining is scrolled partially within the
      // viewport, its paintExtent fills the remainingPaintExtent and it's
      // visible. The cacheExtent is either the size of the child or the
      // paintExtent, whichever is larger.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: 50.0,
        remainingCacheExtent: cacheExtent + 50,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: 50.0,
        cacheExtent: sliverFillRemainingChildHeight,
        visible: true,
      );

      // Scroll so RenderSliverFillRemaining is completely within viewport.
      root.offset = ViewportOffset.fixed(cacheExtent + sliverFillRemainingChildHeight);
      pumpFrame();

      // When RenderSliverFillRemaining is scrolled completely within the
      // viewport, its paintExtent fills the child's height and it's visible.
      // The cacheExtent is also the child's height.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: sliverFillRemainingChildHeight,
        remainingCacheExtent: sliverFillRemainingChildHeight + cacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: sliverFillRemainingChildHeight,
        cacheExtent: sliverFillRemainingChildHeight,
        visible: true,
      );

      // Overscroll
      root.offset = ViewportOffset.fixed(cacheExtent + sliverFillRemainingChildHeight + 50);
      pumpFrame();

      // When you overscroll and RenderSliverFillRemaining is completely within
      // the viewport, its paintExtent fills the child's height and it's visible.
      // The cacheExtent is also the child's height.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: sliverFillRemainingChildHeight + 50,
        remainingCacheExtent: sliverFillRemainingChildHeight + cacheExtent + 50,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: sliverFillRemainingChildHeight,
        cacheExtent: sliverFillRemainingChildHeight,
        visible: true,
      );
    });
  });

  group('RenderSliverFillRemainingAndOverscroll calculates correct geometry', () {
    test('when initially in view', () {
      // Viewport is 800x600
      const double viewportHeight = 600;
      const double cacheExtent = 250.0;
      const double beginningViewportCacheExtent = viewportHeight + cacheExtent;
      const double firstSliverHeight = 400;
      const double sliverFillRemainingChildHeight = 100.0;

      final List<RenderSliver> slivers = <RenderSliver>[
        RenderSliverToBoxAdapter(
          child: RenderSizedBox(const Size(400.0, firstSliverHeight)),
        ),
        RenderSliverFillRemainingAndOverscroll(
          child: RenderSizedBox(const Size(100.0, sliverFillRemainingChildHeight)),
        )
      ];

      final RenderViewport root = RenderViewport(
        crossAxisDirection: AxisDirection.right,
        offset: ViewportOffset.zero(),
        cacheExtent: cacheExtent,
        children: slivers,
      );
      layout(root);

      final RenderSliver firstVisibleSliver = slivers[0];
      expectSliverConstraints(
        sliver: firstVisibleSliver,
        cacheOrigin: 0.0,
        remainingPaintExtent: viewportHeight,
        remainingCacheExtent: beginningViewportCacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: firstVisibleSliver,
        paintExtent: firstSliverHeight,
        cacheExtent: firstSliverHeight,
        visible: true,
      );

      // When RenderSliverFillRemainingAndOverscroll is initially completely within the
      // viewport, its paintExtent fills the remainingPaintExtent and it's
      // visible. The cacheExtent is the same as the paintExtent.
      final RenderSliver sliverFillRemaining = slivers[1];
      const double remainingPaintExtentAfterFirstSliver = viewportHeight - firstSliverHeight;
      const double remainingCacheExtentAfterFirstSliver = beginningViewportCacheExtent - firstSliverHeight;
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: remainingPaintExtentAfterFirstSliver,
        remainingCacheExtent: remainingCacheExtentAfterFirstSliver,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: remainingPaintExtentAfterFirstSliver,
        cacheExtent: remainingPaintExtentAfterFirstSliver,
        visible: true,
      );

      // Overscroll
      root.offset = ViewportOffset.fixed(50);
      pumpFrame();

      // When you overscroll, the RenderSliverFillRemainingAndOverscroll's
      // paintExtent fills the remainingPaintExtent. The cacheExtent does not
      // change.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: remainingPaintExtentAfterFirstSliver + 50,
        remainingCacheExtent: remainingCacheExtentAfterFirstSliver + 50,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: remainingPaintExtentAfterFirstSliver + 50,
        cacheExtent: remainingPaintExtentAfterFirstSliver,
        visible: true,
      );
    });

    test('when scrolled into view', () {
      // Viewport is 800x600
      const double viewportHeight = 600;
      const double cacheExtent = 250.0;
      const double beginningViewportCacheExtent = viewportHeight + cacheExtent;
      const double firstSliverHeight = beginningViewportCacheExtent;
      const double sliverFillRemainingChildHeight = 100.0;

      final List<RenderSliver> slivers = <RenderSliver>[
        RenderSliverToBoxAdapter(
          child: RenderSizedBox(const Size(400.0, firstSliverHeight)),
        ),
        RenderSliverFillRemainingAndOverscroll(
          child: RenderSizedBox(const Size(100.0, sliverFillRemainingChildHeight)),
        )
      ];

      final RenderViewport root = RenderViewport(
        crossAxisDirection: AxisDirection.right,
        offset: ViewportOffset.zero(),
        cacheExtent: cacheExtent,
        children: slivers,
      );
      layout(root);

      final RenderSliver firstVisibleSliver = slivers[0];
      expectSliverConstraints(
        sliver: firstVisibleSliver,
        cacheOrigin: 0.0,
        remainingPaintExtent: viewportHeight,
        remainingCacheExtent: beginningViewportCacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: firstVisibleSliver,
        paintExtent: viewportHeight,
        cacheExtent: firstSliverHeight,
        visible: true,
      );

      // When RenderSliverFillRemainingAndOverscroll is completely outside the viewport, it
      // has no paintExtent and is not visible. When it's outside of the
      // remainingCacheExtent, it does not have a cacheExtent.
      final RenderSliver sliverFillRemaining = slivers[1];
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: 0.0,
        remainingCacheExtent: 0.0,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: 0.0,
        cacheExtent: 0.0,
        visible: false,
      );

      // Scroll so RenderSliverFillRemainingAndOverscroll is not within viewport, but is
      // within remainingCacheExtent.
      root.offset = ViewportOffset.fixed(cacheExtent);
      pumpFrame();

      // When RenderSliverFillRemainingAndOverscroll is completely outside the viewport, it
      // has no paintExtent and is not visible. When it's scrolled within the
      // remainingCacheExtent, the cacheExtent is either the size of the child
      // or the remainingCacheExtent, whichever is smaller.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: 0.0,
        remainingCacheExtent: cacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: 0.0,
        cacheExtent: sliverFillRemainingChildHeight,
        visible: false,
      );

      // Scroll so RenderSliverFillRemainingAndOverscroll is partially within viewport.
      root.offset = ViewportOffset.fixed(cacheExtent + 50);
      pumpFrame();

      // When RenderSliverFillRemainingAndOverscroll is scrolled partially within the
      // viewport, its paintExtent fills the remainingPaintExtent and it's
      // visible. The cacheExtent is either the size of the child or the
      // paintExtent, whichever is larger.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: 50.0,
        remainingCacheExtent: cacheExtent + 50,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: 50.0,
        cacheExtent: sliverFillRemainingChildHeight,
        visible: true,
      );

      // Scroll so RenderSliverFillRemainingAndOverscroll is completely within viewport.
      root.offset = ViewportOffset.fixed(cacheExtent + sliverFillRemainingChildHeight);
      pumpFrame();

      // When RenderSliverFillRemainingAndOverscroll is scrolled completely within the
      // viewport, its paintExtent fills the child's height and it's visible.
      // The cacheExtent is also the child's height.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: sliverFillRemainingChildHeight,
        remainingCacheExtent: sliverFillRemainingChildHeight + cacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: sliverFillRemainingChildHeight,
        cacheExtent: sliverFillRemainingChildHeight,
        visible: true,
      );

      // Overscroll
      root.offset = ViewportOffset.fixed(cacheExtent + sliverFillRemainingChildHeight + 50);
      pumpFrame();

      // When you overscroll and RenderSliverFillRemainingAndOverscroll is
      // completely within the viewport, its paintExtent fills the
      // remainingPaintExtent. The cacheExtent does not change.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: sliverFillRemainingChildHeight + 50,
        remainingCacheExtent: sliverFillRemainingChildHeight + cacheExtent + 50,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: sliverFillRemainingChildHeight + 50,
        cacheExtent: sliverFillRemainingChildHeight,
        visible: true,
      );
    });
  });

  group('RenderSliverFillRemainingWithScrollable calculates correct geometry', () {
    test('when initially in view', () {
      // Viewport is 800x600
      const double viewportHeight = 600;
      const double cacheExtent = 250.0;
      const double beginningViewportCacheExtent = viewportHeight + cacheExtent;
      const double firstSliverHeight = 400;
      const double sliverFillRemainingChildHeight = 100.0;

      final List<RenderSliver> slivers = <RenderSliver>[
        RenderSliverToBoxAdapter(
          child: RenderSizedBox(const Size(400.0, firstSliverHeight)),
        ),
        RenderSliverFillRemainingWithScrollable(
          child: RenderSizedBox(const Size(100.0, sliverFillRemainingChildHeight)),
        )
      ];

      final RenderViewport root = RenderViewport(
        crossAxisDirection: AxisDirection.right,
        offset: ViewportOffset.zero(),
        cacheExtent: cacheExtent,
        children: slivers,
      );
      layout(root);

      final RenderSliver firstVisibleSliver = slivers[0];
      expectSliverConstraints(
        sliver: firstVisibleSliver,
        cacheOrigin: 0.0,
        remainingPaintExtent: viewportHeight,
        remainingCacheExtent: beginningViewportCacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: firstVisibleSliver,
        paintExtent: firstSliverHeight,
        cacheExtent: firstSliverHeight,
        visible: true,
      );

      // When RenderSliverFillRemainingWithScrollable is initially within the
      // viewport, its paintExtent fills the remainingPaintExtent and it's
      // visible. The cacheExtent is either the size of the viewport or the
      // remainingCacheExtent, whichever is smaller.
      final RenderSliver sliverFillRemaining = slivers[1];
      const double remainingPaintExtentAfterFirstSliver = viewportHeight - firstSliverHeight;
      const double remainingCacheExtentAfterFirstSliver = beginningViewportCacheExtent - firstSliverHeight;
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: remainingPaintExtentAfterFirstSliver,
        remainingCacheExtent: remainingCacheExtentAfterFirstSliver,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: remainingPaintExtentAfterFirstSliver,
        cacheExtent: remainingCacheExtentAfterFirstSliver,
        visible: true,
      );

      // Overscroll so first sliver is partially out of view.
      root.offset = ViewportOffset.fixed(50);
      pumpFrame();

      // When you overscroll but RenderSliverFillRemainingWithScrollable does not
      // take up the entire viewport, its paintExtent fills the remainingPaintExtent
      // and it's visible. The cacheExtent is either the size of the viewport or the
      // remainingCacheExtent, whichever is smaller.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: remainingPaintExtentAfterFirstSliver + 50,
        remainingCacheExtent: remainingCacheExtentAfterFirstSliver + 50,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: remainingPaintExtentAfterFirstSliver + 50,
        cacheExtent: remainingCacheExtentAfterFirstSliver + 50,
        visible: true,
      );

      // Overscroll so only RenderSliverFillRemainingWithScrollable is visible
      root.offset = ViewportOffset.fixed(firstSliverHeight);
      pumpFrame();

      // When you overscroll and RenderSliverFillRemainingWithScrollable takes
      // up the entire viewport, its paintExtent fills the viewport and it's
      // visible. The cacheExtent also fills the viewport.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: viewportHeight,
        remainingCacheExtent: beginningViewportCacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: viewportHeight,
        cacheExtent: viewportHeight,
        visible: true,
      );
    });

    test('when scrolled into view', () {
      // Viewport is 800x600
      const double viewportHeight = 600;
      const double cacheExtent = 250.0;
      const double beginningViewportCacheExtent = viewportHeight + cacheExtent;
      const double firstSliverHeight = beginningViewportCacheExtent;
      const double sliverFillRemainingChildHeight = 100.0;

      final List<RenderSliver> slivers = <RenderSliver>[
        RenderSliverToBoxAdapter(
          child: RenderSizedBox(const Size(400.0, firstSliverHeight)),
        ),
        RenderSliverFillRemainingWithScrollable(
          child: RenderSizedBox(const Size(100.0, sliverFillRemainingChildHeight)),
        )
      ];

      final RenderViewport root = RenderViewport(
        crossAxisDirection: AxisDirection.right,
        offset: ViewportOffset.zero(),
        cacheExtent: cacheExtent,
        children: slivers,
      );
      layout(root);

      final RenderSliver firstVisibleSliver = slivers[0];
      expectSliverConstraints(
        sliver: firstVisibleSliver,
        cacheOrigin: 0.0,
        remainingPaintExtent: viewportHeight,
        remainingCacheExtent: beginningViewportCacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: firstVisibleSliver,
        paintExtent: viewportHeight,
        cacheExtent: firstSliverHeight,
        visible: true,
      );

      // When RenderSliverFillRemainingWithScrollable is completely outside the
      // viewport, it has no paintExtent and is not visible. When it's outside
      // of the remainingCacheExtent, it does not have a cacheExtent.
      final RenderSliver sliverFillRemaining = slivers[1];
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: 0.0,
        remainingCacheExtent: 0.0,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: 0.0,
        cacheExtent: 0.0,
        visible: false,
      );

      // Scroll so RenderSliverFillRemainingWithScrollable is not within
      // viewport, but is within remainingCacheExtent.
      root.offset = ViewportOffset.fixed(cacheExtent);
      pumpFrame();

      // When RenderSliverFillRemainingWithScrollable is completely outside the
      // viewport, it has no paintExtent and is not visible. When it's scrolled
      // within the remainingCacheExtent, the cacheExtent is either the size of
      // the viewport or the remainingCacheExtent, whichever is smaller.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: 0.0,
        remainingCacheExtent: cacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: 0.0,
        cacheExtent: cacheExtent,
        visible: false,
      );

      // Scroll so RenderSliverFillRemainingWithScrollable is partially within
      // viewport.
      root.offset = ViewportOffset.fixed(cacheExtent + 50);
      pumpFrame();

      // When RenderSliverFillRemainingWithScrollable is scrolled but does not
      // take up the entire viewport, its paintExtent fills the remainingPaintExtent
      // and it's visible. The cacheExtent is either the size of the viewport
      // or the remainingCacheExtent, whichever is smaller.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: 50.0,
        remainingCacheExtent: cacheExtent + 50,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: 50.0,
        cacheExtent: cacheExtent + 50,
        visible: true,
      );

      // Scroll so RenderSliverFillRemainingWithScrollable takes the entire
      // viewport.
      root.offset = ViewportOffset.fixed(firstSliverHeight);
      pumpFrame();

      // When you scroll and RenderSliverFillRemainingWithScrollable takes
      // up the entire viewport, its paintExtent fills the viewport and it's
      // visible. The cacheExtent also fills the viewport.
      expectSliverConstraints(
        sliver: sliverFillRemaining,
        cacheOrigin: 0.0,
        remainingPaintExtent: viewportHeight,
        remainingCacheExtent: beginningViewportCacheExtent,
        scrollOffset: 0.0,
      );
      expectSliverGeometry(
        sliver: sliverFillRemaining,
        paintExtent: viewportHeight,
        cacheExtent: viewportHeight,
        visible: true,
      );
    });
  });

}

void expectSliverConstraints({
  required RenderSliver sliver,
  required double cacheOrigin,
  required double remainingPaintExtent,
  required double remainingCacheExtent,
  required double scrollOffset,
}) {
  expect(sliver.constraints.cacheOrigin, cacheOrigin, reason: 'cacheOrigin');
  expect(sliver.constraints.remainingPaintExtent, remainingPaintExtent, reason: 'remainingPaintExtent');
  expect(sliver.constraints.remainingCacheExtent, remainingCacheExtent, reason: 'remainingCacheExtent');
  expect(sliver.constraints.scrollOffset, scrollOffset, reason: 'scrollOffset');
}

void expectSliverGeometry({
  required RenderSliver sliver,
  required double paintExtent,
  required double cacheExtent,
  required bool visible,
}) {
  expect(sliver.geometry!.paintExtent, paintExtent, reason: 'paintExtent');
  expect(sliver.geometry!.cacheExtent, cacheExtent, reason: 'cacheExtent');
  expect(sliver.geometry!.visible, visible, reason: 'visible');
}

class TestRenderSliverBoxChildManager extends RenderSliverBoxChildManager {
  TestRenderSliverBoxChildManager({
    required this.children,
  });

  RenderSliverMultiBoxAdaptor? _renderObject;
  List<RenderBox> children;

  RenderSliverList createRenderSliverList() {
    assert(_renderObject == null);
    _renderObject = RenderSliverList(childManager: this);
    return _renderObject! as RenderSliverList;
  }

  RenderSliverFixedExtentList createRenderSliverFixedExtentList() {
    assert(_renderObject == null);
    _renderObject = RenderSliverFixedExtentList(
      childManager: this,
      itemExtent: 100.0,
    );
    return _renderObject! as RenderSliverFixedExtentList;
  }

  RenderSliverGrid createRenderSliverGrid() {
    assert(_renderObject == null);
    _renderObject = RenderSliverGrid(
      childManager: this,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4.0,
      ),
    );
    return _renderObject! as RenderSliverGrid;
  }

  int? _currentlyUpdatingChildIndex;

  @override
  void createChild(int index, { required RenderBox? after }) {
    if (index < 0 || index >= children.length) {
      return;
    }
    try {
      _currentlyUpdatingChildIndex = index;
      _renderObject!.insert(children[index], after: after);
    } finally {
      _currentlyUpdatingChildIndex = null;
    }
  }

  @override
  void removeChild(RenderBox child) {
    _renderObject!.remove(child);
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) {
    assert(lastIndex! >= firstIndex!);
    return children.length * (trailingScrollOffset! - leadingScrollOffset!) / (lastIndex! - firstIndex! + 1);
  }

  @override
  int get childCount => children.length;

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  @override
  void setDidUnderflow(bool value) { }
}
