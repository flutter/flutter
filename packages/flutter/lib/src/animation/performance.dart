// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show VoidCallback, lerpDouble;

import 'package:newton/newton.dart';

import 'animated_value.dart';
import 'curves.dart';
import 'forces.dart';
import 'listener_helpers.dart';
import 'simulation_stepper.dart';

/// A read-only view of a [Performance].
///
/// This interface is implemented by [Performance].
///
/// Read-only access to [Performance] is used by classes that
/// want to watch a performance but should not be able to change the
/// performance's state.
abstract class PerformanceView {
  const PerformanceView();

  /// Update the given variable according to the current progress of the performance.
  void updateVariable(Animatable variable);
  /// Calls the listener every time the progress of the performance changes.
  void addListener(VoidCallback listener);
  /// Stop calling the listener every time the progress of the performance changes.
  void removeListener(VoidCallback listener);
  /// Calls listener every time the status of the performance changes.
  void addStatusListener(PerformanceStatusListener listener);
  /// Stops calling the listener every time the status of the performance changes.
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
  ///
  /// This is the value that is used to update any variables when using
  /// [updateVariable].
  double get progress;

  /// Whether this animation is stopped at the beginning.
  bool get isDismissed => status == PerformanceStatus.dismissed;

  /// Whether this animation is stopped at the end.
  bool get isCompleted => status == PerformanceStatus.completed;

  String toString() {
    return '$runtimeType(${toStringDetails()})';
  }
  String toStringDetails() {
    assert(status != null);
    assert(direction != null);
    String icon;
    switch (status) {
      case PerformanceStatus.forward:
        icon = '\u25B6'; // >
        break;
      case PerformanceStatus.reverse:
        icon = '\u25C0'; // <
        break;
      case PerformanceStatus.completed:
        switch (direction) {
          case AnimationDirection.forward:
            icon = '\u23ED'; // >>|
            break;
          case AnimationDirection.reverse:
            icon = '\u29CF'; // <|
            break;
        }
        break;
      case PerformanceStatus.dismissed:
        switch (direction) {
          case AnimationDirection.forward:
            icon = '\u29D0'; // |>
            break;
          case AnimationDirection.reverse:
            icon = '\u23EE'; // |<<
            break;
        }
        break;
    }
    assert(icon != null);
    return '$icon ${progress.toStringAsFixed(3)}';
  }
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
 
class AlwaysDismissedPerformance extends PerformanceView {
  const AlwaysDismissedPerformance();

  void updateVariable(Animatable variable) {
    variable.setProgress(0.0, AnimationDirection.forward);
  }

