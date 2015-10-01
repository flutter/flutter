// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:newton/newton.dart';

class ClampedSimulation extends Simulation {
  ClampedSimulation(this.simulation, {
    this.xMin: double.NEGATIVE_INFINITY,
    this.xMax: double.INFINITY,
    this.dxMin: double.NEGATIVE_INFINITY,
    this.dxMax: double.INFINITY
  }) {
    assert(simulation != null);
    assert(xMax >= xMin);
    assert(dxMax >= dxMin);
  }

  final Simulation simulation;
  final double xMin;
  final double xMax;
  final double dxMin;
  final double dxMax;

  double x(double time) => simulation.x(time).clamp(xMin, xMax);
  double dx(double time) => simulation.dx(time).clamp(dxMin, dxMax);
  bool isDone(double time) => simulation.isDone(time);
}
