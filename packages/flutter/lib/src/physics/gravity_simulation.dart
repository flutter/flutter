// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'simulation.dart';

/// A simulation that applies a constant accelerating force.
///
/// Models a particle that follows Newton's second law of motion. The simulation
/// ends when the position reaches a defined point.
class GravitySimulation extends Simulation {
  /// Creates a [GravitySimulation] using the given arguments, which are,
  /// respectively: an acceleration that is to be applied continually over time;
  /// an initial position relative to an origin; the magnitude of the distance
  /// from that origin beyond which (in either direction) to consider the
  /// simulation to be "done", which must be positive; and an initial velocity.
  ///
  /// The initial position and maximum distance are measured in arbitrary length
  /// units L from an arbitrary origin. The units will match those used for [x].
  ///
  /// The time unit T used for the arguments to [x], [dx], and [isDone],
  /// combined with the aforementioned length unit, together determine the units
  /// that must be used for the velocity and acceleration arguments: L/T and
  /// L/T² respectively. The same units of velocity are used for the velocity
  /// obtained from [dx].
  GravitySimulation(
    double acceleration,
    double distance,
    double endDistance,
    double velocity
  ) : assert(acceleration != null),
      assert(distance != null),
      assert(velocity != null),
      assert(endDistance != null),
      assert(endDistance >= 0),
      _a = acceleration,
      _x = distance,
      _v = velocity,
      _end = endDistance;

  final double _x;
  final double _v;
  final double _a;
  final double _end;

  @override
  double x(double time) => _x + _v * time + 0.5 * _a * time * time;

  @override
  double dx(double time) => _v + time * _a;

  @override
  bool isDone(double time) => x(time).abs() >= _end;
}
