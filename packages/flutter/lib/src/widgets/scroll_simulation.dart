// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// An implementation of scroll physics that matches iOS.
///
/// See also:
///
///  * [ClampingScrollSimulation], which implements Android scroll physics.
class BouncingScrollSimulation extends Simulation {
  /// Creates a simulation group for scrolling on iOS, with the given
  /// parameters.
  ///
  /// The position and velocity arguments must use the same units as will be
  /// expected from the [x] and [dx] methods respectively (typically logical
  /// pixels and logical pixels per second respectively).
  ///
  /// The leading and trailing extents must use the unit of length, the same
  /// unit as used for the position argument and as expected from the [x]
  /// method (typically logical pixels).
  ///
  /// The units used with the provided [SpringDescription] must similarly be
  /// consistent with the other arguments. A default set of constants is used
  /// for the `spring` description if it is omitted; these defaults assume
  /// that the unit of length is the logical pixel.
  BouncingScrollSimulation({
    @required double position,
    @required double velocity,
    @required this.leadingExtent,
    @required this.trailingExtent,
    @required this.spring,
    Tolerance tolerance: Tolerance.defaultTolerance,
  }) : super(tolerance: tolerance) {
    assert(position != null);
    assert(velocity != null);
    assert(leadingExtent != null);
    assert(trailingExtent != null);
    assert(leadingExtent <= trailingExtent);
    assert(spring != null);

    if (position < leadingExtent) {
      _simulation = _underscrollSimulation(position, velocity);
    } else if (position > trailingExtent) {
      _simulation = _overscrollSimulation(position, velocity);
    } else {
      final FrictionSimulation friction = new FrictionSimulation(0.135, position, velocity, tolerance: tolerance);
      final double finalX = friction.finalX;
      if (velocity > 0.0 && finalX > trailingExtent)
        _updateTime = friction.timeAtX(trailingExtent);
      else if (velocity < 0.0 && finalX < leadingExtent)
        _updateTime = friction.timeAtX(leadingExtent);
      assert(_updateTime != null ? _updateTime.isFinite : true);
      _simulation = friction;
    }
  }

  /// When [x] falls below this value the simulation switches from an internal friction
  /// model to a spring model which causes [x] to "spring" back to [leadingExtent].
  final double leadingExtent;

  /// When [x] exceeds this value the simulation switches from an internal friction
  /// model to a spring model which causes [x] to "spring" back to [trailingExtent].
  final double trailingExtent;

  /// The spring used used to return [x] to either [leadingExtent] or [trailingExtent].
  final SpringDescription spring;

  Simulation _simulation;
  double _updateTime;
  double _timeOffset = 0.0;

  Simulation _underscrollSimulation(double x, double dx) {
    return new ScrollSpringSimulation(spring, x, leadingExtent, dx, tolerance: tolerance);
  }

  Simulation _overscrollSimulation(double x, double dx) {
    return new ScrollSpringSimulation(spring, x, trailingExtent, dx, tolerance: tolerance);
  }

  void _maybeUpdateSimulation(double time) {
    if (_updateTime == null || time < _updateTime)
      return;

    assert(_timeOffset == 0.0);
    final double x = _simulation.x(time);
    final double dx = _simulation.dx(time);
    if (x < leadingExtent) {
      _simulation = _underscrollSimulation(x, dx);
    } else {
      assert(x > trailingExtent);
      _simulation = _overscrollSimulation(x, dx);
    }

    _timeOffset = time - _updateTime;
    _updateTime = null;
  }

  @override
  set tolerance(Tolerance tolerance) {
    super.tolerance = tolerance;
    _simulation.tolerance = tolerance;
  }

  @override
  double x(double time) {
    _maybeUpdateSimulation(time);
    return _simulation.x(time - _timeOffset);
  }

  @override
  double dx(double time) {
    _maybeUpdateSimulation(time);
    return _simulation.dx(time - _timeOffset);
  }

