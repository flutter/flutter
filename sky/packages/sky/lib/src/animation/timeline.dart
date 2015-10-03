// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:newton/newton.dart';
import 'package:sky/src/animation/curves.dart';
import 'package:sky/src/animation/animated_value.dart';
import 'package:sky/src/animation/animated_simulation.dart';

/// A simulation that linearly varies from [begin] to [end] over [duration]
class _TweenSimulation extends Simulation {
  final double _durationInSeconds;
  final AnimatedValue<double> _tween;

  _TweenSimulation(double begin, double end, Duration duration, Curve curve)
    : _durationInSeconds = duration.inMicroseconds / Duration.MICROSECONDS_PER_SECOND,
      _tween = new AnimatedValue<double>(begin, end: end, curve: curve) {
    assert(_durationInSeconds > 0.0);
    assert(begin != null);
    assert(end != null);
  }

  double x(double timeInSeconds) {
    assert(timeInSeconds >= 0.0);
    final double t = (timeInSeconds / _durationInSeconds).clamp(0.0, 1.0);
    _tween.setProgress(t, Direction.forward);
    return _tween.value;
  }

  double dx(double timeInSeconds) => 1.0;

  bool isDone(double timeInSeconds) => timeInSeconds > _durationInSeconds;
}

/// A timeline for an animation
class Timeline {
  Timeline(Function onTick) {
    _animation = new AnimatedSimulation(onTick);
  }

  AnimatedSimulation _animation;

  /// The current value of the timeline
  double get value => _animation.value;
  void set value(double newValue) {
    assert(newValue != null);
    assert(!isAnimating);
    _animation.value = newValue;
  }

  /// Whether the timeline is currently animating
  bool get isAnimating => _animation.isAnimating;

  /// Animate value of the timeline to the given target over the given duration
  ///
  /// Returns a future that resolves when the timeline stops animating,
  /// typically when the timeline arives at the target value.
  Future animateTo(double target, { Duration duration, Curve curve: linear }) {
    assert(duration > Duration.ZERO);
    assert(!_animation.isAnimating);
    return _animation.start(new _TweenSimulation(value, target, duration, curve));
  }

  /// Stop animating the timeline
  void stop() {
    _animation.stop();
  }

  /// Gives the given simulation control over the timeline
  Future fling(Simulation simulation) {
    stop();
    return _animation.start(simulation);
  }
}
