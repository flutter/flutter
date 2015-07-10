// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:newton/newton.dart';

import 'timeline.dart';

const double _kSecondsPerMillisecond = 1000.0;

class AnimatedSimulation {

  AnimatedSimulation(Function onTick) : _onTick = onTick {
    _ticker = new Ticker(_tick);
  }

  final Function _onTick;
  Ticker _ticker;

  Simulation _simulation;
  double _startTime;

  double _value = 0.0;
  double get value => _value;

  Future start(Simulation simulation) {
    assert(simulation != null);
    assert(!_ticker.isTicking);
    _simulation = simulation;
    _startTime = null;
    _value = simulation.x(0.0);
    return _ticker.start();
  }

  void stop() {
    _simulation = null;
    _startTime = null;
    _value = 0.0;
    _ticker.stop();
  }

  bool get isAnimating => _ticker.isTicking;

  void _tick(double timeStamp) {
    if (_startTime == null)
      _startTime = timeStamp;

    double timeInSeconds = (timeStamp - _startTime) / _kSecondsPerMillisecond;
    _value = _simulation.x(timeInSeconds);
    final bool isLastTick = _simulation.isDone(timeInSeconds);

    _onTick(_value);

    if (isLastTick)
      stop();
  }

}
