// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show VoidCallback, lerpDouble;

import 'package:newton/newton.dart';

import 'animated_value.dart';
import 'forces.dart';
import 'simulation_stepper.dart';

/// The status of an animation
enum PerformanceStatus {
  /// The animation is stopped at the beginning
  dismissed,

  /// The animation is running from beginning to end
  forward,

  /// The animation is running backwards, from end to beginning
  reverse,

  /// The animation is stopped at the end
  completed,
}

typedef void PerformanceStatusListener(PerformanceStatus status);

/// An interface that is implemented by [Performance] that exposes a
/// read-only view of the underlying performance. This is used by classes that
/// want to watch a performance but should not be able to change the
/// performance's state.
abstract class PerformanceView {
  const PerformanceView();

  /// Update the given variable according to the current progress of the performance
  void updateVariable(Animatable variable);
  /// Calls the listener every time the progress of the performance changes
  void addListener(VoidCallback listener);
  /// Stop calling the listener every time the progress of the performance changes
  void removeListener(VoidCallback listener);
  /// Calls listener every time the status of the performance changes
  void addStatusListener(PerformanceStatusListener listener);
  /// Stops calling the listener every time the status of the performance changes
  void removeStatusListener(PerformanceStatusListener listener);

  /// The current status of this animation.
  PerformanceStatus get status;

  /// The current direction of the animation.
  AnimationDirection get direction;

  /// The direction used to select the current curve.
  ///
  /// The curve direction is only reset when we hit the beginning or the end of
  /// the timeline to avoid discontinuities in the value of any variables this
  /// performance is used to animate.
  AnimationDirection get curveDirection;

  /// The current progress of this animation (a value from 0.0 to 1.0).
  /// This is the value that is used to update any variables when using updateVariable().
  double get progress;

  /// Whether this animation is stopped at the beginning
  bool get isDismissed => status == PerformanceStatus.dismissed;

  /// Whether this animation is stopped at the end
  bool get isCompleted => status == PerformanceStatus.completed;
}

class AlwaysCompletePerformance extends PerformanceView {
  const AlwaysCompletePerformance();

  void updateVariable(Animatable variable) {
    variable.setProgress(1.0, AnimationDirection.forward);
  }

  // this performance never changes state
  void addListener(VoidCallback listener) { }
  void removeListener(VoidCallback listener) { }
  void addStatusListener(PerformanceStatusListener listener) { }
  void removeStatusListener(PerformanceStatusListener listener) { }
  PerformanceStatus get status => PerformanceStatus.completed;
  AnimationDirection get direction => AnimationDirection.forward;
  AnimationDirection get curveDirection => AnimationDirection.forward;
  double get progress => 1.0;
}
const AlwaysCompletePerformance alwaysCompletePerformance = const AlwaysCompletePerformance();

class ReversePerformance extends PerformanceView {
  ReversePerformance(this.masterPerformance) {
    masterPerformance.addStatusListener(_statusChangeHandler);
  }

  final PerformanceView masterPerformance;

  void updateVariable(Animatable variable) {
    variable.setProgress(progress, curveDirection);
  }

  void addListener(VoidCallback listener) {
    masterPerformance.addListener(listener);
  }
  void removeListener(VoidCallback listener) {
    masterPerformance.removeListener(listener);
  }

  final List<PerformanceStatusListener> _statusListeners = new List<PerformanceStatusListener>();

  /// Calls listener every time the status of this performance changes
  void addStatusListener(PerformanceStatusListener listener) {
    _statusListeners.add(listener);
  }

  /// Stops calling the listener every time the status of this performance changes
  void removeStatusListener(PerformanceStatusListener listener) {
    _statusListeners.remove(listener);
  }

  void _statusChangeHandler(PerformanceStatus status) {
    status = _reverseStatus(status);
    List<PerformanceStatusListener> localListeners = new List<PerformanceStatusListener>.from(_statusListeners);
    for (PerformanceStatusListener listener in localListeners)
      listener(status);
  }

  PerformanceStatus get status => _reverseStatus(masterPerformance.status);
  AnimationDirection get direction => _reverseDirection(masterPerformance.direction);
  AnimationDirection get curveDirection => _reverseDirection(masterPerformance.curveDirection);
  double get progress => 1.0 - masterPerformance.progress;

  PerformanceStatus _reverseStatus(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.forward: return PerformanceStatus.reverse;
      case PerformanceStatus.reverse: return PerformanceStatus.forward;
      case PerformanceStatus.completed: return PerformanceStatus.dismissed;
      case PerformanceStatus.dismissed: return PerformanceStatus.completed;
    }
  }

  AnimationDirection _reverseDirection(AnimationDirection direction) {
    switch (direction) {
      case AnimationDirection.forward: return AnimationDirection.reverse;
      case AnimationDirection.reverse: return AnimationDirection.forward;
    }
  }
}

