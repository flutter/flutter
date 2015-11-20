// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

class HSVColor {
  const HSVColor.fromAHSV(this.a, this.h, this.s, this.v);

  /// Alpha, from 0.0 to 1.0.
  final double a;

  /// Hue, from 0.0 to 360.0.
  final double h;

  /// Saturation, from 0.0 to 1.0.
  final double s;

  /// Value, from 0.0 to 1.0.
  final double v;

  HSVColor withAlpha(double a) {
    return new HSVColor.fromAHSV(a, h, s, v);
  }

  HSVColor withHue(double h) {
    return new HSVColor.fromAHSV(a, h, s, v);
  }

  HSVColor withSaturation(double s) {
    return new HSVColor.fromAHSV(a, h, s, v);
  }

  HSVColor withValue(double v) {
    return new HSVColor.fromAHSV(a, h, s, v);
  }

  /// Returns this color in RGB.
  Color toColor() {
    final double h = this.h % 360;
    final double c = s * v;
    final double x = c * (1 - (((h / 60.0) % 2) - 1).abs());
    final double m = v - c;

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
      ( a      * 0xFF).round(),
      ((r + m) * 0xFF).round(),
      ((g + m) * 0xFF).round(),
      ((b + m) * 0xFF).round()
    );
  }
}
