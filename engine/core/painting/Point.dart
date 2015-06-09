// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// Holds 2 floating-point coordinates.
class Point {
  const Point(this.x, this.y);

  final double x;
  final double y;

  static const Point origin = const Point(0.0, 0.0);

  bool operator ==(other) => other is Point && x == other.x && y == other.y;
  Size operator -(Point other) => new Size(x - other.x, y - other.y);
  Point operator +(Size size) => new Point(x + size.width, y + size.height);

  // does the equivalent of "return this - Point(0,0)"
  Size toSize() => new Size(x, y);

  int get hashCode {
    int result = 373;
    result = 37 * result + x.hashCode;
    result = 37 * result + y.hashCode;
    return result;
  }
  String toString() => "Point($x, $y)";
}
