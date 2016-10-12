// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'friction_simulation.dart';
import 'simulation_group.dart';
import 'simulation.dart';
import 'spring_simulation.dart';

// This class is based on Scroller.java from
// https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/widget
// The "See" comments refer to Scroller methods and values. Some simplifications
// have been made.
class _MountainViewSimulation extends Simulation {
  _MountainViewSimulation({
    this.position,
    this.velocity,
    this.devicePixelRatio: 3.0, // TODO(hansmuller) lookup this value
    this.friction: 0.015,
  }) {
    _scaledFriction = friction * _decelerationForFriction(0.84); // See mPhysicalCoeff
    _duration = _flingDuration(velocity);
    _distance = _flingDistance(velocity);
  }

  final double position;
  final double velocity;
  final double devicePixelRatio;
  final double friction;

  double _scaledFriction;
  double _duration;
  double _distance;

  // See DECELERATION_RATE
  static final double _decelerationRate = math.log(0.78) / math.log(0.9);

  // See computeDeceleration()
  double _decelerationForFriction(double friction) {
    return /*devicePixelRatio * */friction * 61774.04968;
  }

  // See getSplineDeceleration()
  double _flingDeceleration(double velocity) {
    return math.log(0.35 * velocity.abs() / _scaledFriction);
  }
  // See getSplineFlingDuration()
  double _flingDuration(double velocity) {
    return math.exp(_flingDeceleration(velocity) / (_decelerationRate - 1.0));
  }

  // See getSplineFlingDistance()
  double _flingDistance(double velocity) {
    final double rate = _decelerationRate / (_decelerationRate - 1.0) * _flingDeceleration(velocity);
    return _scaledFriction * math.exp(rate);
  }

  // This cubic function is based on the SPLINE_POSITION values computed by the
  // Scroller class. Wolfram Alpha's "cubic fit calculator" was applied to every
  // fifth value {0.0, 0.141, 0.274, 0.392, 0.495, 0.583, 0.658, 0.721, 0.775,
  /// 0.820, 0.858, 0.890, 0.916, 0.938, 0.956, 0.971, 0.982, 0.990, 0.995, 1.0}.
  // That produced: f(x) = 0.000159897 x^3-0.00881705 x^2+0.170734 x-0.162279 with
  // an R-squared value of 0.9999. It's zero at x=1.00132 and 1.0 at x=19.5036.
  // The result of substituting t * (19.5036 - 1.00132) + 1.00132 for x is the
  // cubic function below.
  double _flingDistancePenetration(double t) {
    return (1.01278 * t * t * t) - (2.85395 * t * t) + (2.84117 * t);
  }

  // Based on the deriviate of the _flingPenetration() function,
  // f(t) = 3.03834 t^2 -5.7079 t + 2.84117, which is zero at
  // t = .4132643, and 1.0 at t = 0.93912. The result of replacing t with
  // t * (0.93912 - 0.4132643) + 0.4132643 is the quadratic below.
  double _flingVelocityPenetration(double t) {
    return (0.840175 * t * t) - (1.68096 * t) + 1.0012;
  }

  @override
  double x(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return position + _distance * _flingDistancePenetration(t) * velocity.sign;
  }

  @override
  double dx(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return velocity * _flingVelocityPenetration(t);
  }

  @override
  bool isDone(double time) {
    return time >= _duration;
  }
}

class _CupertinoSimulation extends FrictionSimulation {
  _CupertinoSimulation({ double drag, double position, double velocity })
    : super(drag, position, velocity);
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
    double position,
    double velocity,
    double leadingExtent,
    double trailingExtent,
    SpringDescription spring,
    double drag,
    TargetPlatform platform,
  }) : _leadingExtent = leadingExtent,
       _trailingExtent = trailingExtent,
       _spring = spring,
       _drag = drag,
       _platform = platform {
    assert(_leadingExtent != null);
    assert(_trailingExtent != null);
    assert(_spring != null);
    assert(_drag != null);
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
            velocity: velocity
          );
          break;
        case TargetPlatform.iOS:
          _currentSimulation = new _CupertinoSimulation(
            position: position,
            velocity: velocity,
            drag: _drag,
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
