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
class BouncingScrollSimulation extends SimulationGroup {
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
    @required double leadingExtent,
    @required double trailingExtent,
    @required SpringDescription spring,
    Tolerance tolerance: Tolerance.defaultTolerance,
  }) : _leadingExtent = leadingExtent,
       _trailingExtent = trailingExtent,
       _spring = spring,
       super(tolerance: tolerance) {
    assert(position != null);
    assert(velocity != null);
    assert(_leadingExtent != null);
    assert(_trailingExtent != null);
    assert(_leadingExtent <= _trailingExtent);
    assert(_spring != null);
    _chooseSimulation(position, velocity, 0.0);
  }

  final double _leadingExtent;
  final double _trailingExtent;
  final SpringDescription _spring;

  bool _isSpringing = false;
  Simulation _currentSimulation;
  double _offset = 0.0;

  // This simulation can only step forward.
  @override
  bool step(double time) => _chooseSimulation(
    _currentSimulation.x(time - _offset),
    _currentSimulation.dx(time - _offset),
    time,
  );

  @override
  Simulation get currentSimulation => _currentSimulation;

  @override
  double get currentIntervalOffset => _offset;

  bool _chooseSimulation(double position, double velocity, double intervalOffset) {
    if (!_isSpringing) {
      if (position > _trailingExtent) {
        _isSpringing = true;
        _offset = intervalOffset;
        _currentSimulation = new ScrollSpringSimulation(_spring, position, _trailingExtent, velocity, tolerance: tolerance);
        return true;
      } else if (position < _leadingExtent) {
        _isSpringing = true;
        _offset = intervalOffset;
        _currentSimulation = new ScrollSpringSimulation(_spring, position, _leadingExtent, velocity, tolerance: tolerance);
        return true;
      } else if (_currentSimulation == null) {
        _currentSimulation = new FrictionSimulation(0.135, position, velocity, tolerance: tolerance);
        return true;
      }
    }
    return false;
  }

  @override
  String toString() {
    return '$runtimeType(leadingExtent: $_leadingExtent, trailingExtent: $_trailingExtent)';
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

  final double position;
  final double velocity;
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
