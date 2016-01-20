// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show Color, Size, Rect, VoidCallback, lerpDouble;

import 'package:newton/newton.dart';

import 'animation.dart';
import 'forces.dart';
import 'listener_helpers.dart';
import 'simulation_stepper.dart';

class AnimationController extends Animation<double>
  with EagerListenerMixin, LocalPerformanceListenersMixin, LocalPerformanceStatusListenersMixin {
  AnimationController({ this.duration, double value, this.debugLabel }) {
    _timeline = new SimulationStepper(_tick);
    if (value != null)
      _timeline.value = value.clamp(0.0, 1.0);
  }

  /// A label that is used in the [toString] output. Intended to aid with
  /// identifying animation controller instances in debug output.
  final String debugLabel;

  /// Returns a [Animated<double>] for this animation controller,
  /// so that a pointer to this object can be passed around without
  /// allowing users of that pointer to mutate the AnimationController state.
  Animation<double> get view => this;

  /// The length of time this animation should last.
  Duration duration;

  SimulationStepper _timeline;
  AnimationDirection get direction => _direction;
  AnimationDirection _direction = AnimationDirection.forward;

  /// The progress of this animation along the timeline.
  ///
  /// Note: Setting this value stops the current animation.
  double get value => _timeline.value.clamp(0.0, 1.0);
  void set value(double t) {
    stop();
    _timeline.value = t.clamp(0.0, 1.0);
    _checkStatusChanged();
  }

  /// Whether this animation is currently animating in either the forward or reverse direction.
  bool get isAnimating => _timeline.isAnimating;

  AnimationStatus get status {
    if (!isAnimating && value == 1.0)
      return AnimationStatus.completed;
    if (!isAnimating && value == 0.0)
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
    return _animateTo(_direction == AnimationDirection.forward ? 1.0 : 0.0);
  }

  /// Stops running this animation.
  void stop() {
    _timeline.stop();
  }

  /// Releases any resources used by this object.
  ///
  /// Same as stop().
  void dispose() {
    stop();
  }

  ///
  /// Flings the timeline with an optional force (defaults to a critically
  /// damped spring) and initial velocity. If velocity is positive, the
  /// animation will complete, otherwise it will dismiss.
  Future fling({double velocity: 1.0, Force force}) {
    force ??= kDefaultSpringForce;
    _direction = velocity < 0.0 ? AnimationDirection.reverse : AnimationDirection.forward;
    return _timeline.animateWith(force.release(value, velocity));
  }

  /// Starts running this animation in the forward direction, and
  /// restarts the animation when it completes.
  Future repeat({ double min: 0.0, double max: 1.0, Duration period }) {
    period ??= duration;
    return _timeline.animateWith(new _RepeatingSimulation(min, max, period));
  }

  AnimationStatus _lastStatus = AnimationStatus.dismissed;
  void _checkStatusChanged() {
    AnimationStatus currentStatus = status;
    if (currentStatus != _lastStatus)
      notifyStatusListeners(status);
    _lastStatus = currentStatus;
  }

  Future _animateTo(double target) {
    Duration remainingDuration = duration * (target - _timeline.value).abs();
    _timeline.stop();
    if (remainingDuration == Duration.ZERO)
      return new Future.value();
    return _timeline.animateTo(target, duration: remainingDuration);
  }

  void _tick(double t) {
    notifyListeners();
    _checkStatusChanged();
  }

  String toStringDetails() {
    String paused = _timeline.isAnimating ? '' : '; paused';
    String label = debugLabel == null ? '' : '; for $debugLabel';
    String more = '${super.toStringDetails()} ${value.toStringAsFixed(3)}';
    return '$more$paused$label';
  }
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
    return lerpDouble(min, max, t);
  }

  double dx(double timeInSeconds) => 1.0;

  bool isDone(double timeInSeconds) => false;
}
