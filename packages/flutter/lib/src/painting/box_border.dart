// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic_types.dart';
import 'border_radius.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// The shape to use when rendering a [Border] or [BoxDecoration].
enum BoxShape {
  /// An axis-aligned, 2D rectangle. May have rounded corners (described by a
  /// [BorderRadius]). The edges of the rectangle will match the edges of the box
  /// into which the [Border] or [BoxDecoration] is painted.
  rectangle,

  /// A circle centered in the middle of the box into which the [Border] or
  /// [BoxDecoration] is painted. The diameter of the circle is the shortest
  /// dimension of the box, either the width or the height, such that the circle
  /// touches the edges of the box.
  circle,
}

/// A border of a box, comprised of four sides.
///
/// The sides are represented by [BorderSide] objects.
///
/// ## Sample code
///
/// All four borders the same, two-pixel wide solid white:
///
/// ```dart
/// new Border.all(width: 2.0, color: const Color(0xFFFFFFFF))
/// ```
///
/// The border for a material design divider:
///
/// ```dart
/// new Border(bottom: new BorderSide(color: Theme.of(context).dividerColor))
/// ```
///
/// A 1990s-era "OK" button:
///
/// ```dart
/// new Container(
///   decoration: const BoxDecoration(
///     border: const Border(
///       top: const BorderSide(width: 1.0, color: const Color(0xFFFFFFFFFF)),
///       left: const BorderSide(width: 1.0, color: const Color(0xFFFFFFFFFF)),
///       right: const BorderSide(width: 1.0, color: const Color(0xFFFF000000)),
///       bottom: const BorderSide(width: 1.0, color: const Color(0xFFFF000000)),
///     ),
///   ),
///   child: new Container(
///     padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
///     decoration: const BoxDecoration(
///       border: const Border(
///         top: const BorderSide(width: 1.0, color: const Color(0xFFFFDFDFDF)),
///         left: const BorderSide(width: 1.0, color: const Color(0xFFFFDFDFDF)),
///         right: const BorderSide(width: 1.0, color: const Color(0xFFFF7F7F7F)),
///         bottom: const BorderSide(width: 1.0, color: const Color(0xFFFF7F7F7F)),
///       ),
///       color: const Color(0xFFBFBFBF),
///     ),
///     child: const Text(
///       'OK',
///       textAlign: TextAlign.center,
///       style: const TextStyle(color: const Color(0xFF000000))
///     ),
///   ),
/// )
/// ```
///
/// See also:
///
///  * [BoxDecoration], which uses this class to describe its edge decoration.
///  * [BorderSide], which is used to describe each side of the box.
///  * [Theme], from the material layer, which can be queried to obtain appropriate colors
///    to use for borders in a material app, as shown in the "divider" sample above.
class Border extends ShapeBorder {
  /// Creates a border.
  ///
  /// All the sides of the border default to [BorderSide.none].
  const Border({
    this.top: BorderSide.none,
    this.right: BorderSide.none,
    this.bottom: BorderSide.none,
    this.left: BorderSide.none,
  });

  /// A uniform border with all sides the same color and width.
  ///
  /// The sides default to black solid borders, one logical pixel wide.
  factory Border.all({
    Color color: const Color(0xFF000000),
    double width: 1.0,
    BorderStyle style: BorderStyle.solid,
  }) {
    final BorderSide side = new BorderSide(color: color, width: width, style: style);
    return new Border(top: side, right: side, bottom: side, left: side);
  }

  /// Creates a [Border] that represents the addition of the two given
  /// [Border]s.
  ///
  /// It is only valid to call this if [BorderSide.canMerge] returns true for
  /// the pairwise combination of each side on both [Border]s.
  ///
  /// The arguments must not be null.
  static Border merge(Border a, Border b) {
    assert(a != null);
    assert(b != null);
    assert(BorderSide.canMerge(a.top, b.top));
    assert(BorderSide.canMerge(a.right, b.right));
    assert(BorderSide.canMerge(a.bottom, b.bottom));
    assert(BorderSide.canMerge(a.left, b.left));
    return new Border(
      top: BorderSide.merge(a.top, b.top),
      right: BorderSide.merge(a.right, b.right),
      bottom: BorderSide.merge(a.bottom, b.bottom),
      left: BorderSide.merge(a.left, b.left),
    );
  }

  /// The top side of this border.
  final BorderSide top;

  /// The right side of this border.
  final BorderSide right;

  /// The bottom side of this border.
  final BorderSide bottom;

  /// The left side of this border.
  final BorderSide left;

  @override
  EdgeInsetsGeometry get dimensions {
    return new EdgeInsets.fromLTRB(left.width, top.width, right.width, bottom.width);
  }

  /// Whether all four sides of the border are identical. Uniform borders are
  /// typically more efficient to paint.
  bool get isUniform {
    assert(top != null);
    assert(right != null);
    assert(bottom != null);
    assert(left != null);

    final Color topColor = top.color;
    if (right.color != topColor ||
        bottom.color != topColor ||
        left.color != topColor)
      return false;

    final double topWidth = top.width;
    if (right.width != topWidth ||
        bottom.width != topWidth ||
        left.width != topWidth)
      return false;

    final BorderStyle topStyle = top.style;
    if (right.style != topStyle ||
        bottom.style != topStyle ||
        left.style != topStyle)
      return false;

    return true;
  }

