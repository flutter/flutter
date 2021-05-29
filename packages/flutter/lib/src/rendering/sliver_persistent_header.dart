// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'viewport.dart';
import 'viewport_offset.dart';

// Trims the specified edges of the given `Rect` [original], so that they do not
// exceed the given values.
Rect? _trim(Rect? original, {
  double top = -double.infinity,
  double right = double.infinity,
  double bottom = double.infinity,
  double left = -double.infinity,
}) => original?.intersect(Rect.fromLTRB(left, top, right, bottom));

/// Specifies how a stretched header is to trigger an [AsyncCallback].
///
/// See also:
///
///  * [SliverAppBar], which creates a header that can be stretched into an
///    overscroll area and trigger a callback function.
class OverScrollHeaderStretchConfiguration {
  /// Creates an object that specifies how a stretched header may activate an
  /// [AsyncCallback].
  OverScrollHeaderStretchConfiguration({
    this.stretchTriggerOffset = 100.0,
    this.onStretchTrigger,
  }) : assert(stretchTriggerOffset != null);

  /// The offset of overscroll required to trigger the [onStretchTrigger].
  final double stretchTriggerOffset;

  /// The callback function to be executed when a user over-scrolls to the
  /// offset specified by [stretchTriggerOffset].
  final AsyncCallback? onStretchTrigger;
}

/// {@template flutter.rendering.PersistentHeaderShowOnScreenConfiguration}
/// Specifies how a pinned header or a floating header should react to
/// [RenderObject.showOnScreen] calls.
/// {@endtemplate}
@immutable
class PersistentHeaderShowOnScreenConfiguration {
  /// Creates an object that specifies how a pinned or floating persistent header
  /// should behave in response to [RenderObject.showOnScreen] calls.
  const PersistentHeaderShowOnScreenConfiguration({
    this.minShowOnScreenExtent = double.negativeInfinity,
    this.maxShowOnScreenExtent = double.infinity,
  }) : assert(minShowOnScreenExtent <= maxShowOnScreenExtent);

  /// The smallest the floating header can expand to in the main axis direction,
  /// in response to a [RenderObject.showOnScreen] call, in addition to its
  /// [RenderSliverPersistentHeader.minExtent].
  ///
  /// When a floating persistent header is told to show a [Rect] on screen, it
  /// may expand itself to accommodate the [Rect]. The minimum extent that is
  /// allowed for such expansion is either
  /// [RenderSliverPersistentHeader.minExtent] or [minShowOnScreenExtent],
  /// whichever is larger. If the persistent header's current extent is already
  /// larger than that maximum extent, it will remain unchanged.
  ///
  /// This parameter can be set to the persistent header's `maxExtent` (or
  /// `double.infinity`) so the persistent header will always try to expand when
  /// [RenderObject.showOnScreen] is called on it.
  ///
  /// Defaults to [double.negativeInfinity], must be less than or equal to
  /// [maxShowOnScreenExtent]. Has no effect unless the persistent header is a
  /// floating header.
  final double minShowOnScreenExtent;

