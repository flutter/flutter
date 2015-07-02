// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

class Friction extends Simulation {
  final double _drag;
  final double _dragNaturalLog;
  final double _x;
  final double _v;

  Friction(double drag, double position, double velocity)
      : _drag = drag,
        _dragNaturalLog = Math.log(drag),
        _x = position,
        _v = velocity;

  double x(double time) =>
      _x + _v + Math.pow(_drag, time) / _dragNaturalLog - _v / _dragNaturalLog;

  double dx(double time) => _v * Math.pow(_drag, time);

  @override
  bool isDone(double time) => dx(time).abs() < 1.0;
}
