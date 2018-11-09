// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Size, Rect;

import 'package:flutter/foundation.dart';

import 'animation.dart';
import 'animations.dart';
import 'curves.dart';

// Examples can assume:
// Animation<Offset> _animation;
// AnimationController _controller;

/// An object that can produce a value of type `T` given an [Animation<double>]
/// as input.
///
/// Typically, the values of the input animation are nominally in the range 0.0
/// to 1.0. In principle, however, any value could be provided.
///
/// The main subclass of [Animatable] is [Tween].
abstract class Animatable<T> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Animatable();

  /// Returns the value of the object at point `t`.
  ///
  /// The value of `t` is nominally a fraction in the range 0.0 to 1.0, though
  /// in practice it may extend outside this range.
  ///
  /// See also:
  ///
  ///  * [evaluate], which is a shorthand for applying [transform] to the value
  ///    of an [Animation].
  ///  * [Curve.transform], a similar method for easing curves.
  T transform(double t);

  /// The current value of this object for the given [Animation].
  ///
  /// This function is implemented by deferring to [transform]. Subclasses that
  /// want to provide custom behavior should override [transform], not
  /// [evaluate].
  ///
  /// See also:
  ///
  ///  * [transform], which is similar but takes a `t` value directly instead of
  ///    an [Animation].
  ///  * [animate], which creates an [Animation] out of this object, continually
  ///    applying [evaluate].
  T evaluate(Animation<double> animation) => transform(animation.value);

  /// Returns a new [Animation] that is driven by the given animation but that
  /// takes on values determined by this object.
  ///
  /// Essentially this returns an [Animation] that automatically applies the
  /// [evaluate] method to the parent's value.
  ///
  /// See also:
  ///
  ///  * [AnimationController.drive], which does the same thing from the
  ///    opposite starting point.
  Animation<T> animate(Animation<double> parent) {
    return _AnimatedEvaluation<T>(parent, this);
  }

  /// Returns a new [Animatable] whose value is determined by first evaluating
  /// the given parent and then evaluating this object.
  ///
  /// This allows [Tween]s to be chained before obtaining an [Animation].
  Animatable<T> chain(Animatable<double> parent) {
    return _ChainedEvaluation<T>(parent, this);
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
  T transform(double t) {
    return _evaluatable.transform(_parent.transform(t));
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
/// [animate] method and pass it the [Animation] object that you want to
/// modify.
///
/// You can chain [Tween] objects together using the [chain] method, so that a
/// single [Animation] object is configured by multiple [Tween] objects called
/// in succession. This is different than calling the [animate] method twice,
/// which results in two separate [Animation] objects, each configured with a
/// single [Tween].
///
/// {@tool sample}
///
/// Suppose `_controller` is an [AnimationController], and we want to create an
/// [Animation<Offset>] that is controlled by that controller, and save it in
/// `_animation`. Here are two possible ways of expressing this:
///
/// ```dart
/// _animation = _controller.drive(
///   Tween<Offset>(
///     begin: const Offset(100.0, 50.0),
///     end: const Offset(200.0, 300.0),
///   ),
/// );
/// ```
/// {@end-tool}
/// {@tool sample}
///
/// ```dart
/// _animation = Tween<Offset>(
///   begin: const Offset(100.0, 50.0),
///   end: const Offset(200.0, 300.0),
/// ).animate(_controller);
/// ```
/// {@end-tool}
///
/// In both cases, the `_animation` variable holds an object that, over the
/// lifetime of the `_controller`'s animation, returns a value
/// (`_animation.value`) that depicts a point along the line between the two
/// offsets above. If we used a [MaterialPointArcTween] instead of a
/// [Tween<Offset>] in the code above, the points would follow a pleasing curve
/// instead of a straight line, with no other changes necessary.
///
/// ## Performance optimizations
///
/// Tweens are mutable; specifically, their [begin] and [end] values can be
/// changed at runtime. An object created with [Animation.drive] using a [Tween]
/// will immediately honor changes to that underlying [Tween] (though the
/// listeners will only be triggered if the [Animation] is actively animating).
/// This can be used to change an animation on the fly without having to
/// recreate all the objects in the chain from the [AnimationController] to the
/// final [Tween].
///
/// If a [Tween]'s values are never changed, however, a further optimisation can
/// be applied: the object can be stored in a `static final` variable, so that
/// the exact same instance is used whenever the [Tween] is needed. This is
/// preferable to creating an identical [Tween] afresh each time a [State.build]
/// method is called, for example.
///
/// ## Types with special considerations
///
/// Classes with [lerp] static methods typically have corresponding dedicated
/// [Tween] subclasses that call that method. For example, [ColorTween] uses
/// [Color.lerp] to implement the [ColorTween.lerp] method.
///
/// Types that define `+` and `-` operators to combine values (`T + T → T` and
/// `T - T → T`) and an `*` operator to scale by multiplying with a double (`T *
/// double → T`) can be directly used with `Tween<T>`.
///
/// This does not extend to any type with `+`, `-`, and `*` operators. In
/// particular, [int] does not satisfy this precise contract (`int * double`
/// actually returns [num], not [int]). There are therefore two specific classes
/// that can be used to interpolate integers:
///
///  * [IntTween], which is an approximation of a linear interpolation (using
///    [double.round]).
///  * [StepTween], which uses [double.floor] to ensure that the result is
///    never greater than it would be using if a `Tween<double>`.
///
/// The relevant operators on [Size] also don't fulfill this contract, so
/// [SizeTween] uses [Size.lerp].
///
/// In addition, some of the types that _do_ have suitable `+`, `-`, and `*`
/// operators still have dedicated [Tween] subclasses that perform the
/// interpolation in a more specialized manner. One such class is
/// [MaterialPointArcTween], which is mentioned above. The [AlignmentTween], and
/// [AlignmentGeometryTween], and [FractionalOffsetTween] are another group of
/// [Tween]s that use dedicated `lerp` methods instead of merely relying on the
/// operators (in particular, this allows them to handle null values in a more
/// useful manner).
class Tween<T extends dynamic> extends Animatable<T> {
  /// Creates a tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  Tween({ this.begin, this.end });

  /// The value this variable has at the beginning of the animation.
  ///
  /// See the constructor for details about whether this property may be null
  /// (it varies from subclass to subclass).
  T begin;

  /// The value this variable has at the end of the animation.
  ///
  /// See the constructor for details about whether this property may be null
  /// (it varies from subclass to subclass).
  T end;

  /// Returns the value this variable has at the given animation clock value.
  ///
  /// The default implementation of this method uses the [+], [-], and [*]
  /// operators on `T`. The [begin] and [end] properties must therefore be
  /// non-null by the time this method is called.
  @protected
  T lerp(double t) {
    assert(begin != null);
    assert(end != null);
    return begin + (end - begin) * t;
  }

  /// Returns the interpolated value for the current value of the given animation.
  ///
  /// This method returns `begin` and `end` when the animation values are 0.0 or
  /// 1.0, respectively.
  ///
  /// This function is implemented by deferring to [lerp]. Subclasses that want
  /// to provide custom behavior should override [lerp], not [transform] (nor
  /// [evaluate]).
  ///
  /// See the constructor for details about whether the [begin] and [end]
  /// properties may be null when this is called. It varies from subclass to
  /// subclass.
  @override
  T transform(double t) {
    if (t == 0.0)
      return begin;
    if (t == 1.0)
      return end;
    return lerp(t);
  }

  @override
  String toString() => '$runtimeType($begin \u2192 $end)';
}

/// A [Tween] that evaluates its [parent] in reverse.
class ReverseTween<T> extends Tween<T> {
  /// Construct a [Tween] that evaluates its [parent] in reverse.
  ReverseTween(this.parent) : assert(parent != null), super(begin: parent.end, end: parent.begin);

  /// This tween's value is the same as the parent's value evaluated in reverse.
  ///
  /// This tween's [begin] is the parent's [end] and its [end] is the parent's
  /// [begin]. The [lerp] method returns `parent.lerp(1.0 - t)` and its
  /// [evaluate] method is similar.
  final Tween<T> parent;

  @override
  T lerp(double t) => parent.lerp(1.0 - t);
}

/// An interpolation between two colors.
///
/// This class specializes the interpolation of [Tween<Color>] to use
/// [Color.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
class ColorTween extends Tween<Color> {
  /// Creates a [Color] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as transparent.
  ///
  /// We recommend that you do not pass [Colors.transparent] as [begin]
  /// or [end] if you want the effect of fading in or out of transparent.
  /// Instead prefer null. [Colors.transparent] refers to black transparent and
  /// thus will fade out of or into black which is likely unwanted.
  ColorTween({ Color begin, Color end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  Color lerp(double t) => Color.lerp(begin, end, t);
}

/// An interpolation between two sizes.
///
/// This class specializes the interpolation of [Tween<Size>] to use
/// [Size.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
class SizeTween extends Tween<Size> {
  /// Creates a [Size] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as an empty size.
  SizeTween({ Size begin, Size end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  Size lerp(double t) => Size.lerp(begin, end, t);
}

/// An interpolation between two rectangles.
///
/// This class specializes the interpolation of [Tween<Rect>] to use
/// [Rect.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
class RectTween extends Tween<Rect> {
  /// Creates a [Rect] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as an empty rect at the top left corner.
  RectTween({ Rect begin, Rect end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  Rect lerp(double t) => Rect.lerp(begin, end, t);
}

/// An interpolation between two integers that rounds.
///
/// This class specializes the interpolation of [Tween<int>] to be
/// appropriate for integers by interpolating between the given begin
/// and end values and then rounding the result to the nearest
/// integer.
///
/// This is the closest approximation to a linear tween that is possible with an
/// integer. Compare to [StepTween] and [Tween<double>].
///
/// See [Tween] for a discussion on how to use interpolation objects.
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
/// This class specializes the interpolation of [Tween<int>] to be
/// appropriate for integers by interpolating between the given begin
/// and end values and then using [double.floor] to return the current
/// integer component, dropping the fractional component.
///
/// This results in a value that is never greater than the equivalent
/// value from a linear double interpolation. Compare to [IntTween].
///
/// See [Tween] for a discussion on how to use interpolation objects.
class StepTween extends Tween<int> {
  /// Creates an [int] tween that floors.
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

/// A tween with a constant value.
class ConstantTween<T> extends Tween<T> {
  /// Create a tween whose [begin] and [end] values equal [value].
  ConstantTween(T value) : super(begin: value, end: value);

  /// This tween doesn't interpolate, it always returns [value].
  @override
  T lerp(double t) => begin;

  @override
  String toString() => '$runtimeType(value: begin)';
}

/// Transforms the value of the given animation by the given curve.
///
/// This class differs from [CurvedAnimation] in that [CurvedAnimation] applies
/// a curve to an existing [Animation] object whereas [CurveTween] can be
/// chained with another [Tween] prior to receiving the underlying [Animation].
/// ([CurvedAnimation] also has the additional ability of having different
/// curves when the animation is going forward vs when it is going backward,
/// which can be useful in some scenarios.)
///
/// {@tool sample}
///
/// The following code snippet shows how you can apply a curve to a linear
/// animation produced by an [AnimationController] `controller`:
///
/// ```dart
/// final Animation<double> animation = _controller.drive(
///   CurveTween(curve: Curves.ease),
/// );
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CurvedAnimation], for an alternative way of expressing the sample above.
///  * [AnimationController], for examples of creating and disposing of an
///    [AnimationController].
class CurveTween extends Animatable<double> {
  /// Creates a curve tween.
  ///
  /// The [curve] argument must not be null.
  CurveTween({ @required this.curve })
    : assert(curve != null);

  /// The curve to use when transforming the value of the animation.
  Curve curve;

  @override
  double transform(double t) {
    if (t == 0.0 || t == 1.0) {
      assert(curve.transform(t).round() == t);
      return t;
    }
    return curve.transform(t);
  }

  @override
  String toString() => '$runtimeType(curve: $curve)';
}
