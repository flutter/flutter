// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'simulation.dart';

/// A simulation that never changes velocity.
///
/// This simulates a physical particle moving purely under inertia, with no
/// forces acting on it.
class InertialSimulation extends Simulation {
  /// Creates a simulation that never changes velocity.
  InertialSimulation({
    this.position = 0.0,
    this.velocity = 0.0,
    super.tolerance,
  });

  /// A simulation that is stationary at the origin.
  ///
  /// In this simulation, both [position] and [velocity] are zero.
  // Ideally this would be const, but [Simulation.tolerance] is non-final.
  static final InertialSimulation zero = InertialSimulation();

  /// The position of the particle at the beginning of the simulation.
  final double position;

  /// The velocity at which the particle travels.
  final double velocity;

  @override
  double x(double time) => position + time * velocity;

  @override
  double dx(double time) => velocity;

  @override
  bool isDone(double time) => velocity == 0.0;

  @override
  String toString() => '${objectRuntimeType(this, 'InertialSimulation')}(x₀: ${position.toStringAsFixed(1)}, dx₀: ${velocity.toStringAsFixed(1)})';
}
