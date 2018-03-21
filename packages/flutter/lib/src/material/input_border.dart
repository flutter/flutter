// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Defines the appearance of an [InputDecorator]'s border.
///
/// An input decorator's border is specified by [InputDecoration.border].
///
/// The border is drawn relative to the input decorator's "container" which
/// is the optionally filled area above the decorator's helper, error,
/// and counter.
///
/// Input border's are decorated with a line whose weight and color are defined
/// by [borderSide]. The input decorator's renderer animates the input border's
/// appearance in response to state changes, like gaining or losing the focus,
/// by creating new copies of its input border with [copyWith].
///
/// See also:
///
///  * [UnderlineInputBorder], the default [InputDecorator] border which
///    draws a horizontal line at the bottom of the input decorator's container.
///  * [OutlineInputBorder], an [InputDecorator] border which draws a
///    rounded rectangle around the input decorator's container.
///  * [InputDecoration], which is used to configure an [InputDecorator].
abstract class InputBorder extends ShapeBorder {
  /// No input border.
  ///
  /// Use this value with [InputDecoration.border] to specify that no border
  /// should be drawn. The [InputDecoration.collapsed] constructor sets
  /// its border to this value.
  static const InputBorder none = const _NoInputBorder();

  /// Creates a border for an [InputDecorator].
  ///
  /// The [borderSide] parameter must not be null. Applications typically do
  /// not specify a [borderSide] parameter because the input decorator
  /// substitutes its own, using [copyWith], based on the current theme and
  /// [InputDecorator.isFocused].
  const InputBorder({
    this.borderSide: BorderSide.none,
  }) : assert(borderSide != null);

  /// Defines the border line's color and weight.
  ///
  /// The [InputDecorator] creates copies of its input border, using [copyWith],
  /// based on the current theme and [InputDecorator.isFocused].
  final BorderSide borderSide;

  /// Creates a copy of this input border with the specified `borderSide`.
  InputBorder copyWith({ BorderSide borderSide });

  /// True if this border will enclose the [InputDecorator]'s container.
  ///
  /// This property affects the alignment of container's contents. For example
  /// when an input decorator is configured with an [OutlineInputBorder] its
  /// label is centered with its container.
  bool get isOutline;

  /// Paint this input border on [canvas].
  ///
  /// The [rect] parameter bounds the [InputDecorator]'s container.
  ///
  /// The additional `gap` parameters reflect the state of the [InputDecorator]'s
  /// floating label. When an input decorator gains the focus, its label
  /// animates upwards, to make room for the input child. The [gapStart] and
  /// [gapExtent] parameters define a floating label width interval, and
  /// [gapPercentage] defines the animation's progress (0.0 to 1.0).
  @override
  void paint(Canvas canvas, Rect rect, {
      double gapStart,
      double gapExtent: 0.0,
      double gapPercentage: 0.0,
      TextDirection textDirection,
  });
}

// Used to create the InputBorder.none singleton.
class _NoInputBorder extends InputBorder {
  const _NoInputBorder() : super(borderSide: BorderSide.none);

  @override
  _NoInputBorder copyWith({ BorderSide borderSide }) => const _NoInputBorder();

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  _NoInputBorder scale(double t) => const _NoInputBorder();

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return new Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {
      double gapStart,
      double gapExtent: 0.0,
      double gapPercentage: 0.0,
      TextDirection textDirection,
  }) {
    // Do not paint.
  }
}

/// Draws a horizontal line at the bottom of an [InputDecorator]'s container.
///
/// The input decorator's "container" is the optionally filled area above the
/// decorator's helper, error, and counter.
///
/// See also:
///
///  * [OutlineInputBorder], an [InputDecorator] border which draws a
///    rounded rectangle around the input decorator's container.
///  * [InputDecoration], which is used to configure an [InputDecorator].
class UnderlineInputBorder extends InputBorder {
  /// Creates an underline border for an [InputDecorator].
  ///
  /// The [borderSide] parameter defaults to [BorderSide.none] (it must not be
  /// null). Applications typically do not specify a [borderSide] parameter
  /// because the input decorator substitutes its own, using [copyWith], based
  /// on the current theme and [InputDecorator.isFocused].
  const UnderlineInputBorder({
    BorderSide borderSide: BorderSide.none,
  }) : super(borderSide: borderSide);

  @override
  bool get isOutline => false;

  @override
  UnderlineInputBorder copyWith({ BorderSide borderSide }) {
    return new UnderlineInputBorder(borderSide: borderSide ?? this.borderSide);
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return new EdgeInsets.only(bottom: borderSide.width);
  }

