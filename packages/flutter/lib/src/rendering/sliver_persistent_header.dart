// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'binding.dart';
import 'object.dart';
import 'sliver.dart';
import 'viewport_offset.dart';

abstract class RenderSliverPersistentHeader extends RenderSliver with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  RenderSliverPersistentHeader({ RenderBox child }) {
    this.child = child;
  }

  double get maxExtent;

  /// The intrinsic size of the child as of the last time the sliver was laid out.
  ///
  /// If the render object is dirty (i.e. if [markNeedsLayout] has been called,
  /// or if the object was newly created), then the returned value will be stale
  /// until [layoutChild] has been called.
  @protected
  double get minExtent => _minExtent;
  double _minExtent;

  @protected
  double get childExtent {
    if (child == null)
      return 0.0;
    assert(child.hasSize);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.vertical:
        return child.size.height;
      case Axis.horizontal:
        return child.size.width;
    }
    return null;
  }

  @protected
  double _getChildIntrinsicExtent() {
    if (child == null)
      return 0.0;
    assert(child != null);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.vertical:
        return child.getMinIntrinsicHeight(constraints.crossAxisExtent);
      case Axis.horizontal:
        return child.getMinIntrinsicWidth(constraints.crossAxisExtent);
    }
    return null;
  }

  /// The last value that we passed to updateChild().
  double _lastShrinkOffset;

  /// Called during layout if the shrink offset has changed.
  ///
  /// During this callback, the [child] can be set, mutated, or replaced.
  @protected
  void updateChild(double shrinkOffset) { }

  /// Flag the current child as stale and needing updating even if the shrink
  /// offset has not changed.
  ///
  /// Call this whenever [updateChild] would change or mutate the child even if
  /// given the same `shrinkOffset` as the last time it was called.
  ///
  /// This must be implemented by [RenderSliverPersistentHeader] subclasses such
  /// that the next layout after this call will result in [updateChild] being
  /// called.
  @protected
  void markNeedsUpdate() {
    markNeedsLayout();
    _lastShrinkOffset = null;
  }

  void layoutChild(double scrollOffset, double maxExtent) {
    assert(maxExtent != null);
    final double shrinkOffset = math.min(scrollOffset, maxExtent);
    if (shrinkOffset != _lastShrinkOffset) {
      invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
        assert(constraints == this.constraints);
        updateChild(shrinkOffset);
        _minExtent = _getChildIntrinsicExtent();
      });
      _lastShrinkOffset = shrinkOffset;
    }
    assert(_minExtent != null);
    assert(() {
      if (_minExtent <= maxExtent)
        return true;
      throw new FlutterError(
        'The maxExtent for this $runtimeType is less than the child\'s intrinsic extent.\n'
        'The specified maxExtent was: ${maxExtent.toStringAsFixed(1)}\n'
        'The child was updated with shrink offset: ${shrinkOffset.toStringAsFixed(1)}\n'
        'The actual measured intrinsic extent of the child was: ${_minExtent.toStringAsFixed(1)}\n'
      );
    });
    child?.layout(
      constraints.asBoxConstraints(maxExtent: math.max(_minExtent, maxExtent - shrinkOffset)),
      parentUsesSize: true,
    );
  }

  /// Returns the distance from the leading _visible_ edge of the sliver to the
  /// side of the child closest to that edge, in the scroll axis direction.
  ///
  /// For example, if the [constraints] describe this sliver as having an axis
  /// direction of [AxisDirection.down], then this is the distance from the top
  /// of the visible portion of the sliver to the top of the child. If the child
  /// is scrolled partially off the top of the viewport, then this will be
  /// negative. On the other hand, if the [constraints] describe this sliver as
  /// having an axis direction of [AxisDirection.up], then this is the distance
  /// from the bottom of the visible portion of the sliver to the bottom of the
  /// child. In both cases, this is the direction of increasing
  /// [SliverConstraints.scrollOffset].
  ///
  /// Calling this when the child is not visible is not valid.
  ///
  /// The argument must be the value of the [child] property.
  ///
  /// This must be implemented by [RenderSliverPersistentHeader] subclasses.
  ///
  /// If there is no child, this should return 0.0.
  @override
  double childMainAxisPosition(@checked RenderObject child) => super.childMainAxisPosition(child);

  @override
  bool hitTestChildren(HitTestResult result, { @required double mainAxisPosition, @required double crossAxisPosition }) {
    assert(geometry.hitTestExtent > 0.0);
    if (child != null)
      return hitTestBoxChild(result, child, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition);
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child == this.child);
    applyPaintTransformForBoxChild(child, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry.visible) {
      assert(constraints.axisDirection != null);
      switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
        case AxisDirection.up:
          offset += new Offset(0.0, geometry.paintExtent - childMainAxisPosition(child) - childExtent);
          break;
        case AxisDirection.down:
          offset += new Offset(0.0, childMainAxisPosition(child));
          break;
        case AxisDirection.left:
          offset += new Offset(geometry.paintExtent - childMainAxisPosition(child) - childExtent, 0.0);
          break;
        case AxisDirection.right:
          offset += new Offset(childMainAxisPosition(child), 0.0);
          break;
      }
      context.paintChild(child, offset);
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    try {
      description.add('maxExtent: ${maxExtent.toStringAsFixed(1)}');
    } catch (e) {
      description.add('maxExtent: EXCEPTION (${e.runtimeType}) WHILE COMPUTING MAX EXTENT');
    }
    try {
      description.add('child position: ${childMainAxisPosition(child).toStringAsFixed(1)}');
    } catch (e) {
      description.add('child position: EXCEPTION (${e.runtimeType}) WHILE COMPUTING CHILD POSITION');
    }
  }
}

