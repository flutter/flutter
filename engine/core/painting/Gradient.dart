// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

// Extends the generated _Gradient interface via the PrivateDart attribute.
class Gradient extends _Gradient {
  // TODO(mpcomplete): Support other gradient types.
  // TODO(mpcomplete): Maybe pass a list of (color, colorStop) pairs instead?
  Gradient.Linear(List<Point> endPoints,
                  List<Color> colors,
                  List<double> colorStops)
      : super(0, endPoints, colors, _validate(colorStops, colors));

  // TODO(mpcomplete): Figure out a good way to validate arguments.
  static List<double> _validate(colorStops, colors) {
    if (colorStops != null && colors.length != colorStops.length) {
      throw new ArgumentError(
          "[colors] and [colorStops] parameters must be equal length.");
    }
    return colorStops;
  }
}
