// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('RenderSliverIndexedVariedExtentList basic layout', () {
    final List<double> extents = <double>[100.0, 150.0, 120.0];
    final List<RenderBox> children = extents
        .map((double height) => RenderSizedBox(Size(400.0, height)))
        .toList();

    final TestRenderSliverIndexedVariedExtentBoxChildManager childManager =
        TestRenderSliverIndexedVariedExtentBoxChildManager(children: children);
    final RenderSliverIndexedVariedExtentList sliver = childManager.createRenderSliver(
      itemExtentBuilder: (int index, _) => index < extents.length ? extents[index] : null,
    );

    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 0,
      children: <RenderSliver>[sliver],
    );

    layout(root);
    expect(children[0].attached, true);
    expect(children[1].attached, true);
    expect(children[2].attached, true);
    expect(sliver.firstChild!.size.height, 100.0);

    root.offset = ViewportOffset.fixed(101.0);
    pumpFrame();
    expect(children[0].attached, false);
    expect(children[1].attached, true);
    expect(children[2].attached, true);

    root.offset = ViewportOffset.fixed(260.0);
    pumpFrame();
    expect(children[0].attached, false);
    expect(children[1].attached, false);
    expect(children[2].attached, true);
  });

  test('RenderSliverIndexedVariedExtentList anchor scroll correction', () {
    final List<double> extents = <double>[100.0, 150.0, 120.0, 400.0];
    final List<RenderBox> children = extents
        .map((double height) => RenderSizedBox(Size(400.0, height)))
        .toList();
    final TestRenderSliverIndexedVariedExtentBoxChildManager childManager =
        TestRenderSliverIndexedVariedExtentBoxChildManager(children: children);

    const SliverIndexAnchor anchor = SliverIndexAnchor(index: 1, alignment: 0.5);
    final RenderSliverIndexedVariedExtentList sliver = childManager.createRenderSliver(
      anchor: anchor,
      itemExtentBuilder: (int index, _) => index < extents.length ? extents[index] : null,
    );

    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.fixed(100.0),
      children: <RenderSliver>[sliver],
    );

    layout(root);
    pumpFrame();
    final Rect initialRect = sliver.getAbsoluteProxyBoxRect(child: children[1])!;

    extents[0] = 200.0;
    sliver.itemExtentBuilder = (int index, _) => index < extents.length ? extents[index] : null;
    pumpFrame();

    final Rect finalRect = sliver.getAbsoluteProxyBoxRect(child: children[1])!;

    // The anchor item should not have moved visually.
    expect(finalRect.top, closeTo(initialRect.top, 0.01));
    expect(finalRect.left, closeTo(initialRect.left, 0.01));
  });

  group('getChildIndexForScrollOffset', () {
    int testGetChildIndex(double scrollOffset, List<double> extents) {
      final TestRenderSliverIndexedVariedExtentBoxChildManager childManager =
          TestRenderSliverIndexedVariedExtentBoxChildManager(children: const <RenderBox>[]);
      final RenderSliverIndexedVariedExtentList sliver = childManager.createRenderSliver(
        itemExtentBuilder: (int index, _) => index < extents.length ? extents[index] : null,
      );

      final RenderViewport root = RenderViewport(
        crossAxisDirection: AxisDirection.right,
        offset: ViewportOffset.zero(),
        children: <RenderSliver>[sliver],
      );

      layout(root);

      return sliver.getChildIndexForScrollOffset(scrollOffset);
    }

    test('should be 0 for offset 0', () {
      expect(testGetChildIndex(0.0, <double>[100, 100, 100]), 0);
    });

    test('should be 0 when offset is within the first item', () {
      expect(testGetChildIndex(50.0, <double>[100, 100, 100]), 0);
    });

    test('should return index 1 when offset is exactly at the start of the second item', () {
      expect(testGetChildIndex(100.0, <double>[100, 100, 100]), 1);
    });

    test('should be 1 when offset is just past the first item', () {
      expect(testGetChildIndex(100.1, <double>[100, 150, 120]), 1);
    });

    test('should handle varied extents correctly', () {
      final List<double> extents = <double>[50.0, 200.0, 75.0];
      expect(testGetChildIndex(49.9, extents), 0);
      expect(testGetChildIndex(50.0, extents), 1);
      expect(testGetChildIndex(50.1, extents), 1);
      expect(testGetChildIndex(249.9, extents), 1);
      expect(testGetChildIndex(250.0, extents), 2);
      expect(testGetChildIndex(250.1, extents), 2);
    });
  });

  test('Implements paintsChild correctly', () {
    final List<double> extents = <double>[300.0, 300.0, 300.0];
    final List<RenderSizedBox> children = extents
        .map((double height) => RenderSizedBox(Size(400.0, height)))
        .toList();

    final TestRenderSliverIndexedVariedExtentBoxChildManager childManager =
        TestRenderSliverIndexedVariedExtentBoxChildManager(children: children);
    final RenderSliverIndexedVariedExtentList sliver = childManager.createRenderSliver(
      itemExtentBuilder: (int index, _) => index < extents.length ? extents[index] : null,
    );
    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 0,
      children: <RenderSliver>[sliver],
    );

    layout(root, constraints: const BoxConstraints(maxWidth: 800, maxHeight: 599));

    expect(sliver.paintsChild(children[0]), isTrue); // Partially visible
    expect(sliver.paintsChild(children[1]), isTrue); // Partially visible
    expect(sliver.paintsChild(children[2]), isFalse);

    root.offset = ViewportOffset.fixed(300);
    pumpFrame();
    pumpFrame();
    pumpFrame();

    expect(sliver.paintsChild(children[0]), isFalse);
    expect(sliver.paintsChild(children[1]), isTrue);
    expect(
      sliver.paintsChild(children[2]),
      isTrue,
    ); // Starts at 600, visible in paint extent [300, 899)
  });
}

