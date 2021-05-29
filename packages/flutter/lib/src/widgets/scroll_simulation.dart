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
    return math.log(_inflexion * velocity.abs() / (friction * _decelerationForFriction(0.84)));
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

  // Generated from dev/tools/generate_android_spline_data.dart.
  static final List<double> _splinePosition = <double>[
    0.000022888183591973643,
    0.028561000304762274,
    0.05705195792956655,
    0.08538917797618413,
    0.11349556286812107,
    0.14129881694635613,
    0.16877157254923383,
    0.19581093511175632,
    0.22239649722992452,
    0.24843841866631658,
    0.2740024733220569,
    0.298967680744136,
    0.32333234658228116,
    0.34709556909569184,
    0.3702249257894571,
    0.39272483400399893,
    0.41456988647721615,
    0.43582889025419114,
    0.4564192786416,
    0.476410299013587,
    0.4957560715637827,
    0.5145493169954743,
    0.5327205670880077,
    0.5502846891191615,
    0.5673274324802855,
    0.583810881323224,
    0.5997478744397482,
    0.615194045299478,
    0.6301165005270208,
    0.6445484042257972,
    0.6585198219185201,
    0.6720397744233084,
    0.6850997688076114,
    0.6977281404741683,
    0.7099506591298411,
    0.7217749311525871,
    0.7331784038850426,
    0.7442308394229518,
    0.7549087205105974,
    0.7652471277371271,
    0.7752251637549381,
    0.7848768260203478,
    0.7942056937103814,
    0.8032299679689082,
    0.8119428702388629,
    0.8203713516576219,
    0.8285187880808974,
    0.8363794492831295,
    0.8439768562813565,
    0.851322799855549,
    0.8584111051351724,
    0.8652534074722162,
    0.8718525580962131,
    0.8782333271742155,
    0.8843892099362031,
    0.8903155590440985,
    0.8960465359221951,
    0.9015574505919048,
    0.9068736766459904,
    0.9119951682409297,
    0.9169321898723632,
    0.9216747065581234,
    0.9262420604674766,
    0.9306331858366086,
    0.9348476990715433,
    0.9389007110754832,
    0.9427903495057521,
    0.9465220679845756,
    0.9500943036519721,
    0.9535176728088761,
    0.9567898524767604,
    0.959924306623116,
    0.9629127700159108,
    0.9657622101750765,
    0.9684818726275105,
    0.9710676079044347,
    0.9735231939498,
    0.9758514437576309,
    0.9780599066560445,
    0.9801485715370128,
    0.9821149805689633,
    0.9839677526782791,
    0.9857085499421516,
    0.9873347811966005,
    0.9888547171706613,
    0.9902689443512227,
    0.9915771042095881,
    0.9927840651641069,
    0.9938913963715834,
    0.9948987305580712,
    0.9958114963810524,
    0.9966274782266875,
    0.997352148697352,
    0.9979848677523623,
    0.9985285021374979,
    0.9989844084453229,
    0.9993537595844986,
    0.999638729860106,
    0.9998403888004533,
    0.9999602810470701,
    1.0,
  ];
}