  @override
  UnderlineInputBorder scale(double t) {
    return new UnderlineInputBorder(borderSide: borderSide.scale(t));
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRect(new Rect.fromLTWH(rect.left, rect.top, rect.width, math.max(0.0, rect.height - borderSide.width)));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()..addRect(rect);
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is UnderlineInputBorder) {
      return new UnderlineInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is UnderlineInputBorder) {
      return new UnderlineInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
      );
    }
    return super.lerpTo(b, t);
  }

  /// Draw a horizontal line at the bottom of [rect].
  ///
  /// The [borderSide] defines the line's color and weight. The `textDirection`
  /// `gap` and `textDirection` parameters are ignored.
  @override
  void paint(Canvas canvas, Rect rect, {
      double gapStart,
      double gapExtent: 0.0,
      double gapPercentage: 0.0,
      TextDirection textDirection,
  }) {
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, borderSide.toPaint());
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final InputBorder typedOther = other;
    return typedOther.borderSide == borderSide;
  }

  @override
  int get hashCode => borderSide.hashCode;
}

/// Draws a rounded rectangle around an [InputDecorator]'s container.
///
/// When the input decorator's label is floating, for example because its
/// input child has the focus, the label appears in a gap in the border outline.
///
/// The input decorator's "container" is the optionally filled area above the
/// decorator's helper, error, and counter.
///
/// See also:
///
///  * [UnderlineInputBorder], the default [InputDecorator] border which
///    draws a horizontal line at the bottom of the input decorator's container.
///  * [InputDecoration], which is used to configure an [InputDecorator].
class OutlineInputBorder extends InputBorder {
  /// Creates a rounded rectangle outline border for an [InputDecorator].
  ///
  /// The [borderSide] parameter defaults to [BorderSide.none] (it must not be
  /// null). Applications typically do not specify a [borderSide] parameter
  /// because the input decorator substitutes its own, using [copyWith], based
  /// on the current theme and [InputDecorator.isFocused].
  ///
  /// If [borderRadius] is null (the default) then the border's corners
  /// are drawn with a radius of 4 logical pixels. The corner radii must be
  /// circular, i.e. their [Radius.x] and [Radius.y] values must be the same.
  const OutlineInputBorder({
    BorderSide borderSide: BorderSide.none,
    this.borderRadius: const BorderRadius.all(const Radius.circular(4.0)),
    this.gapPadding: 4.0,
  }) : assert(borderRadius != null),
       assert(gapPadding != null && gapPadding >= 0.0),
       super(borderSide: borderSide);

  // The label text's gap can extend into the corners (even both the top left
  // and the top right corner). To avoid the more complicated problem of finding
  // how far the gap penetrates into an elliptical corner, just require them
  // to be circular.
  //
  // This can't be checked by the constructor because const constructor.
  static bool _cornersAreCircular(BorderRadius borderRadius) {
    return borderRadius.topLeft.x == borderRadius.topLeft.y
        && borderRadius.bottomLeft.x == borderRadius.bottomLeft.y
        && borderRadius.topRight.x == borderRadius.topRight.y
        && borderRadius.bottomRight.x == borderRadius.bottomRight.y;
  }

  /// Horizontal padding on either side of the border's
  /// [InputDecoration.labelText] width gap.
  ///
  /// This value is used by the [paint] method to compute the actual gap width.
  final double gapPadding;

  /// The radii of the border's rounded rectangle corners.
  ///
  /// The corner radii must be circular, i.e. their [Radius.x] and [Radius.y]
  /// values must be the same.
  final BorderRadius borderRadius;

  @override
  bool get isOutline => true;

  @override
  OutlineInputBorder copyWith({
    BorderSide borderSide,
    BorderRadius borderRadius,
    double gapPadding,
  }) {
    return new OutlineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return new EdgeInsets.all(borderSide.width);
  }

