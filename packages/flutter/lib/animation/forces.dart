// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:newton/newton.dart';
import 'package:sky/animation/direction.dart';

// Base class for creating Simulations for the animation Timeline.
abstract class Force {
  Simulation release(double position, double velocity, Direction direction);
}

class SpringForce extends Force {
  SpringForce(this.spring, {this.left: 0.0, this.right: 1.0});

  final SpringDescription spring;
  // Where to put the spring's resting point when releasing left or right,
  // respectively.
  final double left, right;

  Simulation release(double position, double velocity, Direction direction) {
    // Target just past the endpoint, because the animation will stop once the
    // Spring gets within the epsilon, and we want to stop at the endpoint.
    double target = direction == Direction.reverse ?
        this.left - _kEpsilon : this.right + _kEpsilon;
    return new SpringSimulation(spring, position, target, velocity);
  }
}

final SpringDescription _kDefaultSpringDesc =
    new SpringDescription.withDampingRatio(mass: 1.0, springConstant: 500.0, ratio: 1.0);
final SpringForce kDefaultSpringForce = new SpringForce(_kDefaultSpringDesc);

const double _kEpsilon = 0.001;
