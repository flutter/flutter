// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'border_radius.dart';
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

/// The style of line to draw for a [BorderSide] in a [Border].
enum BorderStyle {
  /// Skip the border.
  none,

  /// Draw the border as a solid line.
  solid,

  // if you add more, think about how they will lerp
}

/// A side of a border of a box.
///
/// A [Border] consists of four [BorderSide] objects: [Border.top],
/// [Border.left], [Border.right], and [Border.bottom].
///
/// ## Sample code
///
/// This sample shows how [BorderSide] objects can be used in a [Container], via
/// a [BoxDecoration] and a [Border], to decorate some [Text]. In this example,
/// the text has a thick bar above it that is light blue, and a thick bar below
/// it that is a darker shade of blue.
///
/// ```dart
/// new Container(
///   padding: new EdgeInsets.all(8.0),
///   decoration: new BoxDecoration(
///     border: new Border(
///       top: new BorderSide(width: 16.0, color: Colors.lightBlue.shade50),
///       bottom: new BorderSide(width: 16.0, color: Colors.lightBlue.shade900),
///     ),
///   ),
///   child: new Text('Flutter in the sky', textAlign: TextAlign.center),
/// )
/// ```
///
/// See also:
///
///  * [Border], which uses [BorderSide] objects to represent its sides.
///  * [BoxDecoration], which optionally takes a [Border] object.
///  * [TableBorder], which is similar to [Border] but has two more sides
///    ([TableBorder.horizontalInside] and [TableBorder.verticalInside]), both
///    of which are also [BorderSide] objects.
@immutable
class BorderSide {
  /// Creates the side of a border.
  ///
  /// By default, the border is 1.0 logical pixels wide and solid black.
  const BorderSide({
    this.color: const Color(0xFF000000),
    this.width: 1.0,
    this.style: BorderStyle.solid,
  }) : assert(color != null),
       assert(width != null),
       assert(width >= 0.0),
       assert(style != null);

  /// Creates a [BorderSide] that represents the addition of the two given
  /// [BorderSide]s.
  ///
  /// It is only valid to call this if [canMerge] returns true for the two
  /// sides.
  ///
  /// If one of the sides is zero-width with [BorderStyle.none], then the other
  /// side is return as-is. If both of the sides are zero-width with
  /// [BorderStyle.none], then [BorderSide.zero] is returned.
  ///
  /// The arguments must not be null.
  static BorderSide merge(BorderSide a, BorderSide b) {
    assert(a != null);
    assert(b != null);
    assert(canMerge(a, b));
    final bool aIsNone = a.style == BorderStyle.none && a.width == 0.0;
    final bool bIsNone = b.style == BorderStyle.none && b.width == 0.0;
    if (aIsNone && bIsNone)
      return BorderSide.none;
    if (aIsNone)
      return b;
    if (bIsNone)
      return a;
    assert(a.color == b.color);
    assert(a.style == b.style);
    return new BorderSide(
      color: a.color, // == b.color
      width: a.width + b.width,
      style: a.style, // == b.style
    );
  }

  /// The color of this side of the border.
  final Color color;

  /// The width of this side of the border, in logical pixels. A
  /// zero-width border is a hairline border. To omit the border
  /// entirely, set the [style] to [BorderStyle.none].
  final double width;

  /// The style of this side of the border.
  ///
  /// To omit a side, set [style] to [BorderStyle.none]. This skips
  /// painting the border, but the border still has a [width].
  final BorderStyle style;

  /// A hairline black border that is not rendered.
  static const BorderSide none = const BorderSide(width: 0.0, style: BorderStyle.none);

  /// Creates a copy of this border but with the given fields replaced with the new values.
  BorderSide copyWith({
    Color color,
    double width,
    BorderStyle style
  }) {
    assert(width == null || width >= 0.0);
    return new BorderSide(
      color: color ?? this.color,
      width: width ?? this.width,
      style: style ?? this.style,
    );
  }

  /// Creates a copy of this border but with the width scaled by the given factor.
  ///
  /// Since a zero width is painted as a hairline width rather than no border at
  /// all, the zero factor is special-cased to instead change the style no
  /// [BorderStyle.none].
  BorderSide scale(double t) {
    assert(t != null);
    return new BorderSide(
      color: color,
      width: math.max(0.0, width * t),
      style: t <= 0.0 ? BorderStyle.none : style,
    );
  }

