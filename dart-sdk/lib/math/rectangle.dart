// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.math;

/// A base class for representing two-dimensional axis-aligned rectangles.
///
/// This rectangle uses a left-handed Cartesian coordinate system, with x
/// directed to the right and y directed down, as per the convention in 2D
/// computer graphics.
///
/// See also:
///    [W3C Coordinate Systems Specification](https://www.w3.org/TR/SVG/coords.html#InitialCoordinateSystem).
///
/// The rectangle is the set of points with representable coordinates greater
/// than or equal to left/top, and with distance to left/top no greater than
/// width/height (to the limit of the precision of the coordinates).
///
/// **Legacy:** New usages of [_RectangleBase] are discouraged.
/// To learn more, check out the [Rectangle] class API docs.
abstract class _RectangleBase<T extends num> {
  const _RectangleBase();

  /// The x-coordinate of the left edge.
  T get left;

  /// The y-coordinate of the top edge.
  T get top;

  /// The width of the rectangle.
  T get width;

  /// The height of the rectangle.
  T get height;

  /// The x-coordinate of the right edge.
  T get right => (left + width) as T;

  /// The y-coordinate of the bottom edge.
  T get bottom => (top + height) as T;

  String toString() {
    return 'Rectangle ($left, $top) $width x $height';
  }

  bool operator ==(Object other) =>
      other is Rectangle &&
      left == other.left &&
      top == other.top &&
      right == other.right &&
      bottom == other.bottom;

  int get hashCode => SystemHash.hash4(
      left.hashCode, top.hashCode, right.hashCode, bottom.hashCode, 0);

  /// Computes the intersection of `this` and [other].
  ///
  /// The intersection of two axis-aligned rectangles, if any, is always another
  /// axis-aligned rectangle.
  ///
  /// Returns the intersection of this and `other`, or `null` if they don't
  /// intersect.
  Rectangle<T>? intersection(Rectangle<T> other) {
    var x0 = max(left, other.left);
    var x1 = min(left + width, other.left + other.width);

    if (x0 <= x1) {
      var y0 = max(top, other.top);
      var y1 = min(top + height, other.top + other.height);

      if (y0 <= y1) {
        return Rectangle<T>(x0, y0, (x1 - x0) as T, (y1 - y0) as T);
      }
    }
    return null;
  }

  /// Returns true if `this` intersects [other].
  bool intersects(Rectangle<num> other) {
    return (left <= other.left + other.width &&
        other.left <= left + width &&
        top <= other.top + other.height &&
        other.top <= top + height);
  }

  /// Returns a new rectangle which completely contains `this` and [other].
  Rectangle<T> boundingBox(Rectangle<T> other) {
    var right = max(this.left + this.width, other.left + other.width);
    var bottom = max(this.top + this.height, other.top + other.height);

    var left = min(this.left, other.left);
    var top = min(this.top, other.top);

    return Rectangle<T>(left, top, (right - left) as T, (bottom - top) as T);
  }

  /// Tests whether `this` entirely contains [another].
  bool containsRectangle(Rectangle<num> another) {
    return left <= another.left &&
        left + width >= another.left + another.width &&
        top <= another.top &&
        top + height >= another.top + another.height;
  }

  /// Tests whether [another] is inside or along the edges of `this`.
  bool containsPoint(Point<num> another) {
    return another.x >= left &&
        another.x <= left + width &&
        another.y >= top &&
        another.y <= top + height;
  }

  Point<T> get topLeft => Point<T>(this.left, this.top);
  Point<T> get topRight => Point<T>((this.left + this.width) as T, this.top);
  Point<T> get bottomRight =>
      Point<T>((this.left + this.width) as T, (this.top + this.height) as T);
  Point<T> get bottomLeft => Point<T>(this.left, (this.top + this.height) as T);
}

/// A class for representing two-dimensional rectangles whose properties are
/// immutable.
///
/// **Legacy:** New usages of [Rectangle] are discouraged.
///
/// - If you are using the `Rectangle` class with `dart:html`,
///   we recommend migrating to `package:web`.
///   To learn how and why to migrate,
///   check out the [migration guide](https://dart.dev/go/package-web).
/// - If you want to store the boundaries of a rectangle
///   in some coordinate system,
///   consider using a [record](https://dart.dev/language/records).
///   Depending on how you will use it, this could look
///   like `var boundaries = (mixX: x1, maxX: x2, minY: y1, maxY: y2)`.
/// - If you need to perform intersection calculations or containment checks,
///   consider using a dedicated library, such as
///   [`package:vector_math`](https://pub.dev/packages/vector_math).
/// - If you are developing a Flutter application or package,
///   consider using the
///   [`Rect`](https://api.flutter.dev/flutter/dart-ui/Rect-class.html)
///   type from `dart:ui`.
// TODO: @Deprecated(
//     'Use records or a dedicated library like package:vector_math instead.')
class Rectangle<T extends num> extends _RectangleBase<T> {
  final T left;
  final T top;
  final T width;
  final T height;

