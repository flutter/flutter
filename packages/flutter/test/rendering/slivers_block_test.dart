// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

class TestRenderSliverBoxChildManager extends RenderSliverBoxChildManager {
  TestRenderSliverBoxChildManager({required this.children});

  late RenderSliverList _renderObject;
  List<RenderBox> children;

  RenderSliverList createRenderObject({double spacing = 0.0}) {
    _renderObject = RenderSliverList(childManager: this, spacing: spacing);
    return _renderObject;
  }

  int? _currentlyUpdatingChildIndex;

  @override
  void createChild(int index, {required RenderBox? after}) {
    if (index < 0 || index >= children.length) {
      return;
    }
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
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) {
    assert(lastIndex! >= firstIndex!);
    return children.length *
        (trailingScrollOffset! - leadingScrollOffset!) /
        (lastIndex! - firstIndex! + 1);
  }

  @override
  int get childCount => children.length;

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  @override
  void setDidUnderflow(bool value) {}
}

class ViewportOffsetSpy extends ViewportOffset {
  ViewportOffsetSpy(this._pixels);

  double _pixels;

  @override
  double get pixels => _pixels;

  @override
  bool get hasPixels => true;

  bool corrected = false;

  @override
  bool applyViewportDimension(double viewportDimension) => true;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) => true;

  @override
  void correctBy(double correction) {
    _pixels += correction;
    corrected = true;
  }

  @override
  void jumpTo(double pixels) {
    // Do nothing, not required in test.
  }

  @override
  Future<void> animateTo(double to, {required Duration duration, required Curve curve}) async {
    // Do nothing, not required in test.
  }

  @override
  ScrollDirection get userScrollDirection => ScrollDirection.idle;

  @override
  bool get allowImplicitScrolling => false;
}

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('RenderSliverList basic test - down', () {
    RenderObject inner;
    RenderBox a, b, c, d, e;
    final childManager = TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = RenderSizedBox(const Size(100.0, 400.0)),
        b = RenderSizedBox(const Size(100.0, 400.0)),
        c = RenderSizedBox(const Size(100.0, 400.0)),
        d = RenderSizedBox(const Size(100.0, 400.0)),
        e = RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    final root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 0.0,
      children: <RenderSliver>[inner = childManager.createRenderObject()],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(Offset.zero), Offset.zero);
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, 400.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // make sure that layout is stable by laying out again
    inner.markNeedsLayout();
    pumpFrame();
    expect(a.localToGlobal(Offset.zero), Offset.zero);
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, 400.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // now try various scroll offsets
    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(Offset.zero), const Offset(0.0, -200.0));
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, 200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, -200.0));
    expect(c.localToGlobal(Offset.zero), const Offset(0.0, 200.0));
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.attached, false);
    expect(c.localToGlobal(Offset.zero), const Offset(0.0, -100.0));
    expect(d.localToGlobal(Offset.zero), const Offset(0.0, 300.0));
    expect(e.attached, false);

    // try going back up
    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(Offset.zero), const Offset(0.0, -200.0));
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, 200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);
  });

  test('RenderSliverList basic test - up', () {
    RenderObject inner;
    RenderBox a, b, c, d, e;
    final childManager = TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = RenderSizedBox(const Size(100.0, 400.0)),
        b = RenderSizedBox(const Size(100.0, 400.0)),
        c = RenderSizedBox(const Size(100.0, 400.0)),
        d = RenderSizedBox(const Size(100.0, 400.0)),
        e = RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    final root = RenderViewport(
      axisDirection: AxisDirection.up,
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[inner = childManager.createRenderObject()],
      cacheExtent: 0.0,
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    expect(a.localToGlobal(Offset.zero), const Offset(0.0, 200.0));
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, -200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // make sure that layout is stable by laying out again
    inner.markNeedsLayout();
    pumpFrame();
    expect(a.localToGlobal(Offset.zero), const Offset(0.0, 200.0));
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, -200.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // now try various scroll offsets
    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(Offset.zero), const Offset(0.0, 400.0));
    expect(b.localToGlobal(Offset.zero), Offset.zero);
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = ViewportOffset.fixed(600.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, 400.0));
    expect(c.localToGlobal(Offset.zero), Offset.zero);
    expect(d.attached, false);
    expect(e.attached, false);

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.attached, false);
    expect(c.localToGlobal(Offset.zero), const Offset(0.0, 300.0));
    expect(d.localToGlobal(Offset.zero), const Offset(0.0, -100.0));
    expect(e.attached, false);

    // try going back up
    root.offset = ViewportOffset.fixed(200.0);
    pumpFrame();
    expect(a.localToGlobal(Offset.zero), const Offset(0.0, 400.0));
    expect(b.localToGlobal(Offset.zero), Offset.zero);
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);
  });

  test('SliverList - no zero scroll offset correction', () {
    RenderSliverList inner;
    RenderBox a;
    final childManager = TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = RenderSizedBox(const Size(100.0, 400.0)),
        RenderSizedBox(const Size(100.0, 400.0)),
        RenderSizedBox(const Size(100.0, 400.0)),
        RenderSizedBox(const Size(100.0, 400.0)),
        RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    final root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[inner = childManager.createRenderObject()],
    );
    layout(root);

    final parentData = a.parentData! as SliverMultiBoxAdaptorParentData;
    parentData.layoutOffset = 0.001;

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();

    root.offset = ViewportOffset.fixed(0.0);
    pumpFrame();

    expect(inner.geometry?.scrollOffsetCorrection, isNull);
  });

  test('SliverList - no correction when tiny double precision error', () {
    RenderSliverList inner;
    RenderBox a;
    final childManager = TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = RenderSizedBox(const Size(100.0, 400.0)),
        RenderSizedBox(const Size(100.0, 400.0)),
        RenderSizedBox(const Size(100.0, 400.0)),
        RenderSizedBox(const Size(100.0, 400.0)),
        RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    inner = childManager.createRenderObject();
    final root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[inner],
    );
    layout(root);

    final parentData = a.parentData! as SliverMultiBoxAdaptorParentData;
    // Simulate double precision error.
    parentData.layoutOffset = -0.0000000000001;

    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();

    final spy = ViewportOffsetSpy(0.0);
    root.offset = spy;
    pumpFrame();

    expect(spy.corrected, false);
  });

  test('RenderSliverList with spacing basic test - down and up with dead reckoning', () {
    RenderBox a, b, c, d, e;
    final childManager = TestRenderSliverBoxChildManager(
      children: <RenderBox>[
        a = RenderSizedBox(const Size(100.0, 400.0)),
        b = RenderSizedBox(const Size(100.0, 400.0)),
        c = RenderSizedBox(const Size(100.0, 400.0)),
        d = RenderSizedBox(const Size(100.0, 400.0)),
        e = RenderSizedBox(const Size(100.0, 400.0)),
      ],
    );
    final root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 0.0,
      children: <RenderSliver>[childManager.createRenderObject(spacing: 50.0)],
    );
    layout(root);

    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));

    // At offset 0.0:
    // a starts at 0.0, height 400.0
    // b starts at 400 + 50 = 450.0
    expect(a.localToGlobal(Offset.zero), Offset.zero);
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, 450.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);

    // Scroll into the gap between child a and child b (offset 420.0)
    root.offset = ViewportOffset.fixed(420.0);
    pumpFrame();
    expect(a.attached, false); // a ended at 400.0, collected as garbage
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, 30.0)); // 450.0 - 420.0 = 30.0
    expect(c.attached, true);
    expect(c.localToGlobal(Offset.zero), const Offset(0.0, 480.0)); // 900.0 - 420.0 = 480.0
    expect(d.attached, false);

    // Scroll to offset 900.0
    // b starts at 450.0, ends at 850.0.
    // c starts at 850.0 + 50.0 = 900.0.
    // d starts at 900.0 + 400.0 + 50.0 = 1350.0.
    root.offset = ViewportOffset.fixed(900.0);
    pumpFrame();
    expect(a.attached, false);
    expect(b.attached, false);
    expect(c.localToGlobal(Offset.zero), Offset.zero); // 900.0 - 900.0 = 0.0
    expect(d.localToGlobal(Offset.zero), const Offset(0.0, 450.0)); // 1350.0 - 900.0 = 450.0
    expect(e.attached, false);

    // Now scroll back up to offset 0.0 (tests reverse dead reckoning calculation with spacing)
    root.offset = ViewportOffset.fixed(0.0);
    pumpFrame();
    expect(a.attached, true);
    expect(a.localToGlobal(Offset.zero), Offset.zero);
    expect(b.localToGlobal(Offset.zero), const Offset(0.0, 450.0));
    expect(c.attached, false);
    expect(d.attached, false);
    expect(e.attached, false);
  });

  test(
    'RenderSliverList with variable heights and spacing calculates layout offsets correctly',
    () {
      final RenderBox a = RenderSizedBox(const Size(100.0, 50.0));
      final RenderBox b = RenderSizedBox(const Size(100.0, 120.0));
      final RenderBox c = RenderSizedBox(const Size(100.0, 80.0));
      final childManager = TestRenderSliverBoxChildManager(children: <RenderBox>[a, b, c]);
      final RenderSliverList sliver = childManager.createRenderObject(spacing: 20.0);
      final root = RenderViewport(
        crossAxisDirection: AxisDirection.right,
        offset: ViewportOffset.zero(),
        cacheExtent: 0.0,
        children: <RenderSliver>[sliver],
      );
      layout(root);

      // a starts at 0.0
      // b starts at 50.0 + 20.0 = 70.0
      // c starts at 70.0 + 120.0 + 20.0 = 210.0
      // Total extent: 210.0 + 80.0 = 290.0
      expect(sliver.childScrollOffset(a), 0.0);
      expect(sliver.childScrollOffset(b), 70.0);
      expect(sliver.childScrollOffset(c), 210.0);
      expect(sliver.geometry!.scrollExtent, 290.0);
      expect(sliver.geometry!.maxPaintExtent, 290.0);
    },
  );

  test('SliverMultiBoxAdaptorParentData.toString', () {
    final candidate = SliverMultiBoxAdaptorParentData();
    expect(candidate.keepAlive, isFalse);
    expect(candidate.index, isNull);
    expect(candidate.toString(), 'index=null; layoutOffset=None');
    candidate.keepAlive = true;
    expect(candidate.toString(), 'index=null; keepAlive; layoutOffset=None');
    candidate.keepAlive = false;
    expect(candidate.toString(), 'index=null; layoutOffset=None');
    candidate.index = 0;
    expect(candidate.toString(), 'index=0; layoutOffset=None');
    candidate.index = 1;
    expect(candidate.toString(), 'index=1; layoutOffset=None');
    candidate.index = -1;
    expect(candidate.toString(), 'index=-1; layoutOffset=None');
    candidate.layoutOffset = 100.0;
    expect(candidate.toString(), 'index=-1; layoutOffset=100.0');
  });
}
