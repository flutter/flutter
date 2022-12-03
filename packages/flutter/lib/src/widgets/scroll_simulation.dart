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
///  * [PageScrollSimulation], which implements Android page view scroll physics.
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
    double constantDeceleration = 0,
    super.tolerance,
  }) : assert(position != null),
       assert(velocity != null),
       assert(leadingExtent != null),
       assert(trailingExtent != null),
       assert(leadingExtent <= trailingExtent),
       assert(spring != null) {
    if (position < leadingExtent) {
      _springSimulation = _underscrollSimulation(position, velocity);
      _springTime = double.negativeInfinity;
    } else if (position > trailingExtent) {
      _springSimulation = _overscrollSimulation(position, velocity);
      _springTime = double.negativeInfinity;
    } else {
      // Taken from UIScrollView.decelerationRate (.normal = 0.998)
      // 0.998^1000 = ~0.135
      _frictionSimulation = FrictionSimulation(0.135, position, velocity, constantDeceleration: constantDeceleration);
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

  /// The spring used to return [x] to either [leadingExtent] or [trailingExtent].
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

/// An implementation of scroll physics that matches Android.
///
/// See also:
///
///  * [BouncingScrollSimulation], which implements iOS scroll physics.
///  * [PageScrollSimulation], which implements Android page view scroll physics.
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
    super.tolerance,
  }) : assert(_flingVelocityPenetration(0.0) == _initialVelocityPenetration) {
    _duration = _flingDuration(velocity);
    _distance = (velocity * _duration / _initialVelocityPenetration).abs();
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

  late double _duration;
  late double _distance;

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
  // f(x) = scrollOffset, x is time in milliseconds
  // f(x) = 3.60882×10^-6 x^3 - 0.00668009 x^2 + 4.29427 x - 3.15307
  // f(x) = 3.60882×10^-6 x^3 - 0.00668009 x^2 + 4.29427 x, so f(0) is 0
  // f(686ms) = 961 pixels
  // Scale to f(0 <= t <= 1.0), x = t * 686
  // f(t) = 1165.03 t^3 - 3143.62 t^2 + 2945.87 t
  // Scale f(t) so that 0.0 <= f(t) <= 1.0
  // f(t) = (1165.03 t^3 - 3143.62 t^2 + 2945.87 t) / 961.0
  //      = 1.2 t^3 - 3.27 t^2 + 3.065 t
  static const double _initialVelocityPenetration = 3.065;
  static double _flingDistancePenetration(double t) {
    return (1.2 * t * t * t) - (3.27 * t * t) + (_initialVelocityPenetration * t);
  }

  // The derivative of the _flingDistancePenetration() function.
  static double _flingVelocityPenetration(double t) {
    return (3.6 * t * t) - (6.54 * t) + _initialVelocityPenetration;
  }

  @override
  double x(double time) {
    final double t = clampDouble(time / _duration, 0.0, 1.0);
    return position + _distance * _flingDistancePenetration(t) * velocity.sign;
  }

  @override
  double dx(double time) {
    final double t = clampDouble(time / _duration, 0.0, 1.0);
    return _distance * _flingVelocityPenetration(t) * velocity.sign / _duration;
  }

  @override
  bool isDone(double time) {
    return time >= _duration;
  }
}

/// An implementation of scroll physics that matches Android page view.
///
/// See also:
///
///  * [BouncingScrollSimulation], which implements iOS scroll physics.
///  * [ClampingScrollSimulation], which implements Android scroll physics.
//
// This class ports Android logic from Scroller.java `startScroll`, applying
// the interpolator set in ViewPager.java.
//
// See Android Scroller.java `startScroll` source code
// https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/widget/Scroller.java;l=393;drc=ae5bcf23b5f0875e455790d6af387184dbd009c1
class PageScrollSimulation extends Simulation {
  /// Creates a scroll physics simulation that matches Android page view.
  PageScrollSimulation({
    required this.position,
    required this.target,
    required this.duration,
  }) : assert(position != target),
       _delta = target - position,
       _durationReciprocal = 1.0 / duration;

  /// The position at the beginning of the simulation.
  final double position;

  /// The target, which will be reached at the end of the simulation.
  final double target;

  /// The duration of the simulation in seconds.
  final double duration;

  final double _delta;
  final double _durationReciprocal;

  /// See Android ViewPager interpolator
  /// https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:viewpager/viewpager/src/main/java/androidx/viewpager/widget/ViewPager.java;l=152;drc=1dcb8847e7aca80ee78c5d9864329b93dd276379
  double _interpolate(double t) {
    // y = (t - 1)^5 + 1.0
    t -= 1.0;
    return t * t * t * t * t + 1.0;
  }

  /// A derivative from [_interpolate] function.
  double _interpolateDx(double t) {
    // y = 5 * (t - 1)^4
    t -= 1.0;
    return 5.0 * t * t * t * t;
  }

  @override
  double x(double time) {
    time = time.clamp(0.0, duration);
    return position + _delta * _interpolate(time * _durationReciprocal);
  }

  @override
  double dx(double time) {
    time = time.clamp(0.0, duration);
    return _delta * _interpolateDx(time * _durationReciprocal);
  }

  @override
  bool isDone(double time) {
    return time >= duration;
  }
}
