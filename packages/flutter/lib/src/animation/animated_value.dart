// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Size, Rect;

import 'curves.dart';

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

/// Used by [Performance] to convert the timing of a performance to a different timescale.
/// For example, by setting different values for the interval and reverseInterval, a performance
/// can be made to take longer in one direction that the other.
class AnimationTiming {
  AnimationTiming({ this.curve, this.reverseCurve });

  /// The curve to use in the forward direction
  Curve curve;

  /// The curve to use in the reverse direction
  ///
  /// If this field is null, use [curve] in both directions.
  Curve reverseCurve;

  /// Applies this timing to the given animation clock value in the given direction
  double transform(double t, AnimationDirection direction) {
    Curve activeCurve = _getActiveCurve(direction);
    if (activeCurve == null)
      return t;
    if (t == 0.0 || t == 1.0) {
      assert(activeCurve.transform(t).round() == t);
      return t;
    }
    return activeCurve.transform(t);
  }

  Curve _getActiveCurve(AnimationDirection direction) {
    if (direction == AnimationDirection.forward || reverseCurve == null)
      return curve;
    return reverseCurve;
  }
}

/// An animated variable with a concrete type.
class AnimatedValue<T extends dynamic> extends AnimationTiming implements Animatable {
  AnimatedValue(this.begin, { this.end, Curve curve, Curve reverseCurve })
    : super(curve: curve, reverseCurve: reverseCurve) {
    value = begin;
  }

  /// The current value of this variable.
  T value;

  /// The value this variable has at the beginning of the animation.
  T begin;

  /// The value this variable has at the end of the animation.
  T end;

  /// Returns the value this variable has at the given animation clock value.
  T lerp(double t) => begin + (end - begin) * t;

  /// Updates the value of this variable according to the given animation clock
  /// value and direction.
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

/// An animated variable containing a color.
///
/// This class specializes the interpolation of AnimatedValue<Color> to be
/// appropriate for colors.
class AnimatedColorValue extends AnimatedValue<Color> {
  AnimatedColorValue(Color begin, { Color end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  Color lerp(double t) => Color.lerp(begin, end, t);
}

/// An animated variable containing a size.
///
/// This class specializes the interpolation of AnimatedValue<Size> to be
/// appropriate for rectangles.
class AnimatedSizeValue extends AnimatedValue<Size> {
  AnimatedSizeValue(Size begin, { Size end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  Size lerp(double t) => Size.lerp(begin, end, t);
}

/// An animated variable containing a rectangle.
///
/// This class specializes the interpolation of AnimatedValue<Rect> to be
/// appropriate for rectangles.
class AnimatedRectValue extends AnimatedValue<Rect> {
  AnimatedRectValue(Rect begin, { Rect end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  Rect lerp(double t) => Rect.lerp(begin, end, t);
}

/// An animated variable containing a int.
///
/// The inherited lerp() function doesn't work with ints because it multiplies
/// the begin and end types by a double, and int * double returns a double.
/// This class overrides the lerp() function to round off the result to an int.
class AnimatedIntValue extends AnimatedValue<int> {
  AnimatedIntValue(int begin, { int end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  int lerp(double t) => (begin + (end - begin) * t).round();
}
