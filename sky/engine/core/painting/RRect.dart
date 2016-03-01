// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

// A rounded rectangle with the same radii for all four corners.
class RRect {
  RRect._();

  /// Construct a rounded rectangle from its left, top, right, and bottom edges,
  /// and the radii along its horizontal axis and its vertical axis.
  RRect.fromLTRBXY(double left, double top, double right, double bottom, double radiusX, double radiusY) {
    _value
      ..[0] = left
      ..[1] = top
      ..[2] = right
      ..[3] = bottom
      ..[4] = radiusX
      ..[5] = radiusY;
  }

  /// Construct a rounded rectangle from its bounding box and the radii along
  /// its horizontal axis and its vertical axis.
  RRect.fromRectXY(Rect rect, double radiusX, double radiusY) {
    _value
      ..[0] = rect.left
      ..[1] = rect.top
      ..[2] = rect.right
      ..[3] = rect.bottom
      ..[4] = radiusX
      ..[5] = radiusY;
  }

  static const int _kDataSize = 6;
  final Float32List _value = new Float32List(_kDataSize);

  /// The offset of the left edge of this rectangle from the x axis.
  double get left => _value[0];

  /// The offset of the top edge of this rectangle from the y axis.
  double get top => _value[1];

  /// The offset of the right edge of this rectangle from the x axis.
  double get right => _value[2];

  /// The offset of the bottom edge of this rectangle from the y axis.
  double get bottom => _value[3];

  /// The horizontal semi-axis of the corners.
  double get radiusX => _value[4];

  /// The vertical semi-axis of the corners.
  double get radiusY => _value[5];

  /// A rounded rectangle with all the values set to zero.
  static final RRect zero = new RRect._();

  /// Returns a new RRect translated by the given offset.
  RRect shift(Offset offset) {
    return new RRect.fromLTRBXY(
      _value[0] + offset.dx,
      _value[1] + offset.dy,
      _value[2] + offset.dx,
      _value[3] + offset.dy,
      _value[4],
      _value[5]
    );
  }

  /// Returns a new RRect with edges and radii moved outwards by the given delta.
  RRect inflate(double delta) {
    return new RRect.fromLTRBXY(
      _value[0] - delta,
      _value[1] - delta,
      _value[2] + delta,
      _value[3] + delta,
      _value[4] + delta,
      _value[5] + delta
    );
  }

  /// Returns a new RRect with edges and radii moved inwards by the given delta.
  RRect deflate(double delta) => inflate(-delta);

  /// The distance between the left and right edges of this rectangle.
  double get width => right - left;

  /// The distance between the top and bottom edges of this rectangle.
  double get height => bottom - top;

  /// The bounding box of this rounded rectangle (the rectangle with no rounded corners).
  Rect get outerRect => new Rect.fromLTRB(left, top, right, bottom);

  /// The non-rounded rectangle that fits inside this rounded rectangle by
  /// touching the middle of each curved corner.
  Rect get safeInnerRect {
    const double kInsetFactor = 0.29289321881; // 1-cos(pi/4)
    return new Rect.fromLTRB(
      left + radiusX * kInsetFactor,
      top + radiusY * kInsetFactor,
      right - radiusX * kInsetFactor,
      bottom - radiusY * kInsetFactor
    );
  }

  /// The rectangle that would be formed using only the straight sides of the
  /// rounded rectangle, i.e., the rectangle formed from the centers of the
  /// ellipses that form the corners. This is the intersection of the
  /// [wideMiddleRect] and the [tallMiddleRect].
  Rect get middleRect {
    return new Rect.fromLTRB(
      left + radiusX,
      top + radiusY,
      right - radiusX,
      bottom - radiusY
    );
  }

  /// The biggest rectangle that is entirely inside the rounded rectangle and
  /// has the full width of the rounded rectangle.
  Rect get wideMiddleRect {
    return new Rect.fromLTRB(
      left,
      top + radiusY,
      right,
      bottom - radiusY
    );
  }

