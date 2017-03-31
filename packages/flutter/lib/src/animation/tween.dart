// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Size, Rect;

import 'package:flutter/foundation.dart';

import 'animation.dart';
import 'animations.dart';
import 'curves.dart';

/// An object that can produce a value of type T given an [Animation] as input.
abstract class Animatable<T> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Animatable();

  /// The current value of this object for the given animation.
  T evaluate(Animation<double> animation);

  /// Returns a new Animation that is driven by the given animation but that
  /// takes on values determined by this object.
  Animation<T> animate(Animation<double> parent) {
    return new _AnimatedEvaluation<T>(parent, this);
  }

  /// Returns a new Animatable whose value is determined by first evaluating
  /// the given parent and then evaluating this object.
  Animatable<T> chain(Animatable<double> parent) {
    return new _ChainedEvaluation<T>(parent, this);
  }
}

class _AnimatedEvaluation<T> extends Animation<T> with AnimationWithParentMixin<double> {
  _AnimatedEvaluation(this.parent, this._evaluatable);

  @override
  final Animation<double> parent;

  final Animatable<T> _evaluatable;

  @override
  T get value => _evaluatable.evaluate(parent);

  @override
  String toString() {
    return '$parent\u27A9$_evaluatable\u27A9$value';
  }

  @override
  String toStringDetails() {
    return '${super.toStringDetails()} $_evaluatable';
  }
}

class _ChainedEvaluation<T> extends Animatable<T> {
  _ChainedEvaluation(this._parent, this._evaluatable);

  final Animatable<double> _parent;
  final Animatable<T> _evaluatable;

  @override
  T evaluate(Animation<double> animation) {
    final double value = _parent.evaluate(animation);
    return _evaluatable.evaluate(new AlwaysStoppedAnimation<double>(value));
  }

  @override
  String toString() {
    return '$_parent\u27A9$_evaluatable';
  }
}

/// A linear interpolation between a beginning and ending value.
///
/// [Tween] is useful if you want to interpolate across a range.
///
/// To use a [Tween] object with an animation, call the [Tween] object's
/// `animate()` method and pass it the [Animation] object that you want to
/// modify.
///
/// You can chain [Tween] objects together using the `chain()` method, so that a
/// single [Animation] object is configured by multiple [Tween] objects called
/// in succession. This is different than calling the `animate()` method twice,
/// which results in two [Animation] separate objects, each configured with a
/// single [Tween].
class Tween<T extends dynamic> extends Animatable<T> {
  /// Creates a tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  Tween({ this.begin, this.end });

  /// The value this variable has at the beginning of the animation.
  ///
  /// Must be non-null before this [Tween] is evaluated.
  T begin;

  /// The value this variable has at the end of the animation.
  ///
  /// Must be non-null before this [Tween] is evaluated.
  T end;

  /// Returns the value this variable has at the given animation clock value.
  ///
  /// The [begin] and [end] properties must be non-null by the time this method
  /// is called.
  T lerp(double t) => begin + (end - begin) * t;

  /// Returns the interpolated value for the current value of the given animation.
  ///
  /// This method returns `begin` and `end` when the animation values are 0.0 or
  /// 1.0, respectively.
  ///
  /// The [begin] and [end] properties must be non-null by the time this method
  /// is called with an animation that is not at 0.0 or 1.0.
  @override
  T evaluate(Animation<double> animation) {
    final double t = animation.value;
    if (t == 0.0)
      return begin;
    if (t == 1.0)
      return end;
    return lerp(t);
  }

  @override
  String toString() => '$runtimeType($begin \u2192 $end)';
}

/// An interpolation between two colors.
///
/// This class specializes the interpolation of Tween<Color> to be
/// appropriate for colors.
class ColorTween extends Tween<Color> {
  /// Creates a color tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  ColorTween({ Color begin, Color end }) : super(begin: begin, end: end);

  @override
  Color lerp(double t) => Color.lerp(begin, end, t);
}

/// An interpolation between two sizes.
///
/// This class specializes the interpolation of Tween<Size> to be
/// appropriate for rectangles.
class SizeTween extends Tween<Size> {
  /// Creates a size tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  SizeTween({ Size begin, Size end }) : super(begin: begin, end: end);

  @override
  Size lerp(double t) => Size.lerp(begin, end, t);
}

/// An interpolation between two rectangles.
///
/// This class specializes the interpolation of Tween<Rect> to be
/// appropriate for rectangles.
class RectTween extends Tween<Rect> {
  /// Creates a rect tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  RectTween({ Rect begin, Rect end }) : super(begin: begin, end: end);

  @override
  Rect lerp(double t) => Rect.lerp(begin, end, t);
}

/// An interpolation between two integers that rounds.
///
/// This class specializes the interpolation of Tween<int> to be
/// appropriate for integers by interpolating between the given begin
/// and end values and then rounding the result to the nearest
/// integer.
///
/// This is the closest approximation to a linear tween that is
/// possible with an integer. Compare to [StepTween].
class IntTween extends Tween<int> {
  /// Creates an int tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  IntTween({ int begin, int end }) : super(begin: begin, end: end);

  // The inherited lerp() function doesn't work with ints because it multiplies
  // the begin and end types by a double, and int * double returns a double.
  @override
  int lerp(double t) => (begin + (end - begin) * t).round();
}

/// An interpolation between two integers that floors.
///
/// This class specializes the interpolation of Tween<int> to be
/// appropriate for integers by interpolating between the given begin
/// and end values and then using [int.floor()] to return the current
/// integer component, dropping the fractional component.
///
/// This results in a value that is never greater than the equivalent
/// value from a linear double interpolation. Compare to [IntTween].
class StepTween extends Tween<int> {
  /// Creates a step tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  StepTween({ int begin, int end }) : super(begin: begin, end: end);

  // The inherited lerp() function doesn't work with ints because it multiplies
  // the begin and end types by a double, and int * double returns a double.
  @override
  int lerp(double t) => (begin + (end - begin) * t).floor();
}

/// Transforms the value of the given animation by the given curve.
///
/// This class differs from [CurvedAnimation] in that [CurvedAnimation] applies
/// a curve to an existing [Animation] object whereas [CurveTween] can be
/// chained with another [Tween] prior to receiving the underlying [Animation].
class CurveTween extends Animatable<double> {
  /// Creates a curve tween.
  ///
  /// The [curve] argument must not be null.
  CurveTween({ @required this.curve }) {
    assert(curve != null);
  }

  /// The curve to use when transforming the value of the animation.
  Curve curve;

  @override
  double evaluate(Animation<double> animation) {
    final double t = animation.value;
    if (t == 0.0 || t == 1.0) {
      assert(curve.transform(t).round() == t);
      return t;
    }
    return curve.transform(t);
  }
}
