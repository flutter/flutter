// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

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
      axisDirection: AxisDirection.down,
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
}

class TestRenderSliverBoxChildManager extends RenderSliverBoxChildManager {
  TestRenderSliverBoxChildManager({
    this.children,
  });

  RenderSliverMultiBoxAdaptor _renderObject;
  List<RenderBox> children;

  RenderSliverFillViewport createRenderSliverFillViewport() {
    assert(_renderObject == null);
    _renderObject = RenderSliverFillViewport(
      childManager: this,
    );
    return _renderObject as RenderSliverFillViewport;
  }

  int _currentlyUpdatingChildIndex;

  @override
  void createChild(int index, { @required RenderBox after }) {
    if (index < 0 || index >= children.length)
      return;
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
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    assert(lastIndex >= firstIndex);
    return children.length * (trailingScrollOffset - leadingScrollOffset) / (lastIndex - firstIndex + 1);
  }

  @override
  int get childCount => children.length;

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData as SliverMultiBoxAdaptorParentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  @override
  void setDidUnderflow(bool value) { }
}