  /// Create a rectangle spanned by `(left, top)` and
  /// `(left+width, top+height)`.
  ///
  /// The rectangle contains the points
  /// with x-coordinate between `left` and `left + width`, and
  /// with y-coordinate between `top` and `top + height`, both inclusive.
  ///
  /// The `width` and `height` should be non-negative.
  /// If `width` or `height` are negative, they are clamped to zero.
  ///
  /// If `width` and `height` are zero, the "rectangle" comprises only the
  /// single point `(left, top)`.
  ///
  /// Example:
  /// ```dart
  /// var rectangle = const Rectangle(20, 50, 300, 600);
  /// print(rectangle.left); // 20
  /// print(rectangle.top); // 50
  /// print(rectangle.right); // 320
  /// print(rectangle.bottom); // 650
  /// ```
  ///
  /// **Legacy:** New usages of [Rectangle] are discouraged.
  /// To learn more, check out the [Rectangle] class API docs.
  const Rectangle(this.left, this.top, T width, T height)
      : width = (width < 0)
            ? (width == double.negativeInfinity ? 0.0 : (-width * 0)) as dynamic
            : (width + 0 as dynamic), // Inline _clampToZero<num>.
        height = (height < 0)
            ? (height == double.negativeInfinity ? 0.0 : (-height * 0))
                as dynamic
            : (height + 0 as dynamic);

  /// Create a rectangle spanned by the points [a] and [b];
  ///
  /// The rectangle contains the points
  /// with x-coordinate between `a.x` and `b.x`, and
  /// with y-coordinate between `a.y` and `b.y`, both inclusive.
  ///
  /// If the distance between `a.x` and `b.x` is not representable
  /// (which can happen if one or both is a double),
  /// the actual right edge might be slightly off from `max(a.x, b.x)`.
  /// Similar for the y-coordinates and the bottom edge.
  ///
  /// Example:
  /// ```dart
  /// var leftTop = const Point(20, 50);
  /// var rightBottom = const Point(300, 600);
  ///
  /// var rectangle = Rectangle.fromPoints(leftTop, rightBottom);
  /// print(rectangle); // Rectangle (20, 50) 280 x 550
  /// print(rectangle.left); // 20
  /// print(rectangle.top); // 50
  /// print(rectangle.right); // 300
  /// print(rectangle.bottom); // 600
  /// ```
  factory Rectangle.fromPoints(Point<T> a, Point<T> b) {
    T left = min(a.x, b.x);
    T width = (max(a.x, b.x) - left) as T;
    T top = min(a.y, b.y);
    T height = (max(a.y, b.y) - top) as T;
    return Rectangle<T>(left, top, width, height);
  }
}

