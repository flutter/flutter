// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/physics.dart';

import 'overscroll_indicator.dart';
import 'scroll_position.dart';
import 'scroll_simulation.dart';

// The ScrollPhysics base class is defined in scroll_position.dart because it
// has as circular dependency with ScrollPosition.
export 'scroll_position.dart' show ScrollPhysics;

/// Scroll physics for environments that allow the scroll offset to go beyond
/// the bounds of the content, but then bounce the content back to the edge of
/// those bounds.
///
/// This is the behavior typically seen on iOS.
///
/// See also:
///
/// * [ViewportScrollBehavior], which uses this to provide the iOS component of
///   its scroll behavior.
/// * [ClampingScrollPhysics], which is the analogous physics for Android's
///   clamping behavior.
class BouncingScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that bounce back from the edge.
  const BouncingScrollPhysics({ ScrollPhysics parent }) : super(parent);

  @override
  BouncingScrollPhysics applyTo(ScrollPhysics parent) => new BouncingScrollPhysics(parent: parent);

  /// The multiple applied to overscroll to make it appear that scrolling past
  /// the edge of the scrollable contents is harder than scrolling the list.
  ///
  /// By default this is 0.5, meaning that overscroll is twice as hard as normal
  /// scroll.
  double get frictionFactor => 0.5;

  @override
  double applyPhysicsToUserOffset(ScrollPosition position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);
    if (offset > 0.0)
      return _applyFriction(position.pixels, position.minScrollExtent, position.maxScrollExtent, offset, frictionFactor);
    return -_applyFriction(-position.pixels, -position.maxScrollExtent, -position.minScrollExtent, -offset, frictionFactor);
  }

  static double _applyFriction(double start, double lowLimit, double highLimit, double delta, double gamma) {
    assert(lowLimit <= highLimit);
    assert(delta > 0.0);
    double total = 0.0;
    if (start < lowLimit) {
      final double distanceToLimit = lowLimit - start;
      final double deltaToLimit = distanceToLimit / gamma;
      if (delta < deltaToLimit)
        return total + delta * gamma;
      total += distanceToLimit;
      delta -= deltaToLimit;
    }
    return total + delta;
  }

  @override
  double applyBoundaryConditions(ScrollPosition position, double value) => 0.0;

  @override
  Simulation createBallisticSimulation(ScrollPosition position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return new BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity * 0.91, // TODO(abarth): We should move this constant closer to the drag end.
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
      )..tolerance = tolerance;
    }
    return null;
  }
}

/// Scroll physics for environments that prevent the scroll offset from reaching
/// beyond the bounds of the content.
///
/// This is the behavior typically seen on Android.
///
/// See also:
///
/// * [ViewportScrollBehavior], which uses this to provide the Android component
///   of its scroll behavior.
/// * [BouncingScrollPhysics], which is the analogous physics for iOS' bouncing
///   behavior.
/// * [GlowingOverscrollIndicator], which is used by [ViewportScrollBehavior] to
///   provide the glowing effect that is usually found with this clamping effect
///   on Android.
class ClampingScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that prevent the scroll offset from exceeding the
  /// bounds of the content..
  const ClampingScrollPhysics({ ScrollPhysics parent }) : super(parent);

  @override
  ClampingScrollPhysics applyTo(ScrollPhysics parent) => new ClampingScrollPhysics(parent: parent);

  @override
  double applyBoundaryConditions(ScrollPosition position, double value) {
    assert(value != position.pixels);
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
  Simulation createBallisticSimulation(ScrollPosition position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (position.outOfRange) {
      double end;
      if (position.pixels > position.maxScrollExtent)
        end = position.maxScrollExtent;
      if (position.pixels < position.minScrollExtent)
        end = position.minScrollExtent;
      assert(end != null);
      return new ScrollSpringSimulation(
        spring,
        position.pixels,
        position.maxScrollExtent,
        math.min(0.0, velocity),
        tolerance: tolerance
      );
    }
    if (!position.atEdge && velocity.abs() >= tolerance.velocity) {
      return new ClampingScrollSimulation(
        position: position.pixels,
        velocity: velocity,
        tolerance: tolerance,
      );
    }
    return null;
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
/// * [BouncingScrollPhysics], which provides the bouncing overscroll behavior
///   found on iOS.
/// * [ClampingScrollPhysics], which provides the clamping overscroll behavior
///   found on Android.
class AlwaysScrollableScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that always lets the user scroll.
  const AlwaysScrollableScrollPhysics({ ScrollPhysics parent }) : super(parent);

  @override
  AlwaysScrollableScrollPhysics applyTo(ScrollPhysics parent) => new AlwaysScrollableScrollPhysics(parent: parent);

  @override
  bool shouldAcceptUserOffset(ScrollPosition position) => true;
}