  @override
  OutlineInputBorder scale(double t) {
    return new OutlineInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPadding: gapPadding * t,
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is OutlineInputBorder) {
      final OutlineInputBorder outline = a;
      return new OutlineInputBorder(
        borderRadius: BorderRadius.lerp(outline.borderRadius, borderRadius, t),
        borderSide: BorderSide.lerp(outline.borderSide, borderSide, t),
        gapPadding: outline.gapPadding,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is OutlineInputBorder) {
      final OutlineInputBorder outline = b;
      return new OutlineInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, outline.borderRadius, t),
        borderSide: BorderSide.lerp(borderSide, outline.borderSide, t),
        gapPadding: outline.gapPadding,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  Path _gapBorderPath(Canvas canvas, RRect center, double start, double extent) {
    final Rect tlCorner = new Rect.fromLTWH(
      center.left,
      center.top,
      center.tlRadiusX * 2.0,
      center.tlRadiusY * 2.0,
    );
    final Rect trCorner = new Rect.fromLTWH(
      center.right - center.trRadiusX * 2.0,
      center.top,
      center.trRadiusX * 2.0,
      center.trRadiusY * 2.0,
    );
    final Rect brCorner = new Rect.fromLTWH(
      center.right - center.brRadiusX * 2.0,
      center.bottom - center.brRadiusY * 2.0,
      center.brRadiusX * 2.0,
      center.brRadiusY * 2.0,
    );
    final Rect blCorner = new Rect.fromLTWH(
      center.left,
      center.bottom - center.brRadiusY * 2.0,
      center.blRadiusX * 2.0,
      center.blRadiusY * 2.0,
    );

    const double cornerArcSweep = math.pi / 2.0;
    final double tlCornerArcSweep = start < center.tlRadiusX
      ? math.asin(start / center.tlRadiusX)
      : math.pi / 2.0;

    final Path path = new Path()
      ..addArc(tlCorner, math.pi, tlCornerArcSweep)
      ..moveTo(center.left + center.tlRadiusX, center.top);

    if (start > center.tlRadiusX)
      path.lineTo(center.left + start, center.top);

    const double trCornerArcStart = (3 * math.pi) / 2.0;
    const double trCornerArcSweep = cornerArcSweep;
    if (start + extent < center.width - center.trRadiusX) {
      path
        ..relativeMoveTo(extent, 0.0)
        ..lineTo(center.right - center.trRadiusX, center.top)
        ..addArc(trCorner, trCornerArcStart, trCornerArcSweep);
    } else if (start + extent < center.width) {
      final double dx = center.width - (start + extent);
      final double sweep = math.acos(dx / center.trRadiusX);
      path.addArc(trCorner, trCornerArcStart + sweep, trCornerArcSweep - sweep);
    }

    return path
      ..moveTo(center.right, center.top + center.trRadiusY)
      ..lineTo(center.right, center.bottom - center.brRadiusY)
      ..addArc(brCorner, 0.0, cornerArcSweep)
      ..lineTo(center.left + center.blRadiusX, center.bottom)
      ..addArc(blCorner, math.pi / 2.0, cornerArcSweep)
      ..lineTo(center.left, center.top + center.trRadiusY);
  }

  /// Draw a rounded rectangle around [rect] using [borderRadius].
  ///
  /// The [borderSide] defines the line's color and weight.
  ///
  /// The top side of the rounded rectangle may be interrupted by a single gap
  /// if [gapExtent] is non-null. In that case the gap begins at
  /// `gapStart - gapPadding` (assuming that the [textDirection] is [TextDirection.ltr]).
  /// The gap's width is `(gapPadding + gapExtent + gapPadding) * gapPercentage`.
  @override
  void paint(Canvas canvas, Rect rect, {
      double gapStart,
      double gapExtent: 0.0,
      double gapPercentage: 0.0,
      TextDirection textDirection,
  }) {
    assert(gapExtent != null);
    assert(gapPercentage >= 0.0 && gapPercentage <= 1.0);
    assert(_cornersAreCircular(borderRadius));

    final Paint paint = borderSide.toPaint();
    final RRect outer = borderRadius.toRRect(rect);
    final RRect center = outer.deflate(borderSide.width / 2.0);
    if (gapStart == null || gapExtent <= 0.0 || gapPercentage == 0.0) {
      canvas.drawRRect(center, paint);
    } else {
      final double extent = lerpDouble(0.0, gapExtent + gapPadding * 2.0, gapPercentage);
      switch (textDirection) {
        case TextDirection.rtl: {
          final Path path = _gapBorderPath(canvas, center, gapStart + gapPadding - extent, extent);
          canvas.drawPath(path, paint);
          break;
        }
        case TextDirection.ltr: {
          final Path path = _gapBorderPath(canvas, center, gapStart - gapPadding, extent);
          canvas.drawPath(path, paint);
          break;
        }
      }
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final OutlineInputBorder typedOther = other;
    return typedOther.borderSide == borderSide
        && typedOther.borderRadius == borderRadius
        && typedOther.gapPadding == gapPadding;
  }

  @override
  int get hashCode => hashValues(borderSide, borderRadius, gapPadding);
}
