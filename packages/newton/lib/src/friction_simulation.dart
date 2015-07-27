// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

class FrictionSimulation extends Simulation {
  final double _drag;
  final double _dragLog;
  final double _x;
  final double _v;

  FrictionSimulation(double drag, double position, double velocity)
      : _drag = drag,
        _dragLog = math.log(drag),
        _x = position,
        _v = velocity;

  double x(double time) =>
      _x + _v * math.pow(_drag, time) / _dragLog - _v / _dragLog;

  double dx(double time) => _v * math.pow(_drag, time);

  @override
  bool isDone(double time) => dx(time).abs() < this.tolerance.velocity;
}

class BoundedFrictionSimulation extends FrictionSimulation {
  BoundedFrictionSimulation(
    double drag,
    double position,
    double velocity,
    double this._minX,
    double this._maxX) : super(drag, position, velocity);

  final double _minX;
  final double _maxX;

  double x(double time) {
    return super.x(time).clamp(_minX, _maxX);
  }

  bool isDone(double time) {
    return super.isDone(time) ||
      (x(time) - _minX).abs() < tolerance.distance ||
      (x(time) - _maxX).abs() < tolerance.distance;
  }
}
