// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Holds a 2D floating-point size.
/// Think of this as a vector from Point(0,0) to Point(size.width, size.height)
class Size extends OffsetBase {
  const Size(double width, double height) : super(width, height);
  Size.copy(Size source) : super(source.width, source.height);
  const Size.fromWidth(double width) : super(width, double.INFINITY);
  const Size.fromHeight(double height) : super(double.INFINITY, height);
  const Size.fromRadius(double radius) : super(radius * 2.0, radius * 2.0);

  double get width => _dx;
  double get height => _dy;

  static const Size zero = const Size(0.0, 0.0);
  static const Size infinite = const Size(double.INFINITY, double.INFINITY);

  dynamic operator -(dynamic other) {
    if (other is Size)
      return new Offset(width - other.width, height - other.height);
    if (other is Offset)
      return new Size(width - other.dx, height - other.dy);
    throw new ArgumentError(other);
  }
  Size operator +(Offset other) => new Size(width + other.dx, height + other.dy);
  Size operator *(double operand) => new Size(width * operand, height * operand);
  Size operator /(double operand) => new Size(width / operand, height / operand);
  Size operator ~/(double operand) => new Size((width ~/ operand).toDouble(), (height ~/ operand).toDouble());
  Size operator %(double operand) => new Size(width % operand, height % operand);

  /// Whether this size encloses a non-zero area.
  /// Negative areas are considered empty.
  bool get isEmpty => width <= 0.0 || height <= 0.0;

  /// The lesser of the width and the height.
  double get shortestSide {
    double w = width.abs();
    double h = height.abs();
    return w < h ? w : h;
  }

  // Convenience methods that do the equivalent of calling the similarly named
  // methods on a Rect constructed from the given origin and this size.
  Point center(Point origin) => new Point(origin.x + width / 2.0, origin.y + height / 2.0);
  Point topLeft(Point origin) => origin;
  Point topRight(Point origin) => new Point(origin.x + width, origin.y);
  Point bottomLeft(Point origin) => new Point(origin.x, origin.y + height);
  Point bottomRight(Point origin) => new Point(origin.x + width, origin.y + height);

  /// Linearly interpolate between two sizes
  ///
  /// If either size is null, this function interpolates from [Offset.zero].
  static Size lerp(Size a, Size b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b * t;
    if (b == null)
      return a * (1.0 - t);
    return new Size(lerpDouble(a.width, b.width, t), lerpDouble(a.height, b.height, t));
  }

  /// Compares two Sizes for equality.
  bool operator ==(dynamic other) => other is Size && super == other;

  String toString() => "Size(${width?.toStringAsFixed(1)}, ${height?.toStringAsFixed(1)})";
}
