// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/scheduler.dart';
import 'package:newton/newton.dart';

import 'animation.dart';
import 'curves.dart';
import 'forces.dart';
import 'listener_helpers.dart';

/// A controller for an animation.
///
/// An animation controller can drive an animation forward or backward and can
/// set the animation to a particular value. The controller also defines the
/// bounds of the animation and can drive an animation using a physics
/// simulation.
class AnimationController extends Animation<double>
  with AnimationEagerListenerMixin, AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {

  /// Creates an animation controller.
  ///
  /// * value is the initial value of the animation.
  /// * duration is the length of time this animation should last.
  /// * debugLabel is a string to help identify this animation during debugging (used by toString).
  /// * lowerBound is the smallest value this animation can obtain and the value at which this animation is deemed to be dismissed.
  /// * upperBound is the largest value this animation can obtain and the value at which this animation is deemed to be completed.
  AnimationController({
    double value,
    this.duration,
    this.debugLabel,
    this.lowerBound: 0.0,
    this.upperBound: 1.0
  }) {
    assert(upperBound >= lowerBound);
    _value = (value ?? lowerBound).clamp(lowerBound, upperBound);
    _ticker = new Ticker(_tick);
  }

  /// Creates an animation controller with no upper or lower bound for its value.
  ///
  /// * value is the initial value of the animation.
  /// * duration is the length of time this animation should last.
  /// * debugLabel is a string to help identify this animation during debugging (used by toString).
  ///
  /// This constructor is most useful for animations that will be driven using a
  /// physics simulation, especially when the physics simulation has no
  /// pre-determined bounds.
  AnimationController.unbounded({
    double value: 0.0,
    this.duration,
    this.debugLabel
  }) : lowerBound = double.NEGATIVE_INFINITY,
       upperBound = double.INFINITY,
       _value = value {
    assert(value != null);
    _ticker = new Ticker(_tick);
  }

  /// The value at which this animation is deemed to be dismissed.
  final double lowerBound;

  /// The value at which this animation is deemed to be completed.
  final double upperBound;

  /// A label that is used in the [toString] output. Intended to aid with
  /// identifying animation controller instances in debug output.
  final String debugLabel;

  /// Returns an [Animated<double>] for this animation controller,
  /// so that a pointer to this object can be passed around without
  /// allowing users of that pointer to mutate the AnimationController state.
  Animation<double> get view => this;

  /// The length of time this animation should last.
  Duration duration;

  AnimationDirection get direction => _direction;
  AnimationDirection _direction = AnimationDirection.forward;

  Ticker _ticker;
  Simulation _simulation;

  /// The current value of the animation.
  ///
  /// Setting this value stops the current animation.
  double get value => _value.clamp(lowerBound, upperBound);
  double _value;
  void set value(double newValue) {
    assert(newValue != null);
    stop();
    _value = newValue.clamp(lowerBound, upperBound);
    notifyListeners();
    _checkStatusChanged();
  }

  /// Whether this animation is currently animating in either the forward or reverse direction.
  bool get isAnimating => _ticker.isTicking;

  AnimationStatus get status {
    if (!isAnimating && value == upperBound)
      return AnimationStatus.completed;
    if (!isAnimating && value == lowerBound)
      return AnimationStatus.dismissed;
    return _direction == AnimationDirection.forward ?
        AnimationStatus.forward :
        AnimationStatus.reverse;
  }

  /// Starts running this animation forwards (towards the end).
  Future forward() => play(AnimationDirection.forward);

  /// Starts running this animation in reverse (towards the beginning).
  Future reverse() => play(AnimationDirection.reverse);

  /// Starts running this animation in the given direction.
  Future play(AnimationDirection direction) {
    _direction = direction;
    return resume();
  }

  /// Resumes this animation in the most recent direction.
  Future resume() {
    return animateTo(_direction == AnimationDirection.forward ? upperBound : lowerBound);
  }

  /// Drives the animation from its current value to target.
  Future animateTo(double target, { Duration duration, Curve curve: Curves.linear }) {
    Duration simulationDuration = duration;
    if (simulationDuration == null) {
      double range = upperBound - lowerBound;
      if (range.isFinite) {
        double remainingFraction = (target - _value).abs() / range;
        simulationDuration = this.duration * remainingFraction;
      }
    }
    stop();
    if (simulationDuration == Duration.ZERO) {
      assert(value == target);
      return new Future.value();
    }
    assert(simulationDuration > Duration.ZERO);
    assert(!isAnimating);
    return _startSimulation(new _TweenSimulation(_value, target, simulationDuration, curve));
  }

  /// Starts running this animation in the forward direction, and
  /// restarts the animation when it completes.
  Future repeat({ double min: 0.0, double max: 1.0, Duration period }) {
    period ??= duration;
    return animateWith(new _RepeatingSimulation(min, max, period));
  }

  /// Flings the timeline with an optional force (defaults to a critically
  /// damped spring) and initial velocity. If velocity is positive, the
  /// animation will complete, otherwise it will dismiss.
  Future fling({ double velocity: 1.0, Force force }) {
    force ??= kDefaultSpringForce;
    _direction = velocity < 0.0 ? AnimationDirection.reverse : AnimationDirection.forward;
    return animateWith(force.release(value, velocity));
  }

  /// Drives the animation according to the given simulation.
  Future animateWith(Simulation simulation) {
    stop();
    return _startSimulation(simulation);
  }

  Future _startSimulation(Simulation simulation) {
    assert(simulation != null);
    assert(!isAnimating);
    _simulation = simulation;
    _value = simulation.x(0.0);
    return _ticker.start();
  }

  /// Stops running this animation.
  void stop() {
    _simulation = null;
    _ticker.stop();
  }

  /// Stops running this animation.
  void dispose() {
    stop();
  }

  AnimationStatus _lastStatus = AnimationStatus.dismissed;
  void _checkStatusChanged() {
    AnimationStatus newStatus = status;
    AnimationStatus oldStatus = _lastStatus;
    _lastStatus = newStatus;
    if (oldStatus != newStatus)
      notifyStatusListeners(newStatus);
  }

  void _tick(Duration elapsed) {
    double elapsedInSeconds = elapsed.inMicroseconds.toDouble() / Duration.MICROSECONDS_PER_SECOND;
    _value = _simulation.x(elapsedInSeconds);
    if (_simulation.isDone(elapsedInSeconds))
      stop();
    notifyListeners();
    _checkStatusChanged();
  }

  String toStringDetails() {
    String paused = isAnimating ? '' : '; paused';
    String label = debugLabel == null ? '' : '; for $debugLabel';
    String more = '${super.toStringDetails()} ${value.toStringAsFixed(3)}';
    return '$more$paused$label';
  }
}