  @override
  Border add(ShapeBorder other, { bool reversed: false }) {
    if (other is! Border)
      return null;
    final Border typedOther = other;
    if (BorderSide.canMerge(top, typedOther.top) &&
        BorderSide.canMerge(right, typedOther.right) &&
        BorderSide.canMerge(bottom, typedOther.bottom) &&
        BorderSide.canMerge(left, typedOther.left)) {
      return Border.merge(this, typedOther);
    }
    return null;
  }

  /// Creates a new border with the widths of this border multiplied by `t`.
  @override
  Border scale(double t) {
    return new Border(
      top: top.scale(t),
      right: right.scale(t),
      bottom: bottom.scale(t),
      left: left.scale(t),
    );
  }

  /// Linearly interpolates from `a` to [this].
  ///
  /// If `a` is null, this defers to [scale].
  ///
  /// If `a` is also a [Border], this uses [Border.lerp].
  ///
  /// Otherwise, it defers to [ShapeBorder.lerpFrom].
  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is Border)
      return Border.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  /// Linearly interpolates from [this] to `b`.
  ///
  /// If `b` is null, this defers to [scale].
  ///
  /// If `b` is also a [Border], this uses [Border.lerp].
  ///
  /// Otherwise, it defers to [ShapeBorder.lerpTo].
  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is Border)
      return Border.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  /// Linearly interpolate between two borders.
  ///
  /// If a border is null, it is treated as having four [BorderSide.none]
  /// borders.
  static Border lerp(Border a, Border b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    return new Border(
      top: BorderSide.lerp(a.top, b.top, t),
      right: BorderSide.lerp(a.right, b.right, t),
      bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      left: BorderSide.lerp(a.left, b.left, t)
    );
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRect(dimensions.resolve(textDirection).deflateRect(rect));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRect(rect);
  }

  /// Paints the border within the given [Rect] on the given [Canvas].
  ///
  /// Uniform borders are more efficient to paint than more complex borders.
  ///
  /// You can provide a [BoxShape] to draw the border on. If the `shape` in
  /// [BoxShape.circle], there is the requirement that the border [isUniform].
  ///
  /// If you specify a rectangular box shape ([BoxShape.rectangle]), then you
  /// may specify a [BorderRadius]. If a `borderRadius` is specified, there is
  /// the requirement that the border [isUniform].
  ///
  /// The [getInnerPath] and [getOuterPath] methods do not know about the
  /// `shape` and `borderRadius` arguments.
  ///
  /// The `textDirection` argument is not used by this paint method.
  ///
  /// See also:
  ///
  ///  * [paintBorder], which is used if the border is not uniform.
  @override
  void paint(Canvas canvas, Rect rect, {
    TextDirection textDirection,
    BoxShape shape: BoxShape.rectangle,
    BorderRadius borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          if (shape == BoxShape.circle) {
            assert(borderRadius == null, 'A borderRadius can only be given for rectangular boxes.');
            _paintUniformBorderWithCircle(canvas, rect);
            return;
          }
          if (borderRadius != null) {
            _paintUniformBorderWithRadius(canvas, rect, borderRadius);
            return;
          }
          _paintUniformBorderWithRectangle(canvas, rect);
          return;
      }
    }

    assert(borderRadius == null, 'A borderRadius can only be given for uniform borders.');
    assert(shape == BoxShape.rectangle, 'A border can only be drawn as a circle if it is uniform.');

    paintBorder(canvas, rect, top: top, right: right, bottom: bottom, left: left);
  }

  void _paintUniformBorderWithRadius(Canvas canvas, Rect rect,
                                     BorderRadius borderRadius) {
    assert(isUniform);
    assert(top.style != BorderStyle.none);
    final Paint paint = new Paint()
      ..color = top.color;
    final RRect outer = borderRadius.toRRect(rect);
    final double width = top.width;
    if (width == 0.0) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.0;
      canvas.drawRRect(outer, paint);
    } else {
      final RRect inner = outer.deflate(width);
      canvas.drawDRRect(outer, inner, paint);
    }
  }

  void _paintUniformBorderWithCircle(Canvas canvas, Rect rect) {
    assert(isUniform);
    assert(top.style != BorderStyle.none);
    final double width = top.width;
    final Paint paint = top.toPaint();
    final double radius = (rect.shortestSide - width) / 2.0;
    canvas.drawCircle(rect.center, radius, paint);
  }

  void _paintUniformBorderWithRectangle(Canvas canvas, Rect rect) {
    assert(isUniform);
    assert(top.style != BorderStyle.none);
    final double width = top.width;
    final Paint paint = top.toPaint();
    canvas.drawRect(rect.deflate(width / 2.0), paint);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final Border typedOther = other;
    return top == typedOther.top &&
           right == typedOther.right &&
           bottom == typedOther.bottom &&
           left == typedOther.left;
  }

  @override
  int get hashCode => hashValues(top, right, bottom, left);

  @override
  String toString() {
    if (isUniform)
      return 'Border.all($top)';
    return 'Border($top, $right, $bottom, $left)';
  }
}
