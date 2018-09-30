// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'viewport.dart';
import 'viewport_offset.dart';

/// A base class for slivers that have a [RenderBox] child which scrolls
/// normally, except that when it hits the leading edge (typically the top) of
/// the viewport, it shrinks to a minimum size ([minExtent]).
///
/// This class primarily provides helpers for managing the child, in particular:
///
///  * [layoutChild], which applies min and max extents and a scroll offset to
///    lay out the child. This is normally called from [performLayout].
///
///  * [childExtent], to convert the child's box layout dimensions to the sliver
///    geometry model.
///
///  * hit testing, painting, and other details of the sliver protocol.
///
/// Subclasses must implement [performLayout], [minExtent], and [maxExtent], and
/// typically also will implement [updateChild].
abstract class RenderSliverPersistentHeader extends RenderSliver with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  /// Creates a sliver that changes its size when scrolled to the start of the
  /// viewport.
  ///
  /// This is an abstract class; this constructor only initializes the [child].
  RenderSliverPersistentHeader({ RenderBox child }) {
    this.child = child;
  }

  /// The biggest that this render object can become, in the main axis direction.
  ///
  /// This value should not be based on the child. If it changes, call
  /// [markNeedsLayout].
  double get maxExtent;

  /// The smallest that this render object can become, in the main axis direction.
  ///
  /// If this is based on the intrinsic dimensions of the child, the child
  /// should be measured during [updateChild] and the value cached and returned
  /// here. The [updateChild] method will automatically be invoked any time the
  /// child changes its intrinsic dimensions.
  double get minExtent;

  /// The dimension of the child in the main axis.
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

  bool _needsUpdateChild = true;
  double _lastShrinkOffset = 0.0;
  bool _lastOverlapsContent = false;

  /// Update the child render object if necessary.
  ///
  /// Called before the first layout, any time [markNeedsLayout] is called, and
  /// any time the scroll offset changes. The `shrinkOffset` is the difference
  /// between the [maxExtent] and the current size. Zero means the header is
  /// fully expanded, any greater number up to [maxExtent] means that the header
  /// has been scrolled by that much. The `overlapsContent` argument is true if
  /// the sliver's leading edge is beyond its normal place in the viewport
  /// contents, and false otherwise. It may still paint beyond its normal place
  /// if the [minExtent] after this call is greater than the amount of space that
  /// would normally be left.
  ///
  /// The render object will size itself to the larger of (a) the [maxExtent]
  /// minus the child's intrinsic height and (b) the [maxExtent] minus the
  /// shrink offset.
  ///
  /// When this method is called by [layoutChild], the [child] can be set,
  /// mutated, or replaced. (It should not be called outside [layoutChild].)
  ///
  /// Any time this method would mutate the child, call [markNeedsLayout].
  @protected
  void updateChild(double shrinkOffset, bool overlapsContent) { }

  @override
  void markNeedsLayout() {
    // This is automatically called whenever the child's intrinsic dimensions
    // change, at which point we should remeasure them during the next layout.
    _needsUpdateChild = true;
    super.markNeedsLayout();
  }

  /// Lays out the [child].
  ///
  /// This is called by [performLayout]. It applies the given `scrollOffset`
  /// (which need not match the offset given by the [constraints]) and the
  /// `maxExtent` (which need not match the value returned by the [maxExtent]
  /// getter).
  ///
  /// The `overlapsContent` argument is passed to [updateChild].
  @protected
  void layoutChild(double scrollOffset, double maxExtent, { bool overlapsContent = false }) {
    assert(maxExtent != null);
    final double shrinkOffset = math.min(scrollOffset, maxExtent);
    if (_needsUpdateChild || _lastShrinkOffset != shrinkOffset || _lastOverlapsContent != overlapsContent) {
      invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
        assert(constraints == this.constraints);
        updateChild(shrinkOffset, overlapsContent);
      });
      _lastShrinkOffset = shrinkOffset;
      _lastOverlapsContent = overlapsContent;
      _needsUpdateChild = false;
    }
    assert(minExtent != null);
    assert(() {
      if (minExtent <= maxExtent)
        return true;
      throw FlutterError(
        'The maxExtent for this $runtimeType is less than its minExtent.\n'
        'The specified maxExtent was: ${maxExtent.toStringAsFixed(1)}\n'
        'The specified minExtent was: ${minExtent.toStringAsFixed(1)}\n'
      );
    }());
    child?.layout(
      constraints.asBoxConstraints(maxExtent: math.max(minExtent, maxExtent - shrinkOffset)),
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
  double childMainAxisPosition(covariant RenderObject child) => super.childMainAxisPosition(child);

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
          offset += Offset(0.0, geometry.paintExtent - childMainAxisPosition(child) - childExtent);
          break;
        case AxisDirection.down:
          offset += Offset(0.0, childMainAxisPosition(child));
          break;
        case AxisDirection.left:
          offset += Offset(geometry.paintExtent - childMainAxisPosition(child) - childExtent, 0.0);
          break;
        case AxisDirection.right:
          offset += Offset(childMainAxisPosition(child), 0.0);
          break;
      }
      context.paintChild(child, offset);
    }
  }

  /// Whether the [SemanticsNode]s associated with this [RenderSliver] should
  /// be excluded from the semantic scrolling area.
  ///
  /// [RenderSliver]s that stay on the screen even though the user has scrolled
  /// past them (e.g. a pinned app bar) should set this to true.
  @protected
  bool get excludeFromSemanticsScrolling => _excludeFromSemanticsScrolling;
  bool _excludeFromSemanticsScrolling = false;
  set excludeFromSemanticsScrolling(bool value) {
    if (_excludeFromSemanticsScrolling == value)
      return;
    _excludeFromSemanticsScrolling = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    if (_excludeFromSemanticsScrolling)
      config.addTagForChildren(RenderViewport.excludeFromScrolling);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty.lazy('maxExtent', () => maxExtent));
    properties.add(DoubleProperty.lazy('child position', () => childMainAxisPosition(child)));
  }
}

