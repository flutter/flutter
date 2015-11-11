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

  // Return the drag value for a FrictionSimulation whose x() and dx() values pass
  // through the specified start and end position/velocity values.
  //
  // Total time to reach endVelocity is just: (log(endVelocity) / log(startVelocity)) / log(_drag)
  // or (log(v1) - log(v0)) / log(D), given v = v0 * D^t per the dx() function below.
  // Solving for D given x(time) is trickier. Algebra courtesy of Wolfram Alpha:
  // x1 = x0 + (v0 * D^((log(v1) - log(v0)) / log(D))) / log(D) - v0 / log(D), find D
  static double _dragFor(double startPosition, double endPosition, double startVelocity, double endVelocity) {
    return math.pow(math.E, (startVelocity - endVelocity) / (startPosition - endPosition));
  }

  // A friction simulation that starts and ends at the specified positions
  // and velocities.
  factory FrictionSimulation.through(double startPosition, double endPosition, double startVelocity, double endVelocity) {
    return new FrictionSimulation(
      _dragFor(startPosition, endPosition, startVelocity, endVelocity),
      startPosition,
      startVelocity)
      .. tolerance = new Tolerance(velocity: endVelocity.abs());
  }

  double x(double time) => _x + _v * math.pow(_drag, time) / _dragLog - _v / _dragLog;

  double dx(double time) => _v * math.pow(_drag, time);

  @override
  bool isDone(double time) => dx(time).abs() < this.tolerance.velocity;
}

class BoundedFrictionSimulation extends FrictionSimulation {
  BoundedFrictionSimulation(
    double drag,
    double position,
    double velocity,
    this._minX,
    this._maxX
  ) : super(drag, position, velocity);

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
