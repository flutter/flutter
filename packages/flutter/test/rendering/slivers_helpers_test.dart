// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AxisDirection and applyGrowthDirectionToAxisDirection', () {
    expect(AxisDirection.values.length, 4);
    for (AxisDirection axisDirection in AxisDirection.values)
      expect(applyGrowthDirectionToAxisDirection(axisDirection, GrowthDirection.forward), axisDirection);
    expect(applyGrowthDirectionToAxisDirection(AxisDirection.up, GrowthDirection.reverse), AxisDirection.down);
    expect(applyGrowthDirectionToAxisDirection(AxisDirection.down, GrowthDirection.reverse), AxisDirection.up);
    expect(applyGrowthDirectionToAxisDirection(AxisDirection.left, GrowthDirection.reverse), AxisDirection.right);
    expect(applyGrowthDirectionToAxisDirection(AxisDirection.right, GrowthDirection.reverse), AxisDirection.left);
  });

  test('SliverConstraints', () {
    const SliverConstraints a = SliverConstraints(
      axisDirection: AxisDirection.down,
      growthDirection: GrowthDirection.forward,
      userScrollDirection: ScrollDirection.idle,
      scrollOffset: 0.0,
      overlap: 0.0,
      remainingPaintExtent: 0.0,
      crossAxisExtent: 0.0,
      crossAxisDirection: AxisDirection.right,
      viewportMainAxisExtent: 0.0,
      cacheOrigin: 0.0,
      remainingCacheExtent: 0.0,
    );
    final SliverConstraints b = a.copyWith();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a.toString(), equals(b.toString()));
    expect(a, hasOneLineDescription);
    expect(a.normalizedGrowthDirection, equals(GrowthDirection.forward));

    final SliverConstraints c = a.copyWith(
      axisDirection: AxisDirection.up,
      growthDirection: GrowthDirection.reverse,
      userScrollDirection: ScrollDirection.forward,
      scrollOffset: 10.0,
      overlap: 20.0,
      remainingPaintExtent: 30.0,
      crossAxisExtent: 40.0,
      viewportMainAxisExtent: 30.0,
    );
    const SliverConstraints d = SliverConstraints(
      axisDirection: AxisDirection.up,
      growthDirection: GrowthDirection.reverse,
      userScrollDirection: ScrollDirection.forward,
      scrollOffset: 10.0,
      overlap: 20.0,
      remainingPaintExtent: 30.0,
      crossAxisExtent: 40.0,
      crossAxisDirection: AxisDirection.right,
      viewportMainAxisExtent: 30.0,
      cacheOrigin: 0.0,
      remainingCacheExtent: 0.0,
    );
    expect(c, equals(d));
    expect(c.normalizedGrowthDirection, equals(GrowthDirection.forward));
    expect(d.normalizedGrowthDirection, equals(GrowthDirection.forward));

    final SliverConstraints e = d.copyWith(axisDirection: AxisDirection.right);
    expect(e.normalizedGrowthDirection, equals(GrowthDirection.reverse));

    final SliverConstraints f = d.copyWith(axisDirection: AxisDirection.left);
    expect(f.normalizedGrowthDirection, equals(GrowthDirection.forward));

    final SliverConstraints g = d.copyWith(growthDirection: GrowthDirection.forward);
    expect(g.normalizedGrowthDirection, equals(GrowthDirection.reverse));
  });

  test('SliverGeometry', () {
    expect(const SliverGeometry().debugAssertIsValid(), isTrue);
    expect(() {
      const SliverGeometry(layoutExtent: 10.0, paintExtent: 9.0).debugAssertIsValid();
    }, throwsFlutterError);
    expect(() {
      const SliverGeometry(paintExtent: 9.0, maxPaintExtent: 8.0).debugAssertIsValid();
    }, throwsFlutterError);
  });
}