/// A sliver with a [RenderBox] child which scrolls normally, except that when
/// it hits the leading edge (typically the top) of the viewport, it shrinks to
/// a minimum size before continuing to scroll.
///
/// This sliver makes no effort to avoid overlapping other content.
abstract class RenderSliverScrollingPersistentHeader extends RenderSliverPersistentHeader {
  /// Creates a sliver that shrinks when it hits the start of the viewport, then
  /// scrolls off.
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
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: math.min(constraints.overlap, 0.0),
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
  /// Creates a sliver that shrinks when it hits the start of the viewport, then
  /// stays pinned there.
  RenderSliverPinnedPersistentHeader({
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    final double maxExtent = this.maxExtent;
    final bool overlapsContent = constraints.overlap > 0.0;
    excludeFromSemanticsScrolling = overlapsContent || (constraints.scrollOffset > maxExtent - minExtent);
    layoutChild(constraints.scrollOffset, maxExtent, overlapsContent: overlapsContent);
    final double layoutExtent = (maxExtent - constraints.scrollOffset).clamp(0.0, constraints.remainingPaintExtent);
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: constraints.overlap,
      paintExtent: math.min(childExtent, constraints.remainingPaintExtent),
      layoutExtent: layoutExtent,
      maxPaintExtent: maxExtent,
      maxScrollObstructionExtent: minExtent,
      cacheExtent: layoutExtent > 0.0 ? -constraints.cacheOrigin + layoutExtent : layoutExtent,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) => 0.0;
}

/// Specifies how a floating header is to be "snapped" (animated) into or out
/// of view.
///
/// See also:
///
///  * [RenderSliverFloatingPersistentHeader.maybeStartSnapAnimation] and
///    [RenderSliverFloatingPersistentHeader.maybeStopSnapAnimation], which
///    start or stop the floating header's animation.
///  * [SliverAppBar], which creates a header that can be pinned, floating,
///    and snapped into view via the corresponding parameters.
class FloatingHeaderSnapConfiguration {
  /// Creates an object that specifies how a floating header is to be "snapped"
  /// (animated) into or out of view.
  FloatingHeaderSnapConfiguration({
    @required this.vsync,
    this.curve = Curves.ease,
    this.duration = const Duration(milliseconds: 300),
  }) : assert(vsync != null),
       assert(curve != null),
       assert(duration != null);

  /// The [TickerProvider] for the [AnimationController] that causes a
  /// floating header to snap in or out of view.
  final TickerProvider vsync;

  /// The snap animation curve.
  final Curve curve;

  /// The snap animation's duration.
  final Duration duration;
}

/// A sliver with a [RenderBox] child which shrinks and scrolls like a
/// [RenderSliverScrollingPersistentHeader], but immediately comes back when the
/// user scrolls in the reverse direction.
///
/// See also:
///
///  * [RenderSliverFloatingPinnedPersistentHeader], which is similar but sticks
///    to the start of the viewport rather than scrolling off.
abstract class RenderSliverFloatingPersistentHeader extends RenderSliverPersistentHeader {
  /// Creates a sliver that shrinks when it hits the start of the viewport, then
  /// scrolls off, and comes back immediately when the user reverses the scroll
  /// direction.
  RenderSliverFloatingPersistentHeader({
    RenderBox child,
    FloatingHeaderSnapConfiguration snapConfiguration,
  }) : _snapConfiguration = snapConfiguration, super(child: child);

  AnimationController _controller;
  Animation<double> _animation;
  double _lastActualScrollOffset;
  double _effectiveScrollOffset;

  // Distance from our leading edge to the child's leading edge, in the axis
  // direction. Negative if we're scrolled off the top.
  double _childPosition;

  @override
  void detach() {
    _controller?.dispose();
    _controller = null; // lazily recreated if we're reattached.
    super.detach();
  }

