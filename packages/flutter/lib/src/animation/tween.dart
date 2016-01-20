// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show Color, Size, Rect, VoidCallback, lerpDouble;

import 'package:newton/newton.dart';

import 'animated_value.dart';
import 'curves.dart';
import 'forces.dart';
import 'listener_helpers.dart';
import 'simulation_stepper.dart';

abstract class Animated<T> {
  const Animated();

  /// Calls the listener every time the value of the animation changes.
  void addListener(VoidCallback listener);
  /// Stop calling the listener every time the value of the animation changes.
  void removeListener(VoidCallback listener);
  /// Calls listener every time the status of the animation changes.
  void addStatusListener(PerformanceStatusListener listener);
  /// Stops calling the listener every time the status of the animation changes.
  void removeStatusListener(PerformanceStatusListener listener);

  /// The current status of this animation.
  PerformanceStatus get status;

  /// The current direction of the animation.
  AnimationDirection get direction;

  /// The current value of the animation.
  T get value;

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
    return '$icon';
  }
}

abstract class ProxyAnimatedMixin {
  Animated<double> get parent;

  void addListener(VoidCallback listener) => parent.addListener(listener);
  void removeListener(VoidCallback listener) => parent.removeListener(listener);
  void addStatusListener(PerformanceStatusListener listener) => parent.addStatusListener(listener);
  void removeStatusListener(PerformanceStatusListener listener) => parent.removeStatusListener(listener);

  PerformanceStatus get status => parent.status;
  AnimationDirection get direction => parent.direction;
}

abstract class Evaluatable<T> {
  const Evaluatable();

  T evaluate(Animated<double> animation);

  Animated<T> animate(Animated<double> parent) {
    return new _AnimatedEvaluation<T>(parent, this);
  }
}

class _AnimatedEvaluation<T> extends Animated<T> with ProxyAnimatedMixin {
  _AnimatedEvaluation(this.parent, this._evaluatable);

  /// The animation from which this value is derived.
  final Animated<double> parent;

  final Evaluatable<T> _evaluatable;

  T get value => _evaluatable.evaluate(parent);
}

class AnimationController extends Animated<double>
  with EagerListenerMixin, LocalPerformanceListenersMixin, LocalPerformanceStatusListenersMixin {
  AnimationController({ this.duration, double value, this.debugLabel }) {
    _timeline = new SimulationStepper(_tick);
    if (value != null)
      _timeline.value = value.clamp(0.0, 1.0);
  }

  /// A label that is used in the [toString] output. Intended to aid with
  /// identifying performance instances in debug output.
  final String debugLabel;

  /// Returns a [Animation] for this performance,
  /// so that a pointer to this object can be passed around without
  /// allowing users of that pointer to mutate the Performance state.
  Animated<double> get view => this;

  /// The length of time this performance should last.
  Duration duration;

  SimulationStepper _timeline;
  AnimationDirection get direction => _direction;
  AnimationDirection _direction = AnimationDirection.forward;

  /// The progress of this performance along the timeline.
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

  PerformanceStatus get status {
    if (!isAnimating && value == 1.0)
      return PerformanceStatus.completed;
    if (!isAnimating && value == 0.0)
      return PerformanceStatus.dismissed;
    return _direction == AnimationDirection.forward ?
        PerformanceStatus.forward :
        PerformanceStatus.reverse;
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

  PerformanceStatus _lastStatus = PerformanceStatus.dismissed;
  void _checkStatusChanged() {
    PerformanceStatus currentStatus = status;
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

class CurvedAnimation extends Animated<double> with ProxyAnimatedMixin {
  CurvedAnimation({
    this.parent,
    this.curve: Curves.linear,
    this.reverseCurve
  }) {
    assert(parent != null);
    assert(curve != null);
    parent.addStatusListener(_handleStatusChanged);
  }

  final Animated<double> parent;

  /// The curve to use in the forward direction.
  Curve curve;

  /// The curve to use in the reverse direction.
  ///
  /// If this field is null, uses [curve] in both directions.
  Curve reverseCurve;

  /// The direction used to select the current curve.
  ///
  /// The curve direction is only reset when we hit the beginning or the end of
  /// the timeline to avoid discontinuities in the value of any variables this
  /// performance is used to animate.
  AnimationDirection _curveDirection;

  void _handleStatusChanged(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.dismissed:
      case PerformanceStatus.completed:
        _curveDirection = null;
        break;
      case PerformanceStatus.forward:
        _curveDirection ??= AnimationDirection.forward;
        break;
      case PerformanceStatus.reverse:
        _curveDirection ??= AnimationDirection.reverse;
        break;
    }
  }

  double get value {
    final bool useForwardCurve = reverseCurve == null || (_curveDirection ?? parent.direction) == AnimationDirection.forward;
    Curve activeCurve = useForwardCurve ? curve : reverseCurve;

    double t = parent.value;
    if (activeCurve == null)
      return t;
    if (t == 0.0 || t == 1.0) {
      assert(activeCurve.transform(t).round() == t);
      return t;
    }
    return activeCurve.transform(t);
  }
}

class Tween<T extends dynamic> extends Evaluatable<T> {
  Tween({ this.begin, this.end });

  /// The value this variable has at the beginning of the animation.
  T begin;

  /// The value this variable has at the end of the animation.
  T end;

  /// Returns the value this variable has at the given animation clock value.
  T lerp(double t) => begin + (end - begin) * t;

  T evaluate(Animated<double> animation) {
    if (end == null)
      return begin;
    double t = animation.value;
    if (t == 0.0)
      return begin;
    if (t == 1.0)
      return end;
    return lerp(t);
  }
}

/// An animated variable containing a color.
///
/// This class specializes the interpolation of Tween<Color> to be
/// appropriate for colors.
class ColorTween extends Tween<Color> {
  ColorTween({ Color begin, Color end }) : super(begin: begin, end: end);

  Color lerp(double t) => Color.lerp(begin, end, t);
}

/// An animated variable containing a size.
///
/// This class specializes the interpolation of Tween<Size> to be
/// appropriate for rectangles.
class SizeTween extends Tween<Size> {
  SizeTween({ Size begin, Size end }) : super(begin: begin, end: end);

  Size lerp(double t) => Size.lerp(begin, end, t);
}

/// An animated variable containing a rectangle.
///
/// This class specializes the interpolation of Tween<Rect> to be
/// appropriate for rectangles.
class RectTween extends Tween<Rect> {
  RectTween({ Rect begin, Rect end }) : super(begin: begin, end: end);

  Rect lerp(double t) => Rect.lerp(begin, end, t);
}

/// An animated variable containing a int.
class IntTween extends Tween<int> {
  IntTween({ int begin, int end }) : super(begin: begin, end: end);

  // The inherited lerp() function doesn't work with ints because it multiplies
  // the begin and end types by a double, and int * double returns a double.
  int lerp(double t) => (begin + (end - begin) * t).round();
}

class CurveTween extends Evaluatable<double> {
  CurveTween({ this.curve });

  Curve curve;

  double evaluate(Animated<double> animation) {
    double t = animation.value;
    if (t == 0.0 || t == 1.0) {
      assert(curve.transform(t).round() == t);
      return t;
    }
    return curve.transform(t);
  }
}
