// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:newton/newton.dart';
import 'animated_value.dart';
import 'curves.dart';
import 'ticker.dart';

/// A simulation that varies from [begin] to [end] over [duration] using [curve].
///
/// This class is an adaptor between the Simulation interface and the
/// AnimatedValue interface.
class _TweenSimulation extends Simulation {
  _TweenSimulation(double begin, double end, Duration duration, Curve curve)
    : _durationInSeconds = duration.inMicroseconds / Duration.MICROSECONDS_PER_SECOND,
      _tween = new AnimatedValue<double>(begin, end: end, curve: curve) {
    assert(_durationInSeconds > 0.0);
    assert(begin != null);
    assert(end != null);
  }

  final double _durationInSeconds;
  final AnimatedValue<double> _tween;

  double x(double timeInSeconds) {
    assert(timeInSeconds >= 0.0);
    final double t = (timeInSeconds / _durationInSeconds).clamp(0.0, 1.0);
    _tween.setProgress(t, AnimationDirection.forward);
    return _tween.value;
  }

  double dx(double timeInSeconds) => 1.0;

  bool isDone(double timeInSeconds) => timeInSeconds > _durationInSeconds;
}

typedef TimelineCallback(double value);

/// Steps a simulation one per frame
class SimulationStepper {
  SimulationStepper(TimelineCallback onTick) : _onTick = onTick {
    _ticker = new Ticker(_tick);
  }

  final TimelineCallback _onTick;
  Ticker _ticker;
  Simulation _simulation;

  /// The current value of the timeline.
  double get value => _value;
  double _value = 0.0;
  void set value(double newValue) {
    assert(newValue != null);
    assert(!isAnimating);
    _value = newValue;
    _onTick(_value);
  }

  /// Whether the timeline is currently animating.
  bool get isAnimating => _ticker.isTicking;

  /// Animates value of the timeline to the given target over the given duration.
  ///
  /// Returns a future that resolves when the timeline stops animating,
  /// typically when the timeline arives at the target value.
  Future animateTo(double target, { Duration duration, Curve curve: Curves.linear }) {
    assert(duration > Duration.ZERO);
    assert(!isAnimating);
    return _start(new _TweenSimulation(value, target, duration, curve));
  }

  /// Gives the given simulation control over the timeline.
  Future animateWith(Simulation simulation) {
    stop();
    return _start(simulation);
  }

  /// Starts ticking the given simulation once per frame.
  ///
  /// Returns a future that resolves when the simulation stops ticking.
  Future _start(Simulation simulation) {
    assert(simulation != null);
    assert(!isAnimating);
    _simulation = simulation;
    _value = simulation.x(0.0);
    return _ticker.start();
  }

  /// Stops animating the timeline.
  void stop() {
    _simulation = null;
    _ticker.stop();
  }

  void _tick(Duration elapsed) {
    double elapsedInSeconds = elapsed.inMicroseconds.toDouble() / Duration.MICROSECONDS_PER_SECOND;
    _value = _simulation.x(elapsedInSeconds);
    if (_simulation.isDone(elapsedInSeconds))
      stop();
    _onTick(_value);
  }
}
