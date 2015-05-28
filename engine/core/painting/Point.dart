// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// Holds 2 floating-point coordinates.
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  bool operator ==(other) {
    if (!(other is Point)) return false;
    return x == other.x && y == other.y;
  }
  int get hashCode {
    int result = 373;
    result = 37 * result + x.hashCode;
    result = 37 * result + y.hashCode;
    return result;
  }
  String toString() => "Point($x, $y)";
}
