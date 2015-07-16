// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// Defines what happens at the edge of the gradient.
enum TileMode {
  /// Edge is clamped to the final color.
  clamp,
  /// Edge is repeated from first color to last.
  repeated,
  /// Edge is mirrored from last color to first.
  mirror
}

/// Extends the generated _Gradient interface via the PrivateDart attribute.
class Gradient extends _Gradient {
  /// Creates a linear gradient from [endPoint[0]] to [endPoint[1]]. If
  /// [colorStops] is provided, [colorStops[i]] is a number from 0 to 1 that
  /// specifies where [color[i]] begins in the gradient.
  // TODO(mpcomplete): Maybe pass a list of (color, colorStop) pairs instead?
  Gradient.linear(List<Point> endPoints,
                  List<Color> colors,
                  [List<double> colorStops = null,
                  TileMode tileMode = TileMode.clamp])
      : super() {
    if (endPoints == null || endPoints.length != 2)
      throw new ArgumentError("Expected exactly 2 [endPoints].");
    validateColorStops(colors, colorStops);
    this._initLinear(endPoints, colors, colorStops, tileMode);
  }

  /// Creates a radial gradient centered at [center] that ends at [radius]
  /// distance from the center. If [colorStops] is provided, [colorStops[i]] is
  /// a number from 0 to 1 that specifies where [color[i]] begins in the
  /// gradient.
  Gradient.radial(Point center,
                  double radius,
                  List<Color> colors,
                  [List<double> colorStops = null,
                  TileMode tileMode = TileMode.clamp])
      : super() {
    validateColorStops(colors, colorStops);
    this._initRadial(center, radius, colors, colorStops, tileMode);
  }

  void validateColorStops(List<Color> colors, List<double> colorStops) {
    if (colorStops != null && colors.length != colorStops.length) {
      throw new ArgumentError(
          "[colors] and [colorStops] parameters must be equal length.");
    }
  }
}
