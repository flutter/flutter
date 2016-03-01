// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'tolerance.dart';

abstract class Simulatable {
  /// The current position of the object in the simulation
  double x(double time);

  /// The current velocity of the object in the simulation
  double dx(double time);
}

/// The base class for all simulations. The user is meant to instantiate an
/// instance of a simulation and query the same for the position and velocity
/// of the body at a given interval.
abstract class Simulation implements Simulatable {
  Tolerance tolerance = toleranceDefault;

  /// Returns if the simulation is done at a given time
  bool isDone(double time);
}