/// A sliver with a [RenderBox] child which scrolls normally, except that when
/// it hits the leading edge (typically the top) of the viewport, it shrinks to
/// a minimum size before continuing to scroll.
///
/// This sliver makes no effort to avoid overlapping other content.
abstract class RenderSliverScrollingPersistentHeader extends RenderSliverPersistentHeader {
  RenderSliverScrollingPersistentHeader({
    RenderBox child,
  }) : super(child: child);

  // Distance from our leading edge to the child's leading edge, in the axis
  // direction. Negative if we're scrolled off the top.
  double _childPosition;

  @override
  void performLayout() {
    final double maxExtent = this.maxExtent;
    layoutChild(constraints.scrollOffset, maxExtent);
    final double paintExtent = maxExtent - constraints.scrollOffset;
    geometry = new SliverGeometry(
      scrollExtent: maxExtent,
      paintExtent: paintExtent.clamp(0.0, constraints.remainingPaintExtent),
      maxPaintExtent: maxExtent,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
    _childPosition = math.min(0.0, paintExtent - childExtent);
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    return _childPosition;
  }
}

/// A sliver with a [RenderBox] child which never scrolls off the viewport in
/// the positive scroll direction, and which first scrolls on at a full size but
/// then shrinks as the viewport continues to scroll.
///
/// This sliver avoids overlapping other earlier slivers where possible.
abstract class RenderSliverPinnedPersistentHeader extends RenderSliverPersistentHeader {
  RenderSliverPinnedPersistentHeader({
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    final double maxExtent = this.maxExtent;
    layoutChild(constraints.scrollOffset + constraints.overlap, maxExtent);
    geometry = new SliverGeometry(
      scrollExtent: maxExtent,
      paintExtent: math.min(constraints.overlap + childExtent, constraints.remainingPaintExtent),
      layoutExtent: (maxExtent - constraints.scrollOffset).clamp(0.0, constraints.remainingPaintExtent),
      maxPaintExtent: constraints.overlap + maxExtent,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    return constraints?.overlap;
  }
}

abstract class RenderSliverFloatingPersistentHeader extends RenderSliverPersistentHeader {
  RenderSliverFloatingPersistentHeader({
    RenderBox child,
  }) : super(child: child);

  double _lastActualScrollOffset;
  double _effectiveScrollOffset;

  // Distance from our leading edge to the child's leading edge, in the axis
  // direction. Negative if we're scrolled off the top.
  double _childPosition;

  @override
  void performLayout() {
    final double maxExtent = this.maxExtent;
    if (_lastActualScrollOffset != null && // We've laid out at least once to get an initial position, and either
        ((constraints.scrollOffset < _lastActualScrollOffset) || // we are scrolling back, so should reveal, or
         (_effectiveScrollOffset < maxExtent))) { // some part of it is visible, so should shrink or reveal as appropriate.
      double delta = _lastActualScrollOffset - constraints.scrollOffset;
      final bool allowFloatingExpansion = constraints.userScrollDirection == ScrollDirection.forward;
      if (allowFloatingExpansion) {
        if (_effectiveScrollOffset > maxExtent) // We're scrolled off-screen, but should reveal, so
          _effectiveScrollOffset = maxExtent; // pretend we're just at the limit.
      } else {
        if (delta > 0.0) // If we are trying to expand when allowFloatingExpansion is false,
          delta = 0.0; // disallow the expansion. (But allow shrinking, i.e. delta < 0.0 is fine.)
      }
      _effectiveScrollOffset = (_effectiveScrollOffset - delta).clamp(0.0, constraints.scrollOffset);
    } else {
      _effectiveScrollOffset = constraints.scrollOffset;
    }
    layoutChild(_effectiveScrollOffset, maxExtent);
    final double paintExtent = maxExtent - _effectiveScrollOffset;
    final double layoutExtent = (maxExtent - constraints.scrollOffset).clamp(0.0, constraints.remainingPaintExtent);
    geometry = new SliverGeometry(
      scrollExtent: maxExtent,
      paintExtent: paintExtent.clamp(0.0, constraints.remainingPaintExtent),
      layoutExtent: layoutExtent,
      maxPaintExtent: maxExtent,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
    _childPosition = math.min(0.0, paintExtent - childExtent);
    _lastActualScrollOffset = constraints.scrollOffset;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    return _childPosition;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('effective scroll offset: ${_effectiveScrollOffset?.toStringAsFixed(1)}');
  }
}
