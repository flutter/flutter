// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  /// If either color is null, this function linearly interpolates from a
  /// transparent instance of the other color.
  static HSVColor lerp(HSVColor a, HSVColor b, double t) {
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
      lerpDouble(a.value, b.value, t)
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
  String toString() => "HSVColor($alpha, $hue, $saturation, $value)";
}
