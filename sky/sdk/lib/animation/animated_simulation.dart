// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:newton/newton.dart';
import 'package:sky/base/scheduler.dart' as scheduler;

const double _kSecondsPerMillisecond = 1000.0;

class Ticker {
  Ticker(Function onTick) : _onTick = onTick;

  final Function _onTick;

  Completer _completer;
  int _animationId;

  Future start() {
    assert(!isTicking);
    _completer = new Completer();
    _scheduleTick();
    return _completer.future;
  }

  void stop() {
    if (!isTicking)
      return;

    if (_animationId != null) {
      scheduler.cancelAnimationFrame(_animationId);
      _animationId = null;
    }

    Completer localCompleter = _completer;
    _completer = null;

    // We take the _completer into a local variable so that !isTicking when we
    // actually complete the future.
    assert(!isTicking);
    localCompleter.complete();
  }

  bool get isTicking => _completer != null;

  void _tick(double timeStamp) {
    assert(isTicking);
    assert(_animationId != null);
    _animationId = null;

    _onTick(timeStamp);

    if (isTicking)
      _scheduleTick();
  }

  void _scheduleTick() {
    assert(isTicking);
    assert(_animationId == null);
    _animationId = scheduler.requestAnimationFrame(_tick);
  }
}

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
  void set value(double newValue) {
    assert(!_ticker.isTicking);
    _value = newValue;
    _onTick(_value);
  }

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
    _ticker.stop();
  }

  bool get isAnimating => _ticker.isTicking;

  void _tick(double timeStamp) {
    if (_startTime == null)
      _startTime = timeStamp;

    double timeInSeconds = (timeStamp - _startTime) / _kSecondsPerMillisecond;
    _value = _simulation.x(timeInSeconds);
    final bool isLastTick = _simulation.isDone(timeInSeconds);

    if (isLastTick)
      stop();

    _onTick(_value);
  }

}
