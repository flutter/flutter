// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Holds a 2D floating-point size.
///
/// You can think of this as a vector from Point(0,0) to Point(size.width,
/// size.height).
class Size extends OffsetBase {
  /// Creates a Size with the given width and height.
  const Size(double width, double height) : super(width, height);

  /// Creates an instance of Size that has the same values as another.
  // Used by the rendering library's _DebugSize hack.
  Size.copy(Size source) : super(source.width, source.height);

  /// Creates a square Size whose width and height are the given dimension.
  const Size.square(double dimension) : super(dimension, dimension);

  /// Creates a Size with the given width and an infinite height.
  const Size.fromWidth(double width) : super(width, double.INFINITY);

  /// Creates a Size with the given height and an infinite width.
  const Size.fromHeight(double height) : super(double.INFINITY, height);

  /// Creates a square Size whose width and height are twice the given dimension.
  ///
  /// This is a square that contains a circle with the given radius.
  const Size.fromRadius(double radius) : super(radius * 2.0, radius * 2.0);

  /// The horizontal extent of this size.
  double get width => _dx;

  /// The vertical extent of this size.
  double get height => _dy;

  /// An empty size, one with a zero width and a zero height.
  static const Size zero = const Size(0.0, 0.0);

  /// A size whose width and height are infinite.
  ///
  /// See also [isInfinite], which checks whether either dimension is infinite.
  static const Size infinite = const Size(double.INFINITY, double.INFINITY);

  /// Binary subtraction operator for Size.
  ///
  /// Subtracting a Size from a Size returns the [Offset] that describes how
  /// much bigger the left-hand-side operand is than the right-hand-side
  /// operand. Adding that resulting Offset to the Size that was the
  /// right-hand-side operand would return a Size equal to the Size that was the
  /// left-hand-side operand. (i.e. if `sizeA - sizeB -> offsetA`, then `offsetA
  /// + sizeB -> sizeA`)
  ///
  /// Subtracting an [Offset] from a Size returns the Size that is smaller than
  /// the Size operand by the difference given by the Offset operand. In other
  /// words, the returned Size has a [width] consisting of the [width] of the
  /// left-hand-side operand minus the [Offset.dx] dimension of the
  /// right-hand-side operand, and a [height] consisting of the [height] of the
  /// left-hand-side operand minus the [Offset.dy] dimension of the
  /// right-hand-side operand.
  dynamic operator -(OffsetBase other) {
    if (other is Size)
      return new Offset(width - other.width, height - other.height);
    if (other is Offset)
      return new Size(width - other.dx, height - other.dy);
    throw new ArgumentError(other);
  }

  /// Binary addition operator for adding an Offset to a Size. Returns a Size
  /// whose [width] is the sum of the [width] of the left-hand-side operand, a
  /// Size, and the [Offset.dx] dimension of the right-hand-side operand, an
  /// [Offset], and whose [height] is the sum of the [height] of the
  /// left-hand-side operand and the [Offset.dy] dimension of the
  /// right-hand-side operand.
  Size operator +(Offset other) => new Size(width + other.dx, height + other.dy);

  /// Multiplication operator. Returns a size whose dimensions are the
  /// dimensions of the left-hand-side operand (a Size) multiplied by the
  /// scalar right-hand-side operand (a double).
  Size operator *(double operand) => new Size(width * operand, height * operand);

  /// Division operator. Returns a size whose dimensions are the dimensions of
  /// the left-hand-side operand (a Size) divided by the scalar right-hand-side
  /// operand (a double).
  Size operator /(double operand) => new Size(width / operand, height / operand);

  /// Integer (truncating) division operator. Returns a size whose dimensions
  /// are the dimensions of the left-hand-side operand (a Size) divided by the
  /// scalar right-hand-side operand (a double), rounded towards zero.
  Size operator ~/(double operand) => new Size((width ~/ operand).toDouble(), (height ~/ operand).toDouble());

  /// Modulo (remainder) operator. Returns a size whose dimensions are the
  /// remainder of dividing the left-hand-side operand (a Size) by the scalar
  /// right-hand-side operand (a double).
  Size operator %(double operand) => new Size(width % operand, height % operand);

  /// Whether this size encloses a non-zero area.
  ///
  /// Negative areas are considered empty.
  bool get isEmpty => width <= 0.0 || height <= 0.0;

  /// The lesser of the [width] and the [height].
  double get shortestSide {
    double w = width.abs();
    double h = height.abs();
    return w < h ? w : h;
  }

  // Convenience methods that do the equivalent of calling the similarly named
  // methods on a Rect constructed from the given origin and this size.

  /// The point at the intersection of the top and left edges of the rectangle
  /// described by the given point (which is interpreted as the top-left corner)
  /// and this size.
  ///
  /// See also [Rect.topLeft].
  Point topLeft(Point origin) => origin;

  /// The point at the center of the top edge of the rectangle described by the
  /// given point (which is interpreted as the top-left corner) and this size.
  ///
  /// See also [Rect.topCenter].
  Point topCenter(Point origin) => new Point(origin.x + width / 2.0, origin.y);

  /// The point at the intersection of the top and right edges of the rectangle
  /// described by the given point (which is interpreted as the top-left corner)
  /// and this size.
  ///
  /// See also [Rect.topRight].
  Point topRight(Point origin) => new Point(origin.x + width, origin.y);

  /// The point at the center of the left edge of the rectangle described by the
  /// given point (which is interpreted as the top-left corner) and this size.
  ///
  /// See also [Rect.centerLeft].
  Point centerLeft(Point origin) => new Point(origin.x, origin.y + height / 2.0);

  /// The point halfway between the left and right and the top and bottom edges
  /// of the rectangle described by the given point (which is interpreted as the
  /// top-left corner) and this size.
  ///
  /// See also [Rect.center].
  Point center(Point origin) => new Point(origin.x + width / 2.0, origin.y + height / 2.0);

  /// The point at the center of the right edge of the rectangle described by the
  /// given point (which is interpreted as the top-left corner) and this size.
  ///
  /// See also [Rect.centerLeft].
  Point centerRight(Point origin) => new Point(origin.x + width, origin.y + height / 2.0);

  /// The point at the intersection of the bottom and left edges of the
  /// rectangle described by the given point (which is interpreted as the
  /// top-left corner) and this size.
  ///
  /// See also [Rect.bottomLeft].
  Point bottomLeft(Point origin) => new Point(origin.x, origin.y + height);

  /// The point at the center of the bottom edge of the rectangle described by
  /// the given point (which is interpreted as the top-left corner) and this
  /// size.
  ///
  /// See also [Rect.bottomLeft].
  Point bottomCenter(Point origin) => new Point(origin.x + width / 2.0, origin.y + height);

  /// The point at the intersection of the bottom and right edges of the
  /// rectangle described by the given point (which is interpreted as the
  /// top-left corner) and this size.
  ///
  /// See also [Rect.bottomRight].
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
  @override
  bool operator ==(dynamic other) => other is Size && super == other;

  @override
  String toString() => "Size(${width?.toStringAsFixed(1)}, ${height?.toStringAsFixed(1)})";
}