  @override
  bool isDone(double time) {
    _maybeUpdateSimulation(time);
    return _simulation.isDone(time - _timeOffset);
  }

  @override
  String toString() {
    return '$runtimeType(leadingExtent: $leadingExtent, trailingExtent: $trailingExtent)';
  }
}

/// An implementation of scroll physics that matches Android.
///
/// See also:
///
///  * [BouncingScrollSimulation], which implements iOS scroll physics.
//
// This class is based on Scroller.java from Android:
//   https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/widget
//
// The "See..." comments below refer to Scroller methods and values. Some
// simplifications have been made.
class ClampingScrollSimulation extends Simulation {
  /// Creates a scroll physics simulation that matches Android scrolling.
  ClampingScrollSimulation({
    @required this.position,
    @required this.velocity,
    this.friction: 0.015,
    Tolerance tolerance: Tolerance.defaultTolerance,
  }) : super(tolerance: tolerance) {
    assert(_flingVelocityPenetration(0.0) == _kInitialVelocityPenetration);
    _duration = _flingDuration(velocity);
    _distance = (velocity * _duration / _kInitialVelocityPenetration).abs();
  }

  /// The position of the particle at the beginning of the simulation.
  final double position;

  /// The velocity at which the particle is traveling at the beginning of the
  /// simulation.
  final double velocity;

  /// The amount of friction the particle experiences as it travels.
  ///
  /// The more friction the particle experiences, the sooner it stops.
  final double friction;

  double _duration;
  double _distance;

  // See DECELERATION_RATE.
  static final double _kDecelerationRate = math.log(0.78) / math.log(0.9);

  // See computeDeceleration().
  static double _decelerationForFriction(double friction) {
    return friction * 61774.04968;
  }

  // See getSplineFlingDuration(). Returns a value in seconds.
  double _flingDuration(double velocity) {
    // See mPhysicalCoeff
    final double scaledFriction = friction * _decelerationForFriction(0.84);

    // See getSplineDeceleration().
    final double deceleration = math.log(0.35 * velocity.abs() / scaledFriction);

    return math.exp(deceleration / (_kDecelerationRate - 1.0));
  }

  // Based on a cubic curve fit to the Scroller.computeScrollOffset() values
  // produced for an initial velocity of 4000. The value of Scroller.getDuration()
  // and Scroller.getFinalY() were 686ms and 961 pixels respectively.
  //
  // Algebra courtesy of Wolfram Alpha.
  //
  // f(x) = scrollOffset, x is time in millseconds
  // f(x) = 3.60882×10^-6 x^3 - 0.00668009 x^2 + 4.29427 x - 3.15307
  // f(x) = 3.60882×10^-6 x^3 - 0.00668009 x^2 + 4.29427 x, so f(0) is 0
  // f(686ms) = 961 pixels
  // Scale to f(0 <= t <= 1.0), x = t * 686
  // f(t) = 1165.03 t^3 - 3143.62 t^2 + 2945.87 t
  // Scale f(t) so that 0.0 <= f(t) <= 1.0
  // f(t) = (1165.03 t^3 - 3143.62 t^2 + 2945.87 t) / 961.0
  //      = 1.2 t^3 - 3.27 t^2 + 3.065 t
  static const double _kInitialVelocityPenetration = 3.065;
  static double _flingDistancePenetration(double t) {
    return (1.2 * t * t * t) - (3.27 * t * t) + (_kInitialVelocityPenetration * t);
  }

  // The derivative of the _flingDistancePenetration() function.
  static double _flingVelocityPenetration(double t) {
    return (3.6 * t * t) - (6.54 * t) + _kInitialVelocityPenetration;
  }

  @override
  double x(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return position + _distance * _flingDistancePenetration(t) * velocity.sign;
  }

  @override
  double dx(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return _distance * _flingVelocityPenetration(t) * velocity.sign / _duration;
  }

  @override
  bool isDone(double time) {
    return time >= _duration;
  }
}
