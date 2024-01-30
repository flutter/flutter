// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

/// {@tool dartpad}
/// This sample ...
///
/// ** See code in examples/api/lib/widgets/sliver/pinned_header_sliver.0.dart **
/// {@end-tool}
class PinnedHeaderSliver extends SingleChildRenderObjectWidget {
  const PinnedHeaderSliver({
    super.key,
    super.child,
  });

  @override
  RenderPinnedHeaderSliver createRenderObject(BuildContext context) {
    return RenderPinnedHeaderSliver();
  }
}

class RenderPinnedHeaderSliver extends RenderSliverSingleBoxAdapter {
  RenderPinnedHeaderSliver({ super.child });

  double get childExtent {
    if (child == null) {
      return 0.0;
    }
    assert(child!.hasSize);
    return switch (constraints.axis) {
      Axis.vertical => child!.size.height,
      Axis.horizontal => child!.size.width,
    };
  }

  @override
  double childMainAxisPosition(covariant RenderObject child) => 0;

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    child?.layout(constraints.asBoxConstraints(), parentUsesSize: true);

    final double layoutExtent = clampDouble(childExtent - constraints.scrollOffset, 0, constraints.remainingPaintExtent);
    final double paintExtent = math.min(childExtent, constraints.remainingPaintExtent - constraints.overlap);
    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintOrigin: constraints.overlap,
      paintExtent: paintExtent,
      layoutExtent: layoutExtent,
      maxPaintExtent: childExtent,
      maxScrollObstructionExtent: childExtent,
      cacheExtent: calculateCacheOffset(constraints, from: 0.0, to: childExtent),
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
  }
}
