// Copyright 2014 The Flutter Authors. All rights reserved.
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
    required double position,
    required double velocity,
    required this.leadingExtent,
    required this.trailingExtent,
    required this.spring,
    Tolerance tolerance = Tolerance.defaultTolerance,
  }) : assert(position != null),
       assert(velocity != null),
       assert(leadingExtent != null),
       assert(trailingExtent != null),
       assert(leadingExtent <= trailingExtent),
       assert(spring != null),
       super(tolerance: tolerance) {
    if (position < leadingExtent) {
      _springSimulation = _underscrollSimulation(position, velocity);
      _springTime = double.negativeInfinity;
    } else if (position > trailingExtent) {
      _springSimulation = _overscrollSimulation(position, velocity);
      _springTime = double.negativeInfinity;
    } else {
      // Taken from UIScrollView.decelerationRate (.normal = 0.998)
      // 0.998^1000 = ~0.135
      _frictionSimulation = FrictionSimulation(0.135, position, velocity);
      final double finalX = _frictionSimulation.finalX;
      if (velocity > 0.0 && finalX > trailingExtent) {
        _springTime = _frictionSimulation.timeAtX(trailingExtent);
        _springSimulation = _overscrollSimulation(
          trailingExtent,
          math.min(_frictionSimulation.dx(_springTime), maxSpringTransferVelocity),
        );
        assert(_springTime.isFinite);
      } else if (velocity < 0.0 && finalX < leadingExtent) {
        _springTime = _frictionSimulation.timeAtX(leadingExtent);
        _springSimulation = _underscrollSimulation(
          leadingExtent,
          math.min(_frictionSimulation.dx(_springTime), maxSpringTransferVelocity),
        );
        assert(_springTime.isFinite);
      } else {
        _springTime = double.infinity;
      }
    }
    assert(_springTime != null);
  }

  /// The maximum velocity that can be transferred from the inertia of a ballistic
  /// scroll into overscroll.
  static const double maxSpringTransferVelocity = 5000.0;

  /// When [x] falls below this value the simulation switches from an internal friction
  /// model to a spring model which causes [x] to "spring" back to [leadingExtent].
  final double leadingExtent;

  /// When [x] exceeds this value the simulation switches from an internal friction
  /// model to a spring model which causes [x] to "spring" back to [trailingExtent].
  final double trailingExtent;

  /// The spring used used to return [x] to either [leadingExtent] or [trailingExtent].
  final SpringDescription spring;

  late FrictionSimulation _frictionSimulation;
  late Simulation _springSimulation;
  late double _springTime;
  double _timeOffset = 0.0;

  Simulation _underscrollSimulation(double x, double dx) {
    return ScrollSpringSimulation(spring, x, leadingExtent, dx);
  }

  Simulation _overscrollSimulation(double x, double dx) {
    return ScrollSpringSimulation(spring, x, trailingExtent, dx);
  }

  Simulation _simulation(double time) {
    final Simulation simulation;
    if (time > _springTime) {
      _timeOffset = _springTime.isFinite ? _springTime : 0.0;
      simulation = _springSimulation;
    } else {
      _timeOffset = 0.0;
      simulation = _frictionSimulation;
    }
    return simulation..tolerance = tolerance;
  }

  @override
  double x(double time) => _simulation(time).x(time - _timeOffset);

  @override
  double dx(double time) => _simulation(time).dx(time - _timeOffset);

  @override
  bool isDone(double time) => _simulation(time).isDone(time - _timeOffset);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'BouncingScrollSimulation')}(leadingExtent: $leadingExtent, trailingExtent: $trailingExtent)';
  }
}

