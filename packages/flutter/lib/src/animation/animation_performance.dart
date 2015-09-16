// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/src/animation/animated_value.dart';
import 'package:sky/src/animation/forces.dart';
import 'package:sky/src/animation/timeline.dart';

/// The status of an animation
enum AnimationStatus {
  /// The animation is stopped at the beginning
  dismissed,

  /// The animation is running from beginning to end
  forward,

  /// The animation is running backwards, from end to beginning
  reverse,

  /// The animation is stopped at the end
  completed,
}

/// A collection of values that animated based on a timeline
///
/// For example, a performance may handle an animation of a menu opening by
/// sliding and fading in (changing Y value and opacity) over .5 seconds. The
/// performance can move forwards (present) or backwards (dismiss). A consumer
/// may also take direct control of the timeline by manipulating [progress], or
/// [fling] the timeline causing a physics-based simulation to take over the
/// progression.
class AnimationPerformance {
  AnimationPerformance({ AnimatedVariable variable, this.duration }) :
    _variable = variable {
    _timeline = new Timeline(_tick);
  }

  /// The length of time this performance should last
  Duration duration;

  /// The variable being updated by this performance
  AnimatedVariable get variable => _variable;
  void set variable(AnimatedVariable variable) { _variable = variable; }
  AnimatedVariable _variable;

  Timeline _timeline;
  Direction _direction;

  /// The direction used to select the current curve
  ///
  /// Curve direction is only reset when we hit the beginning or the end of the
  /// timeline to avoid discontinuities in the value of the variable.
  Direction _curveDirection;

  /// If non-null, animate with this timing instead of a linear timing
  AnimationTiming timing;

  /// If non-null, animate with this force instead of a zero-to-one timeline.
  Force attachedForce;

  /// Add a variable to this animation
  ///
  /// If there are no attached variables, this variable becomes the value of
  /// [variable]. Otherwise, all the variables are stored in an [AnimatedList].
  void addVariable(AnimatedVariable newVariable) {
    if (variable == null) {
      variable = newVariable;
    } else if (variable is AnimatedList) {
      final AnimatedList variable = this.variable; // TODO(ianh): Remove this line when the analyzer is cleverer
      variable.variables.add(newVariable);
    } else {
      variable = new AnimatedList([variable, newVariable]);
    }
  }

  /// The progress of this performance along the timeline
  ///
  /// Note: Setting this value stops the current animation.
  double get progress => _timeline.value;
  void set progress(double t) {
    // TODO(mpcomplete): should this affect |direction|?
    stop();
    _timeline.value = t.clamp(0.0, 1.0);
    _checkStatusChanged();
  }

  double get _curvedProgress {
    return timing != null ? timing.transform(progress, _curveDirection) : progress;
  }

  /// Whether this animation is stopped at the beginning
  bool get isDismissed => status == AnimationStatus.dismissed;

  /// Whether this animation is stopped at the end
  bool get isCompleted => status == AnimationStatus.completed;

  /// Whether this animation is currently animating in either the forward or reverse direction
  bool get isAnimating => _timeline.isAnimating;

  /// The current status of this animation
  AnimationStatus get status {
    if (!isAnimating && progress == 1.0)
      return AnimationStatus.completed;
    if (!isAnimating && progress == 0.0)
      return AnimationStatus.dismissed;
    return _direction == Direction.forward ?
        AnimationStatus.forward :
        AnimationStatus.reverse;
  }

  /// Update the given varaible according to the current progress of this performance
  void updateVariable(AnimatedVariable variable) {
    variable.setProgress(_curvedProgress, _curveDirection);
  }

  /// Start running this animation forwards (towards the end)
  Future forward() => play(Direction.forward);

  /// Start running this animation in reverse (towards the beginning)
  Future reverse() => play(Direction.reverse);

  /// Start running this animation in the given direction
  Future play([Direction direction = Direction.forward]) {
    _direction = direction;
    return resume();
  }

  /// Start running this animation in the most recently direction
  Future resume() {
    if (attachedForce != null) {
      return fling(
        velocity: _direction == Direction.forward ? 1.0 : -1.0,
        force: attachedForce
      );
    }
    return _animateTo(_direction == Direction.forward ? 1.0 : 0.0);
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
    _direction = velocity < 0.0 ? Direction.reverse : Direction.forward;
    return _timeline.fling(force.release(progress, velocity));
  }

  final List<Function> _listeners = new List<Function>();

  /// Calls the listener every time the progress of this performance changes
  void addListener(Function listener) {
    _listeners.add(listener);
  }

  /// Stop calling the listener every time the progress of this performance changes
  void removeListener(Function listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    List<Function> localListeners = new List<Function>.from(_listeners);
    for (Function listener in localListeners)
      listener();
  }

  final List<Function> _statusListeners = new List<Function>();

  /// Calls listener every time the status of this performance changes
  void addStatusListener(Function listener) {
    _statusListeners.add(listener);
  }

  /// Stops calling the listener every time the status of this performance changes
  void removeStatusListener(Function listener) {
    _statusListeners.remove(listener);
  }

  AnimationStatus _lastStatus = AnimationStatus.dismissed;
  void _checkStatusChanged() {
    AnimationStatus currentStatus = status;
    if (currentStatus != _lastStatus) {
      List<Function> localListeners = new List<Function>.from(_statusListeners);
      for (Function listener in localListeners)
        listener(currentStatus);
    }
    _lastStatus = currentStatus;
  }

  void _updateCurveDirection() {
    if (status != _lastStatus) {
      if (_lastStatus == AnimationStatus.dismissed || _lastStatus == AnimationStatus.completed)
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
    if (variable != null)
      variable.setProgress(_curvedProgress, _curveDirection);
    _notifyListeners();
    _checkStatusChanged();
  }
}

/// An animation performance with an animated variable with a concrete type
class ValueAnimation<T> extends AnimationPerformance {
  ValueAnimation({ AnimatedValue<T> variable, Duration duration }) :
    super(variable: variable, duration: duration);

  AnimatedValue<T> get variable => _variable as AnimatedValue<T>;
  void set variable(AnimatedValue<T> v) { _variable = v; }

  T get value => variable.value;
}
