// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' show Color, Rect;

import 'package:sky/src/animation/curves.dart';

/// The direction in which an animation is running
enum AnimationDirection {
  /// The animation is running from beginning to end
  forward,

  /// The animation is running backwards, from end to beginning
  reverse
}

/// An interface describing a variable that changes as an animation progresses.
///
/// Animatable objects, by convention, must be cheap to create. This allows them
/// to be used in build functions in Widgets.
abstract class Animatable {
  /// Update the variable to a given time in an animation that is running in the given direction
  void setProgress(double t, AnimationDirection direction);
  String toString();
}

/// Used by [AnimationPerformance] to convert the timing of a performance to a different timescale.
/// For example, by setting different values for the interval and reverseInterval, a performance
/// can be made to take longer in one direction that the other.
class AnimationTiming {
  AnimationTiming({
    this.interval: const Interval(0.0, 1.0),
    this.reverseInterval,
    this.curve: linear,
    this.reverseCurve
  });

  /// The interval during which this timing is active in the forward direction
  Interval interval;

  /// The interval during which this timing is active in the reverse direction
  ///
  /// If this field is null, the timing defaults to using [interval] in both directions.
  Interval reverseInterval;

  /// The curve that this timing applies to the animation clock in the forward direction
  Curve curve;

  /// The curve that this timing applies to the animation clock in the reverse direction
  ///
  /// If this field is null, the timing defaults to using [curve] in both directions.
  Curve reverseCurve;

  /// Applies this timing to the given animation clock value in the given direction
  double transform(double t, AnimationDirection direction) {
    Interval interval = _getInterval(direction);
    if (interval != null)
      t = interval.transform(t);
    assert(t >= 0.0 && t <= 1.0);
    if (t == 0.0 || t == 1.0) {
      assert(t == _applyCurve(t, direction).round().toDouble());
      return t;
    }
    return _applyCurve(t, direction);
  }

  Interval _getInterval(AnimationDirection direction) {
    if (direction == AnimationDirection.forward || reverseInterval == null)
      return interval;
    return reverseInterval;
  }

  Curve _getCurve(AnimationDirection direction) {
    if (direction == AnimationDirection.forward || reverseCurve == null)
      return curve;
    return reverseCurve;
  }

  double _applyCurve(double t, AnimationDirection direction) {
    Curve curve = _getCurve(direction);
    if (curve == null)
      return t;
    return curve.transform(t);
  }
}

/// An animated variable with a concrete type
class AnimatedValue<T extends dynamic> extends AnimationTiming implements Animatable {
  AnimatedValue(this.begin, { this.end, Interval interval, Interval reverseInterval, Curve curve, Curve reverseCurve })
    : super(interval: interval, reverseInterval: reverseInterval, curve: curve, reverseCurve: reverseCurve) {
    value = begin;
  }

  /// The current value of this variable
  T value;

  /// The value this variable has at the beginning of the animation
  T begin;

  /// The value this variable has at the end of the animation
  T end;

  /// Returns the value this variable has at the given animation clock value
  T lerp(double t) => begin + (end - begin) * t;

  /// Updates the value of this variable according to the given animation clock value and direction
  void setProgress(double t, AnimationDirection direction) {
    if (end != null) {
      t = transform(t, direction);
      if (t == 0.0)
        value = begin;
      else if (t == 1.0)
        value = end;
      else
        value = lerp(t);
    }
  }

  String toString() => 'AnimatedValue(begin=$begin, end=$end, value=$value)';
}

/// An animated variable containing a color
///
/// This class specializes the interpolation of AnimatedValue<Color> to be
/// appropriate for colors.
class AnimatedColorValue extends AnimatedValue<Color> {
  AnimatedColorValue(Color begin, { Color end, Interval interval, Interval reverseInterval, Curve curve, Curve reverseCurve })
    : super(begin, end: end, interval: interval, reverseInterval: reverseInterval, curve: curve, reverseCurve: reverseCurve);

  Color lerp(double t) => Color.lerp(begin, end, t);
}

/// An animated variable containing a rectangle
///
/// This class specializes the interpolation of AnimatedValue<Rect> to be
/// appropriate for rectangles.
class AnimatedRectValue extends AnimatedValue<Rect> {
  AnimatedRectValue(Rect begin, { Rect end, Interval interval, Interval reverseInterval, Curve curve, Curve reverseCurve })
    : super(begin, end: end, interval: interval, reverseInterval: reverseInterval, curve: curve, reverseCurve: reverseCurve);

  Rect lerp(double t) => Rect.lerp(begin, end, t);
}
