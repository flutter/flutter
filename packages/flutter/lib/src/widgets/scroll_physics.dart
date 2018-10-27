// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';

import 'overscroll_indicator.dart';
import 'scroll_metrics.dart';
import 'scroll_simulation.dart';

export 'package:flutter/physics.dart' show Simulation, ScrollSpringSimulation, Tolerance;

/// Determines the physics of a [Scrollable] widget.
///
/// For example, determines how the [Scrollable] will behave when the user
/// reaches the maximum scroll extent or when the user stops scrolling.
///
/// When starting a physics [Simulation], the current scroll position and
/// velocity are used as the initial conditions for the particle in the
/// simulation. The movement of the particle in the simulation is then used to
/// determine the scroll position for the widget.
@immutable
class ScrollPhysics {
  /// Creates an object with the default scroll physics.
  const ScrollPhysics({ this.parent });

  /// If non-null, determines the default behavior for each method.
  ///
  /// If a subclass of [ScrollPhysics] does not override a method, that subclass
  /// will inherit an implementation from this base class that defers to
  /// [parent]. This mechanism lets you assemble novel combinations of
  /// [ScrollPhysics] subclasses at runtime.
  final ScrollPhysics parent;

  /// If [parent] is null then return ancestor, otherwise recursively build a
  /// ScrollPhysics that has [ancestor] as its parent.
  ///
  /// This method is typically used to define [applyTo] methods like:
  /// ```dart
  /// FooScrollPhysics applyTo(ScrollPhysics ancestor) {
  ///   return FooScrollPhysics(parent: buildParent(ancestor));
  /// }
  /// ```
  @protected
  ScrollPhysics buildParent(ScrollPhysics ancestor) => parent?.applyTo(ancestor) ?? ancestor;

  /// If [parent] is null then return a [ScrollPhysics] with the same
  /// [runtimeType] where the [parent] has been replaced with the [ancestor].
  ///
  /// If this scroll physics object already has a parent, then this method
  /// is applied recursively and ancestor will appear at the end of the
  /// existing chain of parents.
  ///
  /// The returned object will combine some of the behaviors from this
  /// [ScrollPhysics] instance and some of the behaviors from [ancestor].
  ///
  /// See also:
  ///
  ///   * [buildParent], a utility method that's often used to define [applyTo]
  ///     methods for ScrollPhysics subclasses.
  ScrollPhysics applyTo(ScrollPhysics ancestor) {
    return ScrollPhysics(parent: buildParent(ancestor));
  }

