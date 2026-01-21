// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('RenderSliver.getMaxPaintRect AxisDirection.down', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 100.0, paintExtent: 100.0, maxPaintExtent: 100.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 300.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect AxisDirection.down and GrowthDirection.reverse', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 100.0, paintExtent: 100.0, maxPaintExtent: 100.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.reverse,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 300.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect AxisDirection.down scrolled', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 100.0, paintExtent: 50.0, maxPaintExtent: 100.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 50.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 50.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    // Rect should be shifted up by scrollOffset.
    // Rect.fromLTWH(0.0, -50.0, 100.0, 100.0)
    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, -50.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect AxisDirection.up', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 100.0, paintExtent: 100.0, maxPaintExtent: 100.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.up,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 300.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect AxisDirection.up scrolled', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 100.0, paintExtent: 50.0, maxPaintExtent: 100.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.up,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 50.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 50.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    // For Up:
    // rect = (0, -50, 100, 100)
    // paintExtent = 50
    // Result L: 0
    // Result T: 50 - 100 = -50? No.
    // Code: paintExtent - rect.bottom
    // rect.bottom = 50. paintExtent = 50. Result T = 0.
    // Result R: 100
    // Result B: paintExtent - rect.top
    // rect.top = -50. Result B = 50 - (-50) = 100.
    // Rect(0, 0, 100, 100)
    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect AxisDirection.right', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 100.0, paintExtent: 100.0, maxPaintExtent: 100.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.right,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 300.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.down,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect AxisDirection.right scrolled', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 100.0, paintExtent: 50.0, maxPaintExtent: 100.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.right,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 50.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 50.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.down,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    // Horizontal axis.
    // rect = (-50, 0, 100, 100)
    // Right: returns rect.
    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(-50.0, 0.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect AxisDirection.left', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 100.0, paintExtent: 100.0, maxPaintExtent: 100.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.left,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 300.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.down,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect AxisDirection.left scrolled', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 100.0, paintExtent: 50.0, maxPaintExtent: 100.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.left,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 50.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 50.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.down,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    // Horizontal axis.
    // rect = (-50, 0, 100, 100). Left: -50, Right: 50.
    // Left direction:
    // L: paintExtent - rect.right = 50 - 50 = 0.
    // T: rect.top = 0.
    // R: paintExtent - rect.left = 50 - (-50) = 100.
    // B: rect.bottom = 100.
    // Rect(0, 0, 100, 100)
    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect pinned', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(
        scrollExtent: 100.0,
        paintExtent: 10.0,
        maxPaintExtent: 100.0,
        maxScrollObstructionExtent: 10.0,
      ),
    );

    // Scroll offset 95. Pinned at 10.
    // clampedScrollOffset should be min(95, 100 - 10) = 90.
    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 95.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 10.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    // Rect.fromLTWH(0.0, -90.0, 100.0, 100.0)
    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, -90.0, 100.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect infinite maxPaintExtent', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(
        scrollExtent: double.infinity,
        paintExtent: 100.0,
        maxPaintExtent: double.infinity,
        cacheExtent: 150.0,
      ),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 50.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 300.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 200.0,
        cacheOrigin: -50.0,
      ),
    );

    // maxPaintExtent = scrollOffset + cacheExtent + cacheOrigin
    // = 50 + 150 + (-50) = 150.
    // Rect.fromLTWH(0.0, -50.0, 100.0, 150.0)
    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, -50.0, 100.0, 150.0));
  });

  test('RenderSliver.getMaxPaintRect with crossAxisExtent set (e.g. SliverCrossAxisGroup)', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(
        scrollExtent: 100.0,
        paintExtent: 100.0,
        maxPaintExtent: 100.0,
        crossAxisExtent: 50.0,
      ),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 300.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, 0.0, 50.0, 100.0));
  });

  test('RenderSliver.getMaxPaintRect maxPaintExtent > remainingPaintExtent', () {
    final sliver = _TestRenderSliver(
      const SliverGeometry(scrollExtent: 200.0, paintExtent: 100.0, maxPaintExtent: 150.0),
    );

    sliver.layout(
      const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 100.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      ),
    );

    // getMaxPaintRect should use maxPaintExtent (150.0) regardless of remainingPaintExtent (100.0).
    expect(sliver.getMaxPaintRect(), const Rect.fromLTWH(0.0, 0.0, 100.0, 150.0));
  });
}

/// A [RenderSliver] that allows setting its [geometry] directly for testing purposes.
class _TestRenderSliver extends RenderSliver {
  _TestRenderSliver(this._geometry);

  final SliverGeometry _geometry;

  @override
  void performLayout() {
    geometry = _geometry;
  }

  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  Rect getMaxPaintRect() => super.getMaxPaintRect();
}
