// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// An immutable 2D, axis-aligned, floating-point rectangle
class Rect {
  Rect();

  /// Construct a rectangle from left, top, right, and bottom edges
  Rect.fromLTRB(double left, double top, double right, double bottom) {
    _value
      ..[0] = left
      ..[1] = top
      ..[2] = right
      ..[3] = bottom;
  }

  /// Construct a rectangle from left, top edges and a width and height
  Rect.fromLTWH(double left, double top, double width, double height) {
    _value
      ..[0] = left
      ..[1] = top
      ..[2] = left + width
      ..[3] = top + height;
  }

  final Float32List _value = new Float32List(4);

  /// The offset of the left edge of this rectangle from the x axis
  double get left => _value[0];

  /// The offset of the top edge of this rectangle from the y axis
  double get top => _value[1];

  /// The offset of the right edge of this rectangle from the x axis
  double get right => _value[2];

  /// The offset of the bottom edge of this rectangle from the y axis
  double get bottom => _value[3];

  /// A rectangle with left, top, right, and bottom edges all at zero
  static final Rect zero = new Rect();

  /// Returns a new rectangle translated by the given offset
  Rect shift(Offset offset) {
    return new Rect.fromLTRB(left + offset.dx, top + offset.dy, right + offset.dx, bottom + offset.dy);
  }

  /// Returns a new rectangle with edges moved outwards by the given delta
  Rect inflate(double delta) {
    return new Rect.fromLTRB(left - delta, top - delta, right + delta, bottom + delta);
  }

  /// Returns a new rectangle with edges moved inwards by the given delta
  Rect deflate(double delta) {
    return inflate(-delta);
  }

  /// Returns a new rectangle that is the intersection of the given rectangle and this rectangle
  Rect intersect(Rect other) {
    return new Rect.fromLTRB(
      math.max(left, other.left),
      math.max(top, other.top),
      math.max(right, other.right),
      math.max(bottom, other.bottom));
  }

  /// The distance between the left and right edges of this rectangle
  double get width => right - left;

  /// The distance between the top and bottom edges of this rectangle
  double get height => bottom - top;

  /// The distance between upper-left corner and the lower-right corner of this rectangle
  Size get size => new Size(width, height);

  /// The lesser of the width and the height of this rectangle
  double get shortestSide {
    double w = width.abs();
    double h = height.abs();
    return w < h ? w : h;
  }

  /// The point halfway between the left and right and the top and bottom edges of this rectangle
  Point get center => new Point(left + width / 2.0, top + height / 2.0);

  /// The point at the intersection of the top and left edges of this rectangle
  Point get topLeft => new Point(left, top);

  /// The point at the intersection of the top and right edges of this rectangle
  Point get topRight => new Point(right, top);

  /// The point at the intersection of the bottom and left edges of this rectangle
  Point get bottomLeft => new Point(left, bottom);

  /// The point at the intersection of the bottom and right edges of this rectangle
  Point get bottomRight => new Point(right, bottom);

  /// Whether the given point lies between the left and right and the top and bottom edges of this rectangle
  ///
  /// Rectangles include their top and left edges but exclude their bottom and right edges.
  bool contains(Point point) {
    return point.x >= left && point.x < right && point.y >= top && point.y < bottom;
  }

  /// Linearly interpolate between two rectangles
  ///
  /// If either rect is null, this function interpolates from [Rect.zero].
  static Rect lerp(Rect a, Rect b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return new Rect.fromLTRB(b.left * t, b.top * t, b.right * t, b.bottom * t);
    if (b == null) {
      double k = 1.0 - t;
      return new Rect.fromLTRB(b.left * k, b.top * k, b.right * k, b.bottom * k);
    }
    return new Rect.fromLTRB(
      lerpDouble(a.left, b.left, t),
      lerpDouble(a.top, b.top, t),
      lerpDouble(a.right, b.right, t),
      lerpDouble(a.bottom, b.bottom, t)
    );
  }

  bool operator ==(other) {
    if (other is! Rect)
      return false;
    for (var i = 0; i < 4; ++i) {
      if (_value[i] != other._value[i])
        return false;
    }
    return true;
  }
  int get hashCode =>_value.fold(373, (value, item) => (37 * value + item.hashCode));
  String toString() => "Rect.fromLTRB($left, $top, $right, $bottom)";
}