  // this performance never changes state
  void addListener(VoidCallback listener) { }
  void removeListener(VoidCallback listener) { }
  void addStatusListener(PerformanceStatusListener listener) { }
  void removeStatusListener(PerformanceStatusListener listener) { }
  PerformanceStatus get status => PerformanceStatus.dismissed;
  AnimationDirection get direction => AnimationDirection.forward;
  AnimationDirection get curveDirection => AnimationDirection.forward;
  double get progress => 0.0;
}
const AlwaysDismissedPerformance alwaysDismissedPerformance = const AlwaysDismissedPerformance();

class ReversePerformance extends PerformanceView
  with LazyListenerMixin, LocalPerformanceStatusListenersMixin {
  ReversePerformance(this.masterPerformance);

  final PerformanceView masterPerformance;

  void updateVariable(Animatable variable) {
    variable.setProgress(progress, curveDirection);
  }

  void addListener(VoidCallback listener) {
    didRegisterListener();
    masterPerformance.addListener(listener);
  }
  void removeListener(VoidCallback listener) {
    masterPerformance.removeListener(listener);
    didUnregisterListener();
  }

  void didStartListening() {
    masterPerformance.addStatusListener(_statusChangeHandler);
  }

  void didStopListening() {
    masterPerformance.removeStatusListener(_statusChangeHandler);
  }

  void _statusChangeHandler(PerformanceStatus status) {
    notifyStatusListeners(_reverseStatus(status));
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

class MeanPerformance extends PerformanceView
  with LazyListenerMixin, LocalPerformanceListenersMixin, LocalPerformanceStatusListenersMixin {
  MeanPerformance(this._performances) {
    assert(_performances != null);
  }

  // This list is intended to be immutable. Behavior is undefined if you mutate it.
  final List<PerformanceView> _performances;

  void didStartListening() {
    for (PerformanceView performance in _performances) {
      performance.addListener(notifyListeners);
      performance.addStatusListener(notifyStatusListeners);
    }
  }

  void didStopListening() {
    for (PerformanceView performance in _performances) {
      performance.removeListener(notifyListeners);
      performance.removeStatusListener(notifyStatusListeners);
    }
  }

  void updateVariable(Animatable variable) {
    variable.setProgress(progress, curveDirection);
  }

  PerformanceStatus get status {
    bool dismissed = true;
    bool completed = true;
    int direction = 0;
    for (PerformanceView performance in _performances) {
      switch (performance.status) {
        case PerformanceStatus.dismissed:
          completed = false;
          break;
        case PerformanceStatus.completed:
          dismissed = false;
          break;
        case PerformanceStatus.forward:
          dismissed = false;
          completed = false;
          direction += 1;
          break;
        case PerformanceStatus.reverse:
          dismissed = false;
          completed = false;
          direction -= 1;
          break;
      }
    }
    if (direction > 1)
      return PerformanceStatus.forward;
    if (direction < 1)
      return PerformanceStatus.reverse;
    if (dismissed)
      return PerformanceStatus.dismissed; // all performances were dismissed, or we had none
    if (completed)
      return PerformanceStatus.completed; // all performances were completed
    // Performances were conflicted.
    // Either we had an equal non-zero number of forwards and reverse
    // transitions, or we had both completed and dismissed transitions.
    // We default to whatever our first performance was.
    assert(_performances.isNotEmpty);
    return _performances[0].status;
  }

  AnimationDirection get direction {
    if (_performances.isEmpty)
      return AnimationDirection.forward;
    int direction = 0;
    for (PerformanceView performance in _performances) {
      switch (performance.direction) {
        case AnimationDirection.forward:
          direction += 1;
          break;
        case AnimationDirection.reverse:
          direction -= 1;
          break;
      }
    }
    if (direction > 1)
      return AnimationDirection.forward;
    if (direction < 1)
      return AnimationDirection.reverse;
    // We had an equal (non-zero) number of forwards and reverse transitions.
    // Default to the first one.
    return _performances[0].direction;
  }

  AnimationDirection get curveDirection {
    if (_performances.isEmpty)
      return AnimationDirection.forward;
    int curveDirection = 0;
    for (PerformanceView performance in _performances) {
      switch (performance.curveDirection) {
        case AnimationDirection.forward:
          curveDirection += 1;
          break;
        case AnimationDirection.reverse:
          curveDirection -= 1;
          break;
      }
    }
    if (curveDirection > 1)
      return AnimationDirection.forward;
    if (curveDirection < 1)
      return AnimationDirection.reverse;
    // We had an equal (non-zero) number of forwards and reverse transitions.
    // Default to the first one.
    return _performances[0].curveDirection;
  }

  double get progress {
    if (_performances.isEmpty)
      return 0.0;
    double result = 0.0;
    for (PerformanceView performance in _performances)
      result += performance.progress;
    return result / _performances.length;
  }
}

enum _TrainHoppingMode { minimize, maximize }

/// This performance starts by proxying one performance, but can be given a
/// second performance. When their times cross (either because the second is
/// going in the opposite direction, or because the one overtakes the other),
/// the performance hops over to proxying the second performance, and the second
/// performance becomes the new "first" performance.
///
/// Since this object must track the two performances even when it has no
/// listeners of its own, instead of shutting down when all its listeners are
/// removed, it exposes a [dispose()] method. Call this method to shut this
/// object down.
class TrainHoppingPerformance extends PerformanceView
  with EagerListenerMixin, LocalPerformanceListenersMixin, LocalPerformanceStatusListenersMixin {
  TrainHoppingPerformance(this._currentTrain, this._nextTrain, { this.onSwitchedTrain }) {
    assert(_currentTrain != null);
    if (_nextTrain != null) {
      if (_currentTrain.progress > _nextTrain.progress) {
        _mode = _TrainHoppingMode.maximize;
      } else {
        _mode = _TrainHoppingMode.minimize;
        if (_currentTrain.progress == _nextTrain.progress) {
          _currentTrain = _nextTrain;
          _nextTrain = null;
        }
      }
    }
    _currentTrain.addStatusListener(_statusChangeHandler);
    _currentTrain.addListener(_valueChangeHandler);
    if (_nextTrain != null)
      _nextTrain.addListener(_valueChangeHandler);
    assert(_mode != null);
  }

  PerformanceView get currentTrain => _currentTrain;
  PerformanceView _currentTrain;
  PerformanceView _nextTrain;
  _TrainHoppingMode _mode;

  VoidCallback onSwitchedTrain;

  void updateVariable(Animatable variable) {
    assert(_currentTrain != null);
    variable.setProgress(progress, curveDirection);
  }

  PerformanceStatus _lastStatus;
  void _statusChangeHandler(PerformanceStatus status) {
    assert(_currentTrain != null);
    if (status != _lastStatus) {
      notifyListeners();
      _lastStatus = status;
    }
    assert(_lastStatus != null);
  }

  PerformanceStatus get status => _currentTrain.status;
  AnimationDirection get direction => _currentTrain.direction;
  AnimationDirection get curveDirection => _currentTrain.curveDirection;

  double _lastProgress;  
  void _valueChangeHandler() {
    assert(_currentTrain != null);
    bool hop = false;
    if (_nextTrain != null) {
      switch (_mode) {
        case _TrainHoppingMode.minimize:
          hop = _nextTrain.progress <= _currentTrain.progress;
          break;
        case _TrainHoppingMode.maximize: 
          hop = _nextTrain.progress >= _currentTrain.progress;
          break;
      }
      if (hop) {
        _currentTrain.removeStatusListener(_statusChangeHandler);
        _currentTrain.removeListener(_valueChangeHandler);
        _currentTrain = _nextTrain;
        _nextTrain.addListener(_valueChangeHandler);
        _statusChangeHandler(_nextTrain.status);
      }
    }
    double newProgress = progress;
    if (newProgress != _lastProgress) {
      notifyListeners();
      _lastProgress = newProgress;
    }
    assert(_lastProgress != null);
    if (hop && onSwitchedTrain != null)
      onSwitchedTrain();
  }

  double get progress => _currentTrain.progress;

  /// Frees all the resources used by this performance.
  /// After this is called, this object is no longer usable.
  void dispose() {
    assert(_currentTrain != null);
    _currentTrain.removeStatusListener(_statusChangeHandler);
    _currentTrain.removeListener(_valueChangeHandler);
    _currentTrain = null;
    if (_nextTrain != null) {
      _nextTrain.removeListener(_valueChangeHandler);
      _nextTrain = null;
    }
  }
}

class ProxyPerformance extends PerformanceView
  with LazyListenerMixin, LocalPerformanceListenersMixin, LocalPerformanceStatusListenersMixin {
  ProxyPerformance([PerformanceView performance]) {
    _masterPerformance = performance;
    if (_masterPerformance == null) {
      _status = PerformanceStatus.dismissed;
      _direction = AnimationDirection.forward;
      _curveDirection = AnimationDirection.forward;
      _progress = 0.0;
    }
  }

  PerformanceStatus _status;
  AnimationDirection _direction;
  AnimationDirection _curveDirection;
  double _progress;

  PerformanceView get masterPerformance => _masterPerformance;
  PerformanceView _masterPerformance;
  void set masterPerformance(PerformanceView value) {
    if (value == _masterPerformance)
      return;
    if (_masterPerformance != null) {
      _status = _masterPerformance.status;
      _direction = _masterPerformance.direction;
      _curveDirection = _masterPerformance.curveDirection;
      _progress = _masterPerformance.progress;
      if (isListening)
        didStopListening();
    }
    _masterPerformance = value;
    if (_masterPerformance != null) {
      if (isListening)
        didStartListening();
      if (_progress != _masterPerformance.progress)
        notifyListeners();
      if (_status != _masterPerformance.status)
        notifyStatusListeners(_masterPerformance.status);
      _status = null;
      _direction = null;
      _curveDirection = null;
      _progress = null;
    }
  }

  void didStartListening() {
    if (_masterPerformance != null) {
      _masterPerformance.addListener(notifyListeners);
      _masterPerformance.addStatusListener(notifyStatusListeners);
    }
  }

  void didStopListening() {
    if (_masterPerformance != null) {
      _masterPerformance.removeListener(notifyListeners);
      _masterPerformance.removeStatusListener(notifyStatusListeners);
    }
  }

  void updateVariable(Animatable variable) {
    variable.setProgress(progress, curveDirection);
  }

  PerformanceStatus get status => _masterPerformance != null ? _masterPerformance.status : _status;
  AnimationDirection get direction => _masterPerformance != null ? _masterPerformance.direction : _direction;
  AnimationDirection get curveDirection => _masterPerformance != null ? _masterPerformance.curveDirection : _curveDirection;
  double get progress => _masterPerformance != null ? _masterPerformance.progress : _progress;
}

class CurvedPerformance extends PerformanceView {
  CurvedPerformance(this._performance, { this.curve, this.reverseCurve });

  final PerformanceView _performance;

  /// The curve to use in the forward direction
  Curve curve;

  /// The curve to use in the reverse direction
  ///
  /// If this field is null, use [curve] in both directions.
  Curve reverseCurve;

  void addListener(VoidCallback listener) {
    _performance.addListener(listener);
  }
  void removeListener(VoidCallback listener) {
    _performance.removeListener(listener);
  }

  void addStatusListener(PerformanceStatusListener listener) {
    _performance.addStatusListener(listener);
  }
  void removeStatusListener(PerformanceStatusListener listener) {
    _performance.removeStatusListener(listener);
  }

  void updateVariable(Animatable variable) {
    variable.setProgress(progress, curveDirection);
  }

  PerformanceStatus get status => _performance.status;
  AnimationDirection get direction => _performance.direction;
  AnimationDirection get curveDirection => _performance.curveDirection;
  double get progress {
    Curve activeCurve;
    if (curveDirection == AnimationDirection.forward || reverseCurve == null)
      activeCurve = curve;
    else
      activeCurve = reverseCurve;
    if (activeCurve == null)
      return _performance.progress;
    if (_performance.status == PerformanceStatus.dismissed) {
      assert(_performance.progress == 0.0);
      assert(activeCurve.transform(0.0).roundToDouble() == 0.0);
      return 0.0;
    }
    if (_performance.status == PerformanceStatus.completed) {
      assert(_performance.progress == 1.0);
      assert(activeCurve.transform(1.0).roundToDouble() == 1.0);
      return 1.0;
    }
    return activeCurve.transform(_performance.progress);
  }
}

/// A timeline that can be reversed and used to update [Animatable]s.
///
/// For example, a performance may handle an animation of a menu opening by
/// sliding and fading in (changing Y value and opacity) over .5 seconds. The
/// performance can move forwards (present) or backwards (dismiss). A consumer
/// may also take direct control of the timeline by manipulating [progress], or
/// [fling] the timeline causing a physics-based simulation to take over the
/// progression.
class Performance extends PerformanceView
  with EagerListenerMixin, LocalPerformanceListenersMixin, LocalPerformanceStatusListenersMixin {
  Performance({ this.duration, double progress, this.debugLabel }) {
    _timeline = new SimulationStepper(_tick);
    if (progress != null)
      _timeline.value = progress.clamp(0.0, 1.0);
  }

  /// A label that is used in the [toString] output. Intended to aid with
  /// identifying performance instances in debug output.
  final String debugLabel;

  /// Returns a [PerformanceView] for this performance,
  /// so that a pointer to this object can be passed around without
  /// allowing users of that pointer to mutate the Performance state.
  PerformanceView get view => this;

  /// The length of time this performance should last.
  Duration duration;

  SimulationStepper _timeline;
  AnimationDirection get direction => _direction;
  AnimationDirection _direction = AnimationDirection.forward;
  AnimationDirection get curveDirection => _curveDirection;
  AnimationDirection _curveDirection = AnimationDirection.forward;

  /// The progress of this performance along the timeline.
  ///
  /// Note: Setting this value stops the current animation.
  double get progress => _timeline.value.clamp(0.0, 1.0);
  void set progress(double t) {
    stop();
    _timeline.value = t.clamp(0.0, 1.0);
    _checkStatusChanged();
  }

  /// Whether this animation is currently animating in either the forward or reverse direction.
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

  /// Updates the given variable according to the current progress of this performance.
  void updateVariable(Animatable variable) {
    variable.setProgress(progress, _curveDirection);
  }

  /// Starts running this animation forwards (towards the end).
  Future forward() => play(AnimationDirection.forward);

  /// Starts running this animation in reverse (towards the beginning).
  Future reverse() => play(AnimationDirection.reverse);

  /// Starts running this animation in the given direction.
  Future play([AnimationDirection direction = AnimationDirection.forward]) {
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
    return _timeline.animateWith(force.release(progress, velocity));
  }

  Future repeat({ double min: 0.0, double max: 1.0, Duration period }) {
    period ??= duration;
    return _timeline.animateWith(new _RepeatingSimulation(min, max, period));
  }

  PerformanceStatus _lastStatus = PerformanceStatus.dismissed;
  void _checkStatusChanged() {
    PerformanceStatus currentStatus = status;
    if (currentStatus != _lastStatus)
      notifyStatusListeners(status);
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
    notifyListeners();
    _checkStatusChanged();
  }

  String toStringDetails() {    
    String paused = _timeline.isAnimating ? '' : '; paused';
    String label = debugLabel == null ? '' : '; for $debugLabel';
    String more = super.toStringDetails();
    return '$more$paused$label';
  }
}

/// An animation performance with an animated variable with a concrete type.
class ValuePerformance<T> extends Performance {
  ValuePerformance({ this.variable, Duration duration, double progress }) :
    super(duration: duration, progress: progress);

  AnimatedValue<T> variable;
  T get value => variable.value;

  void didTick(double t) {
    if (variable != null)
      variable.setProgress(progress, _curveDirection);
    super.didTick(t);
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
