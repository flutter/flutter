// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// An immutable 2D floating-point offset.
///
/// An Offset represents a vector from an unspecified point
class Offset extends OffsetBase {
  const Offset(double dx, double dy) : super(dx, dy);

  /// The x component of the offset.
  double get dx => _dx;

  /// The y component of the offset.
  double get dy => _dy;

  /// The magnitude of the offset.
  double get distance => math.sqrt(_dx * _dx + _dy * _dy);

  /// The square of the magnitude of the offset.
  double get distanceSquared => _dx * _dx + _dy * _dy;

  /// An offset with zero magnitude.
  static const Offset zero = const Offset(0.0, 0.0);

  /// An offset with infinite x and y components.
  static const Offset infinite = const Offset(double.INFINITY, double.INFINITY);

  /// Returns a new offset with the x component scaled by scaleX and the y component scaled by scaleY.
  Offset scale(double scaleX, double scaleY) => new Offset(dx * scaleX, dy * scaleY);

  /// Returns a new offset with translateX added to the x component and translateY added to the y component.
  Offset translate(double translateX, double translateY) => new Offset(dx + translateX, dy + translateY);

  Offset operator -() => new Offset(-dx, -dy);
  Offset operator -(Offset other) => new Offset(dx - other.dx, dy - other.dy);
  Offset operator +(Offset other) => new Offset(dx + other.dx, dy + other.dy);
  Offset operator *(double operand) => new Offset(dx * operand, dy * operand);
  Offset operator /(double operand) => new Offset(dx / operand, dy / operand);
  Offset operator ~/(double operand) => new Offset((dx ~/ operand).toDouble(), (dy ~/ operand).toDouble());
  Offset operator %(double operand) => new Offset(dx % operand, dy % operand);

  /// Returns a rect of the given size that starts at (0, 0) plus this offset.
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
  bool operator ==(dynamic other) => other is Offset && super == other;

  String toString() => "Offset(${dx?.toStringAsFixed(1)}, ${dy?.toStringAsFixed(1)})";
}