  /// The biggest rectangle that is entirely inside the rounded rectangle and
  /// has the full height of the rounded rectangle.
  Rect get tallMiddleRect {
    return new Rect.fromLTRB(
      left + radiusX,
      top,
      right - radiusX,
      bottom
    );
  }

  /// Whether this rounded rectangle encloses a non-zero area.
  /// Negative areas are considered empty.
  bool get isEmpty => left >= right || top >= bottom;

  /// Whether this rounded rectangle has a side with no straight section.
  bool get isStadium => width <= 2 * radiusX || height <= 2 * radiusY;

  /// Whether this rounded rectangle has no side with a straight section.
  bool get isEllipse => width <= 2 * radiusX && height <= 2 * radiusY;

  /// Whether this rounded rectangle would draw as a circle.
  bool get isCircle => width == height && isEllipse;

  /// The lesser of the magnitudes of the width and the height of this rounded
  /// rectangle.
  double get shortestSide {
    double w = width.abs();
    double h = height.abs();
    return w < h ? w : h;
  }

  /// The point halfway between the left and right and the top and bottom edges of this rectangle.
  Point get center => new Point(left + width / 2.0, top + height / 2.0);

  /// Whether the given point lies inside the rounded rectangle.
  bool contains(Point point) {
    if (point.x < left || point.x >= right || point.y < top || point.y >= bottom)
      return false; // outside bounding box
    double leftInner = left + radiusX;
    double rightInner = right - radiusX;
    double topInner = top + radiusY;
    double bottomInner = bottom - radiusY;
    if (point.x >= leftInner && point.x <= rightInner)
      return true; // inside tallMiddleRect
    if (point.y >= topInner && point.y <= bottomInner)
      return true; // inside wideMiddleRect
    // it is in one of the corners
    // convert this to a test of the unit circle
    double x, y;
    if (point.x > leftInner) {
      assert(point.x > rightInner);
      x = point.x - (rightInner - leftInner);
    } else {
      x = point.x;
    }
    if (point.y > topInner) {
      assert(point.y > bottomInner);
      y = point.y - (bottomInner - topInner);
    } else {
      y = point.y;
    }
    x = x / (radiusX * 2) - 0.5;
    y = y / (radiusY * 2) - 0.5;
    // check if the point is outside the unit circle
    if (x * x + y * y > 0.25)
      return false;
    return true;
  }

  /// Linearly interpolate between two rounded rectangles.
  ///
  /// If either is null, this function substitutes [RRect.zero] instead.
  static RRect lerp(RRect a, RRect b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return new RRect.fromLTRBXY(b.left * t, b.top * t, b.right * t, b.bottom * t, b.radiusX * t, b.radiusY * t);
    if (b == null) {
      double k = 1.0 - t;
      return new RRect.fromLTRBXY(a.left * k, a.top * k, a.right * k, a.bottom * k, a.radiusX * k, a.radiusY * k);
    }
    return new RRect.fromLTRBXY(
      lerpDouble(a.left, b.left, t),
      lerpDouble(a.top, b.top, t),
      lerpDouble(a.right, b.right, t),
      lerpDouble(a.bottom, b.bottom, t),
      lerpDouble(a.radiusX, b.radiusX, t),
      lerpDouble(a.radiusY, b.radiusY, t)
    );
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! RRect)
      return false;
    final RRect typedOther = other;
    for (int i = 0; i < _kDataSize; i += 1) {
      if (_value[i] != typedOther._value[i])
        return false;
    }
    return true;
  }

  int get hashCode => hashList(_value);

  String toString() => "RRect.fromLTRBXY(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, ${right.toStringAsFixed(1)}, ${bottom.toStringAsFixed(1)}, ${radiusX.toStringAsFixed(1)}, ${radiusY.toStringAsFixed(1)})";
}