  /// Create a [Paint] object that, if used to stroke a line, will draw the line
  /// in this border's style.
  ///
  /// Not all borders use this method to paint their border sides. For example,
  /// non-uniform rectangular [Border]s have beveled edges and so paint their
  /// border sides as filled shapes rather than using a stroke.
  Paint toPaint() {
    switch (style) {
      case BorderStyle.solid:
        return new Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke;
      case BorderStyle.none:
        return new Paint()
          ..color = const Color(0x00000000)
          ..strokeWidth = 0.0
          ..style = PaintingStyle.stroke;
    }
    return null;
  }

  /// Whether the two given [BorderSide]s can be merged using [new
  /// BorderSide.merge].
  ///
  /// Two sides can be merged if one or both are zero-width with
  /// [BorderStyle.none], or if they both have the same color and style.
  ///
  /// The arguments must not be null.
  static bool canMerge(BorderSide a, BorderSide b) {
    assert(a != null);
    assert(b != null);
    if ((a.style == BorderStyle.none && a.width == 0.0) ||
        (b.style == BorderStyle.none && b.width == 0.0))
      return true;
    return a.style == b.style
        && a.color == b.color;
  }

  /// Linearly interpolate between two border sides.
  ///
  /// The arguments must not be null.
  static BorderSide lerp(BorderSide a, BorderSide b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    if (t == 0.0)
      return a;
    if (t == 1.0)
      return b;
    if (a.style == b.style) {
      return new BorderSide(
        color: Color.lerp(a.color, b.color, t),
        width: math.max(0.0, ui.lerpDouble(a.width, b.width, t)),
        style: a.style, // == b.style
      );
    }
    Color colorA, colorB;
    switch (a.style) {
      case BorderStyle.solid:
        colorA = a.color;
        break;
      case BorderStyle.none:
        colorA = a.color.withAlpha(0x00);
        break;
    }
    switch (b.style) {
      case BorderStyle.solid:
        colorB = b.color;
        break;
      case BorderStyle.none:
        colorB = b.color.withAlpha(0x00);
        break;
    }
    return new BorderSide(
      color: Color.lerp(colorA, colorB, t),
      width: math.max(0.0, ui.lerpDouble(a.width, b.width, t)),
      style: BorderStyle.solid,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final BorderSide typedOther = other;
    return color == typedOther.color &&
           width == typedOther.width &&
           style == typedOther.style;
  }

  @override
  int get hashCode => hashValues(color, width, style);

  @override
  String toString() => '$runtimeType($color, ${width.toStringAsFixed(1)}, $style)';
}

/// Base class for shape outlines.
///
/// This class handles how to add multiple borders together.
@immutable
abstract class ShapeBorder {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ShapeBorder();

  /// The widths of the sides of this border represented as an [EdgeInsets].
  ///
  /// Specifically, this is the amount by which a rectangle should be inset so
  /// as to avoid painting over any important part of the border. It is the
  /// amount by which additional borders will be inset before they are drawn.
  ///
  /// This can be used, for example, with a [Padding] widget to inset a box by
  /// the size of these borders.
  ///
  /// Shapes that have a fixed ratio regardless of the area on which they are
  /// painted, or that change their rendering based on the size they are given
  /// when painting (for instance [CircleBorder]), will not return valid
  /// [dimensions] information because they cannot know their eventual size when
  /// computing their [dimensions].
  EdgeInsetsGeometry get dimensions;

  /// Attempts to create a new object that represents the amalgamation of [this]
  /// border and the `other` border.
  ///
  /// If the type of the other border isn't known, or the given instance cannot
  /// be reasonably added to this instance, then this should return null.
  ///
  /// This method is used by the [operator +] implementation.
  ///
  /// The `reversed` argument is true if this object was the right operand of
  /// the `+` operator, and false if it was the left operand.
  @protected
  ShapeBorder add(ShapeBorder other, { bool reversed: false }) => null;

  /// Creates a new border consisting of the two borders on either side of the
  /// operator.
  ///
  /// If the borders belong to classes that know how to add themselves, then
  /// this results in a new border that represents the intelligent addition of
  /// those two borders (see [add]). Otherwise, an object is returned that
  /// merely paints the two borders sequentially, with the left hand operand on
  /// the inside and the right hand operand on the outside.
  ShapeBorder operator +(ShapeBorder other) {
    return add(other) ?? other.add(this, reversed: true) ?? new _CompoundBorder(<ShapeBorder>[other, this]);
  }

