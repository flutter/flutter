// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show Image, Gradient, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'box_fit.dart';
import 'decoration.dart';
import 'edge_insets.dart';
import 'fractional_offset.dart';

export 'edge_insets.dart' show EdgeInsets;

/// The shape to use when rendering a BoxDecoration.
enum BoxShape {
  /// An axis-aligned, 2D rectangle. May have rounded corners (described by a
  /// [BorderRadius]). The edges of the rectangle will match the edges of the box
  /// into which the [BoxDecoration] is painted.
  rectangle,

  /// A circle centered in the middle of the box into which the [BoxDecoration]
  /// is painted. The diameter of the circle is the shortest dimension of the
  /// box, either the width or the height, such that the circle touches the
  /// edges of the box.
  circle,
}

/// An immutable set of radii for each corner of a rectangle.
///
/// Used by [BoxDecoration] when the shape is a [BoxShape.rectangle].
@immutable
class BorderRadius {
  /// Creates a border radius where all radii are [radius].
  const BorderRadius.all(Radius radius) : this.only(
    topLeft: radius,
    topRight: radius,
    bottomRight: radius,
    bottomLeft: radius
  );

  /// Creates a border radius where all radii are [Radius.circular(radius)].
  BorderRadius.circular(double radius) : this.all(
    new Radius.circular(radius)
  );

  /// Creates a vertically symmetric border radius where the top and bottom
  /// sides of the rectangle have the same radii.
  const BorderRadius.vertical({
    Radius top: Radius.zero,
    Radius bottom: Radius.zero
  }) : this.only(
    topLeft: top,
    topRight: top,
    bottomRight: bottom,
    bottomLeft: bottom
  );

  /// Creates a horizontally symmetrical border radius where the left and right
  /// sides of the rectangle have the same radii.
  const BorderRadius.horizontal({
    Radius left: Radius.zero,
    Radius right: Radius.zero
  }) : this.only(
    topLeft: left,
    topRight: right,
    bottomRight: right,
    bottomLeft: left
  );

  /// Creates a border radius with only the given non-zero values. The other
  /// corners will be right angles.
  const BorderRadius.only({
    this.topLeft: Radius.zero,
    this.topRight: Radius.zero,
    this.bottomRight: Radius.zero,
    this.bottomLeft: Radius.zero
  });

  /// A border radius with all zero radii.
  static const BorderRadius zero = const BorderRadius.all(Radius.zero);

  /// The top-left [Radius].
  final Radius topLeft;
  /// The top-right [Radius].
  final Radius topRight;
  /// The bottom-right [Radius].
  final Radius bottomRight;
  /// The bottom-left [Radius].
  final Radius bottomLeft;

  /// Linearly interpolates between two [BorderRadius] objects.
  ///
  /// If either is null, this function interpolates from [BorderRadius.zero].
  static BorderRadius lerp(BorderRadius a, BorderRadius b, double t) {
    if (a == null && b == null)
      return null;
    return new BorderRadius.only(
      topLeft: Radius.lerp(a.topLeft, b.topLeft, t),
      topRight: Radius.lerp(a.topRight, b.topRight, t),
      bottomRight: Radius.lerp(a.bottomRight, b.bottomRight, t),
      bottomLeft: Radius.lerp(a.bottomLeft, b.bottomLeft, t)
    );
  }

  /// Creates a [RRect] from the current border radius and a [Rect].
  RRect toRRect(Rect rect) {
    return new RRect.fromRectAndCorners(
      rect,
      topLeft: topLeft,
      topRight: topRight,
      bottomRight: bottomRight,
      bottomLeft: bottomLeft
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BorderRadius)
      return false;
    final BorderRadius typedOther = other;
    return topLeft == typedOther.topLeft &&
           topRight == typedOther.topRight &&
           bottomRight == typedOther.bottomRight &&
           bottomLeft == typedOther.bottomLeft;
  }

  @override
  int get hashCode => hashValues(topLeft, topRight, bottomRight, bottomLeft);

  @override
  String toString() {
    return 'BorderRadius($topLeft, $topRight, $bottomRight, $bottomLeft)';
  }
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
@immutable
class BorderSide {
  /// Creates the side of a border.
  ///
  /// By default, the border is 1.0 logical pixels wide and solid black.
  const BorderSide({
    this.color: const Color(0xFF000000),
    this.width: 1.0,
    this.style: BorderStyle.solid
  });

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
    return new BorderSide(
      color: color ?? this.color,
      width: width ?? this.width,
      style: style ?? this.style
    );
  }

