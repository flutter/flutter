// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show Gradient, lerpDouble;

import 'package:flutter/foundation.dart';

import 'alignment.dart';
import 'basic_types.dart';

class _ColorsAndStops {
  _ColorsAndStops(this.colors, this.stops);
  final List<Color> colors;
  final List<double> stops;
}

_ColorsAndStops _interpolateColorsAndStops(List<Color> aColors, List<double> aStops, List<Color> bColors, List<double> bStops, double t) {
  assert(aColors.length == bColors.length, 'Cannot interpolate between two gradients with a different number of colors.'); // TODO(ianh): remove limitation
  assert((aStops == null && aColors.length == 2) || (aStops != null && aStops.length == aColors.length));
  assert((bStops == null && bColors.length == 2) || (bStops != null && bStops.length == bColors.length));
  final List<Color> interpolatedColors = <Color>[];
  for (int i = 0; i < aColors.length; i += 1)
    interpolatedColors.add(Color.lerp(aColors[i], bColors[i], t));
  List<double> interpolatedStops;
  if (aStops != null || bStops != null) {
    aStops ??= const <double>[0.0, 1.0];
    bStops ??= const <double>[0.0, 1.0];
    assert(aStops.length == bStops.length);
    interpolatedStops = <double>[];
    for (int i = 0; i < aStops.length; i += 1)
      interpolatedStops.add(ui.lerpDouble(aStops[i], bStops[i], t).clamp(0.0, 1.0));
  }
  return new _ColorsAndStops(interpolatedColors, interpolatedStops);
}

/// A 2D gradient.
///
/// This is an interface that allows [LinearGradient] and [RadialGradient]
/// classes to be used interchangeably in [BoxDecoration]s.
///
/// See also:
///
///  * [dart:ui.Gradient], the class in the [dart:ui] library that is
///    encapsulated by this class and its subclasses.
@immutable
abstract class Gradient {
  /// Initialize the gradient's colors and stops.
  ///
  /// The [colors] argument must not be null, and must have at least two colors
  /// (the length is not verified until the [createShader] method is called).
  ///
  /// If specified, the [stops] argument must have the same number of entries as
  /// [colors] (this is also not verified until the [createShader] method is
  /// called).
  const Gradient({
    @required this.colors,
    this.stops,
  }) : assert(colors != null);

  /// The colors the gradient should obtain at each of the stops.
  ///
  /// If [stops] is non-null, this list must have the same length as [stops].
  ///
  /// This list must have at least two colors in it (otherwise, it's not a
  /// gradient!).
  final List<Color> colors;

  /// A list of values from 0.0 to 1.0 that denote fractions along the gradient.
  ///
  /// If non-null, this list must have the same length as [colors].
  ///
  /// If the first value is not 0.0, then a stop with position 0.0 and a color
  /// equal to the first color in [colors] is implied.
  ///
  /// If the last value is not 1.0, then a stop with position 1.0 and a color
  /// equal to the last color in [colors] is implied.
  ///
  /// The values in the [stops] list must be in ascending order. If a value in
  /// the [stops] list is less than an earlier value in the list, then its value
  /// is assumed to equal the previous value.
  ///
  /// If stops is null, then a set of uniformly distributed stops is implied,
  /// with the first stop at 0.0 and the last stop at 1.0.
  final List<double> stops;

  List<double> _impliedStops() {
    if (stops != null)
      return stops;
    if (colors.length == 2)
      return null;
    assert(colors.length >= 2, 'colors list must have at least two colors');
    final double separation = 1.0 / (colors.length - 1);
    return new List<double>.generate(
      colors.length,
      (int index) => index * separation,
      growable: false,
    );
  }

  /// Creates a [Shader] for this gradient to fill the given rect.
  ///
  /// If the gradient's configuration is text-direction-dependent, for example
  /// it uses [AlignmentDirectional] objects instead of [Alignment]
  /// objects, then the `textDirection` argument must not be null.
  Shader createShader(Rect rect, { TextDirection textDirection });

  /// Returns a new gradient with its properties scaled by the given factor.
  ///
  /// A factor of 0.0 (or less) should result in a variant of the gradient that
  /// is invisible; any two factors epsilon apart should be unnoticeably
  /// different from each other at first glance. From this it follows that
  /// scaling a gradient with values from 1.0 to 0.0 over time should cause the
  /// gradient to smoothly disappear.
  ///
  /// Typically this is the same as interpolating from null (with [lerp]).
  Gradient scale(double factor);

