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

  Point operator *(double operand) => new Point(x * operand, y * operand);
  Point operator /(double operand) => new Point(x / operand, y / operand);
  Point operator ~/(double operand) => new Point((x ~/ operand).toDouble(), (y ~/ operand).toDouble());
  Point operator %(double operand) => new Point(x % operand, y % operand);

  // does the equivalent of "return this - Point.origin"
  Offset toOffset() => new Offset(x, y);

  /// Linearly interpolate between two points
  ///
  /// If either point is null, this function interpolates from [Point.origin].
  static Point lerp(Point a, Point b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b * t;
    if (b == null)
      return a * (1.0 - t);
    return new Point(lerpDouble(a.x, b.x, t), lerpDouble(a.y, b.y, t));
  }

  bool operator ==(dynamic other) {
    if (other is! Point)
      return false;
    final Point typedOther = other;
    return x == typedOther.x &&
           y == typedOther.y;
  }

  int get hashCode => hashValues(x, y);

  String toString() => "Point(${x?.toStringAsFixed(1)}, ${y?.toStringAsFixed(1)})";
}