  /// Linearly interpolate between two border sides.
  static BorderSide lerp(BorderSide a, BorderSide b, double t) {
    assert(a != null);
    assert(b != null);
    if (t == 0.0)
      return a;
    if (t == 1.0)
      return b;
    if (a.style == b.style) {
      return new BorderSide(
        color: Color.lerp(a.color, b.color, t),
        width: ui.lerpDouble(a.width, b.width, t),
        style: a.style // == b.style
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
      width: ui.lerpDouble(a.width, b.width, t),
      style: BorderStyle.solid
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BorderSide)
      return false;
    final BorderSide typedOther = other;
    return color == typedOther.color &&
           width == typedOther.width &&
           style == typedOther.style;
  }

  @override
  int get hashCode => hashValues(color, width, style);

  @override
  String toString() => 'BorderSide($color, $width, $style)';
}

/// A border of a box, comprised of four sides.
@immutable
class Border {
  /// Creates a border.
  ///
  /// All the sides of the border default to [BorderSide.none].
  const Border({
    this.top: BorderSide.none,
    this.right: BorderSide.none,
    this.bottom: BorderSide.none,
    this.left: BorderSide.none
  });

  /// A uniform border with all sides the same color and width.
  factory Border.all({
    Color color: const Color(0xFF000000),
    double width: 1.0,
    BorderStyle style: BorderStyle.solid
  }) {
    final BorderSide side = new BorderSide(color: color, width: width, style: style);
    return new Border(top: side, right: side, bottom: side, left: side);
  }

  /// The top side of this border.
  final BorderSide top;

  /// The right side of this border.
  final BorderSide right;

  /// The bottom side of this border.
  final BorderSide bottom;

  /// The left side of this border.
  final BorderSide left;

  /// The widths of the sides of this border represented as an EdgeInsets.
  EdgeInsets get dimensions {
    return new EdgeInsets.fromLTRB(left.width, top.width, right.width, bottom.width);
  }

  /// Whether all four sides of the border are identical.
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

  /// Creates a new border with the widths of this border multiplied by [t].
  Border scale(double t) {
    return new Border(
      top: top.copyWith(width: t * top.width),
      right: right.copyWith(width: t * right.width),
      bottom: bottom.copyWith(width: t * bottom.width),
      left: left.copyWith(width: t * left.width)
    );
  }

  /// Linearly interpolate between two borders.
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