  /// Defines the parameters used to snap (animate) the floating header in and
  /// out of view.
  ///
  /// If [snapConfiguration] is null then the floating header does not snap.
  ///
  /// See also:
  ///
  ///  * [RenderSliverFloatingPersistentHeader.maybeStartSnapAnimation] and
  ///    [RenderSliverFloatingPersistentHeader.maybeStopSnapAnimation], which
  ///    start or stop the floating header's animation.
  ///  * [SliverAppBar], which creates a header that can be pinned, floating,
  ///    and snapped into view via the corresponding parameters.
  FloatingHeaderSnapConfiguration get snapConfiguration => _snapConfiguration;
  FloatingHeaderSnapConfiguration _snapConfiguration;
  set snapConfiguration(FloatingHeaderSnapConfiguration value) {
    if (value == _snapConfiguration)
      return;
    if (value == null) {
      _controller?.dispose();
    } else {
      if (_snapConfiguration != null && value.vsync != _snapConfiguration.vsync)
        _controller?.resync(value.vsync);
    }
    _snapConfiguration = value;
  }

  /// Updates [geometry], and returns the new value for [childMainAxisPosition].
  ///
  /// This is used by [performLayout].
  @protected
  double updateGeometry() {
    final double maxExtent = this.maxExtent;
    final double paintExtent = maxExtent - _effectiveScrollOffset;
    final double layoutExtent = maxExtent - constraints.scrollOffset;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: math.min(constraints.overlap, 0.0),
      paintExtent: paintExtent.clamp(0.0, constraints.remainingPaintExtent),
      layoutExtent: layoutExtent.clamp(0.0, constraints.remainingPaintExtent),
      maxPaintExtent: maxExtent,
      maxScrollObstructionExtent: maxExtent,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
    return math.min(0.0, paintExtent - childExtent);
  }

  /// If the header isn't already fully exposed, then scroll it into view.
  void maybeStartSnapAnimation(ScrollDirection direction) {
    if (snapConfiguration == null)
      return;
    if (direction == ScrollDirection.forward && _effectiveScrollOffset <= 0.0)
      return;
    if (direction == ScrollDirection.reverse && _effectiveScrollOffset >= maxExtent)
      return;

    final TickerProvider vsync = snapConfiguration.vsync;
    final Duration duration = snapConfiguration.duration;
    _controller ??= AnimationController(vsync: vsync, duration: duration)
      ..addListener(() {
        if (_effectiveScrollOffset == _animation.value)
          return;
        _effectiveScrollOffset = _animation.value;
        markNeedsLayout();
      });

    _animation = _controller.drive(
      Tween<double>(
        begin: _effectiveScrollOffset,
        end: direction == ScrollDirection.forward ? 0.0 : maxExtent,
      ).chain(CurveTween(
        curve: snapConfiguration.curve,
      )),
    );

    _controller.forward(from: 0.0);
  }

  /// If a header snap animation is underway then stop it.
  void maybeStopSnapAnimation(ScrollDirection direction) {
    _controller?.stop();
  }

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
    final bool overlapsContent = _effectiveScrollOffset < constraints.scrollOffset;
    excludeFromSemanticsScrolling = overlapsContent;
    layoutChild(_effectiveScrollOffset, maxExtent, overlapsContent: overlapsContent);
    _childPosition = updateGeometry();
    _lastActualScrollOffset = constraints.scrollOffset;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    return _childPosition;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('effective scroll offset', _effectiveScrollOffset));
  }
}

/// A sliver with a [RenderBox] child which shrinks and then remains pinned to
/// the start of the viewport like a [RenderSliverPinnedPersistentHeader], but
/// immediately grows when the user scrolls in the reverse direction.
///
/// See also:
///
///  * [RenderSliverFloatingPersistentHeader], which is similar but scrolls off
///    the top rather than sticking to it.
abstract class RenderSliverFloatingPinnedPersistentHeader extends RenderSliverFloatingPersistentHeader {
  /// Creates a sliver that shrinks when it hits the start of the viewport, then
  /// stays pinned there, and grows immediately when the user reverses the
  /// scroll direction.
  RenderSliverFloatingPinnedPersistentHeader({
    RenderBox child,
    FloatingHeaderSnapConfiguration snapConfiguration,
  }) : super(child: child, snapConfiguration: snapConfiguration);

  @override
  double updateGeometry() {
    final double minExtent = this.minExtent;
    final double maxExtent = this.maxExtent;
    final double paintExtent = maxExtent - _effectiveScrollOffset;
    final double layoutExtent = maxExtent - constraints.scrollOffset;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintExtent: paintExtent.clamp(minExtent, constraints.remainingPaintExtent),
      layoutExtent: layoutExtent.clamp(0.0, constraints.remainingPaintExtent - minExtent),
      maxPaintExtent: maxExtent,
      maxScrollObstructionExtent: maxExtent,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
    return 0.0;
  }
}