  /// Linearly interpolates from another [Gradient] to `this`.
  ///
  /// When implementing this method in subclasses, return null if this class
  /// cannot interpolate from `a`. In that case, [lerp] will try `a`'s [lerpTo]
  /// method instead.
  ///
  /// If `a` is null, this must not return null. The base class implements this
  /// by deferring to [scale].
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `this` (or something equivalent to `this`), and values in
  /// between meaning that the interpolation is at the relevant point on the
  /// timeline between `a` and `this`. The interpolation can be extrapolated
  /// beyond 0.0 and 1.0, so negative values and values greater than 1.0 are
  /// valid (and can easily be generated by curves such as
  /// [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  ///
  /// Instead of calling this directly, use [Gradient.lerp].
  @protected
  Gradient lerpFrom(Gradient a, double t) {
    if (a == null)
      return scale(t);
    return null;
  }

  /// Linearly interpolates from `this` to another [Gradient].
  ///
  /// This is called if `b`'s [lerpTo] did not know how to handle this class.
  ///
  /// When implementing this method in subclasses, return null if this class
  /// cannot interpolate from `b`. In that case, [lerp] will apply a default
  /// behavior instead.
  ///
  /// If `b` is null, this must not return null. The base class implements this
  /// by deferring to [scale].
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `this` (or something
  /// equivalent to `this`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `this` and `b`. The interpolation can be extrapolated beyond 0.0
  /// and 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  ///
  /// Instead of calling this directly, use [Gradient.lerp].
  @protected
  Gradient lerpTo(Gradient b, double t) {
    if (b == null)
      return scale(1.0 - t);
    return null;
  }

  /// Linearly interpolates between two [Gradient]s.
  ///
  /// This defers to `b`'s [lerpTo] function if `b` is not null. If `b` is
  /// null or if its [lerpTo] returns null, it uses `a`'s [lerpFrom]
  /// function instead. If both return null, it returns `a` before `t == 0.5`
  /// and `b` after `t == 0.5`.
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  static Gradient lerp(Gradient a, Gradient b, double t) {
    assert(t != null);
    Gradient result;
    if (b != null)
      result = b.lerpFrom(a, t); // if a is null, this must return non-null
    if (result == null && a != null)
      result = a.lerpTo(b, t); // if b is null, this must return non-null
    if (result != null)
      return result;
    if (a == null && b == null)
      return null;
    assert(a != null && b != null);
    return t < 0.5 ? a.scale(1.0 - (t * 2.0)) : b.scale((t - 0.5) * 2.0);
  }
}

/// A 2D linear gradient.
///
/// This class is used by [BoxDecoration] to represent gradients. This abstracts
/// out the arguments to the [new ui.Gradient.linear] constructor from the
/// `dart:ui` library.
///
/// A gradient has two anchor points, [begin] and [end]. The [begin] point
/// corresponds to 0.0, and the [end] point corresponds to 1.0. These points are
/// expressed in fractions, so that the same gradient can be reused with varying
/// sized boxes without changing the parameters. (This contrasts with [new
/// ui.Gradient.linear], whose arguments are expressed in logical pixels.)
///
/// The [colors] are described by a list of [Color] objects. There must be at
/// least two colors. The [stops] list, if specified, must have the same length
/// as [colors]. It specifies fractions of the vector from start to end, between
/// 0.0 and 1.0, for each color. If it is null, a uniform distribution is
/// assumed.
///
/// The region of the canvas before [begin] and after [end] is colored according
/// to [tileMode].
///
/// Typically this class is used with [BoxDecoration], which does the painting.
/// To use a [LinearGradient] to paint on a canvas directly, see [createShader].
///
/// ## Sample code
///
/// This sample draws a picture that looks like vertical window shades by having
/// a [Container] display a [BoxDecoration] with a [LinearGradient].
///
/// ```dart
/// new Container(
///   decoration: new BoxDecoration(
///     gradient: new LinearGradient(
///       begin: Alignment.topLeft,
///       end: new Alignment(0.8, 0.0), // 10% of the width, so there are ten blinds.
///       colors: [const Color(0xFFFFFFEE), const Color(0xFF999999)], // whitish to gray
///       tileMode: TileMode.repeated, // repeats the gradient over the canvas
///     ),
///   ),
/// )
/// ```
///
/// See also:
///
///  * [RadialGradient], which displays a gradient in concentric circles, and
///    has an example which shows a different way to use [Gradient] objects.
///  * [BoxDecoration], which can take a [LinearGradient] in its
///    [BoxDecoration.gradient] property.
class LinearGradient extends Gradient {
  /// Creates a linear gradient.
  ///
  /// The [colors] argument must not be null. If [stops] is non-null, it must
  /// have the same length as [colors].
  const LinearGradient({
    this.begin: Alignment.centerLeft,
    this.end: Alignment.centerRight,
    @required List<Color> colors,
    List<double> stops,
    this.tileMode: TileMode.clamp,
  }) : assert(begin != null),
       assert(end != null),
       assert(tileMode != null),
       super(colors: colors, stops: stops);