  /// Creates a new border with the widths of this border multiplied by `t`.
  ShapeBorder scale(double t);

  /// Linearly interpolates from `a` to [this].
  ///
  /// When implementing this method in subclasses, return null if this class
  /// cannot interpolate from `a`. In that case, [lerp] will try `a`'s [lerpTo]
  /// method instead. If `a` is null, this must not return null.
  ///
  /// The base class implementation handles the case of `a` being null by
  /// deferring to [scale].
  ///
  /// Instead of calling this directly, use [ShapeBorder.lerp].
  @protected
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a == null)
      return scale(t);
    return null;
  }

  /// Linearly interpolates from [this] to `b`.
  ///
  /// This is called if `b`'s [lerpTo] did not know how to handle this class.
  ///
  /// When implementing this method in subclasses, return null if this class
  /// cannot interpolate from `b`. In that case, [lerp] will apply a default
  /// behavior instead. If `b` is null, this must not return null.
  ///
  /// The base class implementation handles the case of `b` being null by
  /// deferring to [scale].
  ///
  /// Instead of calling this directly, use [ShapeBorder.lerp].
  @protected
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b == null)
      return scale(1.0 - t);
    return null;
  }

  /// Linearly interpolates from `begin` to `end`.
  ///
  /// This defers to `end`'s [lerpTo] function if `end` is not null. If `end` is
  /// null or if its [lerpTo] returns null, it uses `begin`'s [lerpFrom]
  /// function instead. If both return null, it returns `begin` before `t=0.5`
  /// and `end` after `t=0.5`.
  static ShapeBorder lerp(ShapeBorder begin, ShapeBorder end, double t) {
    ShapeBorder result;
    if (end != null)
      result = end.lerpFrom(begin, t);
    if (result == null && begin != null)
      result = begin.lerpTo(end, t);
    return result ?? (t < 0.5 ? begin : end);
  }

  /// Create a [Path] that describes the outer edge of the border.
  ///
  /// This path must not cross the path given by [getInnerPath] for the same
  /// [Rect].
  ///
  /// To obtain a [Path] that describes the area of the border itself, set the
  /// [Path.fillType] of the returned object to [PathFillType.evenOdd], and add
  /// to this object the path returned from [getInnerPath] (using
  /// [Path.addPath]).
  ///
  /// The `textDirection` argument must be provided  non-null if the border
  /// has a text direction dependency (for example if it is expressed in terms
  /// of "start" and "end" instead of "left" and "right"). It may be null if
  /// the border will not need the text direction to paint itself.
  ///
  /// See also:
  ///
  ///  * [getInnerPath], which creates the path for the inner edge.
  ///  * [Path.contains], which can tell if an [Offset] is within a [Path].
  Path getOuterPath(Rect rect, { TextDirection textDirection });

  /// Create a [Path] that describes the inner edge of the border.
  ///
  /// This path must not cross the path given by [getOuterPath] for the same
  /// [Rect].
  ///
  /// To obtain a [Path] that describes the area of the border itself, set the
  /// [Path.fillType] of the returned object to [PathFillType.evenOdd], and add
  /// to this object the path returned from [getOuterPath] (using
  /// [Path.addPath]).
  ///
  /// The `textDirection` argument must be provided and non-null if the border
  /// has a text direction dependency (for example if it is expressed in terms
  /// of "start" and "end" instead of "left" and "right"). It may be null if
  /// the border will not need the text direction to paint itself.
  ///
  /// See also:
  ///
  ///  * [getOuterPath], which creates the path for the outer edge.
  ///  * [Path.contains], which can tell if an [Offset] is within a [Path].
  Path getInnerPath(Rect rect, { TextDirection textDirection });

  /// Paints the border within the given [Rect] on the given [Canvas].
  ///
  /// The `textDirection` argument must be provided and non-null if the border
  /// has a text direction dependency (for example if it is expressed in terms
  /// of "start" and "end" instead of "left" and "right"). It may be null if
  /// the border will not need the text direction to paint itself.
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection });

  @override
  String toString() {
    return '$runtimeType()';
  }
}