  /// Used by [DragScrollActivity] and other user-driven activities to convert
  /// an offset in logical pixels as provided by the [DragUpdateDetails] into a
  /// delta to apply (subtract from the current position) using
  /// [ScrollActivityDelegate.setPixels].
  ///
  /// This is used by some [ScrollPosition] subclasses to apply friction during
  /// overscroll situations.
  ///
  /// This method must not adjust parts of the offset that are entirely within
  /// the bounds described by the given `position`.
  ///
  /// The given `position` is only valid during this method call. Do not keep a
  /// reference to it to use later, as the values may update, may not update, or
  /// may update to reflect an entirely unrelated scrollable.
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (parent == null)
      return offset;
    return parent.applyPhysicsToUserOffset(position, offset);
  }

  /// Whether the scrollable should let the user adjust the scroll offset, for
  /// example by dragging.
  ///
  /// By default, the user can manipulate the scroll offset if, and only if,
  /// there is actually content outside the viewport to reveal.
  ///
  /// The given `position` is only valid during this method call. Do not keep a
  /// reference to it to use later, as the values may update, may not update, or
  /// may update to reflect an entirely unrelated scrollable.
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (parent == null)
      return position.pixels != 0.0 || position.minScrollExtent != position.maxScrollExtent;
    return parent.shouldAcceptUserOffset(position);
  }

  /// Determines the overscroll by applying the boundary conditions.
  ///
  /// Called by [ScrollPosition.applyBoundaryConditions], which is called by
  /// [ScrollPosition.setPixels] just before the [ScrollPosition.pixels] value
  /// is updated, to determine how much of the offset is to be clamped off and
  /// sent to [ScrollPosition.didOverscrollBy].
  ///
  /// The `value` argument is guaranteed to not equal the [ScrollMetrics.pixels]
  /// of the `position` argument when this is called.
  ///
  /// It is possible for this method to be called when the `position` describes
  /// an already-out-of-bounds position. In that case, the boundary conditions
  /// should usually only prevent a further increase in the extent to which the
  /// position is out of bounds, allowing a decrease to be applied successfully,
  /// so that (for instance) an animation can smoothly snap an out of bounds
  /// position to the bounds. See [BallisticScrollActivity].
  ///
  /// This method must not clamp parts of the offset that are entirely within
  /// the bounds described by the given `position`.
  ///
  /// The given `position` is only valid during this method call. Do not keep a
  /// reference to it to use later, as the values may update, may not update, or
  /// may update to reflect an entirely unrelated scrollable.
  ///
  /// ## Examples
  ///
  /// [BouncingScrollPhysics] returns zero. In other words, it allows scrolling
  /// past the boundary unhindered.
  ///
  /// [ClampingScrollPhysics] returns the amount by which the value is beyond
  /// the position or the boundary, whichever is furthest from the content. In
  /// other words, it disallows scrolling past the boundary, but allows
  /// scrolling back from being overscrolled, if for some reason the position
  /// ends up overscrolled.
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (parent == null)
      return 0.0;
    return parent.applyBoundaryConditions(position, value);
  }

  /// Returns a simulation for ballistic scrolling starting from the given
  /// position with the given velocity.
  ///
  /// This is used by [ScrollPositionWithSingleContext] in the
  /// [ScrollPositionWithSingleContext.goBallistic] method. If the result
  /// is non-null, [ScrollPositionWithSingleContext] will begin a
  /// [BallisticScrollActivity] with the returned value. Otherwise, it will
  /// begin an idle activity instead.
  ///
  /// The given `position` is only valid during this method call. Do not keep a
  /// reference to it to use later, as the values may update, may not update, or
  /// may update to reflect an entirely unrelated scrollable.
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (parent == null)
      return null;
    return parent.createBallisticSimulation(position, velocity);
  }

  static final SpringDescription _kDefaultSpring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 100.0,
    ratio: 1.1,
  );

  /// The spring to use for ballistic simulations.
  SpringDescription get spring => parent?.spring ?? _kDefaultSpring;

  /// The default accuracy to which scrolling is computed.
  static final Tolerance _kDefaultTolerance = Tolerance(
    // TODO(ianh): Handle the case of the device pixel ratio changing.
    // TODO(ianh): Get this from the local MediaQuery not dart:ui's window object.
    velocity: 1.0 / (0.050 * ui.window.devicePixelRatio), // logical pixels per second
    distance: 1.0 / ui.window.devicePixelRatio // logical pixels
  );

  /// The tolerance to use for ballistic simulations.
  Tolerance get tolerance => parent?.tolerance ?? _kDefaultTolerance;

  /// The minimum distance an input pointer drag must have moved to
  /// to be considered a scroll fling gesture.
  ///
  /// This value is typically compared with the distance traveled along the
  /// scrolling axis.
  ///
  /// See also:
  ///
  ///  * [VelocityTracker.getVelocityEstimate], which computes the velocity
  ///    of a press-drag-release gesture.
  double get minFlingDistance => parent?.minFlingDistance ?? kTouchSlop;

  /// The minimum velocity for an input pointer drag to be considered a
  /// scroll fling.
  ///
  /// This value is typically compared with the magnitude of fling gesture's
  /// velocity along the scrolling axis.
  ///
  /// See also:
  ///
  ///  * [VelocityTracker.getVelocityEstimate], which computes the velocity
  ///    of a press-drag-release gesture.
  double get minFlingVelocity => parent?.minFlingVelocity ?? kMinFlingVelocity;

  /// Scroll fling velocity magnitudes will be clamped to this value.
  double get maxFlingVelocity => parent?.maxFlingVelocity ?? kMaxFlingVelocity;

  /// Returns the velocity carried on repeated flings.
  ///
  /// The function is applied to the existing scroll velocity when another
  /// scroll drag is applied in the same direction.
  ///
  /// By default, physics for platforms other than iOS doesn't carry momentum.
  double carriedMomentum(double existingVelocity) {
    if (parent == null)
      return 0.0;
    return parent.carriedMomentum(existingVelocity);
  }

  /// The minimum amount of pixel distance drags must move by to start motion
  /// the first time or after each time the drag motion stopped.
  ///
  /// If null, no minimum threshold is enforced.
  double get dragStartDistanceMotionThreshold => parent?.dragStartDistanceMotionThreshold;

  /// Whether a viewport is allowed to change its scroll position implicitly in
  /// responds to a call to [RenderObject.showOnScreen].
  ///
  /// [RenderObject.showOnScreen] is for example used to bring a text field
  /// fully on screen after it has received focus. This property controls
  /// whether the viewport associated with this object is allowed to change the
  /// scroll position to fulfill such a request.
  bool get allowImplicitScrolling => true;

  @override
  String toString() {
    if (parent == null)
      return runtimeType.toString();
    return '$runtimeType -> $parent';
  }
}

