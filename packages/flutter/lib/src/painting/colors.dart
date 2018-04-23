// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show Color, lerpDouble, hashValues;

import 'package:flutter/foundation.dart';

/// A color represented using [alpha], [hue], [saturation], and [value].
///
/// An [HSVColor] is represented in a parameter space that's motivated by human
/// perception. The representation is useful for some color computations (e.g.,
/// rotating the hue through the colors of the rainbow).
@immutable
class HSVColor {
  /// Creates a color.
  ///
  /// All the arguments must not be null and be in their respective ranges. See
  /// the fields for each parameter for a description of their ranges.
  const HSVColor.fromAHSV(this.alpha, this.hue, this.saturation, this.value)
      : assert(alpha != null),
        assert(hue != null),
        assert(saturation != null),
        assert(value != null);

  /// Creates an [HSVColor] from an RGB [Color].
  ///
  /// This constructor does not necessarily round-trip with [toColor] because
  /// of floating point imprecision.
  factory HSVColor.fromColor(Color color) {
    final double alpha = color.alpha / 0xFF;
    final double red = color.red / 0xFF;
    final double green = color.green / 0xFF;
    final double blue = color.blue / 0xFF;

    final double max = math.max(red, math.max(green, blue));
    final double min = math.min(red, math.min(green, blue));
    final double delta = max - min;

    double hue = 0.0;

    if (max == 0.0) {
      hue = 0.0;
    } else if (max == red) {
      hue = 60.0 * (((green - blue) / delta) % 6);
    } else if (max == green) {
      hue = 60.0 * (((blue - red) / delta) + 2);
    } else if (max == blue) {
      hue = 60.0 * (((red - green) / delta) + 4);
    }
    
    /// fix hue to 0.0 when red == green == blue.
    hue = hue.isNaN ? 0.0 : hue;
    final double saturation = max == 0.0 ? 0.0 : delta / max;

    return new HSVColor.fromAHSV(alpha, hue, saturation, max);
  }

  /// Alpha, from 0.0 to 1.0.
  final double alpha;

  /// Hue, from 0.0 to 360.0.
  final double hue;

  /// Saturation, from 0.0 to 1.0.
  final double saturation;

  /// Value, from 0.0 to 1.0.
  final double value;

  /// Returns a copy of this color with the alpha parameter replaced with the given value.
  HSVColor withAlpha(double alpha) {
    return new HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  /// Returns a copy of this color with the hue parameter replaced with the given value.
  HSVColor withHue(double hue) {
    return new HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  /// Returns a copy of this color with the saturation parameter replaced with the given value.
  HSVColor withSaturation(double saturation) {
    return new HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  /// Returns a copy of this color with the value parameter replaced with the given value.
  HSVColor withValue(double value) {
    return new HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  /// Returns this color in RGB.
  Color toColor() {
    final double h = hue % 360;
    final double c = saturation * value;
    final double x = c * (1 - (((h / 60.0) % 2) - 1).abs());
    final double m = value - c;

    double r;
    double g;
    double b;
    if (h < 60.0) {
      r = c;
      g = x;
      b = 0.0;
    } else if (h < 120.0) {
      r = x;
      g = c;
      b = 0.0;
    } else if (h < 180.0) {
      r = 0.0;
      g = c;
      b = x;
    } else if (h < 240.0) {
      r = 0.0;
      g = x;
      b = c;
    } else if (h < 300.0) {
      r = x;
      g = 0.0;
      b = c;
    } else {
      r = c;
      g = 0.0;
      b = x;
    }
    return new Color.fromARGB(
      (alpha   * 0xFF).round(),
      ((r + m) * 0xFF).round(),
      ((g + m) * 0xFF).round(),
      ((b + m) * 0xFF).round()
    );
  }

  HSVColor _scaleAlpha(double factor) {
    return withAlpha(alpha * factor);
  }

  /// Linearly interpolate between two HSVColors.
  ///
  /// The colors are interpolated by interpolating the [alpha], [hue],
  /// [saturation], and [value] channels separately, which usually leads to a
  /// more pleasing effect than [Color.lerp] (which interpolates the red, green,
  /// and blue channels separately).
  ///
  /// If either color is null, this function linearly interpolates from a
  /// transparent instance of the other color. This is usually preferable to
  /// interpolating from [Colors.transparent] (`const Color(0x00000000)`) since
  /// that will interpolate from a transparent red and cycle through the hues to
  /// match the target color, regardless of what that color's hue is.
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
  static HSVColor lerp(HSVColor a, HSVColor b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    if (a == null)
      return b._scaleAlpha(t);
    if (b == null)
      return a._scaleAlpha(1.0 - t);
    return new HSVColor.fromAHSV(
      lerpDouble(a.alpha, b.alpha, t),
      lerpDouble(a.hue, b.hue, t),
      lerpDouble(a.saturation, b.saturation, t),
      lerpDouble(a.value, b.value, t),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! HSVColor)
      return false;
    final HSVColor typedOther = other;
    return typedOther.alpha == alpha
        && typedOther.hue == hue
        && typedOther.saturation == saturation
        && typedOther.value == value;
  }

  @override
  int get hashCode => hashValues(alpha, hue, saturation, value);

  @override
  String toString() => 'HSVColor($alpha, $hue, $saturation, $value)';
}

/// A color that has a small table of related colors called a "swatch".
///
/// The table is indexed by values of type `T`.
///
/// See also:
///
///  * [MaterialColor] and [MaterialAccentColor], which define material design
///    primary and accent color swatches.
///  * [material.Colors], which defines all of the standard material design colors.
class ColorSwatch<T> extends Color {
  /// Creates a color that has a small table of related colors called a "swatch".
  ///
  /// The `primary` argument should be the 32 bit ARGB value of one of the
  /// values in the swatch, as would be passed to the [new Color] constructor
  /// for that same color, and as is exposed by [value]. (This is distinct from
  /// the specific index of the color in the swatch.)
  const ColorSwatch(int primary, this._swatch) : super(primary);

  @protected
  final Map<T, Color> _swatch;

  /// Returns an element of the swatch table.
  Color operator [](T index) => _swatch[index];

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final ColorSwatch<T> typedOther = other;
    return super == other && _swatch == typedOther._swatch;
  }

  @override
  int get hashCode => hashValues(runtimeType, value, _swatch);

  @override
  String toString() => '$runtimeType(primary value: ${super.toString()})';
}
