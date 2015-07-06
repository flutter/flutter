// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

/// The abstract base class of all composite simulations. Concrete subclasses
/// must implement the appropriate methods to select the appropriate simulation
/// at a given time interval. The simulation group takes care to call the `step`
/// method at appropriate intervals. If more fine grained control over the the
/// step is necessary, subclasses may override the `Simulatable` methods.
abstract class SimulationGroup extends Simulation {
  Simulation get currentSimulation;

  void step(double time);

  double x(double time) {
    _stepIfNecessary(time);
    return currentSimulation.x(time);
  }

  double dx(double time) {
    _stepIfNecessary(time);
    return currentSimulation.dx(time);
  }

  @override
  bool isDone(double time) {
    _stepIfNecessary(time);
    return currentSimulation.isDone(time);
  }

  double _lastStep = -1.0;
  void _stepIfNecessary(double time) {
    if (_nearEqual(_lastStep, time)) {
      return;
    }

    _lastStep = time;
    step(time);
  }
}
