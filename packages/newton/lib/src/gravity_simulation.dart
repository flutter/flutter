// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

class GravitySimulation extends Simulation {
  final double _x;
  final double _v;
  final double _a;
  final double _end;

  GravitySimulation(
      double acceleration, double distance, double endDistance, double velocity)
      : _a = acceleration,
        _x = distance,
        _v = velocity,
        _end = endDistance;

  double x(double time) => _x + _v * time + 0.5 * _a * time * time;

  double dx(double time) => _v + time * _a;

  @override
  bool isDone(double time) => x(time).abs() >= _end;
}