/// Scroll physics for environments that allow the scroll offset to go beyond
/// the bounds of the content, but then bounce the content back to the edge of
/// those bounds.
///
/// This is the behavior typically seen on iOS.
///
/// See also:
///
///  * [ScrollConfiguration], which uses this to provide the default
///    scroll behavior on iOS.
///  * [ClampingScrollPhysics], which is the analogous physics for Android's
///    clamping behavior.
class BouncingScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that bounce back from the edge.
  const BouncingScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  BouncingScrollPhysics applyTo(ScrollPhysics ancestor) {
    return BouncingScrollPhysics(parent: buildParent(ancestor));
  }

  /// The multiple applied to overscroll to make it appear that scrolling past
  /// the edge of the scrollable contents is harder than scrolling the list.
  /// This is done by reducing the ratio of the scroll effect output vs the
  /// scroll gesture input.
  ///
  /// This factor starts at 0.52 and progressively becomes harder to overscroll
  /// as more of the area past the edge is dragged in (represented by an increasing
  /// `overscrollFraction` which starts at 0 when there is no overscroll).
  double frictionFactor(double overscrollFraction) => 0.52 * math.pow(1 - overscrollFraction, 2);

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange)
      return offset;

    final double overscrollPastStart = math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd = math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast = math.max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0)
        || (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        // Apply less resistance when easing the overscroll vs tensioning.
        ? frictionFactor((overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit)
        return absDelta * gamma;
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0.0;

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity * 0.91, // TODO(abarth): We should move this constant closer to the drag end.
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    return null;
  }

  // The ballistic simulation here decelerates more slowly than the one for
  // ClampingScrollPhysics so we require a more deliberate input gesture
  // to trigger a fling.
  @override
  double get minFlingVelocity => kMinFlingVelocity * 2.0;

  // Methodology:
  // 1- Use https://github.com/flutter/scroll_overlay to test with Flutter and
  //    platform scroll views superimposed.
  // 2- Record incoming speed and make rapid flings in the test app.
  // 3- If the scrollables stopped overlapping at any moment, adjust the desired
  //    output value of this function at that input speed.
  // 4- Feed new input/output set into a power curve fitter. Change function
  //    and repeat from 2.
  // 5- Repeat from 2 with medium and slow flings.
  /// Momentum build-up function that mimics iOS's scroll speed increase with repeated flings.
  ///
  /// The velocity of the last fling is not an important factor. Existing speed
  /// and (related) time since last fling are factors for the velocity transfer
  /// calculations.
  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        math.min(0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(), 40000.0);
  }

  // Eyeballed from observation to counter the effect of an unintended scroll
  // from the natural motion of lifting the finger after a scroll.
  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

