// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, ColorSpace;

bool _isClose(double x, double y) => (x - y).abs() < 0.001;

/// Extension on [Color] that adds a custom equality check.
extension Equivalency on Color {
  /// Returns `true` if the 2 colors are in the same [ColorSpace] and are 
  /// essentially the same color.
  bool isEquivalentTo(Color? color) {
    return color != null &&
        colorSpace == color.colorSpace &&
        _isClose(a, color.a) &&
        _isClose(r, color.r) &&
        _isClose(g, color.g) &&
        _isClose(b, color.b);
  }
}
