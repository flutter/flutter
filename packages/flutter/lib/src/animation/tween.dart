// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Size, Rect, VoidCallback, lerpDouble;

import 'animation.dart';
import 'animations.dart';
import 'curves.dart';

abstract class Animatable<T> {
  const Animatable();

  T evaluate(Animation<double> animation);

  Animation<T> animate(Animation<double> parent) {
    return new _AnimatedEvaluation<T>(parent, this);
  }

  Animatable<T> chain(Animatable<double> parent) {
    return new _ChainedEvaluation<T>(parent, this);
  }
}

class _AnimatedEvaluation<T> extends Animation<T> with ProxyAnimatedMixin {
  _AnimatedEvaluation(this.parent, this._evaluatable);

  /// The animation from which this value is derived.
  final Animation<double> parent;

  final Animatable<T> _evaluatable;

  T get value => _evaluatable.evaluate(parent);
}

class _ChainedEvaluation<T> extends Animatable<T> {
  const _ChainedEvaluation(this._parent, this._evaluatable);

  final Animatable<double> _parent;
  final Animatable<T> _evaluatable;

  T evaluate(Animation<double> animation) {
    double value = _parent.evaluate(animation);
    return _evaluatable.evaluate(new AlwaysStoppedAnimation(value));
  }
}

abstract class TweenBase<T extends dynamic> extends Animatable<T> {
  const TweenBase();

  /// The value this variable has at the beginning of the animation.
  T get begin;

  /// The value this variable has at the end of the animation.
  T get end;

  /// Returns the value this variable has at the given animation clock value.
  T lerp(double t) => begin + (end - begin) * t;

  T evaluate(Animation<double> animation) {
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

/// Immutable variant of Tween for use in const expressions.
class ConstTween<T extends dynamic> extends TweenBase<T> {
  const ConstTween({ this.begin, this.end });

  /// The value this variable has at the beginning of the animation.
  final T begin;

  /// The value this variable has at the end of the animation.
  final T end;
}

class Tween<T extends dynamic> extends TweenBase<T> {
  Tween({ this.begin, this.end });

  /// The value this variable has at the beginning of the animation.
  T begin;

  /// The value this variable has at the end of the animation.
  T end;
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

class CurveTween extends Animatable<double> {
  CurveTween({ this.curve });

  Curve curve;

  double evaluate(Animation<double> animation) {
    double t = animation.value;
    if (t == 0.0 || t == 1.0) {
      assert(curve.transform(t).round() == t);
      return t;
    }
    return curve.transform(t);
  }
}