  /// Paints the border within the given rect on the given canvas.
  void paint(Canvas canvas, Rect rect, {
    BoxShape shape: BoxShape.rectangle,
    BorderRadius borderRadius: null
  }) {
    if (isUniform) {
      if (borderRadius != null) {
        _paintBorderWithRadius(canvas, rect, borderRadius);
        return;
      }
      if (shape == BoxShape.circle) {
        _paintBorderWithCircle(canvas, rect);
        return;
      }
    }

    assert(borderRadius == null); // TODO(abarth): Support non-uniform rounded borders.
    assert(shape == BoxShape.rectangle); // TODO(ianh): Support non-uniform borders on circles.

    assert(top != null);
    assert(right != null);
    assert(bottom != null);
    assert(left != null);

    final Paint paint = new Paint()
      ..strokeWidth = 0.0; // used for hairline borders
    Path path;

    switch (top.style) {
      case BorderStyle.solid:
        paint.color = top.color;
        path = new Path();
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
        path = new Path();
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
        path = new Path();
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
        path = new Path();
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

  void _paintBorderWithRadius(Canvas canvas, Rect rect,
                              BorderRadius borderRadius) {
    assert(isUniform);
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

  void _paintBorderWithCircle(Canvas canvas, Rect rect) {
    assert(isUniform);
    final double width = top.width;
    final Paint paint = new Paint()
      ..color = top.color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    final double radius = (rect.shortestSide - width) / 2.0;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
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
  String toString() => 'Border($top, $right, $bottom, $left)';
}

/// A shadow cast by a box.
///
/// BoxShadow can cast non-rectangular shadows if the box is non-rectangular
/// (e.g., has a border radius or a circular shape).
///
/// This class is similar to CSS box-shadow.
@immutable
class BoxShadow {
  /// Creates a box shadow.
  ///
  /// By default, the shadow is solid black with zero [offset], [blurRadius],
  /// and [spreadRadius].
  const BoxShadow({
    this.color: const Color(0xFF000000),
    this.offset: Offset.zero,
    this.blurRadius: 0.0,
    this.spreadRadius: 0.0
  });

  /// The color of the shadow.
  final Color color;

  /// The displacement of the shadow from the box.
  final Offset offset;

  /// The standard deviation of the Gaussian to convolve with the box's shape.
  final double blurRadius;

  /// The amount the box should be inflated prior to applying the blur.
  final double spreadRadius;

  /// Converts a blur radius in pixels to sigmas.
  ///
  /// See the sigma argument to [MaskFilter.blur].
  //
  // See SkBlurMask::ConvertRadiusToSigma().
  // <https://github.com/google/skia/blob/bb5b77db51d2e149ee66db284903572a5aac09be/src/effects/SkBlurMask.cpp#L23>
  static double convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }

  /// The [blurRadius] in sigmas instead of logical pixels.
  ///
  /// See the sigma argument to [MaskFilter.blur].
  double get blurSigma => convertRadiusToSigma(blurRadius);

  /// Returns a new box shadow with its offset, blurRadius, and spreadRadius scaled by the given factor.
  BoxShadow scale(double factor) {
    return new BoxShadow(
      color: color,
      offset: offset * factor,
      blurRadius: blurRadius * factor,
      spreadRadius: spreadRadius * factor
    );
  }

  /// Linearly interpolate between two box shadows.
  ///
  /// If either box shadow is null, this function linearly interpolates from a
  /// a box shadow that matches the other box shadow in color but has a zero
  /// offset and a zero blurRadius.
  static BoxShadow lerp(BoxShadow a, BoxShadow b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    return new BoxShadow(
      color: Color.lerp(a.color, b.color, t),
      offset: Offset.lerp(a.offset, b.offset, t),
      blurRadius: ui.lerpDouble(a.blurRadius, b.blurRadius, t),
      spreadRadius: ui.lerpDouble(a.spreadRadius, b.spreadRadius, t)
    );
  }

  /// Linearly interpolate between two lists of box shadows.
  ///
  /// If the lists differ in length, excess items are lerped with null.
  static List<BoxShadow> lerpList(List<BoxShadow> a, List<BoxShadow> b, double t) {
    if (a == null && b == null)
      return null;
    a ??= <BoxShadow>[];
    b ??= <BoxShadow>[];
    final List<BoxShadow> result = <BoxShadow>[];
    final int commonLength = math.min(a.length, b.length);
    for (int i = 0; i < commonLength; ++i)
      result.add(BoxShadow.lerp(a[i], b[i], t));
    for (int i = commonLength; i < a.length; ++i)
      result.add(a[i].scale(1.0 - t));
    for (int i = commonLength; i < b.length; ++i)
      result.add(b[i].scale(t));
    return result;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BoxShadow)
      return false;
    final BoxShadow typedOther = other;
    return color == typedOther.color &&
           offset == typedOther.offset &&
           blurRadius == typedOther.blurRadius &&
           spreadRadius == typedOther.spreadRadius;
  }

  @override
  int get hashCode => hashValues(color, offset, blurRadius, spreadRadius);

  @override
  String toString() => 'BoxShadow($color, $offset, $blurRadius, $spreadRadius)';
}

/// A 2D gradient.
@immutable
abstract class Gradient {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Gradient();

  /// Creates a [Shader] for this gradient to fill the given rect.
  Shader createShader(Rect rect);
}

/// A 2D linear gradient.
class LinearGradient extends Gradient {
  /// Creates a linear graident.
  ///
  /// The [colors] argument must not be null. If [stops] is non-null, it must
  /// have the same length as [colors].
  const LinearGradient({
    this.begin: FractionalOffset.centerLeft,
    this.end: FractionalOffset.centerRight,
    this.colors,
    this.stops,
    this.tileMode: TileMode.clamp
  });

  /// The offset from coordinate (0.0,0.0) at which stop 0.0 of the
  /// gradient is placed, in a coordinate space that maps the top left
  /// of the paint box at (0.0,0.0) and the bottom right at (1.0,1.0).
  ///
  /// For example, a begin offset of (0.0,0.5) is half way down the
  /// left side of the box.
  final FractionalOffset begin;

  /// The offset from coordinate (0.0,0.0) at which stop 1.0 of the
  /// gradient is placed, in a coordinate space that maps the top left
  /// of the paint box at (0.0,0.0) and the bottom right at (1.0,1.0).
  ///
  /// For example, an end offset of (1.0,0.5) is half way down the
  /// right side of the box.
  final FractionalOffset end;

  /// The colors the gradient should obtain at each of the stops.
  ///
  /// If [stops] is non-null, this list must have the same length as [stops].
  final List<Color> colors;

  /// A list of values from 0.0 to 1.0 that denote fractions of the vector from
  /// start to end.
  ///
  /// If non-null, this list must have the same length as [colors]. Otherwise
  /// the colors are distributed evenly between [begin] and [end].
  final List<double> stops;

  /// How this gradient should tile the plane.
  final TileMode tileMode;

  @override
  Shader createShader(Rect rect) {
    return new ui.Gradient.linear(
      begin.withinRect(rect),
      end.withinRect(rect),
      colors, stops, tileMode,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! LinearGradient)
      return false;
    final LinearGradient typedOther = other;
    if (begin != typedOther.begin ||
        end != typedOther.end ||
        tileMode != typedOther.tileMode ||
        colors?.length != typedOther.colors?.length ||
        stops?.length != typedOther.stops?.length)
      return false;
    if (colors != null) {
      assert(typedOther.colors != null);
      assert(colors.length == typedOther.colors.length);
      for (int i = 0; i < colors.length; i += 1) {
        if (colors[i] != typedOther.colors[i])
          return false;
      }
    }
    if (stops != null) {
      assert(typedOther.stops != null);
      assert(stops.length == typedOther.stops.length);
      for (int i = 0; i < stops.length; i += 1) {
        if (stops[i] != typedOther.stops[i])
          return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => hashValues(begin, end, tileMode, hashList(colors), hashList(stops));

  @override
  String toString() {
    return 'LinearGradient($begin, $end, $colors, $stops, $tileMode)';
  }
}

/// A 2D radial gradient.
class RadialGradient extends Gradient {
  /// Creates a radial graident.
  ///
  /// The [colors] argument must not be null. If [stops] is non-null, it must
  /// have the same length as [colors].
  const RadialGradient({
    this.center: FractionalOffset.center,
    this.radius: 0.5,
    this.colors,
    this.stops,
    this.tileMode: TileMode.clamp
  });

  /// The center of the gradient, as an offset into the unit square
  /// describing the gradient which will be mapped onto the paint box.
  ///
  /// For example, an offset of (0.5,0.5) will place the radial
  /// gradient in the center of the box.
  final FractionalOffset center;

  /// The radius of the gradient, as a fraction of the shortest side
  /// of the paint box.
  ///
  /// For example, if a radial gradient is painted on a box that is
  /// 100.0 pixels wide and 200.0 pixels tall, then a radius of 1.0
  /// will place the 1.0 stop at 100.0 pixels from the [center].
  final double radius;

  /// The colors the gradient should obtain at each of the stops.
  ///
  /// If [stops] is non-null, this list must have the same length as [stops].
  final List<Color> colors;

  /// A list of values from 0.0 to 1.0 that denote concentric rings.
  ///
  /// The rings are centered at [center] and have a radius equal to the value of
  /// the stop times [radius].
  ///
  /// If non-null, this list must have the same length as [colors]. Otherwise
  /// the colors are distributed evenly between the [center] and the ring at
  /// [radius].
  final List<double> stops;

  /// How this gradient should tile the plane.
  final TileMode tileMode;

  @override
  Shader createShader(Rect rect) {
    return new ui.Gradient.radial(
      center.withinRect(rect),
      radius * rect.shortestSide,
      colors, stops, tileMode
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! RadialGradient)
      return false;
    final RadialGradient typedOther = other;
    if (center != typedOther.center ||
        radius != typedOther.radius ||
        tileMode != typedOther.tileMode ||
        colors?.length != typedOther.colors?.length ||
        stops?.length != typedOther.stops?.length)
      return false;
    if (colors != null) {
      assert(typedOther.colors != null);
      assert(colors.length == typedOther.colors.length);
      for (int i = 0; i < colors.length; i += 1) {
        if (colors[i] != typedOther.colors[i])
          return false;
      }
    }
    if (stops != null) {
      assert(typedOther.stops != null);
      assert(stops.length == typedOther.stops.length);
      for (int i = 0; i < stops.length; i += 1) {
        if (stops[i] != typedOther.stops[i])
          return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => hashValues(center, radius, tileMode, hashList(colors), hashList(stops));

  @override
  String toString() {
    return 'RadialGradient($center, $radius, $colors, $stops, $tileMode)';
  }
}

/// How to paint any portions of a box not covered by an image.
enum ImageRepeat {
  /// Repeat the image in both the x and y directions until the box is filled.
  repeat,

  /// Repeat the image in the x direction until the box is filled horizontally.
  repeatX,

  /// Repeat the image in the y direction until the box is filled vertically.
  repeatY,

  /// Leave uncovered poritions of the box transparent.
  noRepeat
}

Iterable<Rect> _generateImageTileRects(Rect outputRect, Rect fundamentalRect, ImageRepeat repeat) sync* {
  if (repeat == ImageRepeat.noRepeat) {
    yield fundamentalRect;
    return;
  }

  int startX = 0;
  int startY = 0;
  int stopX = 0;
  int stopY = 0;
  final double strideX = fundamentalRect.width;
  final double strideY = fundamentalRect.height;

  if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatX) {
    startX = ((outputRect.left - fundamentalRect.left) / strideX).floor();
    stopX = ((outputRect.right - fundamentalRect.right) / strideX).ceil();
  }

  if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatY) {
    startY = ((outputRect.top - fundamentalRect.top) / strideY).floor();
    stopY = ((outputRect.bottom - fundamentalRect.bottom) / strideY).ceil();
  }

  for (int i = startX; i <= stopX; ++i) {
    for (int j = startY; j <= stopY; ++j)
      yield fundamentalRect.shift(new Offset(i * strideX, j * strideY));
  }
}

/// Paints an image into the given rectangle in the canvas.
///
///  * `canvas`: The canvas onto which the image will be painted.
///  * `rect`: The region of the canvas into which the image will be painted.
///    The image might not fill the entire rectangle (e.g., depending on the
///    `fit`).
///  * `image`: The image to paint onto the canvas.
///  * `colorFilter`: If non-null, the color filter to apply when painting the
///    image.
///  * `fit`: How the image should be inscribed into `rect`. If null, the
///    default behavior depends on `centerSlice`. If `centerSlice` is also null,
///    the default behavior is [BoxFit.scaleDown]. If `centerSlice` is
///    non-null, the default behavior is [BoxFit.fill]. See [BoxFit] for
///    details.
///  * `repeat`: If the image does not fill `rect`, whether and how the image
///    should be repeated to fill `rect`. By default, the image is not repeated.
///    See [ImageRepeat] for details.
///  * `centerSlice`: The image is drawn in nine portions described by splitting
///    the image by drawing two horizontal lines and two vertical lines, where
///    `centerSlice` describes the rectangle formed by the four points where
///    these four lines intersect each other. (This forms a 3-by-3 grid
///    of regions, the center region being described by `centerSlice`.)
///    The four regions in the corners are drawn, without scaling, in the four
///    corners of the destination rectangle defined by applying `fit`. The
///    remaining five regions are drawn by stretching them to fit such that they
///    exactly cover the destination rectangle while maintaining their relative
///    positions.
///  * `alignment`: How the destination rectangle defined by applying `fit` is
///    aligned within `rect`. For example, if `fit` is [BoxFit.contain] and
///    `alignment` is [FractionalOffset.bottomRight], the image will be as large
///    as possible within `rect` and placed with its bottom right corner at the
///    bottom right corner of `rect`.
void paintImage({
  @required Canvas canvas,
  @required Rect rect,
  @required ui.Image image,
  ColorFilter colorFilter,
  BoxFit fit,
  ImageRepeat repeat: ImageRepeat.noRepeat,
  Rect centerSlice,
  FractionalOffset alignment
}) {
  assert(canvas != null);
  assert(image != null);
  Size outputSize = rect.size;
  Size inputSize = new Size(image.width.toDouble(), image.height.toDouble());
  Offset sliceBorder;
  if (centerSlice != null) {
    sliceBorder = new Offset(
      centerSlice.left + inputSize.width - centerSlice.right,
      centerSlice.top + inputSize.height - centerSlice.bottom
    );
    outputSize -= sliceBorder;
    inputSize -= sliceBorder;
  }
  fit ??= centerSlice == null ? BoxFit.scaleDown : BoxFit.fill;
  assert(centerSlice == null || (fit != BoxFit.none && fit != BoxFit.cover));
  final FittedSizes fittedSizes = applyBoxFit(fit, inputSize, outputSize);
  final Size sourceSize = fittedSizes.source;
  Size destinationSize = fittedSizes.destination;
  if (centerSlice != null) {
    outputSize += sliceBorder;
    destinationSize += sliceBorder;
    // We don't have the ability to draw a subset of the image at the same time
    // as we apply a nine-patch stretch.
    assert(sourceSize == inputSize);
  }
  if (repeat != ImageRepeat.noRepeat && destinationSize == outputSize) {
    // There's no need to repeat the image because we're exactly filling the
    // output rect with the image.
    repeat = ImageRepeat.noRepeat;
  }
  final Paint paint = new Paint()..isAntiAlias = false;
  if (colorFilter != null)
    paint.colorFilter = colorFilter;
  if (sourceSize != destinationSize) {
    // Use the "low" quality setting to scale the image, which corresponds to
    // bilinear interpolation, rather than the default "none" which corresponds
    // to nearest-neighbor.
    paint.filterQuality = FilterQuality.low;
  }
  final double dx = (outputSize.width - destinationSize.width) * (alignment?.dx ?? 0.5);
  final double dy = (outputSize.height - destinationSize.height) * (alignment?.dy ?? 0.5);
  final Offset destinationPosition = rect.topLeft.translate(dx, dy);
  final Rect destinationRect = destinationPosition & destinationSize;
  if (repeat != ImageRepeat.noRepeat) {
    canvas.save();
    canvas.clipRect(rect);
  }
  if (centerSlice == null) {
    final Rect sourceRect = (alignment ?? FractionalOffset.center).inscribe(
      fittedSizes.source, Offset.zero & inputSize
    );
    for (Rect tileRect in _generateImageTileRects(rect, destinationRect, repeat))
      canvas.drawImageRect(image, sourceRect, tileRect, paint);
  } else {
    for (Rect tileRect in _generateImageTileRects(rect, destinationRect, repeat))
      canvas.drawImageNine(image, centerSlice, tileRect, paint);
  }
  if (repeat != ImageRepeat.noRepeat)
    canvas.restore();
}

/// A background image for a box.
///
/// The image is painted using [paintImage], which describes the meanings of the
/// various fields on this class in more detail.
@immutable
class BackgroundImage {
  /// Creates a background image.
  ///
  /// The [image] argument must not be null.
  const BackgroundImage({
    this.image,
    this.fit,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.colorFilter,
    this.alignment,
  });

  /// The image to be painted into the background.
  final ImageProvider image;

  /// How the background image should be inscribed into the box.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to paint any portions of the box not covered by the background image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  /// A color filter to apply to the background image before painting it.
  final ColorFilter colorFilter;

  /// How to align the image within its bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the image to the top-left corner of its
  /// layout bounds.  An alignment of (1.0, 0.5) aligns the image to the middle
  /// of the right edge of its layout bounds.
  ///
  /// Defaults to [FractionalOffset.center].
  final FractionalOffset alignment;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BackgroundImage)
      return false;
    final BackgroundImage typedOther = other;
    return image == typedOther.image &&
           fit == typedOther.fit &&
           repeat == typedOther.repeat &&
           centerSlice == typedOther.centerSlice &&
           colorFilter == typedOther.colorFilter &&
           alignment == typedOther.alignment;
  }

  @override
  int get hashCode => hashValues(image, fit, repeat, centerSlice, colorFilter, alignment);

  @override
  String toString() => 'BackgroundImage($image, $fit, $repeat)';
}

/// An immutable description of how to paint a box.
///
/// The following example uses the [Container] widget from the widgets layer to
/// draw a background image with a border:
///
/// ```dart
/// new Container(
///   decoration: new BoxDecoration(
///     backgroundColor: const Color(0xff7c94b6),
///     backgroundImage: new BackgroundImage(
///       image: new ExactAssetImage('images/flowers.jpeg'),
///       fit: BoxFit.cover,
///     ),
///     border: new Border.all(
///       color: Colors.black,
///       width: 8.0,
///     ),
///   ),
/// )
/// ```
class BoxDecoration extends Decoration {
  /// Creates a box decoration.
  ///
  /// * If [backgroundColor] is null, this decoration does not paint a background color.
  /// * If [backgroundImage] is null, this decoration does not paint a background image.
  /// * If [border] is null, this decoration does not paint a border.
  /// * If [borderRadius] is null, this decoration uses more efficient background
  ///   painting commands. The [borderRadius] argument must be be null if [shape] is
  ///   [BoxShape.circle].
  /// * If [boxShadow] is null, this decoration does not paint a shadow.
  /// * If [gradient] is null, this decoration does not paint gradients.
  const BoxDecoration({
    this.backgroundColor,
    this.backgroundImage,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.shape: BoxShape.rectangle
  });

  @override
  bool debugAssertIsValid() {
    assert(shape != BoxShape.circle ||
           borderRadius == null); // Can't have a border radius if you're a circle.
    return super.debugAssertIsValid();
  }

  /// The color to fill in the background of the box.
  ///
  /// The color is filled into the shape of the box (e.g., either a rectangle,
  /// potentially with a border radius, or a circle).
  final Color backgroundColor;

  /// An image to paint above the background color. If [shape] is [BoxShape.circle]
  /// then the image is clipped to the circle's boundary.
  final BackgroundImage backgroundImage;

  /// A border to draw above the background.
  final Border border;

  /// If non-null, the corners of this box are rounded by this [BorderRadius].
  ///
  /// Applies only to boxes with rectangular shapes.
  final BorderRadius borderRadius;

  /// A list of shadows cast by this box behind the background.
  final List<BoxShadow> boxShadow;

  /// A gradient to use when filling the background.
  final Gradient gradient;

  /// The shape to fill the background color into and to cast as a shadow.
  final BoxShape shape;

  /// The inset space occupied by the border.
  @override
  EdgeInsets get padding => border?.dimensions;

  /// Returns a new box decoration that is scaled by the given factor.
  BoxDecoration scale(double factor) {
    // TODO(abarth): Scale ALL the things.
    return new BoxDecoration(
      backgroundColor: Color.lerp(null, backgroundColor, factor),
      backgroundImage: backgroundImage,
      border: Border.lerp(null, border, factor),
      borderRadius: BorderRadius.lerp(null, borderRadius, factor),
      boxShadow: BoxShadow.lerpList(null, boxShadow, factor),
      gradient: gradient,
      shape: shape
    );
  }

  @override
  bool get isComplex => boxShadow != null;

  /// Linearly interpolate between two box decorations.
  ///
  /// Interpolates each parameter of the box decoration separately.
  ///
  /// See also [Decoration.lerp].
  static BoxDecoration lerp(BoxDecoration a, BoxDecoration b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    // TODO(abarth): lerp ALL the fields.
    return new BoxDecoration(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      backgroundImage: b.backgroundImage,
      border: Border.lerp(a.border, b.border, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      boxShadow: BoxShadow.lerpList(a.boxShadow, b.boxShadow, t),
      gradient: b.gradient,
      shape: b.shape
    );
  }

  @override
  BoxDecoration lerpFrom(Decoration a, double t) {
    if (a is! BoxDecoration)
      return BoxDecoration.lerp(null, this, t);
    return BoxDecoration.lerp(a, this, t);
  }

  @override
  BoxDecoration lerpTo(Decoration b, double t) {
    if (b is! BoxDecoration)
      return BoxDecoration.lerp(this, null, t);
    return BoxDecoration.lerp(this, b, t);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BoxDecoration)
      return false;
    final BoxDecoration typedOther = other;
    return backgroundColor == typedOther.backgroundColor &&
           backgroundImage == typedOther.backgroundImage &&
           border == typedOther.border &&
           borderRadius == typedOther.borderRadius &&
           boxShadow == typedOther.boxShadow &&
           gradient == typedOther.gradient &&
           shape == typedOther.shape;
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      backgroundImage,
      border,
      borderRadius,
      boxShadow,
      gradient,
      shape
    );
  }

  /// Stringifies the BoxDecoration. By default, the output will be on one line.
  /// If the method is passed a non-empty string argument, then the output will
  /// span multiple lines, each prefixed by that argument.
  @override
  String toString([String prefix = '', String indentPrefix]) {
    final List<String> result = <String>[];
    if (backgroundColor != null)
      result.add('${prefix}backgroundColor: $backgroundColor');
    if (backgroundImage != null)
      result.add('${prefix}backgroundImage: $backgroundImage');
    if (border != null)
      result.add('${prefix}border: $border');
    if (borderRadius != null)
      result.add('${prefix}borderRadius: $borderRadius');
    if (boxShadow != null) {
      if (indentPrefix != null && boxShadow.length > 1) {
        result.add('${prefix}boxShadow:');
        for (BoxShadow shadow in boxShadow)
          result.add('$indentPrefix$shadow');
      } else {
        result.add('${prefix}boxShadow: ${boxShadow.map((BoxShadow shadow) => shadow.toString()).join(", ")}');
      }
    }
    if (gradient != null)
      result.add('${prefix}gradient: $gradient');
    if (shape != BoxShape.rectangle)
      result.add('${prefix}shape: $shape');
    if (prefix == '')
      return '$runtimeType(${result.join(', ')})';
    if (result.isEmpty)
      return '$prefix<no decorations specified>';
    return result.join('\n');
  }

  @override
  bool hitTest(Size size, Offset position) {
    assert(shape != null);
    assert((Offset.zero & size).contains(position));
    switch (shape) {
      case BoxShape.rectangle:
        if (borderRadius != null) {
          final RRect bounds = borderRadius.toRRect(Offset.zero & size);
          return bounds.contains(position);
        }
        return true;
      case BoxShape.circle:
        // Circles are inscribed into our smallest dimension.
        final Offset center = size.center(Offset.zero);
        final double distance = (position - center).distance;
        return distance <= math.min(size.width, size.height) / 2.0;
    }
    assert(shape != null);
    return null;
  }

  @override
  _BoxDecorationPainter createBoxPainter([VoidCallback onChanged]) {
    assert(onChanged != null || backgroundImage == null);
    return new _BoxDecorationPainter(this, onChanged);
  }
}

/// An object that paints a [BoxDecoration] into a canvas.
class _BoxDecorationPainter extends BoxPainter {
  _BoxDecorationPainter(@required this._decoration, VoidCallback onChange) : super(onChange) {
    assert(_decoration != null);
  }

  final BoxDecoration _decoration;

  Paint _cachedBackgroundPaint;
  Rect _rectForCachedBackgroundPaint;
  Paint _getBackgroundPaint(Rect rect) {
    assert(rect != null);
    if (_cachedBackgroundPaint == null ||
        (_decoration.gradient == null && _rectForCachedBackgroundPaint != null) ||
        (_decoration.gradient != null && _rectForCachedBackgroundPaint != rect)) {
      final Paint paint = new Paint();

      if (_decoration.backgroundColor != null)
        paint.color = _decoration.backgroundColor;

      if (_decoration.gradient != null) {
        paint.shader = _decoration.gradient.createShader(rect);
        _rectForCachedBackgroundPaint = rect;
      } else {
        _rectForCachedBackgroundPaint = null;
      }

      _cachedBackgroundPaint = paint;
    }

    return _cachedBackgroundPaint;
  }

  void _paintBox(Canvas canvas, Rect rect, Paint paint) {
    switch (_decoration.shape) {
      case BoxShape.circle:
        assert(_decoration.borderRadius == null);
        final Offset center = rect.center;
        final double radius = rect.shortestSide / 2.0;
        canvas.drawCircle(center, radius, paint);
        break;
      case BoxShape.rectangle:
        if (_decoration.borderRadius == null) {
          canvas.drawRect(rect, paint);
        } else {
          canvas.drawRRect(_decoration.borderRadius.toRRect(rect), paint);
        }
        break;
    }
  }

  void _paintShadows(Canvas canvas, Rect rect) {
    if (_decoration.boxShadow == null)
      return;
    for (BoxShadow boxShadow in _decoration.boxShadow) {
      final Paint paint = new Paint()
        ..color = boxShadow.color
        ..maskFilter = new MaskFilter.blur(BlurStyle.normal, boxShadow.blurSigma);
      final Rect bounds = rect.shift(boxShadow.offset).inflate(boxShadow.spreadRadius);
      _paintBox(canvas, bounds, paint);
    }
  }

  void _paintBackgroundColor(Canvas canvas, Rect rect) {
    if (_decoration.backgroundColor != null || _decoration.gradient != null)
      _paintBox(canvas, rect, _getBackgroundPaint(rect));
  }

  ImageStream _imageStream;
  ImageInfo _image;

  void _paintBackgroundImage(Canvas canvas, Rect rect, ImageConfiguration configuration) {
    final BackgroundImage backgroundImage = _decoration.backgroundImage;
    if (backgroundImage == null)
      return;
    final ImageStream newImageStream = backgroundImage.image.resolve(configuration);
    if (newImageStream.key != _imageStream?.key) {
      _imageStream?.removeListener(_imageListener);
      _imageStream = newImageStream;
      _imageStream.addListener(_imageListener);
    }
    final ui.Image image = _image?.image;
    if (image == null)
      return;

    Path clipPath;
    if (_decoration.shape == BoxShape.circle)
      clipPath = new Path()..addOval(rect);
    else if (_decoration.borderRadius != null)
      clipPath = new Path()..addRRect(_decoration.borderRadius.toRRect(rect));
    if (clipPath != null) {
      canvas.save();
      canvas.clipPath(clipPath);
    }

    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      colorFilter: backgroundImage.colorFilter,
      alignment: backgroundImage.alignment,
      fit: backgroundImage.fit,
      repeat: backgroundImage.repeat
    );

    if (clipPath != null)
      canvas.restore();
  }

  void _imageListener(ImageInfo value, bool synchronousCall) {
    if (_image == value)
      return;
    _image = value;
    assert(onChanged != null);
    if (!synchronousCall)
      onChanged();
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    _imageStream = null;
    _image = null;
    super.dispose();
  }

  /// Paint the box decoration into the given location on the given canvas
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size;
    _paintShadows(canvas, rect);
    _paintBackgroundColor(canvas, rect);
    _paintBackgroundImage(canvas, rect, configuration);
    _decoration.border?.paint(
      canvas,
      rect,
      shape: _decoration.shape,
      borderRadius: _decoration.borderRadius
    );
  }
}