  /// The offset at which stop 0.0 of the gradient is placed.
  ///
  /// If this is a [Alignment], then it is expressed as a vector from
  /// coordinate (0.0, 0.0), in a coordinate space that maps the center of the
  /// paint box at (0.0, 0.0) and the bottom right at (1.0, 1.0).
  ///
  /// For example, a begin offset of (-1.0, 0.0) is half way down the
  /// left side of the box.
  ///
  /// It can also be a [AlignmentDirectional], where the start is the
  /// left in left-to-right contexts and the right in right-to-left contexts. If
  /// a text-direction-dependent value is provided here, then the [createShader]
  /// method will need to be given a [TextDirection].
  final AlignmentGeometry begin;

  /// The offset at which stop 1.0 of the gradient is placed.
  ///
  /// If this is a [Alignment], then it is expressed as a vector from
  /// coordinate (0.0, 0.0), in a coordinate space that maps the center of the
  /// paint box at (0.0, 0.0) and the bottom right at (1.0, 1.0).
  ///
  /// For example, a begin offset of (1.0, 0.0) is half way down the
  /// right side of the box.
  ///
  /// It can also be a [AlignmentDirectional], where the start is the left in
  /// left-to-right contexts and the right in right-to-left contexts. If a
  /// text-direction-dependent value is provided here, then the [createShader]
  /// method will need to be given a [TextDirection].
  final AlignmentGeometry end;

  /// How this gradient should tile the plane beyond in the region before
  /// [begin] and after [end].
  ///
  /// For details, see [TileMode].
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/dart-ui/tile_mode_clamp_linear.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/dart-ui/tile_mode_mirror_linear.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/dart-ui/tile_mode_repeated_linear.png)
  final TileMode tileMode;

  @override
  Shader createShader(Rect rect, { TextDirection textDirection }) {
    return new ui.Gradient.linear(
      begin.resolve(textDirection).withinRect(rect),
      end.resolve(textDirection).withinRect(rect),
      colors, _impliedStops(), tileMode,
    );
  }