const double _inflexion = 0.35;

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
    required this.position,
    required this.velocity,
    this.friction = 0.015,
    Tolerance tolerance = Tolerance.defaultTolerance,
  }) : super(tolerance: tolerance) {
    _duration = _splineFlingDuration(velocity);
    _distance = _splineFlingDistance(velocity);
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

  late int _duration;
  late double _distance;

  // See DECELERATION_RATE.
  static final double _kDecelerationRate = math.log(0.78) / math.log(0.9);

  // See computeDeceleration().
  static double _decelerationForFriction(double friction) {
    return 9.80665 *
        39.37 *
        friction *
        1.0 * // Flutter operates on logical pixels so the DPI should be 1.0.
        160.0;
  }

  // See getSplineDeceleration().
  double _splineDeceleration(double velocity) {
    return math.log(_inflexion *
        velocity.abs() /
        (friction * _decelerationForFriction(0.84)));
  }

  // See getSplineFlingDuration().
  int _splineFlingDuration(double velocity) {
    final double deceleration = _splineDeceleration(velocity);
    return (1000 * math.exp(deceleration / (_kDecelerationRate - 1.0))).round();
  }

  // See getSplineFlingDistance().
  double _splineFlingDistance(double velocity) {
    final double l = _splineDeceleration(velocity);
    final double decelMinusOne = _kDecelerationRate - 1.0;
    return friction *
        _decelerationForFriction(0.84) *
        math.exp(_kDecelerationRate / decelMinusOne * l);
  }

  @override
  double x(double time) {
    if (time == 0) {
      return position;
    }
    final _NBSample sample = _NBSample(time, _duration);
    return position + (sample.distanceCoef * _distance) * velocity.sign;
  }

  @override
  double dx(double time) {
    if (time == 0) {
      return velocity;
    }
    final _NBSample sample = _NBSample(time, _duration);
    return sample.velocityCoef * _distance / _duration * velocity.sign * 1000.0;
  }

  @override
  bool isDone(double time) {
    return time * 1000.0 >= _duration;
  }
}

class _NBSample {
  _NBSample(double time, int duration) {
    _initSplinePosition();

    // See computeScrollOffset().
    final double t = time * 1000.0 / duration;
    final int index = (_nbSamples * t).clamp(0, _nbSamples).round();
    _distanceCoef = 1.0;
    _velocityCoef = 0.0;
    if (index < _nbSamples) {
      final double tInf = index / _nbSamples;
      final double tSup = (index + 1) / _nbSamples;
      final double dInf = _splinePosition[index];
      final double dSup = _splinePosition[index + 1];
      _velocityCoef = (dSup - dInf) / (tSup - tInf);
      _distanceCoef = dInf + (t - tInf) * _velocityCoef;
    }
  }

  late double _velocityCoef;
  double get velocityCoef => _velocityCoef;

  late double _distanceCoef;
  double get distanceCoef => _distanceCoef;

  static const int _nbSamples = 100;
  static final List<double> _splinePosition =
      List<double>.filled(_nbSamples + 1, 0.0);
  static final List<double> _splineTime =
      List<double>.filled(_nbSamples + 1, 0.0);
  static const double _startTension = 0.5;
  static const double _endTension = 1.0;
  static bool _isInitialized = false;

  // See static iniitalization in Scroller.java.
  static void _initSplinePosition() {
    if (_isInitialized) {
      return;
    }
    const double p1 = _startTension * _inflexion;
    const double p2 = 1.0 - _endTension * (1.0 - _inflexion);
    double xMin = 0.0;
    double yMin = 0.0;
    for (int i = 0; i < _nbSamples; i++) {
      final double alpha = i / _nbSamples;
      double xMax = 1.0;
      double x, tx, coef;
      while (true) {
        x = xMin + (xMax - xMin) / 2.0;
        coef = 3.0 * x * (1.0 - x);
        tx = coef * ((1.0 - x) * p1 + x * p2) + x * x * x;
        if ((tx - alpha).abs() < 1e-5) {
          break;
        }
        if (tx > alpha) {
          xMax = x;
        } else {
          xMin = x;
        }
      }
      _splinePosition[i] = coef * ((1.0 - x) * _startTension + x) + x * x * x;
      double yMax = 1.0;
      double y, dy;
      while (true) {
        y = yMin + (yMax - yMin) / 2.0;
        coef = 3.0 * y * (1.0 - y);
        dy = coef * ((1.0 - y) * _startTension + y) + y * y * y;
        if ((dy - alpha).abs() < 1e-5) {
          break;
        }
        if (dy > alpha) {
          yMax = y;
        } else {
          yMin = y;
        }
      }
      _splineTime[i] = coef * ((1.0 - y) * p1 + y * p2) + y * y * y;
    }
    _splinePosition[_nbSamples] = _splineTime[_nbSamples] = 1.0;
    _isInitialized = true;
  }
}
