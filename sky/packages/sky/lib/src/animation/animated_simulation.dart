// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:newton/newton.dart';
import 'package:sky/src/animation/scheduler.dart';

typedef _TickerCallback(Duration timeStamp);

/// Calls its callback once per animation frame
class Ticker {
  /// Constructs a ticker that will call onTick once per frame while running
  Ticker(_TickerCallback onTick) : _onTick = onTick;

  final _TickerCallback _onTick;

  Completer _completer;
  int _animationId;

  /// Start calling onTick once per animation frame
  ///
  /// The returned future resolves once the ticker stops ticking.
  Future start() {
    assert(!isTicking);
    _completer = new Completer();
    _scheduleTick();
    return _completer.future;
  }

  /// Stop calling onTick
  ///
  /// Causes the future returned by [start] to resolve.
  void stop() {
    if (!isTicking)
      return;

    if (_animationId != null) {
      scheduler.cancelAnimationFrame(_animationId);
      _animationId = null;
    }

    // We take the _completer into a local variable so that !isTicking
    // when we actually complete the future (isTicking uses _completer
    // to determine its state).
    Completer localCompleter = _completer;
    _completer = null;
    assert(!isTicking);
    localCompleter.complete();
  }

  /// Whether this ticker has scheduled a call to onTick
  bool get isTicking => _completer != null;

  void _tick(Duration timeStamp) {
    assert(isTicking);
    assert(_animationId != null);
    _animationId = null;

    _onTick(timeStamp);

    // The onTick callback may have scheduled another tick already.
    if (isTicking && _animationId == null)
      _scheduleTick();
  }

  void _scheduleTick() {
    assert(isTicking);
    assert(_animationId == null);
    _animationId = scheduler.requestAnimationFrame(_tick);
  }
}

/// Ticks a simulation once per frame
class AnimatedSimulation {

  AnimatedSimulation(Function onTick) : _onTick = onTick {
    _ticker = new Ticker(_tick);
  }

  final Function _onTick;
  Ticker _ticker;

  Simulation _simulation;
  Duration _startTime;

  double _value = 0.0;
  /// The current value of the simulation
  double get value => _value;
  void set value(double newValue) {
    assert(!_ticker.isTicking);
    _value = newValue;
    _onTick(_value);
  }

  /// Start ticking the given simulation once per frame
  ///
  /// Returns a future that resolves when the simulation stops ticking.
  Future start(Simulation simulation) {
    assert(simulation != null);
    assert(!_ticker.isTicking);
    _simulation = simulation;
    _startTime = null;
    _value = simulation.x(0.0);
    return _ticker.start();
  }

  /// Stop ticking the current simulation
  void stop() {
    _simulation = null;
    _startTime = null;
    _ticker.stop();
  }

  /// Whether this object is currently ticking a simulation
  bool get isAnimating => _ticker.isTicking;

  void _tick(Duration timeStamp) {
    if (_startTime == null)
      _startTime = timeStamp;

    double timeInMicroseconds = (timeStamp - _startTime).inMicroseconds.toDouble();
    double timeInSeconds =  timeInMicroseconds / Duration.MICROSECONDS_PER_SECOND;
    _value = _simulation.x(timeInSeconds);
    final bool isLastTick = _simulation.isDone(timeInSeconds);

    if (isLastTick)
      stop();

    _onTick(_value);
  }

}