  /// Returns a new [LinearGradient] with its properties (in particular the
  /// colors) scaled by the given factor.
  ///
  /// If the factor is 0.0 or less, then the gradient is fully transparent.
  @override
  LinearGradient scale(double factor) {
    return new LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map<Color>((Color color) => Color.lerp(null, color, factor)).toList(),
      stops: stops,
      tileMode: tileMode,
    );
  }

  @override
  Gradient lerpFrom(Gradient a, double t) {
    if (a == null || (a is LinearGradient && a.colors.length == colors.length)) // TODO(ianh): remove limitation
      return LinearGradient.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  Gradient lerpTo(Gradient b, double t) {
    if (b == null || (b is LinearGradient && b.colors.length == colors.length)) // TODO(ianh): remove limitation
      return LinearGradient.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  /// Linearly interpolate between two [LinearGradient]s.
  ///
  /// If either gradient is null, this function linearly interpolates from a
  /// a gradient that matches the other gradient in [begin], [end], [stops] and
  /// [tileMode] and with the same [colors] but transparent (using [scale]).
  ///
  /// If neither gradient is null, they must have the same number of [colors].
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  static LinearGradient lerp(LinearGradient a, LinearGradient b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    final _ColorsAndStops interpolated = _interpolateColorsAndStops(a.colors, a.stops, b.colors, b.stops, t);
    return new LinearGradient(
      begin: AlignmentGeometry.lerp(a.begin, b.begin, t),
      end: AlignmentGeometry.lerp(a.end, b.end, t),
      colors: interpolated.colors,
      stops: interpolated.stops,
      tileMode: t < 0.5 ? a.tileMode : b.tileMode, // TODO(ianh): interpolate tile mode
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final LinearGradient typedOther = other;
    if (begin != typedOther.begin ||
        end != typedOther.end ||
        tileMode != typedOther.tileMode ||
        colors?.length != typedOther.colors?.length ||
        stops?.length != typedOther.stops?.length)
      return false;
    if (colors != null) {
      assert(typedOther.colors != null);
      assert(colors.length == typedOther.colors.length);
      for (int i = 0; i < colors.length; i += 1) {
        if (colors[i] != typedOther.colors[i])
          return false;
      }
    }
    if (stops != null) {
      assert(typedOther.stops != null);
      assert(stops.length == typedOther.stops.length);
      for (int i = 0; i < stops.length; i += 1) {
        if (stops[i] != typedOther.stops[i])
          return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => hashValues(begin, end, tileMode, hashList(colors), hashList(stops));

  @override
  String toString() {
    return '$runtimeType($begin, $end, $colors, $stops, $tileMode)';
  }
}

/// A 2D radial gradient.
///
/// This class is used by [BoxDecoration] to represent gradients. This abstracts
/// out the arguments to the [new ui.Gradient.radial] constructor from the
/// `dart:ui` library.
///
/// A gradient has a [center] and a [radius]. The [center] point corresponds to
/// 0.0, and the ring at [radius] from the center corresponds to 1.0. These
/// lengths are expressed in fractions, so that the same gradient can be reused
/// with varying sized boxes without changing the parameters. (This contrasts
/// with [new ui.Gradient.radial], whose arguments are expressed in logical
/// pixels.)
///
/// The [colors] are described by a list of [Color] objects. There must be at
/// least two colors. The [stops] list, if specified, must have the same length
/// as [colors]. It specifies fractions of the radius between 0.0 and 1.0,
/// giving concentric rings for each color stop. If it is null, a uniform
/// distribution is assumed.
///
/// The region of the canvas beyond [radius] from the [center] is colored
/// according to [tileMode].
///
/// Typically this class is used with [BoxDecoration], which does the painting.
/// To use a [RadialGradient] to paint on a canvas directly, see [createShader].
///
/// ## Sample code
///
/// This function draws a gradient that looks like a sun in a blue sky.
///
/// ```dart
/// void paintSky(Canvas canvas, Rect rect) {
///   var gradient = new RadialGradient(
///     center: const Alignment(0.7, -0.6), // near the top right
///     radius: 0.2,
///     colors: [
///       const Color(0xFFFFFF00), // yellow sun
///       const Color(0xFF0099FF), // blue sky
///     ],
///     stops: [0.4, 1.0],
///   );
///   // rect is the area we are painting over
///   var paint = new Paint()
///     ..shader = gradient.createShader(rect);
///   canvas.drawRect(rect, paint);
/// }
/// ```
///
/// See also:
///
///  * [LinearGradient], which displays a gradient in parallel lines, and has an
///    example which shows a different way to use [Gradient] objects.
///  * [BoxDecoration], which can take a [RadialGradient] in its
///    [BoxDecoration.gradient] property.
///  * [CustomPainter], which shows how to use the above sample code in a custom
///    painter.
class RadialGradient extends Gradient {
  /// Creates a radial gradient.
  ///
  /// The [colors] argument must not be null. If [stops] is non-null, it must
  /// have the same length as [colors].
  const RadialGradient({
    this.center: Alignment.center,
    this.radius: 0.5,
    @required List<Color> colors,
    List<double> stops,
    this.tileMode: TileMode.clamp,
  }) : assert(center != null),
       assert(radius != null),
       assert(tileMode != null),
       super(colors: colors, stops: stops);

  /// The center of the gradient, as an offset into the (-1.0, -1.0) x (1.0, 1.0)
  /// square describing the gradient which will be mapped onto the paint box.
  ///
  /// For example, an alignment of (0.0, 0.0) will place the radial
  /// gradient in the center of the box.
  ///
  /// If this is a [Alignment], then it is expressed as a vector from
  /// coordinate (0.0, 0.0), in a coordinate space that maps the center of the
  /// paint box at (0.0, 0.0) and the bottom right at (1.0, 1.0).
  ///
  /// It can also be a [AlignmentDirectional], where the start is the left in
  /// left-to-right contexts and the right in right-to-left contexts. If a
  /// text-direction-dependent value is provided here, then the [createShader]
  /// method will need to be given a [TextDirection].
  final AlignmentGeometry center;

  /// The radius of the gradient, as a fraction of the shortest side
  /// of the paint box.
  ///
  /// For example, if a radial gradient is painted on a box that is
  /// 100.0 pixels wide and 200.0 pixels tall, then a radius of 1.0
  /// will place the 1.0 stop at 100.0 pixels from the [center].
  final double radius;

  /// How this gradient should tile the plane beyond the outer ring at [radius]
  /// pixels from the [center].
  ///
  /// For details, see [TileMode].
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/dart-ui/tile_mode_clamp_radial.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/dart-ui/tile_mode_mirror_radial.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/dart-ui/tile_mode_repeated_radial.png)
  final TileMode tileMode;

  @override
  Shader createShader(Rect rect, { TextDirection textDirection }) {
    return new ui.Gradient.radial(
      center.resolve(textDirection).withinRect(rect),
      radius * rect.shortestSide,
      colors, _impliedStops(), tileMode,
    );
  }

  /// Returns a new [RadialGradient] with its colors scaled by the given factor.
  ///
  /// If the factor is 0.0 or less, then the gradient is fully transparent.
  @override
  RadialGradient scale(double factor) {
    return new RadialGradient(
      center: center,
      radius: radius,
      colors: colors.map<Color>((Color color) => Color.lerp(null, color, factor)).toList(),
      stops: stops,
      tileMode: tileMode,
    );
  }

  @override
  Gradient lerpFrom(Gradient a, double t) {
    if (a == null || (a is RadialGradient && a.colors.length == colors.length)) // TODO(ianh): remove limitation
      return RadialGradient.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  Gradient lerpTo(Gradient b, double t) {
    if (b == null || (b is RadialGradient && b.colors.length == colors.length)) // TODO(ianh): remove limitation
      return RadialGradient.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  /// Linearly interpolate between two [RadialGradient]s.
  ///
  /// If either gradient is null, this function linearly interpolates from a
  /// a gradient that matches the other gradient in [center], [radius], [stops] and
  /// [tileMode] and with the same [colors] but transparent (using [scale]).
  ///
  /// If neither gradient is null, they must have the same number of [colors].
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  static RadialGradient lerp(RadialGradient a, RadialGradient b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    final _ColorsAndStops interpolated = _interpolateColorsAndStops(a.colors, a.stops, b.colors, b.stops, t);
    return new RadialGradient(
      center: AlignmentGeometry.lerp(a.center, b.center, t),
      radius: math.max(0.0, ui.lerpDouble(a.radius, b.radius, t)),
      colors: interpolated.colors,
      stops: interpolated.stops,
      tileMode: t < 0.5 ? a.tileMode : b.tileMode, // TODO(ianh): interpolate tile mode
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final RadialGradient typedOther = other;
    if (center != typedOther.center ||
        radius != typedOther.radius ||
        tileMode != typedOther.tileMode ||
        colors?.length != typedOther.colors?.length ||
        stops?.length != typedOther.stops?.length)
      return false;
    if (colors != null) {
      assert(typedOther.colors != null);
      assert(colors.length == typedOther.colors.length);
      for (int i = 0; i < colors.length; i += 1) {
        if (colors[i] != typedOther.colors[i])
          return false;
      }
    }
    if (stops != null) {
      assert(typedOther.stops != null);
      assert(stops.length == typedOther.stops.length);
      for (int i = 0; i < stops.length; i += 1) {
        if (stops[i] != typedOther.stops[i])
          return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => hashValues(center, radius, tileMode, hashList(colors), hashList(stops));

  @override
  String toString() {
    return '$runtimeType($center, $radius, $colors, $stops, $tileMode)';
  }
}
