// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// An immutable 2D floating-point x,y coordinate pair.
///
/// A Point represents a specific position in Cartesian space.
///
/// Subtracting a point from another returns the [Offset] that represents the
/// vector between the two points.
class Point {
  /// Creates a point. The first argument sets [x], the horizontal component,
  /// and the second sets [y], the vertical component.
  const Point(this.x, this.y);

  /// The horizontal component of the point.
  final double x;

  /// The vertical component of the point.
  final double y;

  /// The point at the origin, (0, 0).
  static const Point origin = const Point(0.0, 0.0);

  /// Unary negation operator. Returns a point with the coordinates negated.
  Point operator -() => new Point(-x, -y);

  /// Binary subtraction operator. Returns an [Offset] representing the
  /// direction and distance from the other point (the right-hand-side operand)
  /// to this point (the left-hand-side operand).
  Offset operator -(Point other) => new Offset(x - other.x, y - other.y);

  /// Binary addition operator. Returns a point that is this point (the
  /// left-hand-side operand) plus a vector [Offset] (the right-hand-side
  /// operand).
  Point operator +(Offset other) => new Point(x + other.dx, y + other.dy);

  /// Rectangle constructor operator. Combines a point and a [Size] to form a
  /// [Rect] whose top-left coordinate is this point, the left-hand-side
  /// operand, and whose size is the right-hand-side operand.
  ///
  /// ```dart
  ///   Rect myRect = Point.origin & const Size(100.0, 100.0);
  ///   // same as: new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0)
  /// ```
  ///
  /// See also: [Offset.&]
  Rect operator &(Size other) => new Rect.fromLTWH(x, y, other.width, other.height);

  /// Multiplication operator. Returns a point whose coordinates are the
  /// coordinates of the left-hand-side operand (a Point) multiplied by the
  /// scalar right-hand-side operand (a double).
  Point operator *(double operand) => new Point(x * operand, y * operand);

  /// Division operator. Returns a point whose coordinates are the
  /// coordinates of the left-hand-side operand (a point) divided by the
  /// scalar right-hand-side operand (a double).
  Point operator /(double operand) => new Point(x / operand, y / operand);

  /// Integer (truncating) division operator. Returns a point whose
  /// coordinates are the coordinates of the left-hand-side operand (a point)
  /// divided by the scalar right-hand-side operand (a double), rounded towards
  /// zero.
  Point operator ~/(double operand) => new Point((x ~/ operand).toDouble(), (y ~/ operand).toDouble());

  /// Modulo (remainder) operator. Returns a point whose coordinates are the
  /// remainder of the coordinates of the left-hand-side operand (a point)
  /// divided by the scalar right-hand-side operand (a double).
  Point operator %(double operand) => new Point(x % operand, y % operand);

  /// Converts this point to an [Offset] with the same coordinates.
  // does the equivalent of "return this - Point.origin"
  Offset toOffset() => new Offset(x, y);

  /// Linearly interpolate between two points.
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

  @override
  bool operator ==(dynamic other) {
    if (other is! Point)
      return false;
    final Point typedOther = other;
    return x == typedOther.x &&
           y == typedOther.y;
  }

  @override
  int get hashCode => hashValues(x, y);

  @override
  String toString() => "Point(${x?.toStringAsFixed(1)}, ${y?.toStringAsFixed(1)})";
}