/// Scroll physics for environments that prevent the scroll offset from reaching
/// beyond the bounds of the content.
///
/// This is the behavior typically seen on Android.
///
/// See also:
///
///  * [ScrollConfiguration], which uses this to provide the default
///    scroll behavior on Android.
///  * [BouncingScrollPhysics], which is the analogous physics for iOS' bouncing
///    behavior.
///  * [GlowingOverscrollIndicator], which is used by [ScrollConfiguration] to
///    provide the glowing effect that is usually found with this clamping effect
///    on Android. When using a [MaterialApp], the [GlowingOverscrollIndicator]'s
///    glow color is specified to use [ThemeData.accentColor].
class ClampingScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that prevent the scroll offset from exceeding the
  /// bounds of the content..
  const ClampingScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  ClampingScrollPhysics applyTo(ScrollPhysics ancestor) {
    return ClampingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    assert(() {
      if (value == position.pixels) {
        throw FlutterError(
          '$runtimeType.applyBoundaryConditions() was called redundantly.\n'
          'The proposed new position, $value, is exactly equal to the current position of the '
          'given ${position.runtimeType}, ${position.pixels}.\n'
          'The applyBoundaryConditions method should only be called when the value is '
          'going to actually change the pixels, otherwise it is redundant.\n'
          'The physics object in question was:\n'
          '  $this\n'
          'The position object in question was:\n'
          '  $position\n'
        );
      }
      return true;
    }());
    if (value < position.pixels && position.pixels <= position.minScrollExtent) // underscroll
      return value - position.pixels;
    if (position.maxScrollExtent <= position.pixels && position.pixels < value) // overscroll
      return value - position.pixels;
    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) // hit top edge
      return value - position.minScrollExtent;
    if (position.pixels < position.maxScrollExtent && position.maxScrollExtent < value) // hit bottom edge
      return value - position.maxScrollExtent;
    return 0.0;
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (position.outOfRange) {
      double end;
      if (position.pixels > position.maxScrollExtent)
        end = position.maxScrollExtent;
      if (position.pixels < position.minScrollExtent)
        end = position.minScrollExtent;
      assert(end != null);
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end,
        math.min(0.0, velocity),
        tolerance: tolerance
      );
    }
    if (velocity.abs() < tolerance.velocity)
      return null;
    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent)
      return null;
    if (velocity < 0.0 && position.pixels <= position.minScrollExtent)
      return null;
    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }
}

/// Scroll physics that always lets the user scroll.
///
/// On Android, overscrolls will be clamped by default and result in an
/// overscroll glow. On iOS, overscrolls will load a spring that will return
/// the scroll view to its normal range when released.
///
/// See also:
///
///  * [ScrollPhysics], which can be used instead of this class when the default
///    behavior is desired instead.
///  * [BouncingScrollPhysics], which provides the bouncing overscroll behavior
///    found on iOS.
///  * [ClampingScrollPhysics], which provides the clamping overscroll behavior
///    found on Android.
class AlwaysScrollableScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that always lets the user scroll.
  const AlwaysScrollableScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  AlwaysScrollableScrollPhysics applyTo(ScrollPhysics ancestor) {
    return AlwaysScrollableScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}

/// Scroll physics that does not allow the user to scroll.
///
/// See also:
///
///  * [ScrollPhysics], which can be used instead of this class when the default
///    behavior is desired instead.
///  * [BouncingScrollPhysics], which provides the bouncing overscroll behavior
///    found on iOS.
///  * [ClampingScrollPhysics], which provides the clamping overscroll behavior
///    found on Android.
class NeverScrollableScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that does not let the user scroll.
  const NeverScrollableScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  NeverScrollableScrollPhysics applyTo(ScrollPhysics ancestor) {
    return NeverScrollableScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => false;

  @override
  bool get allowImplicitScrolling => false;
}
