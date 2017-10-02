// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Gradient, lerpDouble;

import 'package:flutter/foundation.dart';

import 'alignment.dart';
import 'basic_types.dart';

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
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Gradient();

  /// Creates a [Shader] for this gradient to fill the given rect.
  ///
  /// If the gradient's configuration is text-direction-dependent, for example
  /// it uses [AlignmentDirectional] objects instead of [Alignment]
  /// objects, then the `textDirection` argument must not be null.
  Shader createShader(Rect rect, { TextDirection textDirection });
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
/// least two colors. If there are more than two, a [stops] list must be
/// provided. It must have the same length as [colors], and specifies the
/// position of each color stop between 0.0 and 1.0.
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
  /// Creates a linear graident.
  ///
  /// The [colors] argument must not be null. If [stops] is non-null, it must
  /// have the same length as [colors].
  const LinearGradient({
    this.begin: Alignment.centerLeft,
    this.end: Alignment.centerRight,
    @required this.colors,
    this.stops,
    this.tileMode: TileMode.clamp,
  }) : assert(begin != null),
       assert(end != null),
       assert(colors != null),
       assert(tileMode != null);

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

  /// The colors the gradient should obtain at each of the stops.
  ///
  /// If [stops] is non-null, this list must have the same length as [stops]. If
  /// [colors] has more than two colors, [stops] must be non-null.
  ///
  /// This list must have at least two colors in it (otherwise, it's not a
  /// gradient!).
  final List<Color> colors;

  /// A list of values from 0.0 to 1.0 that denote fractions of the vector from
  /// start to end.
  ///
  /// If non-null, this list must have the same length as [colors]. If
  /// [colors] has more than two colors, [stops] must be non-null.
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
  final List<double> stops;

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
      colors, stops, tileMode,
    );
  }

  /// Returns a new [LinearGradient] with its properties (in particular the
  /// colors) scaled by the given factor.
  ///
  /// If the factor is 1.0 or greater, then the gradient is returned unmodified.
  /// If the factor is 0.0 or less, then the gradient is fully transparent.
  /// Values in between scale the opacity of the colors.
  LinearGradient scale(double factor) {
    return new LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map<Color>((Color color) => Color.lerp(null, color, factor)).toList(),
      stops: stops,
      tileMode: tileMode,
    );
  }

  /// Linearly interpolate between two [LinearGradient]s.
  ///
  /// If either gradient is null, this function linearly interpolates from a
  /// a gradient that matches the other gradient in [begin], [end], [stops] and
  /// [tileMode] and with the same [colors] but transparent (using [scale]).
  ///
  /// If neither gradient is null, they must have the same number of [colors].
  static LinearGradient lerp(LinearGradient a, LinearGradient b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    assert(a.colors.length == b.colors.length, 'Cannot interpolate between two gradients with a different number of colors.');
    assert(a.stops == null || b.stops == null || a.stops.length == b.stops.length);
    final List<Color> interpolatedColors = <Color>[];
    for (int i = 0; i < a.colors.length; i += 1)
      interpolatedColors.add(Color.lerp(a.colors[i], b.colors[i], t));
    List<double> interpolatedStops;
    if (a.stops != null && b.stops != null) {
      for (int i = 0; i < a.stops.length; i += 1)
        interpolatedStops.add(ui.lerpDouble(a.stops[i], b.stops[i], t));
    } else {
      interpolatedStops = a.stops ?? b.stops;
    }
    return new LinearGradient(
      begin: AlignmentGeometry.lerp(a.begin, b.begin, t),
      end: AlignmentGeometry.lerp(a.end, b.end, t),
      colors: interpolatedColors,
      stops: interpolatedStops,
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
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
/// least two colors. If there are more than two, a [stops] list must be
/// provided. It must have the same length as [colors], and specifies the
/// position of each color stop between 0.0 and 1.0.
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
    @required this.colors,
    this.stops,
    this.tileMode: TileMode.clamp,
  }) : assert(center != null),
       assert(radius != null),
       assert(colors != null),
       assert(tileMode != null);

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

  /// The colors the gradient should obtain at each of the stops.
  ///
  /// If [stops] is non-null, this list must have the same length as [stops]. If
  /// [colors] has more than two colors, [stops] must be non-null.
  ///
  /// This list must have at least two colors in it (otherwise, it's not a
  /// gradient!).
  final List<Color> colors;

  /// A list of values from 0.0 to 1.0 that denote concentric rings.
  ///
  /// The rings are centered at [center] and have a radius equal to the value of
  /// the stop times [radius].
  ///
  /// If non-null, this list must have the same length as [colors]. If
  /// [colors] has more than two colors, [stops] must be non-null.
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
  final List<double> stops;

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
      colors, stops, tileMode,
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
