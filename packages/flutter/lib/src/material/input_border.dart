// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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
  /// Creates a border for an [InputDecorator].
  ///
  /// The [borderSide] parameter must not be null. Applications typically do
  /// not specify a [borderSide] parameter because the input decorator
  /// substitutes its own, using [copyWith], based on the current theme and
  /// [InputDecorator.isFocused].
  const InputBorder({
    this.borderSide = BorderSide.none,
  }) : assert(borderSide != null);

  /// No input border.
  ///
  /// Use this value with [InputDecoration.border] to specify that no border
  /// should be drawn. The [InputDecoration.collapsed] constructor sets
  /// its border to this value.
  static const InputBorder none = _NoInputBorder();

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
  void paint(
    Canvas canvas,
    Rect rect, {
    double gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
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
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return Path()..addRect(rect);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection textDirection,
  }) {
    // Do not paint.
  }
}

/// Draws a horizontal line at the bottom of an [InputDecorator]'s container and
/// defines the container's shape.
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
  ///
  /// The [borderRadius] parameter defaults to a value where the top left
  /// and right corners have a circular radius of 4.0. The [borderRadius]
  /// parameter must not be null.
  const UnderlineInputBorder({
    BorderSide borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(4.0),
      topRight: Radius.circular(4.0),
    ),
  }) : assert(borderRadius != null),
       super(borderSide: borderSide);

  /// The radii of the border's rounded rectangle corners.
  ///
  /// When this border is used with a filled input decorator, see
  /// [InputDecoration.filled], the border radius defines the shape
  /// of the background fill as well as the bottom left and right
  /// edges of the underline itself.
  ///
  /// By default the top right and top left corners have a circular radius
  /// of 4.0.
  final BorderRadius borderRadius;

  @override
  bool get isOutline => false;

  @override
  UnderlineInputBorder copyWith({ BorderSide borderSide, BorderRadius borderRadius }) {
    return UnderlineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.only(bottom: borderSide.width);
  }

  @override
  UnderlineInputBorder scale(double t) {
    return UnderlineInputBorder(borderSide: borderSide.scale(t));
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return Path()
      ..addRect(Rect.fromLTWH(rect.left, rect.top, rect.width, math.max(0.0, rect.height - borderSide.width)));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is UnderlineInputBorder) {
      return UnderlineInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is UnderlineInputBorder) {
      return UnderlineInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t),
      );
    }
    return super.lerpTo(b, t);
  }

  /// Draw a horizontal line at the bottom of [rect].
  ///
  /// The [borderSide] defines the line's color and weight. The `textDirection`
  /// `gap` and `textDirection` parameters are ignored.
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection textDirection,
  }) {
    if (borderRadius.bottomLeft != Radius.zero || borderRadius.bottomRight != Radius.zero)
      canvas.clipPath(getOuterPath(rect, textDirection: textDirection));
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, borderSide.toPaint());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is InputBorder
        && other.borderSide == borderSide;
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
  /// If the [borderSide] parameter is [BorderSide.none], it will not draw a
  /// border. However, it will still define a shape (which you can see if
  /// [InputDecoration.filled] is true).
  ///
  /// If an application does not specify a [borderSide] parameter of
  /// value [BorderSide.none], the input decorator substitutes its own, using
  /// [copyWith], based on the current theme and [InputDecorator.isFocused].
  ///
  /// The [borderRadius] parameter defaults to a value where all four
  /// corners have a circular radius of 4.0. The [borderRadius] parameter
  /// must not be null and the corner radii must be circular, i.e. their
  /// [Radius.x] and [Radius.y] values must be the same.
  ///
  /// See also:
  ///
  ///  * [InputDecoration.hasFloatingPlaceholder], which should be set to false
  ///    when the [borderSide] is [BorderSide.none]. If let as true, the label
  ///    will extend beyond the container as if the border were still being
  ///    drawn.
  const OutlineInputBorder({
    BorderSide borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.gapPadding = 4.0,
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
    return OutlineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(borderSide.width);
  }

  @override
  OutlineInputBorder scale(double t) {
    return OutlineInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPadding: gapPadding * t,
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is OutlineInputBorder) {
      final OutlineInputBorder outline = a;
      return OutlineInputBorder(
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
      return OutlineInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, outline.borderRadius, t),
        borderSide: BorderSide.lerp(borderSide, outline.borderSide, t),
        gapPadding: outline.gapPadding,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  Path _gapBorderPath(Canvas canvas, RRect center, double start, double extent) {
    // When the corner radii on any side add up to be greater than the
    // given height, each radius has to be scaled to not exceed the
    // size of the width/height of the RRect.
    final RRect scaledRRect = center.scaleRadii();

    final Rect tlCorner = Rect.fromLTWH(
      scaledRRect.left,
      scaledRRect.top,
      scaledRRect.tlRadiusX * 2.0,
      scaledRRect.tlRadiusY * 2.0,
    );
    final Rect trCorner = Rect.fromLTWH(
      scaledRRect.right - scaledRRect.trRadiusX * 2.0,
      scaledRRect.top,
      scaledRRect.trRadiusX * 2.0,
      scaledRRect.trRadiusY * 2.0,
    );
    final Rect brCorner = Rect.fromLTWH(
      scaledRRect.right - scaledRRect.brRadiusX * 2.0,
      scaledRRect.bottom - scaledRRect.brRadiusY * 2.0,
      scaledRRect.brRadiusX * 2.0,
      scaledRRect.brRadiusY * 2.0,
    );
    final Rect blCorner = Rect.fromLTWH(
      scaledRRect.left,
      scaledRRect.bottom - scaledRRect.blRadiusY * 2.0,
      scaledRRect.blRadiusX * 2.0,
      scaledRRect.blRadiusX * 2.0,
    );

    const double cornerArcSweep = math.pi / 2.0;
    final double tlCornerArcSweep = start < scaledRRect.tlRadiusX
      ? math.asin((start / scaledRRect.tlRadiusX).clamp(-1.0, 1.0))
      : math.pi / 2.0;

    final Path path = Path()
      ..addArc(tlCorner, math.pi, tlCornerArcSweep)
      ..moveTo(scaledRRect.left + scaledRRect.tlRadiusX, scaledRRect.top);

    if (start > scaledRRect.tlRadiusX)
      path.lineTo(scaledRRect.left + start, scaledRRect.top);

    const double trCornerArcStart = (3 * math.pi) / 2.0;
    const double trCornerArcSweep = cornerArcSweep;
    if (start + extent < scaledRRect.width - scaledRRect.trRadiusX) {
      path
        ..relativeMoveTo(extent, 0.0)
        ..lineTo(scaledRRect.right - scaledRRect.trRadiusX, scaledRRect.top)
        ..addArc(trCorner, trCornerArcStart, trCornerArcSweep);
    } else if (start + extent < scaledRRect.width) {
      final double dx = scaledRRect.width - (start + extent);
      final double sweep = math.acos(dx / scaledRRect.trRadiusX);
      path.addArc(trCorner, trCornerArcStart + sweep, trCornerArcSweep - sweep);
    }

    return path
      ..moveTo(scaledRRect.right, scaledRRect.top + scaledRRect.trRadiusY)
      ..lineTo(scaledRRect.right, scaledRRect.bottom - scaledRRect.brRadiusY)
      ..addArc(brCorner, 0.0, cornerArcSweep)
      ..lineTo(scaledRRect.left + scaledRRect.blRadiusX, scaledRRect.bottom)
      ..addArc(blCorner, math.pi / 2.0, cornerArcSweep)
      ..lineTo(scaledRRect.left, scaledRRect.top + scaledRRect.tlRadiusY);
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
  void paint(
    Canvas canvas,
    Rect rect, {
    double gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
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
        case TextDirection.rtl:
          final Path path = _gapBorderPath(canvas, center, math.max(0.0, gapStart + gapPadding - extent), extent);
          canvas.drawPath(path, paint);
          break;

        case TextDirection.ltr:
          final Path path = _gapBorderPath(canvas, center, math.max(0.0, gapStart - gapPadding), extent);
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is OutlineInputBorder
        && other.borderSide == borderSide
        && other.borderRadius == borderRadius
        && other.gapPadding == gapPadding;
  }

  @override
  int get hashCode => hashValues(borderSide, borderRadius, gapPadding);
}
