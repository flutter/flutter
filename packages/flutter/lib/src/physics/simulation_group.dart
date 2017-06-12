// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'simulation.dart';
import 'tolerance.dart';
import 'utils.dart';

/// Base class for composite simulations.
///
/// Concrete subclasses must implement the [currentSimulation] getter, the
/// [currentIntervalOffset] getter, and the [step] function to select the
/// appropriate simulation at a given time interval. This class implements the
/// [x], [dx], and [isDone] functions by calling the [step] method if necessary
/// and then deferring to the [currentSimulation]'s methods with a time offset
/// by [currentIntervalOffset].
///
/// The tolerance of this simulation is pushed to the simulations that are used
/// by this group as they become active. This mean simulations should not be
/// shared among different groups that are active at the same time.
abstract class SimulationGroup extends Simulation {
  /// Initializes the [tolerance] field for subclasses.
  SimulationGroup({ Tolerance tolerance: Tolerance.defaultTolerance }) : super(tolerance: tolerance);

  /// The currently active simulation.
  ///
  /// This getter should return the same value until [step] is called and
  /// returns true.
  Simulation get currentSimulation;

  /// The time offset applied to the currently active simulation when deferring
  /// [x], [dx], and [isDone] to it.
  double get currentIntervalOffset;

  /// Called when a significant change in the interval is detected. Subclasses
  /// must decide if the current simulation must be switched (or updated).
  ///
  /// Must return true if the simulation was switched in this step, otherwise
  /// false.
  ///
  /// If this function returns true, then [currentSimulation] must start
  /// returning a new value.
  bool step(double time);

  double _lastStep = -1.0;
  void _stepIfNecessary(double time) {
    if (nearEqual(_lastStep, time, Tolerance.defaultTolerance.time))
      return;

    _lastStep = time;
    if (step(time))
      currentSimulation.tolerance = tolerance;
  }

  @override
  double x(double time) {
    _stepIfNecessary(time);
    return currentSimulation.x(time - currentIntervalOffset);
  }

  @override
  double dx(double time) {
    _stepIfNecessary(time);
    return currentSimulation.dx(time - currentIntervalOffset);
  }

  @override
  bool isDone(double time) {
    _stepIfNecessary(time);
    return currentSimulation.isDone(time - currentIntervalOffset);
  }

  @override
  set tolerance(Tolerance value) {
    currentSimulation.tolerance = value;
    super.tolerance = value;
  }
}
