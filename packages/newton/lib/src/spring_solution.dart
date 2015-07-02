// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

abstract class _SpringSolution implements Simulatable {
  factory _SpringSolution(
      SpringDesc desc, double initialPosition, double initialVelocity) {
    double cmk =
        desc.damping * desc.damping - 4 * desc.mass * desc.springConstant;

    if (cmk == 0.0) {
      return new _CriticalSolution(desc, initialPosition, initialVelocity);
    } else if (cmk > 0.0) {
      return new _OverdampedSolution(desc, initialPosition, initialVelocity);
    } else {
      return new _UnderdampedSolution(desc, initialPosition, initialVelocity);
    }

    return null;
  }
}

class _CriticalSolution implements _SpringSolution {
  double r, c1, c2;

  _CriticalSolution(SpringDesc desc, double distance, double velocity) {
    r = -desc.damping / (2.0 * desc.mass);
    c1 = distance;
    c2 = velocity / (r * distance);
  }

  double x(double time) => (c1 + c2 * time) * Math.pow(Math.E, r * time);

  double dx(double time) {
    final double power = Math.pow(Math.E, r * time);
    return r * (c1 + c2 * time) * power + c2 * power;
  }
}

class _OverdampedSolution implements _SpringSolution {
  double r1, r2, c1, c2;

  _OverdampedSolution(SpringDesc desc, double distance, double velocity) {
    double cmk =
        desc.damping * desc.damping - 4 * desc.mass * desc.springConstant;

    r1 = (-desc.damping - Math.sqrt(cmk)) / (2.0 * desc.mass);
    r2 = (-desc.damping + Math.sqrt(cmk)) / (2.0 * desc.mass);
    c2 = (velocity - r1 * distance) / (r2 - r1);
    c1 = distance - c2;
  }

  double x(double time) =>
      (c1 * Math.pow(Math.E, r1 * time) + c2 * Math.pow(Math.E, r2 * time));

  double dx(double time) => (c1 * r1 * Math.pow(Math.E, r1 * time) +
      c2 * r2 * Math.pow(Math.E, r2 * time));
}

class _UnderdampedSolution implements _SpringSolution {
  double w, r, c1, c2;

  _UnderdampedSolution(SpringDesc desc, double distance, double velocity) {
    w = Math.sqrt(4.0 * desc.mass * desc.springConstant -
            desc.damping * desc.damping) /
        (2.0 * desc.mass);
    r = -(desc.damping / 2.0 * desc.mass);
    c1 = distance;
    c2 = (velocity - r * distance) / w;
  }

  double x(double time) => Math.pow(Math.E, r * time) *
      (c1 * Math.cos(w * time) + c2 * Math.sin(w * time));

  double dx(double time) {
    final double power = Math.pow(Math.E, r * time);
    final double cosine = Math.cos(w * time);
    final double sine = Math.sin(w * time);

    return power * (c2 * w * cosine - c1 * w * sine) +
        r * power * (c2 * sine + c1 * cosine);
  }
}
