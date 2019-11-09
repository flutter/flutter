// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// A sliver that lays out its sliver children along the main axis of the view port.
class RenderSliverSection extends RenderSliver with ContainerRenderObjectMixin<RenderSliver, SliverPhysicalContainerParentData> {
  /// Creates a render object that lays out it children along the main axis of the viewport
  RenderSliverSection({
    this.key,
    bool pushPinnedHeaders = true,
    List<RenderSliver> children,
  }) : _pushPinnedHeaders = pushPinnedHeaders {
    addAll(children);
  }

  /// Doc
  final Key key;

  /// Doc
  bool get pushPinnedHeaders => _pushPinnedHeaders;
  bool _pushPinnedHeaders;
  set pushPinnedHeaders(bool newValue) {
    assert(newValue != null);
    if (newValue == _pushPinnedHeaders)
      return;
    _pushPinnedHeaders = newValue;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    assert(constraints != null);
    geometry = SliverGeometry.zero;
    double groupLayoutExtent = 0;
    double groupMaxPaintOffset = constraints.overlap;
    double groupPrecedingScrollExtent = constraints.precedingScrollExtent;
    double groupScrollOffset = constraints.scrollOffset;
    int groupTotalFlex = 0;

    RenderSliver child = firstChild;
    while (child != null) {
      final double childScrollOffset = math.max(
        0, groupScrollOffset - groupLayoutExtent);
      int childFlexFactor = _getFlex(child);
      groupTotalFlex += childFlexFactor;

      child.layout(
        constraints.copyWith(
          scrollOffset: childScrollOffset,
          precedingScrollExtent: groupPrecedingScrollExtent,
          overlap: groupMaxPaintOffset - groupLayoutExtent,
          remainingPaintExtent: math.max(
            0, constraints.remainingPaintExtent - groupLayoutExtent),
          remainingCacheExtent: math.max(
            0, constraints.remainingCacheExtent - groupLayoutExtent),
          cacheOrigin: math.max(-childScrollOffset, constraints.cacheOrigin),
          flexExtent: childFlexFactor > 0 && _spacePerFlex != null
            ? childFlexFactor * _spacePerFlex
            : 0.0,
        ),
        parentUsesSize: true
      );

      final SliverPhysicalContainerParentData childParentData = child
        .parentData;
      final SliverGeometry childGeometry = child.geometry;

      geometry = SliverGeometry(
        scrollExtent: geometry.scrollExtent + childGeometry.scrollExtent,
        paintExtent: math.max(geometry.paintExtent,
          groupLayoutExtent + childGeometry.paintOrigin +
            childGeometry.paintExtent),
        layoutExtent: geometry.layoutExtent + childGeometry.layoutExtent,
        maxPaintExtent: geometry.maxPaintExtent + childGeometry.maxPaintExtent,
        maxScrollObstructionExtent: geometry.maxScrollObstructionExtent +
          childGeometry.maxScrollObstructionExtent,
        hitTestExtent: geometry.hitTestExtent + childGeometry.hitTestExtent,
        visible: geometry.visible || childGeometry.visible,
        hasVisualOverflow: geometry.hasVisualOverflow ||
          childGeometry.hasVisualOverflow,
        scrollOffsetCorrection: childGeometry.scrollOffsetCorrection,
        cacheExtent: geometry.cacheExtent + childGeometry.cacheExtent,
      );

      // Scroll offset will be adjusted, and layout rerun.
      if (geometry.scrollOffsetCorrection != null)
        return;

      final double effectiveLayoutOffset = groupLayoutExtent +
        childGeometry.paintOrigin;

      childParentData.paintOffset =
        _computeAbsolutePaintOffset(child, effectiveLayoutOffset);

      groupMaxPaintOffset = math.max(
        effectiveLayoutOffset + childGeometry.paintExtent, groupMaxPaintOffset);

      groupLayoutExtent = groupLayoutExtent +
        math.min(constraints.remainingPaintExtent, childGeometry.layoutExtent);
      groupPrecedingScrollExtent += childGeometry.scrollExtent;
      groupScrollOffset -= childGeometry.scrollExtent;

      child = childParentData.nextSibling;
    }
  }
}