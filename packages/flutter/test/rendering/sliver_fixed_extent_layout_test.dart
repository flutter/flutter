// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('RenderSliverFixedExtentList layout test - rounding error', () {
    final List<RenderBox> children = <RenderBox>[
      RenderSizedBox(const Size(400.0, 100.0)),
      RenderSizedBox(const Size(400.0, 100.0)),
      RenderSizedBox(const Size(400.0, 100.0)),
    ];
    final TestRenderSliverBoxChildManager childManager = TestRenderSliverBoxChildManager(
      children: children,
    );
    final RenderViewport root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 0,
      children: <RenderSliver>[
        childManager.createRenderSliverFillViewport(),
      ],
    );
    layout(root);
    expect(children[0].attached, true);
    expect(children[1].attached, false);

    root.offset = ViewportOffset.fixed(600);
    pumpFrame();
    expect(children[0].attached, false);
    expect(children[1].attached, true);

    // Simulate double precision error.
    root.offset = ViewportOffset.fixed(1199.999999999998);
    pumpFrame();
    expect(children[1].attached, false);
    expect(children[2].attached, true);
  });

  group('getMaxChildIndexForScrollOffset', () {
    // Regression test for https://github.com/flutter/flutter/issues/68182

    const double genericItemExtent = 600.0;
    const double extraValueToNotHaveRoundingIssues = 1e-10;
    const double extraValueToHaveRoundingIssues = 1e-11;

    test('should be 0 when item extent is 0', () {
      const double offsetValueWhichDoesntCare = 1234;
      final int actual = testGetMaxChildIndexForScrollOffset(offsetValueWhichDoesntCare, 0);
      expect(actual, 0);
    });

    test('should be 0 when offset is 0', () {
      final int actual = testGetMaxChildIndexForScrollOffset(0, genericItemExtent);
      expect(actual, 0);
    });

    test('should be 0 when offset is equal to item extent', () {
      final int actual = testGetMaxChildIndexForScrollOffset(genericItemExtent, genericItemExtent);
      expect(actual, 0);
    });

    test('should be 1 when offset is greater than item extent', () {
      final int actual = testGetMaxChildIndexForScrollOffset(genericItemExtent + 1, genericItemExtent);
      expect(actual, 1);
    });

    test('should be 1 when offset is slightly greater than item extent', () {
      final int actual = testGetMaxChildIndexForScrollOffset(
        genericItemExtent + extraValueToNotHaveRoundingIssues,
        genericItemExtent,
      );
      expect(actual, 1);
    });

    test('should be 4 when offset is four times and a half greater than item extent', () {
      final int actual = testGetMaxChildIndexForScrollOffset(genericItemExtent * 4.5, genericItemExtent);
      expect(actual, 4);
    });

    test('should be 5 when offset is 6 times greater than item extent', () {
      const double anotherGenericItemExtent = 414.0;
      final int actual = testGetMaxChildIndexForScrollOffset(
        anotherGenericItemExtent * 6,
        anotherGenericItemExtent,
      );
      expect(actual, 5);
    });

    test('should be 5 when offset is 6 times greater than a specific item extent where the division will return more than 13 zero decimals', () {
      const double itemExtentSpecificForAProblematicScreenSize = 411.42857142857144;
      final int actual = testGetMaxChildIndexForScrollOffset(
        itemExtentSpecificForAProblematicScreenSize * 6 + extraValueToHaveRoundingIssues,
        itemExtentSpecificForAProblematicScreenSize,
      );
      expect(actual, 5);
    });

    test('should be 0 when offset is a bit greater than item extent', () {
      final int actual = testGetMaxChildIndexForScrollOffset(
        genericItemExtent + extraValueToHaveRoundingIssues,
        genericItemExtent,
      );
      expect(actual, 0);
    });
  });
}

int testGetMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
  final TestRenderSliverFixedExtentBoxAdaptor renderSliver = TestRenderSliverFixedExtentBoxAdaptor();
  return renderSliver.getMaxChildIndexForScrollOffset(scrollOffset, itemExtent);
}

class TestRenderSliverBoxChildManager extends RenderSliverBoxChildManager {
  TestRenderSliverBoxChildManager({
    required this.children,
  });

  RenderSliverMultiBoxAdaptor? _renderObject;
  List<RenderBox> children;

  RenderSliverFillViewport createRenderSliverFillViewport() {
    assert(_renderObject == null);
    _renderObject = RenderSliverFillViewport(
      childManager: this,
    );
    return _renderObject! as RenderSliverFillViewport;
  }

  int? _currentlyUpdatingChildIndex;

  @override
  void createChild(int index, { required RenderBox? after }) {
    if (index < 0 || index >= children.length)
      return;
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

class TestRenderSliverFixedExtentBoxAdaptor extends RenderSliverFixedExtentBoxAdaptor {
  TestRenderSliverFixedExtentBoxAdaptor()
    :super(childManager: TestRenderSliverBoxChildManager(children: <RenderBox>[]));

  @override
  // ignore: unnecessary_overrides
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return super.getMaxChildIndexForScrollOffset(scrollOffset, itemExtent);
  }

  @override
  double get itemExtent => throw UnimplementedError();
}
