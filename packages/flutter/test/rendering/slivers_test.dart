// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('RenderViewport basic test - no children', () {
    final RenderViewport root = new RenderViewport(
      offset: new ViewportOffset.zero(),
    );
    layout(root);
    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
  });

  test('RenderViewport basic test - down', () {
    RenderBox a, b, c, d, e;
    final RenderViewport root = new RenderViewport(
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        new RenderSliverToBoxAdapter(child: a = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: b = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: c = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: d = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: e = new RenderSizedBox(const Size(100.0, 400.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));

    expect(a.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 400.0));
    expect(b.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 800.0));
    expect(c.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1000.0));
    expect(d.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1000.0));
    expect(e.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1000.0));

    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -600.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -900.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -500.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));

    final HitTestResult result = new HitTestResult();
    root.hitTest(result, position: const Offset(130.0, 150.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderViewport basic test - up', () {
    RenderBox a, b, c, d, e;
    final RenderViewport root = new RenderViewport(
      axisDirection: AxisDirection.up,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        new RenderSliverToBoxAdapter(child: a = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: b = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: c = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: d = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: e = new RenderSizedBox(const Size(100.0, 400.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));

    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 800.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1100.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 700.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));

    final HitTestResult result = new HitTestResult();
    root.hitTest(result, position: const Offset(150.0, 350.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderViewport basic test - right', () {
    RenderBox a, b, c, d, e;
    final RenderViewport root = new RenderViewport(
      axisDirection: AxisDirection.right,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        new RenderSliverToBoxAdapter(child: a = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: b = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: c = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: d = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: e = new RenderSizedBox(const Size(400.0, 100.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(400.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));

    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-600.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-900.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(-500.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-100.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(300.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 0.0));

    final HitTestResult result = new HitTestResult();
    root.hitTest(result, position: const Offset(150.0, 450.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderViewport basic test - left', () {
    RenderBox a, b, c, d, e;
    final RenderViewport root = new RenderViewport(
      axisDirection: AxisDirection.left,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        new RenderSliverToBoxAdapter(child: a = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: b = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: c = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: d = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: e = new RenderSizedBox(const Size(400.0, 100.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(400.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));

    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(1000.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(1300.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(900.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(100.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-300.0, 0.0));

    final HitTestResult result = new HitTestResult();
    root.hitTest(result, position: const Offset(550.0, 150.0));
    expect(result.path.first.target, equals(c));
  });

  // TODO(ianh): test anchor
  // TODO(ianh): test center
  // TODO(ianh): test semantics

  test('RenderShrinkWrappingViewport basic test - no children', () {
    final RenderShrinkWrappingViewport root = new RenderShrinkWrappingViewport(
      offset: new ViewportOffset.zero(),
    );
    layout(root);
    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
  });

  test('RenderShrinkWrappingViewport basic test - down', () {
    RenderBox a, b, c, d, e;
    final RenderShrinkWrappingViewport root = new RenderShrinkWrappingViewport(
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        new RenderSliverToBoxAdapter(child: a = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: b = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: c = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: d = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: e = new RenderSizedBox(const Size(100.0, 400.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));

    expect(a.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 400.0));
    expect(b.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 800.0));
    expect(c.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1000.0));
    expect(d.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1000.0));
    expect(e.localToGlobal(const Offset(800.0, 400.0)), const Offset(800.0, 1000.0));

    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -600.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -900.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -500.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 600.0));

    final HitTestResult result = new HitTestResult();
    root.hitTest(result, position: const Offset(130.0, 150.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderShrinkWrappingViewport basic test - up', () {
    RenderBox a, b, c, d, e;
    final RenderShrinkWrappingViewport root = new RenderShrinkWrappingViewport(
      axisDirection: AxisDirection.up,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        new RenderSliverToBoxAdapter(child: a = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: b = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: c = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: d = new RenderSizedBox(const Size(100.0, 400.0))),
        new RenderSliverToBoxAdapter(child: e = new RenderSizedBox(const Size(100.0, 400.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 200.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -200.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));

    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 800.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 1100.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 700.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -100.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, -400.0));

    final HitTestResult result = new HitTestResult();
    root.hitTest(result, position: const Offset(150.0, 350.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderShrinkWrappingViewport basic test - right', () {
    RenderBox a, b, c, d, e;
    final RenderShrinkWrappingViewport root = new RenderShrinkWrappingViewport(
      axisDirection: AxisDirection.right,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        new RenderSliverToBoxAdapter(child: a = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: b = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: c = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: d = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: e = new RenderSizedBox(const Size(400.0, 100.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(400.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));

    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-600.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(800.0, 0.0));

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(-900.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(-500.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-100.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(300.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 0.0));

    final HitTestResult result = new HitTestResult();
    root.hitTest(result, position: const Offset(150.0, 450.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderShrinkWrappingViewport basic test - left', () {
    RenderBox a, b, c, d, e;
    final RenderShrinkWrappingViewport root = new RenderShrinkWrappingViewport(
      axisDirection: AxisDirection.left,
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        new RenderSliverToBoxAdapter(child: a = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: b = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: c = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: d = new RenderSizedBox(const Size(400.0, 100.0))),
        new RenderSliverToBoxAdapter(child: e = new RenderSizedBox(const Size(400.0, 100.0))),
      ],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(400.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));

    root.offset = new ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));

    root.offset = new ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(1000.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(-200.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-400.0, 0.0));

    root.offset = new ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.localToGlobal(const Offset(0.0, 0.0)), const Offset(1300.0, 0.0));
    expect(b.localToGlobal(const Offset(0.0, 0.0)), const Offset(900.0, 0.0));
    expect(c.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 0.0));
    expect(d.localToGlobal(const Offset(0.0, 0.0)), const Offset(100.0, 0.0));
    expect(e.localToGlobal(const Offset(0.0, 0.0)), const Offset(-300.0, 0.0));

    final HitTestResult result = new HitTestResult();
    root.hitTest(result, position: const Offset(550.0, 150.0));
    expect(result.path.first.target, equals(c));
  });

  test('RenderShrinkWrappingViewport shrinkwrap test - 1 child', () {
    RenderBox child;
    final RenderBox root = new RenderPositionedBox(
      child: child = new RenderShrinkWrappingViewport(
        axisDirection: AxisDirection.left,
        offset: new ViewportOffset.fixed(200.0),
        children: <RenderSliver>[
          new RenderSliverToBoxAdapter(child: new RenderSizedBox(const Size(400.0, 100.0))),
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
    final RenderBox root = new RenderPositionedBox(
      child: child = new RenderShrinkWrappingViewport(
        axisDirection: AxisDirection.right,
        offset: new ViewportOffset.fixed(200.0),
        children: <RenderSliver>[
          new RenderSliverToBoxAdapter(child: new RenderSizedBox(const Size(300.0, 100.0))),
          new RenderSliverToBoxAdapter(child: new RenderSizedBox(const Size(150.0, 100.0))),
        ],
      ),
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));
    expect(child.size.width, equals(450.0));
    expect(child.size.height, equals(600.0));
  });
}
