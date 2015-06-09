// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

// Extends the generated _Gradient interface via the PrivateDart attribute.
class Gradient extends _Gradient {
  // TODO(mpcomplete): Maybe pass a list of (color, colorStop) pairs instead?
  Gradient.Linear(List<Point> endPoints,
                  List<Color> colors,
                  List<double> colorStops)
      : super() {
    if (endPoints == null || endPoints.length != 2)
      throw new ArgumentError("Expected exactly 2 [endPoints].");
    validateColorStops(colors, colorStops);
    this._initLinear(endPoints, colors, colorStops);
  }

  Gradient.Radial(Point center,
                  double radius,
                  List<Color> colors,
                  List<double> colorStops)
      : super() {
    validateColorStops(colors, colorStops);
    this._initRadial(center, radius, colors, colorStops);
  }

  void validateColorStops(List<Color> colors, List<double> colorStops) {
    if (colorStops != null && colors.length != colorStops.length) {
      throw new ArgumentError(
          "[colors] and [colorStops] parameters must be equal length.");
    }
  }
}
