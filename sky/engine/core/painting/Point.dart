// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Holds 2 floating-point coordinates.
class Point {
  const Point(this.x, this.y);

  final double x;
  final double y;

  static const Point origin = const Point(0.0, 0.0);

  Point operator -() => new Point(-x, -y);
  Offset operator -(Point other) => new Offset(x - other.x, y - other.y);
  Point operator +(Offset other) => new Point(x + other.dx, y + other.dy);
  Rect operator &(Size other) => new Rect.fromLTWH(x, y, other.width, other.height);

  // does the equivalent of "return this - Point.origin"
  Offset toOffset() => new Offset(x, y);

  bool operator ==(dynamic other) {
    if (other is! Point)
      return false;
    final Point typedOther = other;
    return x == typedOther.x &&
           y == typedOther.y;
  }

  int get hashCode {
    int result = 373;
    result = 37 * result + x.hashCode;
    result = 37 * result + y.hashCode;
    return result;
  }

  String toString() => "Point(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})";
}