/// A class for representing two-dimensional axis-aligned rectangles with
/// mutable properties.
///
/// **Legacy:** New usages of [MutableRectangle] are discouraged.
///
/// - If you are using the `MutableRectangle` class with `dart:html`,
///   we recommend migrating to `package:web`.
///   To learn how and why to migrate,
///   check out the [migration guide](https://dart.dev/go/package-web).
/// - If you want to store the boundaries of a rectangle
///   in some coordinate system,
///   consider using a [record](https://dart.dev/language/records).
///   Depending on how you will use it, this could look
///   like `var boundaries = (mixX: x1, maxX: x2, minY: y1, maxY: y2)`.
/// - If you need to perform intersection calculations or containment checks,
///   consider using a dedicated library, such as
///   [`package:vector_math`](https://pub.dev/packages/vector_math).
/// - If you are developing a Flutter application or package,
///   consider using the
///   [`Rect`](https://api.flutter.dev/flutter/dart-ui/Rect-class.html)
///   type from `dart:ui`.
// TODO: @Deprecated(
//     'Use records or a dedicated library like package:vector_math instead.')
class MutableRectangle<T extends num> extends _RectangleBase<T>
    implements Rectangle<T> {
  /// The x-coordinate of the left edge.
  ///
  /// Setting the value will move the rectangle without changing its width.
  T left;

  /// The y-coordinate of the left edge.
  ///
  /// Setting the value will move the rectangle without changing its height.
  T top;
  T _width;
  T _height;

  /// Create a mutable rectangle spanned by `(left, top)` and
  /// `(left+width, top+height)`.
  ///
  /// The rectangle contains the points
  /// with x-coordinate between `left` and `left + width`, and
  /// with y-coordinate between `top` and `top + height`, both inclusive.
  ///
  /// The `width` and `height` should be non-negative.
  /// If `width` or `height` are negative, they are clamped to zero.
  ///
  /// If `width` and `height` are zero, the "rectangle" comprises only the
  /// single point `(left, top)`.
  ///
  /// Example:
  /// ```dart
  /// var rectangle = MutableRectangle(20, 50, 300, 600);
  /// print(rectangle); // Rectangle (20, 50) 300 x 600
  /// print(rectangle.left); // 20
  /// print(rectangle.top); // 50
  /// print(rectangle.right); // 320
  /// print(rectangle.bottom); // 650
  ///
  /// // Change rectangle width and height.
  /// rectangle.width = 200;
  /// rectangle.height = 100;
  ///
  /// print(rectangle); // Rectangle (20, 50) 200 x 100
  /// print(rectangle.left); // 20
  /// print(rectangle.top); // 50
  /// print(rectangle.right); // 220
  /// print(rectangle.bottom); // 150
  /// ```
  ///
  /// **Legacy:** New usages of [MutableRectangle] are discouraged.
  /// To learn more, check out the [MutableRectangle] class API docs.
  MutableRectangle(this.left, this.top, T width, T height)
      : this._width =
            (width < 0) ? _clampToZero<T>(width) : (width + 0 as dynamic),
        this._height =
            (height < 0) ? _clampToZero<T>(height) : (height + 0 as dynamic);

  /// Create a mutable rectangle spanned by the points [a] and [b];
  ///
  /// The rectangle contains the points
  /// with x-coordinate between `a.x` and `b.x`, and
  /// with y-coordinate between `a.y` and `b.y`, both inclusive.
  ///
  /// If the distance between `a.x` and `b.x` is not representable
  /// (which can happen if one or both is a double),
  /// the actual right edge might be slightly off from `max(a.x, b.x)`.
  /// Similar for the y-coordinates and the bottom edge.
  ///
  /// Example:
  /// ```dart
  /// var leftTop = const Point(20, 50);
  /// var rightBottom = const Point(300, 600);
  /// var rectangle = MutableRectangle.fromPoints(leftTop, rightBottom);
  /// print(rectangle); // Rectangle (20, 50) 280 x 550
  /// print(rectangle.left); // 20
  /// print(rectangle.top); // 50
  /// print(rectangle.right); // 300
  /// print(rectangle.bottom); // 600
  /// ```
  factory MutableRectangle.fromPoints(Point<T> a, Point<T> b) {
    T left = min(a.x, b.x);
    T width = (max(a.x, b.x) - left) as T;
    T top = min(a.y, b.y);
    T height = (max(a.y, b.y) - top) as T;
    return MutableRectangle<T>(left, top, width, height);
  }

  T get width => _width;

  /// Sets the width of the rectangle.
  ///
  /// The width must be non-negative.
  /// If a negative width is supplied, it is clamped to zero.
  ///
  /// Setting the value will change the right edge of the rectangle,
  /// but will not change [left].
  set width(T width) {
    if (width < 0) width = _clampToZero<T>(width);
    _width = width;
  }

  T get height => _height;

  /// Sets the height of the rectangle.
  ///
  /// The height must be non-negative.
  /// If a negative height is supplied, it is clamped to zero.
  ///
  /// Setting the value will change the bottom edge of the rectangle,
  /// but will not change [top].
  set height(T height) {
    if (height < 0) height = _clampToZero<T>(height);
    _height = height;
  }
}

/// Converts a negative [int] or [double] to a zero-value of the same type.
///
/// Returns `0` if value is int, `0.0` if value is double.
T _clampToZero<T extends num>(T value) {
  assert(value < 0);
  if (value == double.negativeInfinity) return 0.0 as dynamic;
  return (-value * 0) as dynamic;
}
