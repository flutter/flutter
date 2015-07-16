// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:newton/newton.dart';
import 'package:sky/animation/animated_simulation.dart';

const  double _kEpsilon = 0.001;

// Simple simulation that linearly varies from |begin| to |end| over |duration|.
class TweenSimulation extends Simulation {
  final double _durationInSeconds;
  final double begin;
  final double end;

  TweenSimulation(Duration duration, this.begin, this.end) :
      _durationInSeconds = duration.inMilliseconds / 1000.0 {
    assert(_durationInSeconds > 0.0);
    assert(begin != null && begin >= 0.0 && begin <= 1.0);
    assert(end != null && end >= 0.0 && end <= 1.0);
  }

  double x(double timeInSeconds) {
    assert(timeInSeconds >= 0.0);
    final double t = timeInSeconds / _durationInSeconds;
    return t >= 1.0 ? end : begin + (end - begin) * t;
  }

  double dx(double timeInSeconds) => 1.0;

  bool isDone(double timeInSeconds) => timeInSeconds > _durationInSeconds;
}

class Timeline {
  Timeline(Function onTick) : _onTick = onTick {
    _animation = new AnimatedSimulation(_tick);
  }

  final Function _onTick;
  AnimatedSimulation _animation;

  double get value => _animation.value.clamp(0.0, 1.0);
  void set value(double newValue) {
    assert(newValue != null && newValue >= 0.0 && newValue <= 1.0);
    assert(!isAnimating);
    _animation.value = newValue;
  }

  bool get isAnimating => _animation.isAnimating;

  Future _start({
    Duration duration,
    double begin: 0.0,
    double end: 1.0
  }) {
    assert(!_animation.isAnimating);

    return _animation.start(new TweenSimulation(duration, begin, end));
  }

  Future animateTo(double target, { Duration duration }) {
    return _start(duration: duration, begin: value, end: target);
  }

  void stop() {
    _animation.stop();
  }

  static final SpringDescription _kDefaultSpringDesc =
      new SpringDescription.withDampingRatio(
          mass: 1.0, springConstant: 500.0, ratio: 1.0);

  Simulation defaultSpringSimulation({double velocity: 0.0}) {
    // Target just past the 0 or 1 endpoint, because the animation will stop
    // once the Spring gets within the epsilon, and we want to stop at 0 or 1.
    double target = velocity < 0.0 ? -_kEpsilon : 1.0 + _kEpsilon;
    return new SpringSimulation(_kDefaultSpringDesc, value, target, velocity);
  }

  // Give |simulation| control over the timeline.
  Future fling(Simulation simulation) {
    stop();
    return _animation.start(simulation);
  }

  void _tick(double newValue) {
    _onTick(value);
  }
}
