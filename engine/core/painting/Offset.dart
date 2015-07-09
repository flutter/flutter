// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// Holds a 2D floating-point offset.
/// Think of this as a vector from an unspecified point
class Offset extends OffsetBase {
  const Offset(dx, dy) : super(dx, dy);
  Offset.copy(Offset source) : super(source.dx, source.dy);

  double get dx => _dx;
  double get dy => _dy;

  static const Offset zero = const Offset(0.0, 0.0);
  static const Offset infinite = const Offset(double.INFINITY, double.INFINITY);

  Offset scale(double scaleX, double scaleY) => new Offset(dx * scaleX, dy * scaleY);
  Offset translate(double translateX, double translateY) => new Offset(dx + translateX, dy + translateY);

  Offset operator -() => new Offset(-dx, -dy);
  Offset operator -(Offset other) => new Offset(dx - other.dx, dy - other.dy);
  Offset operator +(Offset other) => new Offset(dx + other.dx, dy + other.dy);
  Offset operator *(double operand) => new Offset(dx * operand, dy * operand);
  Offset operator /(double operand) => new Offset(dx / operand, dy / operand);
  Offset operator ~/(double operand) => new Offset((dx ~/ operand).toDouble(), (dy ~/ operand).toDouble());
  Offset operator %(double operand) => new Offset(dx % operand, dy % operand);
  Rect operator &(Size other) => new Rect.fromLTWH(dx, dy, other.width, other.height);

  // does the equivalent of "return new Point(0,0) + this"
  Point toPoint() => new Point(this.dx, this.dy);

  String toString() => "Offset($dx, $dy)";
}
