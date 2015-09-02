// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

Color _scaleAlpha(Color a, double factor) {
  return a.withAlpha((a.alpha * factor).round());
}

/// An immutable 32 bit color value in ARGB
class Color {
  /// Construct a color from the lower 32 bits of an int
  ///
  /// Bits 24-31 are the alpha value.
  /// Bits 16-23 are the red value.
  /// Bits 8-15 are the green value.
  /// Bits 0-7 are the blue value.
  const Color(int value) : _value = (value & 0xFFFFFFFF);

  /// Construct a color from the lower 8 bits of four integers.
  const Color.fromARGB(int a, int r, int g, int b) :
    _value = ((((a & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) & 0xFFFFFFFF);

  final int _value;
  /// A 32 bit value representing this color
  ///
  /// Bits 24-31 are the alpha value.
  /// Bits 16-23 are the red value.
  /// Bits 8-15 are the green value.
  /// Bits 0-7 are the blue value.
  int get value => _value;

  /// The alpha channel of this color in an 8 bit value
  int get alpha => (0xff000000 & _value) >> 24;

  /// The red channel of this color in an 8 bit value
  int get red => (0x00ff0000 & _value) >> 16;

  /// The green channel of this color in an 8 bit value
  int get green => (0x0000ff00 & _value) >> 8;

  /// The blue channel of this color in an 8 bit value
  int get blue => (0x000000ff & _value) >> 0;

  bool operator ==(other) => other is Color && _value == other._value;

  /// Returns a new color that matches this color with the alpha channel replaced with a.
  Color withAlpha(int a) {
    return new Color.fromARGB(a, red, green, blue);
  }

  /// Returns a new color that matches this color with the red channel replaced with r.
  Color withRed(int r) {
    return new Color.fromARGB(alpha, r, green, blue);
  }

  /// Returns a new color that matches this color with the green channel replaced with g.
  Color withGreen(int g) {
    return new Color.fromARGB(alpha, red, g, blue);
  }

  /// Returns a new color that matches this color with the blue channel replaced with b.
  Color withBlue(int b) {
    return new Color.fromARGB(alpha, red, green, b);
  }

  /// Linearly interpolate between two colors
  ///
  /// If either color is null, this function linearly interpolates from a
  /// transparent instance of the other color.
  static Color lerp(Color a, Color b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return _scaleAlpha(b, t);
    if (b == null)
      return _scaleAlpha(a, 1.0 - t);
    return new Color.fromARGB(
      lerpDouble(a.alpha, b.alpha, t).toInt(),
      lerpDouble(a.red, b.red, t).toInt(),
      lerpDouble(a.green, b.green, t).toInt(),
      lerpDouble(a.blue, b.blue, t).toInt()
    );
  }

  int get hashCode => _value.hashCode;
  String toString() => "Color(0x${_value.toRadixString(16).padLeft(8, '0')})";
}