class TestRenderSliverIndexedVariedExtentBoxChildManager extends RenderSliverBoxChildManager {
  TestRenderSliverIndexedVariedExtentBoxChildManager({required this.children});

  RenderSliverIndexedVariedExtentList? _renderObject;
  final List<RenderBox> children;
  int? _currentlyUpdatingChildIndex;

  RenderSliverIndexedVariedExtentList createRenderSliver({
    required ItemExtentBuilder itemExtentBuilder,
    ItemPositionsListener? itemPositionsListener,
    SliverIndexAnchor anchor = SliverIndexAnchor.zero,
  }) {
    assert(_renderObject == null);
    _renderObject = RenderSliverIndexedVariedExtentList(
      childManager: this,
      itemExtentBuilder: itemExtentBuilder,
      itemPositionsListener: itemPositionsListener ?? ItemPositionsListener.create(),
      anchor: anchor,
      api: IndexedScrollAPI(),
    );
    return _renderObject!;
  }

  @override
  int get childCount => children.length;

  @override
  void createChild(int index, {required RenderBox? after}) {
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
    if (childCount == 0) {
      return 0.0;
    }
    final int visibleItems = lastIndex! - firstIndex! + 1;
    final double avgExtent = (trailingScrollOffset! - leadingScrollOffset!) / visibleItems;
    return avgExtent * children.length;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final SliverMultiBoxAdaptorParentData parentData =
        child.parentData! as SliverMultiBoxAdaptorParentData;
    parentData.index = _currentlyUpdatingChildIndex;
  }

  @override
  void setDidUnderflow(bool value) {}
}

extension on RenderSliver {
  Rect? getAbsoluteProxyBoxRect({required RenderBox child}) {
    final Matrix4 transform = child.getTransformTo(null);
    return MatrixUtils.transformRect(transform, Offset.zero & child.size);
  }
}