/// Represents the addition of two otherwise-incompatible borders.
///
/// The borders are listed from the outside to the inside.
class _CompoundBorder extends ShapeBorder {
  _CompoundBorder(this.borders) {
    assert(borders != null);
    assert(borders.length >= 2);
    assert(!borders.any((ShapeBorder border) => border is _CompoundBorder));
  }

  final List<ShapeBorder> borders;

  @override
  EdgeInsetsGeometry get dimensions {
    return borders.fold<EdgeInsetsGeometry>(
      EdgeInsets.zero,
      (EdgeInsetsGeometry previousValue, ShapeBorder border) {
        return previousValue.add(border.dimensions);
      },
    );
  }

  @override
  ShapeBorder add(ShapeBorder other, { bool reversed: false }) {
    // This wraps the list of borders with "other", or, if "reversed" is true,
    // wraps "other" with the list of borders.
    // If "reversed" is false, "other" should end up being at the start of the
    // list, otherwise, if "reversed" is true, it should end up at the end.
    // First, see if we can merge the new adjacent borders.
    if (other is! _CompoundBorder) {
      // Here, "ours" is the border at the side where we're adding the new
      // border, and "merged" is the result of attempting to merge it with the
      // new border. If it's null, it couldn't be merged.
      final ShapeBorder ours = reversed ? borders.last : borders.first;
      final ShapeBorder merged = ours.add(other, reversed: reversed)
                             ?? other.add(ours, reversed: !reversed);
      if (merged != null) {
        final List<ShapeBorder> result = <ShapeBorder>[];
        result.addAll(borders);
        result[reversed ? result.length - 1 : 0] = merged;
        return new _CompoundBorder(result);
      }
    }
    // We can't, so fall back to just adding the new border to the list.
    final List<ShapeBorder> mergedBorders = <ShapeBorder>[];
    if (reversed)
      mergedBorders.addAll(borders);
    if (other is _CompoundBorder)
      mergedBorders.addAll(other.borders);
    else
      mergedBorders.add(other);
    if (!reversed)
      mergedBorders.addAll(borders);
    return new _CompoundBorder(mergedBorders);
  }

