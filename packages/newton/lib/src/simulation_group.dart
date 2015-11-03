// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

/// The abstract base class for all composite simulations. Concrete subclasses
/// must implement the appropriate methods to select the appropriate simulation
/// at a given time interval. The simulation group takes care to call the `step`
/// method at appropriate intervals. If more fine grained control over the the
/// step is necessary, subclasses may override `Simulatable` methods.
abstract class SimulationGroup extends Simulation {

  /// The currently active simulation
  Simulation get currentSimulation;

  /// The time offset applied to the currently active simulation;
  double get currentIntervalOffset;

  /// Called when a significant change in the interval is detected. Subclasses
  /// must decide if the the current simulation must be switched (or updated).
  /// The result is whether the simulation was switched in this step.
  bool step(double time);

  double x(double time) {
    _stepIfNecessary(time);
    return currentSimulation.x(time - currentIntervalOffset);
  }

  double dx(double time) {
    _stepIfNecessary(time);
    return currentSimulation.dx(time - currentIntervalOffset);
  }

  @override
  void set tolerance(Tolerance t) {
    this.currentSimulation.tolerance = t;
    super.tolerance = t;
  }

  @override
  bool isDone(double time) {
    _stepIfNecessary(time);
    return currentSimulation.isDone(time - currentIntervalOffset);
  }

  double _lastStep = -1.0;
  void _stepIfNecessary(double time) {
    if (_nearEqual(_lastStep, time, toleranceDefault.time)) {
      return;
    }

    _lastStep = time;
    if (step(time)) {
      this.currentSimulation.tolerance = this.tolerance;
    }
  }
}