  /// The biggest the floating header can expand to in the main axis direction,
  /// in response to a [RenderObject.showOnScreen] call, in addition to its
  /// [RenderSliverPersistentHeader.maxExtent].
  ///
  /// When a floating persistent header is told to show a [Rect] on screen, it
  /// may expand itself to accommodate the [Rect]. The maximum extent that is
  /// allowed for such expansion is either
  /// [RenderSliverPersistentHeader.maxExtent] or [maxShowOnScreenExtent],
  /// whichever is smaller. If the persistent header's current extent is already
  /// larger than that maximum extent, it will remain unchanged.
  ///
  /// This parameter can be set to the persistent header's `minExtent` (or
  /// `double.negativeInfinity`) so the persistent header will never try to
  /// expand when [RenderObject.showOnScreen] is called on it.
  ///
  /// Defaults to [double.infinity], must be greater than or equal to
  /// [minShowOnScreenExtent]. Has no effect unless the persistent header is a
  /// floating header.
  final double maxShowOnScreenExtent;
}

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
  RenderSliverPersistentHeader({
    RenderBox? child,
    this.stretchConfiguration,
  }) {
    this.child = child;
  }

  late double _lastStretchOffset;

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
    assert(child!.hasSize);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.vertical:
        return child!.size.height;
      case Axis.horizontal:
        return child!.size.width;
    }
  }

  bool _needsUpdateChild = true;
  double _lastShrinkOffset = 0.0;
  bool _lastOverlapsContent = false;

  /// Defines the parameters used to execute an [AsyncCallback] when a
  /// stretching header over-scrolls.
  ///
  /// If [stretchConfiguration] is null then callback is not triggered.
  ///
  /// See also:
  ///
  ///  * [SliverAppBar], which creates a header that can stretched into an
  ///    overscroll area and trigger a callback function.
  OverScrollHeaderStretchConfiguration? stretchConfiguration;

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
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('The maxExtent for this $runtimeType is less than its minExtent.'),
        DoubleProperty('The specified maxExtent was', maxExtent),
        DoubleProperty('The specified minExtent was', minExtent),
      ]);
    }());
    double stretchOffset = 0.0;
    if (stretchConfiguration != null && constraints.scrollOffset == 0.0) {
      stretchOffset += constraints.overlap.abs();
    }

    child?.layout(
      constraints.asBoxConstraints(
        maxExtent: math.max(minExtent, maxExtent - shrinkOffset) + stretchOffset,
      ),
      parentUsesSize: true,
    );

    if (stretchConfiguration != null &&
      stretchConfiguration!.onStretchTrigger != null &&
      stretchOffset >= stretchConfiguration!.stretchTriggerOffset &&
      _lastStretchOffset <= stretchConfiguration!.stretchTriggerOffset) {
      stretchConfiguration!.onStretchTrigger!();
    }
    _lastStretchOffset = stretchOffset;
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
  bool hitTestChildren(SliverHitTestResult result, { required double mainAxisPosition, required double crossAxisPosition }) {
    assert(geometry!.hitTestExtent > 0.0);
    if (child != null)
      return hitTestBoxChild(BoxHitTestResult.wrap(result), child!, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition);
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child == this.child);
    applyPaintTransformForBoxChild(child as RenderBox, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry!.visible) {
      assert(constraints.axisDirection != null);
      switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
        case AxisDirection.up:
          offset += Offset(0.0, geometry!.paintExtent - childMainAxisPosition(child!) - childExtent);
          break;
        case AxisDirection.down:
          offset += Offset(0.0, childMainAxisPosition(child!));
          break;
        case AxisDirection.left:
          offset += Offset(geometry!.paintExtent - childMainAxisPosition(child!) - childExtent, 0.0);
          break;
        case AxisDirection.right:
          offset += Offset(childMainAxisPosition(child!), 0.0);
          break;
      }
      context.paintChild(child!, offset);
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.addTagForChildren(RenderViewport.excludeFromScrolling);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty.lazy('maxExtent', () => maxExtent));
    properties.add(DoubleProperty.lazy('child position', () => childMainAxisPosition(child!)));
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
    RenderBox? child,
    OverScrollHeaderStretchConfiguration? stretchConfiguration,
  }) : super(
    child: child,
    stretchConfiguration: stretchConfiguration,
  );

  // Distance from our leading edge to the child's leading edge, in the axis
  // direction. Negative if we're scrolled off the top.
  double? _childPosition;

  /// Updates [geometry], and returns the new value for [childMainAxisPosition].
  ///
  /// This is used by [performLayout].
  @protected
  double updateGeometry() {
    double stretchOffset = 0.0;
    if (stretchConfiguration != null && _childPosition == 0.0) {
      stretchOffset += constraints.overlap.abs();
    }
    final double maxExtent = this.maxExtent;
    final double paintExtent = maxExtent - constraints.scrollOffset;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: math.min(constraints.overlap, 0.0),
      paintExtent: paintExtent.clamp(0.0, constraints.remainingPaintExtent),
      maxPaintExtent: maxExtent + stretchOffset,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
    return stretchOffset > 0 ? 0.0 : math.min(0.0, paintExtent - childExtent);
  }


  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
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
    _childPosition = updateGeometry();
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    assert(_childPosition != null);
    return _childPosition!;
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
    RenderBox? child,
    OverScrollHeaderStretchConfiguration? stretchConfiguration,
    this.showOnScreenConfiguration = const PersistentHeaderShowOnScreenConfiguration(),
  }) : super(
    child: child,
    stretchConfiguration: stretchConfiguration,
  );

  /// Specifies the persistent header's behavior when `showOnScreen` is called.
  ///
  /// If set to null, the persistent header will delegate the `showOnScreen` call
  /// to it's parent [RenderObject].
  PersistentHeaderShowOnScreenConfiguration? showOnScreenConfiguration;

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    final double maxExtent = this.maxExtent;
    final bool overlapsContent = constraints.overlap > 0.0;
    layoutChild(constraints.scrollOffset, maxExtent, overlapsContent: overlapsContent);
    final double effectiveRemainingPaintExtent = math.max(0, constraints.remainingPaintExtent - constraints.overlap);
    final double layoutExtent = (maxExtent - constraints.scrollOffset).clamp(0.0, effectiveRemainingPaintExtent);
    final double stretchOffset = stretchConfiguration != null ?
      constraints.overlap.abs() :
      0.0;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: constraints.overlap,
      paintExtent: math.min(childExtent, effectiveRemainingPaintExtent),
      layoutExtent: layoutExtent,
      maxPaintExtent: maxExtent + stretchOffset,
      maxScrollObstructionExtent: minExtent,
      cacheExtent: layoutExtent > 0.0 ? -constraints.cacheOrigin + layoutExtent : layoutExtent,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) => 0.0;

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    final Rect? localBounds = descendant != null
      ? MatrixUtils.transformRect(descendant.getTransformTo(this), rect ?? descendant.paintBounds)
      : rect;

    Rect? newRect;
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        newRect = _trim(localBounds, bottom: childExtent);
        break;
      case AxisDirection.right:
        newRect = _trim(localBounds, left: 0);
        break;
      case AxisDirection.down:
        newRect = _trim(localBounds, top: 0);
        break;
      case AxisDirection.left:
        newRect = _trim(localBounds, right: childExtent);
        break;
    }

    super.showOnScreen(
      descendant: this,
      rect: newRect,
      duration: duration,
      curve: curve,
    );
  }
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
    @Deprecated(
      'Specify SliverPersistentHeaderDelegate.vsync instead. '
      'This feature was deprecated after v1.19.0.',
    )
    this.vsync,
    this.curve = Curves.ease,
    this.duration = const Duration(milliseconds: 300),
  }) : assert(curve != null),
       assert(duration != null);

  /// The [TickerProvider] for the [AnimationController] that causes a floating
  /// header to snap in or out of view.
  @Deprecated(
    'Specify SliverPersistentHeaderDelegate.vsync instead. '
    'This feature was deprecated after v1.19.0.',
  )
  final TickerProvider? vsync;

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
    RenderBox? child,
    TickerProvider? vsync,
    this.snapConfiguration,
    OverScrollHeaderStretchConfiguration? stretchConfiguration,
    required this.showOnScreenConfiguration,
  }) : _vsync = vsync,
       super(
    child: child,
    stretchConfiguration: stretchConfiguration,
  );

  AnimationController? _controller;
  late Animation<double> _animation;
  double? _lastActualScrollOffset;
  double? _effectiveScrollOffset;

  // Distance from our leading edge to the child's leading edge, in the axis
  // direction. Negative if we're scrolled off the top.
  double? _childPosition;

  @override
  void detach() {
    _controller?.dispose();
    _controller = null; // lazily recreated if we're reattached.
    super.detach();
  }


  /// A [TickerProvider] to use when animating the scroll position.
  TickerProvider? get vsync => _vsync;
  TickerProvider? _vsync;
  set vsync(TickerProvider? value) {
    if (value == _vsync)
      return;
    _vsync = value;
    if (value == null) {
      _controller?.dispose();
      _controller = null;
    } else {
      _controller?.resync(value);
    }
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
  FloatingHeaderSnapConfiguration? snapConfiguration;

  /// {@macro flutter.rendering.PersistentHeaderShowOnScreenConfiguration}
  ///
  /// If set to null, the persistent header will delegate the `showOnScreen` call
  /// to it's parent [RenderObject].
  PersistentHeaderShowOnScreenConfiguration? showOnScreenConfiguration;

  /// Updates [geometry], and returns the new value for [childMainAxisPosition].
  ///
  /// This is used by [performLayout].
  @protected
  double updateGeometry() {
    double stretchOffset = 0.0;
    if (stretchConfiguration != null && _childPosition == 0.0) {
      stretchOffset += constraints.overlap.abs();
    }
    final double maxExtent = this.maxExtent;
    final double paintExtent = maxExtent - _effectiveScrollOffset!;
    final double layoutExtent = maxExtent - constraints.scrollOffset;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: math.min(constraints.overlap, 0.0),
      paintExtent: paintExtent.clamp(0.0, constraints.remainingPaintExtent),
      layoutExtent: layoutExtent.clamp(0.0, constraints.remainingPaintExtent),
      maxPaintExtent: maxExtent + stretchOffset,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
    return stretchOffset > 0 ? 0.0 : math.min(0.0, paintExtent - childExtent);
  }

  void _updateAnimation(Duration duration, double endValue, Curve curve) {
    assert(duration != null);
    assert(endValue != null);
    assert(curve != null);
    assert(
      vsync != null,
      'vsync must not be null if the floating header changes size animatedly.',
    );

    final AnimationController effectiveController =
      _controller ??= AnimationController(vsync: vsync!, duration: duration)
                        ..addListener(() {
      if (_effectiveScrollOffset == _animation.value)
        return;
      _effectiveScrollOffset = _animation.value;
      markNeedsLayout();
    });

    _animation = effectiveController.drive(
      Tween<double>(
        begin: _effectiveScrollOffset,
        end: endValue,
      ).chain(CurveTween(curve: curve)),
    );
  }

  /// If the header isn't already fully exposed, then scroll it into view.
  void maybeStartSnapAnimation(ScrollDirection direction) {
    final FloatingHeaderSnapConfiguration? snap = snapConfiguration;
    if (snap == null)
      return;
    if (direction == ScrollDirection.forward && _effectiveScrollOffset! <= 0.0)
      return;
    if (direction == ScrollDirection.reverse && _effectiveScrollOffset! >= maxExtent)
      return;

    _updateAnimation(
      snap.duration,
      direction == ScrollDirection.forward ? 0.0 : maxExtent,
      snap.curve,
    );
    _controller?.forward(from: 0.0);
  }

  /// If a header snap animation or a [showOnScreen] expand animation is underway
  /// then stop it.
  void maybeStopSnapAnimation(ScrollDirection direction) {
    _controller?.stop();
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    final double maxExtent = this.maxExtent;
    if (_lastActualScrollOffset != null && // We've laid out at least once to get an initial position, and either
        ((constraints.scrollOffset < _lastActualScrollOffset!) || // we are scrolling back, so should reveal, or
         (_effectiveScrollOffset! < maxExtent))) { // some part of it is visible, so should shrink or reveal as appropriate.
      double delta = _lastActualScrollOffset! - constraints.scrollOffset;

      final bool allowFloatingExpansion = constraints.userScrollDirection == ScrollDirection.forward;
      if (allowFloatingExpansion) {
        if (_effectiveScrollOffset! > maxExtent) // We're scrolled off-screen, but should reveal, so
          _effectiveScrollOffset = maxExtent; // pretend we're just at the limit.
      } else {
        if (delta > 0.0) // If we are trying to expand when allowFloatingExpansion is false,
          delta = 0.0; // disallow the expansion. (But allow shrinking, i.e. delta < 0.0 is fine.)
      }
      _effectiveScrollOffset = (_effectiveScrollOffset! - delta).clamp(0.0, constraints.scrollOffset);
    } else {
      _effectiveScrollOffset = constraints.scrollOffset;
    }
    final bool overlapsContent = _effectiveScrollOffset! < constraints.scrollOffset;

    layoutChild(
      _effectiveScrollOffset!,
      maxExtent,
      overlapsContent: overlapsContent,
    );
    _childPosition = updateGeometry();
    _lastActualScrollOffset = constraints.scrollOffset;
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    final PersistentHeaderShowOnScreenConfiguration? showOnScreen = showOnScreenConfiguration;
    if (showOnScreen == null)
      return super.showOnScreen(descendant: descendant, rect: rect, duration: duration, curve: curve);

    assert(child != null || descendant == null);
    // We prefer the child's coordinate space (instead of the sliver's) because
    // it's easier for us to convert the target rect into target extents: when
    // the sliver is sitting above the leading edge (not possible with pinned
    // headers), the leading edge of the sliver and the leading edge of the child
    // will not be aligned. The only exception is when child is null (and thus
    // descendant == null).
    final Rect? childBounds = descendant != null
      ? MatrixUtils.transformRect(descendant.getTransformTo(child), rect ?? descendant.paintBounds)
      : rect;

    double targetExtent;
    Rect? targetRect;
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        targetExtent = childExtent - (childBounds?.top ?? 0);
        targetRect = _trim(childBounds, bottom: childExtent);
        break;
      case AxisDirection.right:
        targetExtent = childBounds?.right ?? childExtent;
        targetRect = _trim(childBounds, left: 0);
        break;
      case AxisDirection.down:
        targetExtent = childBounds?.bottom ?? childExtent;
        targetRect = _trim(childBounds, top: 0);
        break;
      case AxisDirection.left:
        targetExtent = childExtent - (childBounds?.left ?? 0);
        targetRect = _trim(childBounds, right: childExtent);
        break;
    }

    // A stretch header can have a bigger childExtent than maxExtent.
    final double effectiveMaxExtent = math.max(childExtent, maxExtent);

    targetExtent = targetExtent.clamp(
        showOnScreen.minShowOnScreenExtent,
        showOnScreen.maxShowOnScreenExtent,
      )
      // Clamp the value back to the valid range after applying additional
      // constraints. Contracting is not allowed.
      .clamp(childExtent, effectiveMaxExtent);

    // Expands the header if needed, with animation.
    if (targetExtent > childExtent) {
      final double targetScrollOffset = maxExtent - targetExtent;
      assert(
        vsync != null,
        'vsync must not be null if the floating header changes size animatedly.',
      );
      _updateAnimation(duration, targetScrollOffset, curve);
      _controller?.forward(from: 0.0);
    }

    super.showOnScreen(
      descendant: descendant == null ? this : child,
      rect: targetRect,
      duration: duration,
      curve: curve,
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    return _childPosition ?? 0.0;
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
    RenderBox? child,
    TickerProvider? vsync,
    FloatingHeaderSnapConfiguration? snapConfiguration,
    OverScrollHeaderStretchConfiguration? stretchConfiguration,
    PersistentHeaderShowOnScreenConfiguration? showOnScreenConfiguration,
  }) : super(
    child: child,
    vsync: vsync,
    snapConfiguration: snapConfiguration,
    stretchConfiguration: stretchConfiguration,
    showOnScreenConfiguration: showOnScreenConfiguration,
  );

  @override
  double updateGeometry() {
    final double minExtent = this.minExtent;
    final double minAllowedExtent = constraints.remainingPaintExtent > minExtent ?
      minExtent :
      constraints.remainingPaintExtent;
    final double maxExtent = this.maxExtent;
    final double paintExtent = maxExtent - _effectiveScrollOffset!;
    final double clampedPaintExtent = paintExtent.clamp(
      minAllowedExtent,
      constraints.remainingPaintExtent,
    );
    final double layoutExtent = maxExtent - constraints.scrollOffset;
    final double stretchOffset = stretchConfiguration != null ?
      constraints.overlap.abs() :
      0.0;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: math.min(constraints.overlap, 0.0),
      paintExtent: clampedPaintExtent,
      layoutExtent: layoutExtent.clamp(0.0, clampedPaintExtent),
      maxPaintExtent: maxExtent + stretchOffset,
      maxScrollObstructionExtent: minExtent,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );
    return 0.0;
  }
}
