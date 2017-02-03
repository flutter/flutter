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
  }) : _leadingExtent = leadingExtent,
       _trailingExtent = trailingExtent,
       _spring = spring {
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
        _currentSimulation = new ScrollSpringSimulation(_spring, position, _trailingExtent, velocity);
        return true;
      } else if (position < _leadingExtent) {
        _isSpringing = true;
        _offset = intervalOffset;
        _currentSimulation = new ScrollSpringSimulation(_spring, position, _leadingExtent, velocity);
        return true;
      } else if (_currentSimulation == null) {
        _currentSimulation = new FrictionSimulation(0.135, position, velocity * 0.91);
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
  //
  // TODO(ianh): The incoming `velocity` is used to determine the starting speed
  // and duration, but does not represent the exact velocity of the simulation
  // at t=0 as it should. This causes crazy scrolling irregularities when the
  // scroll dimensions change during a fling.
  ClampingScrollSimulation({
    @required this.position,
    @required this.velocity,
    this.friction: 0.015,
    Tolerance tolerance: Tolerance.defaultTolerance,
  }) : super(tolerance: tolerance) {
    _scaledFriction = friction * _decelerationForFriction(0.84); // See mPhysicalCoeff
    _duration = _flingDuration(velocity);
    _distance = _flingDistance(velocity);
  }

  final double position;
  final double velocity;
  final double friction;

  double _scaledFriction;
  double _duration;
  double _distance;

  // See DECELERATION_RATE.
  static final double _decelerationRate = math.log(0.78) / math.log(0.9);

  // See computeDeceleration().
  double _decelerationForFriction(double friction) {
    return friction * 61774.04968;
  }

  // See getSplineDeceleration().
  double _flingDeceleration(double velocity) {
    return math.log(0.35 * velocity.abs() / _scaledFriction);
  }

  // See getSplineFlingDuration(). Returns a value in seconds.
  double _flingDuration(double velocity) {
    return math.exp(_flingDeceleration(velocity) / (_decelerationRate - 1.0));
  }

  // See getSplineFlingDistance().
  double _flingDistance(double velocity) {
    final double rate = _decelerationRate / (_decelerationRate - 1.0) * _flingDeceleration(velocity);
    return _scaledFriction * math.exp(rate);
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
  double _flingDistancePenetration(double t) {
    return (1.2 * t * t * t) - (3.27 * t * t) + (3.065 * t);
  }

  // The derivative of the _flingDistancePenetration() function.
  double _flingVelocityPenetration(double t) {
    return (3.63693 * t * t) - (6.5424 * t) + 3.06542;
  }

  @override
  double x(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return position + _distance * _flingDistancePenetration(t) * velocity.sign;
  }

  @override
  double dx(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return _distance * _flingVelocityPenetration(t) * velocity.sign;
  }

  @override
  bool isDone(double time) {
    return time >= _duration;
  }
}

////////////////////////////////////////////////////////////////////////////////
// DELETE EVERYTHING BELOW THIS LINE WHEN REMOVING LEGACY SCROLLING CODE
////////////////////////////////////////////////////////////////////////////////

final SpringDescription _kScrollSpring = new SpringDescription.withDampingRatio(mass: 0.5, springConstant: 100.0, ratio: 1.1);
final double _kDrag = 0.025;

class _CupertinoSimulation extends FrictionSimulation {
  static const double drag = 0.135;
  _CupertinoSimulation({ double position, double velocity })
    : super(drag, position, velocity * 0.91);
}

class _MountainViewSimulation extends ClampingScrollSimulation {
  _MountainViewSimulation({
    double position,
    double velocity,
    double friction: 0.015,
  }) : super(
    position: position,
    velocity: velocity,
    friction: friction,
  );
}

/// Composite simulation for scrollable interfaces.
///
/// Simulates kinetic scrolling behavior between a leading and trailing
/// boundary. Friction is applied within the extents and a spring action is
/// applied at the boundaries. This simulation can only step forward.
class ScrollSimulation extends SimulationGroup {
  /// Creates a [ScrollSimulation] with the given parameters.
  ///
  /// The position and velocity arguments must use the same units as will be
  /// expected from the [x] and [dx] methods respectively.
  ///
  /// The leading and trailing extents must use the unit of length, the same
  /// unit as used for the position argument and as expected from the [x]
  /// method.
  ///
  /// The units used with the provided [SpringDescription] must similarly be
  /// consistent with the other arguments.
  ///
  /// The final argument is the coefficient of friction, which is unitless.
  ScrollSimulation({
    @required double position,
    @required double velocity,
    @required double leadingExtent,
    @required double trailingExtent,
    SpringDescription spring,
    double drag,
    TargetPlatform platform,
  }) : _leadingExtent = leadingExtent,
       _trailingExtent = trailingExtent,
       _spring = spring ?? _kScrollSpring,
       _drag = drag ?? _kDrag,
       _platform = platform {
    assert(position != null);
    assert(velocity != null);
    assert(_leadingExtent != null);
    assert(_trailingExtent != null);
    assert(_spring != null);
    _chooseSimulation(position, velocity, 0.0);
  }

  final double _leadingExtent;
  final double _trailingExtent;
  final SpringDescription _spring;
  final double _drag;
  final TargetPlatform _platform;

  bool _isSpringing = false;
  Simulation _currentSimulation;
  double _offset = 0.0;

  @override
  bool step(double time) => _chooseSimulation(
      _currentSimulation.x(time - _offset),
      _currentSimulation.dx(time - _offset), time);

  @override
  Simulation get currentSimulation => _currentSimulation;

  @override
  double get currentIntervalOffset => _offset;

  bool _chooseSimulation(double position, double velocity, double intervalOffset) {
    if (_spring == null && (position > _trailingExtent || position < _leadingExtent))
      return false;

    // This simulation can only step forward.
    if (!_isSpringing) {
      if (position > _trailingExtent) {
        _isSpringing = true;
        _offset = intervalOffset;
        _currentSimulation = new ScrollSpringSimulation(_spring, position, _trailingExtent, velocity);
        return true;
      } else if (position < _leadingExtent) {
        _isSpringing = true;
        _offset = intervalOffset;
        _currentSimulation = new ScrollSpringSimulation(_spring, position, _leadingExtent, velocity);
        return true;
      }
    }

    if (_currentSimulation == null) {
      switch (_platform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          _currentSimulation = new _MountainViewSimulation(
            position: position,
            velocity: velocity,
          );
          break;
        case TargetPlatform.iOS:
          _currentSimulation = new _CupertinoSimulation(
            position: position,
            velocity: velocity,
          );
          break;
      }
      // No platform specified
      _currentSimulation ??= new FrictionSimulation(_drag, position, velocity);

      return true;
    }

    return false;
  }

  @override
  String toString() {
    return 'ScrollSimulation(leadingExtent: $_leadingExtent, trailingExtent: $_trailingExtent)';
  }
}
