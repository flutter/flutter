// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

class RenderTestBox extends RenderBox {
  late Size boxSize;
  int calls = 0;
  double value = 0.0;
  double next() {
    value += 1.0;
    return value;
  }
  @override
  double computeMinIntrinsicWidth(double height) => next();
  @override
  double computeMaxIntrinsicWidth(double height) => next();
  @override
  double computeMinIntrinsicHeight(double width) => next();
  @override
  double computeMaxIntrinsicHeight(double width) => next();

  @override
  void performLayout() {
    size = constraints.biggest;
    boxSize = size;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    calls += 1;
    return boxSize.height / 2.0;
  }
}

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('Intrinsics cache', () {
    final RenderBox test = RenderTestBox();

    expect(test.getMinIntrinsicWidth(0.0), equals(1.0));
    expect(test.getMinIntrinsicWidth(100.0), equals(2.0));
    expect(test.getMinIntrinsicWidth(200.0), equals(3.0));
    expect(test.getMinIntrinsicWidth(0.0), equals(1.0));
    expect(test.getMinIntrinsicWidth(100.0), equals(2.0));
    expect(test.getMinIntrinsicWidth(200.0), equals(3.0));

    expect(test.getMaxIntrinsicWidth(0.0), equals(4.0));
    expect(test.getMaxIntrinsicWidth(100.0), equals(5.0));
    expect(test.getMaxIntrinsicWidth(200.0), equals(6.0));
    expect(test.getMaxIntrinsicWidth(0.0), equals(4.0));
    expect(test.getMaxIntrinsicWidth(100.0), equals(5.0));
    expect(test.getMaxIntrinsicWidth(200.0), equals(6.0));

    expect(test.getMinIntrinsicHeight(0.0), equals(7.0));
    expect(test.getMinIntrinsicHeight(100.0), equals(8.0));
    expect(test.getMinIntrinsicHeight(200.0), equals(9.0));
    expect(test.getMinIntrinsicHeight(0.0), equals(7.0));
    expect(test.getMinIntrinsicHeight(100.0), equals(8.0));
    expect(test.getMinIntrinsicHeight(200.0), equals(9.0));

    expect(test.getMaxIntrinsicHeight(0.0), equals(10.0));
    expect(test.getMaxIntrinsicHeight(100.0), equals(11.0));
    expect(test.getMaxIntrinsicHeight(200.0), equals(12.0));
    expect(test.getMaxIntrinsicHeight(0.0), equals(10.0));
    expect(test.getMaxIntrinsicHeight(100.0), equals(11.0));
    expect(test.getMaxIntrinsicHeight(200.0), equals(12.0));

    // now read them all again backwards
    expect(test.getMaxIntrinsicHeight(200.0), equals(12.0));
    expect(test.getMaxIntrinsicHeight(100.0), equals(11.0));
    expect(test.getMaxIntrinsicHeight(0.0), equals(10.0));
    expect(test.getMinIntrinsicHeight(200.0), equals(9.0));
    expect(test.getMinIntrinsicHeight(100.0), equals(8.0));
    expect(test.getMinIntrinsicHeight(0.0), equals(7.0));
    expect(test.getMaxIntrinsicWidth(200.0), equals(6.0));
    expect(test.getMaxIntrinsicWidth(100.0), equals(5.0));
    expect(test.getMaxIntrinsicWidth(0.0), equals(4.0));
    expect(test.getMinIntrinsicWidth(200.0), equals(3.0));
    expect(test.getMinIntrinsicWidth(100.0), equals(2.0));
    expect(test.getMinIntrinsicWidth(0.0), equals(1.0));

  });

  // Regression test for https://github.com/flutter/flutter/issues/101179
  test('Cached baselines should be cleared if its parent re-layout', () {
    double viewHeight =  200.0;
    final RenderTestBox test = RenderTestBox();
    final RenderBox baseline = RenderBaseline(
      baseline: 0.0,
      baselineType: TextBaseline.alphabetic,
      child: test,
    );
    final RenderConstrainedBox root = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tightFor(width: 200.0, height: viewHeight),
      child: baseline,
    );

    layout(RenderPositionedBox(
      child: root,
    ));

    BoxParentData? parentData = test.parentData as BoxParentData?;
    expect(parentData!.offset.dy, -(viewHeight / 2.0));
    expect(test.calls, 1);

    // Trigger the root render re-layout.
    viewHeight = 300.0;
    root.additionalConstraints = BoxConstraints.tightFor(width: 200.0, height: viewHeight);
    pumpFrame();

    parentData = test.parentData as BoxParentData?;
    expect(parentData!.offset.dy, -(viewHeight / 2.0));
    expect(test.calls, 2); // The layout constraints change will clear the cached data.

    final RenderObject parent = test.parent! as RenderObject;
    expect(parent.debugNeedsLayout, false);

    // Do not forget notify parent dirty after the cached data be cleared by `layout()`
    test.markNeedsLayout();
    expect(parent.debugNeedsLayout, true);

    pumpFrame();
    expect(parent.debugNeedsLayout, false);
    expect(test.calls, 3); // Self dirty will clear the cached data.

    parent.markNeedsLayout();
    pumpFrame();

    expect(test.calls, 3); // Use the cached data if the layout constraints do not change.
  });
}