  @override
  ShapeBorder scale(double t) {
    return new _CompoundBorder(
      borders.map<ShapeBorder>((ShapeBorder border) => border.scale(t)).toList()
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    return _CompoundBorder.lerp(a, this, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    return _CompoundBorder.lerp(this, b, t);
  }

  static _CompoundBorder lerp(ShapeBorder a, ShapeBorder b, double t) {
    assert(a is _CompoundBorder || b is _CompoundBorder); // Not really necessary, but all call sites currently intend this.
    final List<ShapeBorder> aList = a is _CompoundBorder ? a.borders : <ShapeBorder>[a];
    final List<ShapeBorder> bList = b is _CompoundBorder ? b.borders : <ShapeBorder>[b];
    final List<ShapeBorder> results = <ShapeBorder>[];
    final int length = math.max(aList.length, bList.length);
    for (int index = 0; index < length; index += 1) {
      final ShapeBorder localA = index < aList.length ? aList[index] : null;
      final ShapeBorder localB = index < bList.length ? bList[index] : null;
      if (localA != null && localB != null) {
        final ShapeBorder localResult = localA.lerpTo(localB, t) ?? localB.lerpFrom(localA, t);
        if (localResult != null) {
          results.add(localResult);
          continue;
        }
      }
      // If we're changing from one shape to another, make sure the shape that is coming in
      // is inserted before the shape that is going away, so that the outer path changes to
      // the new border earlier rather than later. (This affects, among other things, where
      // the ShapeDecoration class puts its background.)
      if (localB != null)
        results.add(localB.scale(t));
      if (localA != null)
        results.add(localA.scale(1.0 - t));
    }
    return new _CompoundBorder(results);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    for (int index = 0; index < borders.length - 1; index += 1)
      rect = borders[index].dimensions.resolve(textDirection).deflateRect(rect);
    return borders.last.getInnerPath(rect);
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return borders.first.getOuterPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {
    for (ShapeBorder border in borders) {
      border.paint(canvas, rect, textDirection: textDirection);
      rect = border.dimensions.resolve(textDirection).deflateRect(rect);
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final _CompoundBorder typedOther = other;
    if (borders == typedOther.borders)
      return true;
    if (borders.length != typedOther.borders.length)
      return false;
    for (int index = 0; index < borders.length; index += 1) {
      if (borders[index] != typedOther.borders[index])
        return false;
    }
    return true;
  }

  @override
  int get hashCode => hashList(borders);

  @override
  String toString() {
    // We list them in reverse order because when adding two borders they end up
    // in the list in the opposite order of what the source looks like: a + b =>
    // [b, a]. We do this to make the painting code more optimal, and most of
    // the rest of the code doesn't care, except toString() (for debugging).
    return borders.reversed.map<String>((ShapeBorder border) => border.toString()).join(' + ');
  }
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

/// Paints a border around the given rectangle on the canvas.
///
/// The four sides can be independently specified. They are painted in the order
/// top, right, bottom, left. This is only notable if the widths of the borders
/// and the size of the given rectangle are such that the border sides will
/// overlap each other. No effort is made to optimize the rendering of uniform
/// borders (where all the borders have the same configuration); to render a
/// uniform border, consider using [Canvas.drawRect] directly.
///
/// The arguments must not be null.
///
/// See also:
///
///  * [paintImage], which paints an image in a rectangle on a canvas.
///  * [Border], which uses this function to paint its border when the border is
///    not uniform.
///  * [BoxDecoration], which describes its border using the [Border] class.
void paintBorder(Canvas canvas, Rect rect, {
  BorderSide top: BorderSide.none,
  BorderSide right: BorderSide.none,
  BorderSide bottom: BorderSide.none,
  BorderSide left: BorderSide.none,
}) {
  assert(canvas != null);
  assert(rect != null);
  assert(top != null);
  assert(right != null);
  assert(bottom != null);
  assert(left != null);

  // We draw the borders as filled shapes, unless the borders are hairline
  // borders, in which case we use PaintingStyle.stroke, with the stroke width
  // specified here.
  final Paint paint = new Paint()
    ..strokeWidth = 0.0;

  final Path path = new Path();

  switch (top.style) {
    case BorderStyle.solid:
      paint.color = top.color;
      path.reset();
      path.moveTo(rect.left, rect.top);
      path.lineTo(rect.right, rect.top);
      if (top.width == 0.0) {
        paint.style = PaintingStyle.stroke;
      } else {
        paint.style = PaintingStyle.fill;
        path.lineTo(rect.right - right.width, rect.top + top.width);
        path.lineTo(rect.left + left.width, rect.top + top.width);
      }
      canvas.drawPath(path, paint);
      break;
    case BorderStyle.none:
      break;
  }

  switch (right.style) {
    case BorderStyle.solid:
      paint.color = right.color;
      path.reset();
      path.moveTo(rect.right, rect.top);
      path.lineTo(rect.right, rect.bottom);
      if (right.width == 0.0) {
        paint.style = PaintingStyle.stroke;
      } else {
        paint.style = PaintingStyle.fill;
        path.lineTo(rect.right - right.width, rect.bottom - bottom.width);
        path.lineTo(rect.right - right.width, rect.top + top.width);
      }
      canvas.drawPath(path, paint);
      break;
    case BorderStyle.none:
      break;
  }

  switch (bottom.style) {
    case BorderStyle.solid:
      paint.color = bottom.color;
      path.reset();
      path.moveTo(rect.right, rect.bottom);
      path.lineTo(rect.left, rect.bottom);
      if (bottom.width == 0.0) {
        paint.style = PaintingStyle.stroke;
      } else {
        paint.style = PaintingStyle.fill;
        path.lineTo(rect.left + left.width, rect.bottom - bottom.width);
        path.lineTo(rect.right - right.width, rect.bottom - bottom.width);
      }
      canvas.drawPath(path, paint);
      break;
    case BorderStyle.none:
      break;
  }

  switch (left.style) {
    case BorderStyle.solid:
      paint.color = left.color;
      path.reset();
      path.moveTo(rect.left, rect.bottom);
      path.lineTo(rect.left, rect.top);
      if (left.width == 0.0) {
        paint.style = PaintingStyle.stroke;
      } else {
        paint.style = PaintingStyle.fill;
        path.lineTo(rect.left + left.width, rect.top + top.width);
        path.lineTo(rect.left + left.width, rect.bottom - bottom.width);
      }
      canvas.drawPath(path, paint);
      break;
    case BorderStyle.none:
      break;
  }
}