class _TweenSimulation extends Simulation {
  _TweenSimulation(this._begin, this._end, Duration duration, this._curve)
    : _durationInSeconds = duration.inMicroseconds / Duration.MICROSECONDS_PER_SECOND {
    assert(_durationInSeconds > 0.0);
    assert(_begin != null);
    assert(_end != null);
  }

  final double _durationInSeconds;
  final double _begin;
  final double _end;
  final Curve _curve;

  double x(double timeInSeconds) {
    assert(timeInSeconds >= 0.0);
    double t = (timeInSeconds / _durationInSeconds).clamp(0.0, 1.0);
    if (t == 0.0)
      return _begin;
    else if (t == 1.0)
      return _end;
    else
      return _begin + (_end - _begin) * _curve.transform(t);
  }

  double dx(double timeInSeconds) => 1.0;

  bool isDone(double timeInSeconds) => timeInSeconds > _durationInSeconds;
}

class _RepeatingSimulation extends Simulation {
  _RepeatingSimulation(this.min, this.max, Duration period)
    : _periodInSeconds = period.inMicroseconds / Duration.MICROSECONDS_PER_SECOND {
    assert(_periodInSeconds > 0.0);
  }

  final double min;
  final double max;

  final double _periodInSeconds;

  double x(double timeInSeconds) {
    assert(timeInSeconds >= 0.0);
    final double t = (timeInSeconds / _periodInSeconds) % 1.0;
    return ui.lerpDouble(min, max, t);
  }

  double dx(double timeInSeconds) => 1.0;

  bool isDone(double timeInSeconds) => false;
}
