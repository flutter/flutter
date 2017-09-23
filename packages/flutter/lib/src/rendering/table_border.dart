// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' hide Border;

/// Border specification for [Table] widgets.
///
/// This is like [Border], with the addition of two sides: the inner horizontal
/// borders between rows and the inner vertical borders between columns.
///
/// The sides are represented by [BorderSide] objects.
@immutable
class TableBorder {
  /// Creates a border for a table.
  ///
  /// All the sides of the border default to [BorderSide.none].
  const TableBorder({
    this.top: BorderSide.none,
    this.right: BorderSide.none,
    this.bottom: BorderSide.none,
    this.left: BorderSide.none,
    this.horizontalInside: BorderSide.none,
    this.verticalInside: BorderSide.none,
  });

  /// A uniform border with all sides the same color and width.
  ///
  /// The sides default to black solid borders, one logical pixel wide.
  factory TableBorder.all({
    Color color: const Color(0xFF000000),
    double width: 1.0,
    BorderStyle style: BorderStyle.solid,
  }) {
    final BorderSide side = new BorderSide(color: color, width: width, style: style);
    return new TableBorder(top: side, right: side, bottom: side, left: side, horizontalInside: side, verticalInside: side);
  }

  /// Creates a border for a table where all the interior sides use the same
  /// styling and all the exterior sides use the same styling.
  factory TableBorder.symmetric({
    BorderSide inside: BorderSide.none,
    BorderSide outside: BorderSide.none,
  }) {
    return new TableBorder(
      top: outside,
      right: outside,
      bottom: outside,
      left: outside,
      horizontalInside: inside,
      verticalInside: inside,
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

  /// The horizontal interior sides of this border.
  final BorderSide horizontalInside;

  /// The vertical interior sides of this border.
  final BorderSide verticalInside;

  /// The widths of the sides of this border represented as an [EdgeInsets].
  ///
  /// This can be used, for example, with a [Padding] widget to inset a box by
  /// the size of these borders.
  EdgeInsets get dimensions {
    return new EdgeInsets.fromLTRB(left.width, top.width, right.width, bottom.width);
  }

  /// Whether all four sides of the border are identical. Uniform borders are
  /// typically more efficient to paint.
  bool get isUniform {
    assert(top != null);
    assert(right != null);
    assert(bottom != null);
    assert(left != null);
    assert(horizontalInside != null);
    assert(verticalInside != null);

    final Color topColor = top.color;
    if (right.color != topColor ||
        bottom.color != topColor ||
        left.color != topColor ||
        horizontalInside.color != topColor ||
        verticalInside.color != topColor)
      return false;

    final double topWidth = top.width;
    if (right.width != topWidth ||
        bottom.width != topWidth ||
        left.width != topWidth ||
        horizontalInside.width != topWidth ||
        verticalInside.width != topWidth)
      return false;

    final BorderStyle topStyle = top.style;
    if (right.style != topStyle ||
        bottom.style != topStyle ||
        left.style != topStyle ||
        horizontalInside.style != topStyle ||
        verticalInside.style != topStyle)
      return false;

    return true;
  }

  /// Creates a new border with the widths of this border multiplied by `t`.
  TableBorder scale(double t) {
    return new TableBorder(
      top: top.copyWith(width: t * top.width),
      right: right.copyWith(width: t * right.width),
      bottom: bottom.copyWith(width: t * bottom.width),
      left: left.copyWith(width: t * left.width),
      horizontalInside: horizontalInside.copyWith(width: t * horizontalInside.width),
      verticalInside: verticalInside.copyWith(width: t * verticalInside.width)
    );
  }

  /// Linearly interpolate between two table borders.
  ///
  /// If a border is null, it is treated as having only [BorderSide.none]
  /// borders.
  static TableBorder lerp(TableBorder a, TableBorder b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    return new TableBorder(
      top: BorderSide.lerp(a.top, b.top, t),
      right: BorderSide.lerp(a.right, b.right, t),
      bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      left: BorderSide.lerp(a.left, b.left, t),
      horizontalInside: BorderSide.lerp(a.horizontalInside, b.horizontalInside, t),
      verticalInside: BorderSide.lerp(a.verticalInside, b.verticalInside, t)
    );
  }

  /// Paints the border around the given [Rect] on the given [Canvas], with the
  /// given rows and columns.
  ///
  /// Uniform borders are more efficient to paint than more complex borders.
  ///
  /// The `rows` argument specifies the vertical positions of the rows,
  /// specified in terms of the top of each row, in order from top to bottom,
  /// relative to the given rectangle, with an additional entry for the bottom
  /// of the last row (so the first entry should be zero and the last entry
  /// should be `rect.height`).
  ///
  /// The `columns` argument has slightly different semantics; it specifies the
  /// horizontal positions of the columns, specified in terms of the _left_ edge
  /// of each row, relative to the given rectangle, in left-to-right order (so
  /// the first entry should be zero). There is no extra entry for the right
  /// edge of the last column.
  ///
  /// There must be at least one row and at least one column, so the `rows` list
  /// should at a minimum have two values, and the `columns` argument one value.
  ///
  /// The [verticalInside] border is only drawn if there are at least columns
  /// rows. The [horizontalInside] border is only drawn if there are at least
  /// two rows. The vertical borders are drawn below the horizontal borders.
  ///
  /// The outer borders (in the order [top], [right], [bottom], [left], with
  /// [left] above the others) are painted above the inner borders.
  ///
  /// The paint order is particularly notable in the case of
  /// partially-transparent borders.
  void paint(Canvas canvas, Rect rect, {
    @required List<double> rows,
    @required List<double> columns,
  }) {
    // properties can't be null
    assert(top != null);
    assert(right != null);
    assert(bottom != null);
    assert(left != null);
    assert(horizontalInside != null);
    assert(verticalInside != null);

    // arguments can't be null
    assert(canvas != null);
    assert(rect != null);
    assert(rows != null);
    assert(rows.length >= 2);
    assert(rows.first == 0.0);
    assert(rows.last == rect.height);
    assert(columns != null);
    assert(columns.isNotEmpty);
    assert(columns.first == 0.0);
    assert(columns.last < rect.width);

    final Paint paint = new Paint();
    final Path path = new Path();

    switch (verticalInside.style) {
      case BorderStyle.solid:
        paint
          ..color = verticalInside.color
          ..strokeWidth = verticalInside.width
          ..style = PaintingStyle.stroke;
        path.reset();
        for (int x = 1; x < columns.length; x += 1) {
          path.moveTo(rect.left + columns[x], rect.top);
          path.lineTo(rect.left + columns[x], rect.bottom);
        }
        canvas.drawPath(path, paint);
        break;
      case BorderStyle.none:
        break;
    }

    switch (horizontalInside.style) {
      case BorderStyle.solid:
        paint
          ..color = horizontalInside.color
          ..strokeWidth = horizontalInside.width
          ..style = PaintingStyle.stroke;
        path.reset();
        for (int y = 1; y < rows.length; y += 1) {
          path.moveTo(rect.left, rect.top + rows[y]);
          path.lineTo(rect.right, rect.top + rows[y]);
        }
        canvas.drawPath(path, paint);
        break;
      case BorderStyle.none:
        break;
    }

    paintBorder(canvas, rect, top: top, right: right, bottom: bottom, left: left);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final TableBorder typedOther = other;
    return top == typedOther.top
        && right == typedOther.right
        && bottom == typedOther.bottom
        && left == typedOther.left
        && horizontalInside == typedOther.horizontalInside
        && verticalInside == typedOther.verticalInside;
  }

  @override
  int get hashCode => hashValues(top, right, bottom, left, horizontalInside, verticalInside);

  @override
  String toString() => 'TableBorder($top, $right, $bottom, $left, $horizontalInside, $verticalInside)';
}
