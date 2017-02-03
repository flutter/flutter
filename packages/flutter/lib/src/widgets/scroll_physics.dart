// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/physics.dart';

import 'overscroll_indicator.dart';
import 'scroll_simulation.dart';
import 'scroll_position.dart';

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
      double distanceToLimit = lowLimit - start;
      double deltaToLimit = distanceToLimit / gamma;
      if (delta < deltaToLimit)
        return total + delta * gamma;
      total += distanceToLimit;
      delta -= deltaToLimit;
    }
    return total + delta;
  }

  @override
  Simulation createBallisticSimulation(ScrollPosition position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return new BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
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

class PageScrollPhysics extends ScrollPhysics {
  const PageScrollPhysics({ ScrollPhysics parent }) : super(parent);

  @override
  PageScrollPhysics applyTo(ScrollPhysics parent) => new PageScrollPhysics(parent: parent);

  double _roundToPage(ScrollPosition position, double pixels, double pageSize) {
    final int index = (pixels + pageSize / 2.0) ~/ pageSize;
    return (pageSize * index).clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  double _getTargetPixels(ScrollPosition position, Tolerance tolerance, double velocity) {
    final double pageSize = position.viewportDimension;
    if (velocity < -tolerance.velocity)
      return _roundToPage(position, position.pixels - pageSize / 2.0, pageSize);
    if (velocity > tolerance.velocity)
      return _roundToPage(position, position.pixels + pageSize / 2.0, pageSize);
    return _roundToPage(position, position.pixels, pageSize);
  }

  @override
  Simulation createBallisticSimulation(ScrollPosition position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent))
      return super.createBallisticSimulation(position, velocity);
    final Tolerance tolerance = this.tolerance;
    final double target = _getTargetPixels(position, tolerance, velocity);
    return new ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
  }
}
