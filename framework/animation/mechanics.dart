// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

const double kGravity = -0.980;
const double _kMinVelocity = 0.01;

abstract class System {
  void update(double deltaT);
}

class Particle extends System {
  final double mass;
  double velocity;
  double position;

  Particle({this.mass: 1.0, this.velocity: 0.0, this.position: 0.0});

  void applyImpluse(double impluse) {
    velocity += impluse / mass;
  }

  void update(double deltaT) {
    position += velocity * deltaT;
  }

  double get energy => 0.5 * mass * velocity * velocity;
         set energy(double e) {
    assert(e >= 0.0);
    velocity = math.sqrt(2 * e / mass);
  }
}

class Box {
  final double min;
  final double max;

  Box({this.min, this.max}) {
    assert(min == null || max == null || min <= max);
  }

  void confine(Particle p) {
    if (min != null) {
      p.position = math.max(min, p.position);
      if (p.position == min)
        p.velocity = math.max(0.0, p.velocity);
    }
    if (max != null) {
      p.position = math.min(max, p.position);
      if (p.position == max)
        p.velocity = math.min(0.0, p.velocity);
    }
  }
}

class ParticleInBox extends System {
  final Particle particle;
  final Box box;

  ParticleInBox({this.particle, this.box}) {
    box.confine(particle);
  }

  void update(double deltaT) {
    particle.update(deltaT);
    box.confine(particle);
  }
}

class ParticleInBoxWithFriction extends ParticleInBox {
  final double friction;
  final double _sign;

  ParticleInBoxWithFriction({Particle particle, Box box, this.friction})
      : super(particle: particle, box: box),
        _sign = particle.velocity.sign;

  void update(double deltaT) {
    double force = -_sign * friction;
    particle.applyImpluse(force * deltaT);
    if (particle.velocity.sign != _sign)
      particle.velocity = 0.0;
    super.update(deltaT);
  }
}

class Spring {
  final double k;
  double displacement;

  Spring(this.k, {this.displacement: 0.0});

  double get force => -k * displacement;
}

class ParticleAndSpringInBox extends System {
  final Particle particle;
  final Spring spring;
  final Box box;

  ParticleAndSpringInBox({this.particle, this.spring, this.box}) {
    _applyInvariants();
  }

  void update(double deltaT) {
    particle.applyImpluse(spring.force * deltaT);
    particle.update(deltaT);
    _applyInvariants();
  }

  void _applyInvariants() {
    box.confine(particle);
    spring.displacement = particle.position;
  }
}

class ParticleClimbingRamp extends System {
  final Particle particle;
  final Box box;
  final double slope;

  ParticleClimbingRamp({
      this.particle,
      this.box,
      this.slope,
      double targetPosition}) {
    double deltaPosition = targetPosition - particle.position;
    particle.energy = -kGravity * slope * deltaPosition * particle.mass;
    box.confine(particle);
  }

  void update(double deltaT) {
    particle.applyImpluse(kGravity * slope * deltaT);
    // If we don't apply a min velocity, error terms in the simulation can
    // prevent us from reaching the targetPosition before gravity overtakes our
    // initial velocity and we start rolling down the hill.
    particle.velocity = math.max(_kMinVelocity, particle.velocity);
    particle.update(deltaT);
    box.confine(particle);
  }
}
