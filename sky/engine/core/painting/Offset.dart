// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// An immutable 2D floating-point offset.
///
/// An Offset represents a vector from an unspecified [Point].
///
/// Adding an offset to a [Point] returns the [Point] that is indicated by the
/// vector from that first point.
class Offset extends OffsetBase {
  /// Creates an offset. The first argument sets [dx], the horizontal component,
  /// and the second sets [dy], the vertical component.
  const Offset(double dx, double dy) : super(dx, dy);

  /// The x component of the offset.
  double get dx => _dx;

  /// The y component of the offset.
  double get dy => _dy;

  /// The magnitude of the offset.
  double get distance => math.sqrt(_dx * _dx + _dy * _dy);

  /// The square of the magnitude of the offset.
  ///
  /// This is cheaper than computing the [distance] itself.
  double get distanceSquared => _dx * _dx + _dy * _dy;

  /// An offset with zero magnitude.
  static const Offset zero = const Offset(0.0, 0.0);

  /// An offset with infinite x and y components.
  static const Offset infinite = const Offset(double.INFINITY, double.INFINITY);

  /// Returns a new offset with the x component scaled by scaleX and the y component scaled by scaleY.
  Offset scale(double scaleX, double scaleY) => new Offset(dx * scaleX, dy * scaleY);

  /// Returns a new offset with translateX added to the x component and translateY added to the y component.
  Offset translate(double translateX, double translateY) => new Offset(dx + translateX, dy + translateY);

  /// Unary negation operator. Returns an offset with the coordinates negated.
  Offset operator -() => new Offset(-dx, -dy);

  /// Binary subtraction operator. Returns an offset whose [dx] value is the
  /// left-hand-side operand's [dx] minus the right-hand-side operand's [dx] and
  /// whose [dy] value is the left-hand-side operand's [dy] minus the
  /// right-hand-side operand's [dy].
  Offset operator -(Offset other) => new Offset(dx - other.dx, dy - other.dy);

  /// Binary addition operator. Returns an offset whose [dx] value is the sum of
  /// the [dx] values of the two operands, and whose [dy] value is the sum of
  /// the [dy] values of the two operands.
  Offset operator +(Offset other) => new Offset(dx + other.dx, dy + other.dy);

  /// Multiplication operator. Returns an offset whose coordinates are the
  /// coordinates of the left-hand-side operand (an Offset) multiplied by the
  /// scalar right-hand-side operand (a double).
  Offset operator *(double operand) => new Offset(dx * operand, dy * operand);

  /// Division operator. Returns an offset whose coordinates are the
  /// coordinates of the left-hand-side operand (an Offset) divided by the
  /// scalar right-hand-side operand (a double).
  Offset operator /(double operand) => new Offset(dx / operand, dy / operand);

  /// Integer (truncating) division operator. Returns an offset whose
  /// coordinates are the coordinates of the left-hand-side operand (an Offset)
  /// divided by the scalar right-hand-side operand (a double), rounded towards
  /// zero.
  Offset operator ~/(double operand) => new Offset((dx ~/ operand).toDouble(), (dy ~/ operand).toDouble());

  /// Modulo (remainder) operator. Returns an offset whose coordinates are the
  /// remainder of dividing the coordinates of the left-hand-side operand (an
  /// Offset) by the scalar right-hand-side operand (a double).
  Offset operator %(double operand) => new Offset(dx % operand, dy % operand);

  /// Rectangle constructor operator. Combines an offset and a [Size] to form a
  /// [Rect] whose top-left coordinate is the point given by adding this offset,
  /// the left-hand-side operand, to the origin, and whose size is the
  /// right-hand-side operand.
  ///
  /// ```dart
  ///   Rect myRect = Offset.zero & const Size(100.0, 100.0);
  ///   // same as: new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0)
  /// ```
  ///
  /// See also: [Point.&]
  Rect operator &(Size other) => new Rect.fromLTWH(dx, dy, other.width, other.height);

  /// Returns the point at (0, 0) plus this offset.
  Point toPoint() => new Point(dx, dy);

  /// Linearly interpolate between two offsets.
  ///
  /// If either offset is null, this function interpolates from [Offset.zero].
  static Offset lerp(Offset a, Offset b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b * t;
    if (b == null)
      return a * (1.0 - t);
    return new Offset(lerpDouble(a.dx, b.dx, t), lerpDouble(a.dy, b.dy, t));
  }

  /// Compares two Offsets for equality.
  @override
  bool operator ==(dynamic other) => other is Offset && super == other;

  @override
  String toString() => "Offset(${dx?.toStringAsFixed(1)}, ${dy?.toStringAsFixed(1)})";
}
