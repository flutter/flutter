// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library animation_mechanics;

import 'dart:math' as math;

const double kGravity = -0.980; // m^s-2

abstract class System {
  void update(double deltaT);
}

class Particle extends System {
  final double mass;
  double velocity;
  double position;

  Particle({this.mass: 1.0, this.velocity: 0.0, this.position: 0.0});

  void applyImpulse(double impulse) {
    velocity += impulse / mass;
  }

  void update(double deltaT) {
    position += velocity * deltaT;
  }

  void setVelocityFromEnergy({double energy, double direction}) {
    assert(direction == -1.0 || direction == 1.0);
    assert(energy >= 0.0);
    velocity = math.sqrt(2.0 * energy / mass) * direction;
  }
}

abstract class Box {
  void confine(Particle p);
}

class ClosedBox extends Box {
  final double min; // m
  final double max; // m

  ClosedBox({this.min, this.max}) {
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

class GeofenceBox extends Box {
  final double min; // m
  final double max; // m

  final Function onEscape;

  GeofenceBox({this.min, this.max, this.onEscape}) {
    assert(min == null || max == null || min <= max);
    assert(onEscape != null);
  }

  void confine(Particle p) {
    if (((min != null) && (p.position < min)) ||
        ((max != null) && (p.position > max)))
      onEscape();
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
  final double friction; // unitless
  final double _sign;

  final Function onStop;

  ParticleInBoxWithFriction({Particle particle, Box box, this.friction, this.onStop})
      : super(particle: particle, box: box),
        _sign = particle.velocity.sign;

  void update(double deltaT) {
    double force = -_sign * friction * particle.mass * -kGravity;
    particle.applyImpulse(force * deltaT);
    if (particle.velocity.sign != _sign) {
      particle.velocity = 0.0;
    }
    super.update(deltaT);
    if ((particle.velocity == 0.0) && (onStop != null))
      onStop();
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
    particle.applyImpulse(spring.force * deltaT);
    particle.update(deltaT);
    _applyInvariants();
  }

  void _applyInvariants() {
    box.confine(particle);
    spring.displacement = particle.position;
  }
}

class ParticleClimbingRamp extends System {

  // This is technically the same as ParticleInBoxWithFriction. The
  // difference is in how the system is set up. Here, we configure the
  // system so as to stop by a certain distance after having been
  // given an initial impulse from rest, whereas
  // ParticleInBoxWithFriction is set up to stop with a consistent
  // decelerating force assuming an initial velocity. The angle theta
  // (0 < theta < π/2) is used to configure how much energy the
  // particle is to start with; lower angles result in a gentler kick
  // while higher angles result in a faster conclusion.

  final Particle particle;
  final Box box;
  final double theta;
  final double _sinTheta;

  ParticleClimbingRamp({
      this.particle,
      this.box,
      double theta, // in radians
      double targetPosition}) : this.theta = theta, this._sinTheta = math.sin(theta) {
    assert(theta > 0.0);
    assert(theta < math.PI / 2.0);
    double deltaPosition = targetPosition - particle.position;
    double tanTheta = math.tan(theta);
    // We need to give the particle exactly as much (kinetic) energy
    // as it needs to get to the top of the slope and stop with
    // energy=0. This is exactly the same amount of energy as the
    // potential energy at the top of the slope, which is g*h*m.
    // If the slope's horizontal component is delta P long, then
    // the height is delta P times tan theta.
    particle.setVelocityFromEnergy(
      energy: (kGravity * (deltaPosition * tanTheta) * particle.mass).abs(),
      direction: deltaPosition > 0.0 ? 1.0 : -1.0
    );
    box.confine(particle);
  }

  void update(double deltaT) {
    particle.update(deltaT);
    // Note that we apply the impulse from gravity after updating the particle's
    // position so that we overestimate the distance traveled by the particle.
    // That ensures that we actually hit the edge of the box and don't wind up
    // reversing course.
    particle.applyImpulse(particle.mass * kGravity * _sinTheta * deltaT);
    box.confine(particle);
  }
}

class Multisystem extends System {
  final Particle particle;

  System _currentSystem;

  Multisystem({ this.particle, System system }) {
    assert(system != null);
    _currentSystem = system;
  }

  void update(double deltaT) {
    _currentSystem.update(deltaT);
  }

  void transitionToSystem(System system) {
    assert(system != null);
    _currentSystem = system;
  }
}