class _RepeatingSimulation extends Simulation {
  _RepeatingSimulation(this.min, this.max, Duration period)
    : _periodInSeconds = period.inMicroseconds.toDouble() / Duration.MICROSECONDS_PER_SECOND {
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

/// A timeline that can be reversed and used to update [Animatable]s.
///
/// For example, a performance may handle an animation of a menu opening by
/// sliding and fading in (changing Y value and opacity) over .5 seconds. The
/// performance can move forwards (present) or backwards (dismiss). A consumer
/// may also take direct control of the timeline by manipulating [progress], or
/// [fling] the timeline causing a physics-based simulation to take over the
/// progression.
class Performance extends PerformanceView {
  Performance({ this.duration, double progress, this.debugLabel }) {
    _timeline = new SimulationStepper(_tick);
    if (progress != null)
      _timeline.value = progress.clamp(0.0, 1.0);
  }

  /// A label that is used in the toString() output. Intended to aid with
  /// identifying performance instances in debug output.
  final String debugLabel;

  /// Returns a [PerformanceView] for this performance,
  /// so that a pointer to this object can be passed around without
  /// allowing users of that pointer to mutate the Performance state.
  PerformanceView get view => this;

  /// The length of time this performance should last
  Duration duration;

  SimulationStepper _timeline;
  AnimationDirection get direction => _direction;
  AnimationDirection _direction;
  AnimationDirection get curveDirection => _curveDirection;
  AnimationDirection _curveDirection;

  /// If non-null, animate with this timing instead of a linear timing
  AnimationTiming timing;

  /// The progress of this performance along the timeline
  ///
  /// Note: Setting this value stops the current animation.
  double get progress => _timeline.value.clamp(0.0, 1.0);
  void set progress(double t) {
    stop();
    _timeline.value = t.clamp(0.0, 1.0);
    _checkStatusChanged();
  }

  double get _curvedProgress {
    return timing != null ? timing.transform(progress, _curveDirection) : progress;
  }

  /// Whether this animation is currently animating in either the forward or reverse direction
  bool get isAnimating => _timeline.isAnimating;

  PerformanceStatus get status {
    if (!isAnimating && progress == 1.0)
      return PerformanceStatus.completed;
    if (!isAnimating && progress == 0.0)
      return PerformanceStatus.dismissed;
    return _direction == AnimationDirection.forward ?
        PerformanceStatus.forward :
        PerformanceStatus.reverse;
  }

  /// Update the given varaible according to the current progress of this performance
  void updateVariable(Animatable variable) {
    variable.setProgress(_curvedProgress, _curveDirection);
  }

  /// Start running this animation forwards (towards the end)
  Future forward() => play(AnimationDirection.forward);

  /// Start running this animation in reverse (towards the beginning)
  Future reverse() => play(AnimationDirection.reverse);

  /// Start running this animation in the given direction
  Future play([AnimationDirection direction = AnimationDirection.forward]) {
    _direction = direction;
    return resume();
  }

  /// Start running this animation in the most recent direction
  Future resume() {
    return _animateTo(_direction == AnimationDirection.forward ? 1.0 : 0.0);
  }

  /// Stop running this animation
  void stop() {
    _timeline.stop();
  }

  /// Start running this animation according to the given physical parameters
  ///
  /// Flings the timeline with an optional force (defaults to a critically
  /// damped spring) and initial velocity. If velocity is positive, the
  /// animation will complete, otherwise it will dismiss.
  Future fling({double velocity: 1.0, Force force}) {
    if (force == null)
      force = kDefaultSpringForce;
    _direction = velocity < 0.0 ? AnimationDirection.reverse : AnimationDirection.forward;
    return _timeline.animateWith(force.release(progress, velocity));
  }

  Future repeat({ double min: 0.0, double max: 1.0, Duration period }) {
    if (period == null)
      period = duration;
    return _timeline.animateWith(new _RepeatingSimulation(min, max, period));
  }

  final List<VoidCallback> _listeners = new List<VoidCallback>();

  /// Calls the listener every time the progress of this performance changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Stop calling the listener every time the progress of this performance changes
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    List<VoidCallback> localListeners = new List<VoidCallback>.from(_listeners);
    for (VoidCallback listener in localListeners)
      listener();
  }

  final List<PerformanceStatusListener> _statusListeners = new List<PerformanceStatusListener>();

  /// Calls listener every time the status of this performance changes
  void addStatusListener(PerformanceStatusListener listener) {
    _statusListeners.add(listener);
  }

  /// Stops calling the listener every time the status of this performance changes
  void removeStatusListener(PerformanceStatusListener listener) {
    _statusListeners.remove(listener);
  }

  PerformanceStatus _lastStatus = PerformanceStatus.dismissed;
  void _checkStatusChanged() {
    PerformanceStatus currentStatus = status;
    if (currentStatus != _lastStatus) {
      List<PerformanceStatusListener> localListeners = new List<PerformanceStatusListener>.from(_statusListeners);
      for (PerformanceStatusListener listener in localListeners)
        listener(currentStatus);
    }
    _lastStatus = currentStatus;
  }

  void _updateCurveDirection() {
    if (status != _lastStatus) {
      if (_lastStatus == PerformanceStatus.dismissed || _lastStatus == PerformanceStatus.completed)
        _curveDirection = _direction;
    }
  }

  Future _animateTo(double target) {
    Duration remainingDuration = duration * (target - _timeline.value).abs();
    _timeline.stop();
    if (remainingDuration == Duration.ZERO)
      return new Future.value();
    return _timeline.animateTo(target, duration: remainingDuration);
  }

  void _tick(double t) {
    _updateCurveDirection();
    didTick(t);
  }

  void didTick(double t) {
    _notifyListeners();
    _checkStatusChanged();
  }

  String toString() {
    if (debugLabel != null)
      return '$runtimeType at $progress for $debugLabel';
    return '$runtimeType at $progress';
  }
}

/// An animation performance with an animated variable with a concrete type
class ValuePerformance<T> extends Performance {
  ValuePerformance({ this.variable, Duration duration, double progress }) :
    super(duration: duration, progress: progress);

  AnimatedValue<T> variable;
  T get value => variable.value;

  void didTick(double t) {
    if (variable != null)
      variable.setProgress(_curvedProgress, _curveDirection);
    super.didTick(t);
  }
}
