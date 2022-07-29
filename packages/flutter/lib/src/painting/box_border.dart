// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'border_radius.dart';
import 'borders.dart';
import 'edge_insets.dart';

// Examples can assume:
// late BuildContext context;

/// The shape to use when rendering a [Border] or [BoxDecoration].
///
/// Consider using [ShapeBorder] subclasses directly (with [ShapeDecoration]),
/// instead of using [BoxShape] and [Border], if the shapes will need to be
/// interpolated or animated. The [Border] class cannot interpolate between
/// different shapes.
enum BoxShape {
  /// An axis-aligned, 2D rectangle. May have rounded corners (described by a
  /// [BorderRadius]). The edges of the rectangle will match the edges of the box
  /// into which the [Border] or [BoxDecoration] is painted.
  ///
  /// See also:
  ///
  ///  * [RoundedRectangleBorder], the equivalent [ShapeBorder].
  rectangle,

  /// A circle centered in the middle of the box into which the [Border] or
  /// [BoxDecoration] is painted. The diameter of the circle is the shortest
  /// dimension of the box, either the width or the height, such that the circle
  /// touches the edges of the box.
  ///
  /// See also:
  ///
  ///  * [CircleBorder], the equivalent [ShapeBorder].
  circle,

  // Don't add more, instead create a new ShapeBorder.
}

/// Base class for box borders that can paint as rectangles, circles, or rounded
/// rectangles.
///
/// This class is extended by [Border] and [BorderDirectional] to provide
/// concrete versions of four-sided borders using different conventions for
/// specifying the sides.
///
/// The only API difference that this class introduces over [ShapeBorder] is
/// that its [paint] method takes additional arguments.
///
/// See also:
///
///  * [BorderSide], which is used to describe each side of the box.
///  * [RoundedRectangleBorder], another way of describing a box's border.
///  * [CircleBorder], another way of describing a circle border.
///  * [BoxDecoration], which uses a [BoxBorder] to describe its borders.
abstract class BoxBorder extends ShapeBorder {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const BoxBorder();

  /// The top side of this border.
  ///
  /// This getter is available on both [Border] and [BorderDirectional]. If
  /// [isUniform] is true, then this is the same style as all the other sides.
  BorderSide get top;

  /// The bottom side of this border.
  BorderSide get bottom;

  /// Whether all four sides of the border are identical. Uniform borders are
  /// typically more efficient to paint.
  ///
  /// A uniform border by definition has no text direction dependency and
  /// therefore could be expressed as a [Border], even if it is currently a
  /// [BorderDirectional]. A uniform border can also be expressed as a
  /// [RoundedRectangleBorder].
  bool get isUniform;

  // We override this to tighten the return value, so that callers can assume
  // that we'll return a [BoxBorder].
  @override
  BoxBorder? add(ShapeBorder other, { bool reversed = false }) => null;

  /// Linearly interpolate between two borders.
  ///
  /// If a border is null, it is treated as having four [BorderSide.none]
  /// borders.
  ///
  /// This supports interpolating between [Border] and [BorderDirectional]
  /// objects. If both objects are different types but both have sides on one or
  /// both of their lateral edges (the two sides that aren't the top and bottom)
  /// other than [BorderSide.none], then the sides are interpolated by reducing
  /// `a`'s lateral edges to [BorderSide.none] over the first half of the
  /// animation, and then bringing `b`'s lateral edges _from_ [BorderSide.none]
  /// over the second half of the animation.
  ///
  /// For a more flexible approach, consider [ShapeBorder.lerp], which would
  /// instead [add] the two sets of sides and interpolate them simultaneously.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static BoxBorder? lerp(BoxBorder? a, BoxBorder? b, double t) {
    assert(t != null);
    if ((a is Border?) && (b is Border?)) {
      return Border.lerp(a, b, t);
    }
    if ((a is BorderDirectional?) && (b is BorderDirectional?)) {
      return BorderDirectional.lerp(a, b, t);
    }
    if (b is Border && a is BorderDirectional) {
      final BoxBorder c = b;
      b = a;
      a = c;
      t = 1.0 - t;
      // fall through to next case
    }
    if (a is Border && b is BorderDirectional) {
      if (b.start == BorderSide.none && b.end == BorderSide.none) {
        // The fact that b is a BorderDirectional really doesn't matter, it turns out.
        return Border(
          top: BorderSide.lerp(a.top, b.top, t),
          right: BorderSide.lerp(a.right, BorderSide.none, t),
          bottom: BorderSide.lerp(a.bottom, b.bottom, t),
          left: BorderSide.lerp(a.left, BorderSide.none, t),
        );
      }
      if (a.left == BorderSide.none && a.right == BorderSide.none) {
        // The fact that a is a Border really doesn't matter, it turns out.
        return BorderDirectional(
          top: BorderSide.lerp(a.top, b.top, t),
          start: BorderSide.lerp(BorderSide.none, b.start, t),
          end: BorderSide.lerp(BorderSide.none, b.end, t),
          bottom: BorderSide.lerp(a.bottom, b.bottom, t),
        );
      }
      // Since we have to swap a visual border for a directional one,
      // we speed up the horizontal sides' transitions and switch from
      // one mode to the other at t=0.5.
      if (t < 0.5) {
        return Border(
          top: BorderSide.lerp(a.top, b.top, t),
          right: BorderSide.lerp(a.right, BorderSide.none, t * 2.0),
          bottom: BorderSide.lerp(a.bottom, b.bottom, t),
          left: BorderSide.lerp(a.left, BorderSide.none, t * 2.0),
        );
      }
      return BorderDirectional(
        top: BorderSide.lerp(a.top, b.top, t),
        start: BorderSide.lerp(BorderSide.none, b.start, (t - 0.5) * 2.0),
        end: BorderSide.lerp(BorderSide.none, b.end, (t - 0.5) * 2.0),
        bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      );
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('BoxBorder.lerp can only interpolate Border and BorderDirectional classes.'),
      ErrorDescription(
        'BoxBorder.lerp() was called with two objects of type ${a.runtimeType} and ${b.runtimeType}:\n'
        '  $a\n'
        '  $b\n'
        'However, only Border and BorderDirectional classes are supported by this method.',
      ),
      ErrorHint('For a more general interpolation method, consider using ShapeBorder.lerp instead.'),
    ]);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection? textDirection }) {
    assert(textDirection != null, 'The textDirection argument to $runtimeType.getInnerPath must not be null.');
    return Path()
      ..addRect(dimensions.resolve(textDirection).deflateRect(rect));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection? textDirection }) {
    assert(textDirection != null, 'The textDirection argument to $runtimeType.getOuterPath must not be null.');
    return Path()
      ..addRect(rect);
  }

  /// Paints the border within the given [Rect] on the given [Canvas].
  ///
  /// This is an extension of the [ShapeBorder.paint] method. It allows
  /// [BoxBorder] borders to be applied to different [BoxShape]s and with
  /// different [borderRadius] parameters, without changing the [BoxBorder]
  /// object itself.
  ///
  /// The `shape` argument specifies the [BoxShape] to draw the border on.
  ///
  /// If the `shape` is specifies a rectangular box shape
  /// ([BoxShape.rectangle]), then the `borderRadius` argument describes the
  /// corners of the rectangle.
  ///
  /// The [getInnerPath] and [getOuterPath] methods do not know about the
  /// `shape` and `borderRadius` arguments.
  ///
  /// See also:
  ///
  ///  * [paintBorder], which is used if the border is not uniform.
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  });

  static void _paintUniformBorderWithRadius(Canvas canvas, Rect rect, BorderSide side, BorderRadius borderRadius) {
    assert(side.style != BorderStyle.none);
    final Paint paint = Paint()
      ..color = side.color;
    final double width = side.width;
    if (width == 0.0) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.0;
      canvas.drawRRect(borderRadius.toRRect(rect), paint);
    } else {
      final RRect borderRect = borderRadius.toRRect(rect);
      final RRect inner = borderRect.deflate(side.strokeInset);
      final RRect outer = borderRect.inflate(side.strokeOutset);
      canvas.drawDRRect(outer, inner, paint);
    }
  }

  static void _paintUniformBorderWithCircle(Canvas canvas, Rect rect, BorderSide side) {
    assert(side.style != BorderStyle.none);
    final double radius = (rect.shortestSide + side.strokeOffset) / 2;
    canvas.drawCircle(rect.center, radius, side.toPaint());
  }

  static void _paintUniformBorderWithRectangle(Canvas canvas, Rect rect, BorderSide side) {
    assert(side.style != BorderStyle.none);
    canvas.drawRect(rect.inflate(side.strokeOffset / 2), side.toPaint());
  }
}

/// A border of a box, comprised of four sides: top, right, bottom, left.
///
/// The sides are represented by [BorderSide] objects.
///
/// {@tool snippet}
///
/// All four borders the same, two-pixel wide solid white:
///
/// ```dart
/// Border.all(width: 2.0, color: const Color(0xFFFFFFFF))
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// The border for a Material Design divider:
///
/// ```dart
/// Border(bottom: BorderSide(color: Theme.of(context).dividerColor))
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// A 1990s-era "OK" button:
///
/// ```dart
/// Container(
///   decoration: const BoxDecoration(
///     border: Border(
///       top: BorderSide(color: Color(0xFFFFFFFF)),
///       left: BorderSide(color: Color(0xFFFFFFFF)),
///       right: BorderSide(),
///       bottom: BorderSide(),
///     ),
///   ),
///   child: Container(
///     padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
///     decoration: const BoxDecoration(
///       border: Border(
///         top: BorderSide(color: Color(0xFFDFDFDF)),
///         left: BorderSide(color: Color(0xFFDFDFDF)),
///         right: BorderSide(color: Color(0xFF7F7F7F)),
///         bottom: BorderSide(color: Color(0xFF7F7F7F)),
///       ),
///       color: Color(0xFFBFBFBF),
///     ),
///     child: const Text(
///       'OK',
///       textAlign: TextAlign.center,
///       style: TextStyle(color: Color(0xFF000000))
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [BoxDecoration], which uses this class to describe its edge decoration.
///  * [BorderSide], which is used to describe each side of the box.
///  * [Theme], from the material layer, which can be queried to obtain appropriate colors
///    to use for borders in a [MaterialApp], as shown in the "divider" sample above.
class Border extends BoxBorder {
  /// Creates a border.
  ///
  /// All the sides of the border default to [BorderSide.none].
  ///
  /// The arguments must not be null.
  const Border({
    this.top = BorderSide.none,
    this.right = BorderSide.none,
    this.bottom = BorderSide.none,
    this.left = BorderSide.none,
  }) : assert(top != null),
       assert(right != null),
       assert(bottom != null),
       assert(left != null);

  /// Creates a border whose sides are all the same.
  ///
  /// The `side` argument must not be null.
  const Border.fromBorderSide(BorderSide side)
      : assert(side != null),
        top = side,
        right = side,
        bottom = side,
        left = side;

  /// Creates a border with symmetrical vertical and horizontal sides.
  ///
  /// The `vertical` argument applies to the [left] and [right] sides, and the
  /// `horizontal` argument applies to the [top] and [bottom] sides.
  ///
  /// All arguments default to [BorderSide.none] and must not be null.
  const Border.symmetric({
    BorderSide vertical = BorderSide.none,
    BorderSide horizontal = BorderSide.none,
  }) : assert(vertical != null),
       assert(horizontal != null),
       left = vertical,
       top = horizontal,
       right = vertical,
       bottom = horizontal;

  /// A uniform border with all sides the same color and width.
  ///
  /// The sides default to black solid borders, one logical pixel wide.
  factory Border.all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
    double strokeAlign = BorderSide.strokeAlignInside,
  }) {
    final BorderSide side = BorderSide(color: color, width: width, style: style, strokeAlign: strokeAlign);
    return Border.fromBorderSide(side);
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
    return Border(
      top: BorderSide.merge(a.top, b.top),
      right: BorderSide.merge(a.right, b.right),
      bottom: BorderSide.merge(a.bottom, b.bottom),
      left: BorderSide.merge(a.left, b.left),
    );
  }

  @override
  final BorderSide top;

  /// The right side of this border.
  final BorderSide right;

  @override
  final BorderSide bottom;

  /// The left side of this border.
  final BorderSide left;

  @override
  EdgeInsetsGeometry get dimensions {
    if (_widthIsUniform) {
      return EdgeInsets.all(top.strokeInset);
    }
    return EdgeInsets.fromLTRB(left.strokeInset, top.strokeInset, right.strokeInset, bottom.strokeInset);
  }

  @override
  bool get isUniform => _colorIsUniform && _widthIsUniform && _styleIsUniform && _strokeAlignIsUniform;

  bool get _colorIsUniform {
    final Color topColor = top.color;
    return right.color == topColor && bottom.color == topColor && left.color == topColor;
  }

  bool get _widthIsUniform {
    final double topWidth = top.width;
    return right.width == topWidth && bottom.width == topWidth && left.width == topWidth;
  }

  bool get _styleIsUniform {
    final BorderStyle topStyle = top.style;
    return right.style == topStyle && bottom.style == topStyle && left.style == topStyle;
  }

  bool get _strokeAlignIsUniform {
    final double topStrokeAlign = top.strokeAlign;
    return right.strokeAlign == topStrokeAlign
        && bottom.strokeAlign == topStrokeAlign
        && left.strokeAlign == topStrokeAlign;
  }

  @override
  Border? add(ShapeBorder other, { bool reversed = false }) {
    if (other is Border &&
        BorderSide.canMerge(top, other.top) &&
        BorderSide.canMerge(right, other.right) &&
        BorderSide.canMerge(bottom, other.bottom) &&
        BorderSide.canMerge(left, other.left)) {
      return Border.merge(this, other);
    }
    return null;
  }

  @override
  Border scale(double t) {
    return Border(
      top: top.scale(t),
      right: right.scale(t),
      bottom: bottom.scale(t),
      left: left.scale(t),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is Border) {
      return Border.lerp(a, this, t);
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is Border) {
      return Border.lerp(this, b, t);
    }
    return super.lerpTo(b, t);
  }

  /// Linearly interpolate between two borders.
  ///
  /// If a border is null, it is treated as having four [BorderSide.none]
  /// borders.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static Border? lerp(Border? a, Border? b, double t) {
    assert(t != null);
    if (a == null && b == null) {
      return null;
    }
    if (a == null) {
      return b!.scale(t);
    }
    if (b == null) {
      return a.scale(1.0 - t);
    }
    return Border(
      top: BorderSide.lerp(a.top, b.top, t),
      right: BorderSide.lerp(a.right, b.right, t),
      bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      left: BorderSide.lerp(a.left, b.left, t),
    );
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
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          switch (shape) {
            case BoxShape.circle:
              assert(borderRadius == null, 'A borderRadius can only be given for rectangular boxes.');
              BoxBorder._paintUniformBorderWithCircle(canvas, rect, top);
              break;
            case BoxShape.rectangle:
              if (borderRadius != null) {
                BoxBorder._paintUniformBorderWithRadius(canvas, rect, top, borderRadius);
                return;
              }
              BoxBorder._paintUniformBorderWithRectangle(canvas, rect, top);
              break;
          }
          return;
      }
    }

    assert(() {
      if (borderRadius != null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('A borderRadius can only be given for a uniform Border.'),
          ErrorDescription('The following is not uniform:'),
          if (!_colorIsUniform) ErrorDescription('BorderSide.color'),
          if (!_widthIsUniform) ErrorDescription('BorderSide.width'),
          if (!_styleIsUniform) ErrorDescription('BorderSide.style'),
          if (!_strokeAlignIsUniform) ErrorDescription('BorderSide.strokeAlign'),
        ]);
      }
      return true;
    }());
    assert(() {
      if (shape != BoxShape.rectangle) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('A Border can only be drawn as a circle if it is uniform.'),
          ErrorDescription('The following is not uniform:'),
          if (!_colorIsUniform) ErrorDescription('BorderSide.color'),
          if (!_widthIsUniform) ErrorDescription('BorderSide.width'),
          if (!_styleIsUniform) ErrorDescription('BorderSide.style'),
          if (!_strokeAlignIsUniform) ErrorDescription('BorderSide.strokeAlign'),
        ]);
      }
      return true;
    }());
    assert(() {
      if (!_strokeAlignIsUniform || top.strokeAlign != BorderSide.strokeAlignInside) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('A Border can only draw strokeAlign different than strokeAlignOutside on uniform borders.'),
        ]);
      }
      return true;
    }());

    paintBorder(canvas, rect, top: top, right: right, bottom: bottom, left: left);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Border
        && other.top == top
        && other.right == right
        && other.bottom == bottom
        && other.left == left;
  }

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  String toString() {
    if (isUniform) {
      return '${objectRuntimeType(this, 'Border')}.all($top)';
    }
    final List<String> arguments = <String>[
      if (top != BorderSide.none) 'top: $top',
      if (right != BorderSide.none) 'right: $right',
      if (bottom != BorderSide.none) 'bottom: $bottom',
      if (left != BorderSide.none) 'left: $left',
    ];
    return '${objectRuntimeType(this, 'Border')}(${arguments.join(", ")})';
  }
}

/// A border of a box, comprised of four sides, the lateral sides of which
/// flip over based on the reading direction.
///
/// The lateral sides are called [start] and [end]. When painted in
/// left-to-right environments, the [start] side will be painted on the left and
/// the [end] side on the right; in right-to-left environments, it is the
/// reverse. The other two sides are [top] and [bottom].
///
/// The sides are represented by [BorderSide] objects.
///
/// If the [start] and [end] sides are the same, then it is slightly more
/// efficient to use a [Border] object rather than a [BorderDirectional] object.
///
/// See also:
///
///  * [BoxDecoration], which uses this class to describe its edge decoration.
///  * [BorderSide], which is used to describe each side of the box.
///  * [Theme], from the material layer, which can be queried to obtain appropriate colors
///    to use for borders in a [MaterialApp], as shown in the "divider" sample above.
class BorderDirectional extends BoxBorder {
  /// Creates a border.
  ///
  /// The [start] and [end] sides represent the horizontal sides; the start side
  /// is on the leading edge given the reading direction, and the end side is on
  /// the trailing edge. They are resolved during [paint].
  ///
  /// All the sides of the border default to [BorderSide.none].
  ///
  /// The arguments must not be null.
  const BorderDirectional({
    this.top = BorderSide.none,
    this.start = BorderSide.none,
    this.end = BorderSide.none,
    this.bottom = BorderSide.none,
  }) : assert(top != null),
       assert(start != null),
       assert(end != null),
       assert(bottom != null);

  /// Creates a [BorderDirectional] that represents the addition of the two
  /// given [BorderDirectional]s.
  ///
  /// It is only valid to call this if [BorderSide.canMerge] returns true for
  /// the pairwise combination of each side on both [BorderDirectional]s.
  ///
  /// The arguments must not be null.
  static BorderDirectional merge(BorderDirectional a, BorderDirectional b) {
    assert(a != null);
    assert(b != null);
    assert(BorderSide.canMerge(a.top, b.top));
    assert(BorderSide.canMerge(a.start, b.start));
    assert(BorderSide.canMerge(a.end, b.end));
    assert(BorderSide.canMerge(a.bottom, b.bottom));
    return BorderDirectional(
      top: BorderSide.merge(a.top, b.top),
      start: BorderSide.merge(a.start, b.start),
      end: BorderSide.merge(a.end, b.end),
      bottom: BorderSide.merge(a.bottom, b.bottom),
    );
  }

  @override
  final BorderSide top;

  /// The start side of this border.
  ///
  /// This is the side on the left in left-to-right text and on the right in
  /// right-to-left text.
  ///
  /// See also:
  ///
  ///  * [TextDirection], which is used to describe the reading direction.
  final BorderSide start;

  /// The end side of this border.
  ///
  /// This is the side on the right in left-to-right text and on the left in
  /// right-to-left text.
  ///
  /// See also:
  ///
  ///  * [TextDirection], which is used to describe the reading direction.
  final BorderSide end;

  @override
  final BorderSide bottom;

  @override
  EdgeInsetsGeometry get dimensions {
    if (isUniform) {
      return EdgeInsetsDirectional.all(top.strokeInset);
    }
    return EdgeInsetsDirectional.fromSTEB(start.strokeInset, top.strokeInset, end.strokeInset, bottom.strokeInset);
  }

  @override
  bool get isUniform {
    final Color topColor = top.color;
    if (start.color != topColor ||
        end.color != topColor ||
        bottom.color != topColor) {
      return false;
    }

    final double topWidth = top.width;
    if (start.width != topWidth ||
        end.width != topWidth ||
        bottom.width != topWidth) {
      return false;
    }

    final BorderStyle topStyle = top.style;
    if (start.style != topStyle ||
        end.style != topStyle ||
        bottom.style != topStyle) {
      return false;
    }

    if (_strokeAlignIsUniform == false) {
      return false;
    }

    return true;
  }

  bool get _strokeAlignIsUniform {
    final double topStrokeAlign = top.strokeAlign;
    return start.strokeAlign == topStrokeAlign
        && bottom.strokeAlign == topStrokeAlign
        && end.strokeAlign == topStrokeAlign;
  }

  @override
  BoxBorder? add(ShapeBorder other, { bool reversed = false }) {
    if (other is BorderDirectional) {
      final BorderDirectional typedOther = other;
      if (BorderSide.canMerge(top, typedOther.top) &&
          BorderSide.canMerge(start, typedOther.start) &&
          BorderSide.canMerge(end, typedOther.end) &&
          BorderSide.canMerge(bottom, typedOther.bottom)) {
        return BorderDirectional.merge(this, typedOther);
      }
      return null;
    }
    if (other is Border) {
      final Border typedOther = other;
      if (!BorderSide.canMerge(typedOther.top, top) ||
          !BorderSide.canMerge(typedOther.bottom, bottom)) {
        return null;
      }
      if (start != BorderSide.none ||
          end != BorderSide.none) {
        if (typedOther.left != BorderSide.none ||
            typedOther.right != BorderSide.none) {
          return null;
        }
        assert(typedOther.left == BorderSide.none);
        assert(typedOther.right == BorderSide.none);
        return BorderDirectional(
          top: BorderSide.merge(typedOther.top, top),
          start: start,
          end: end,
          bottom: BorderSide.merge(typedOther.bottom, bottom),
        );
      }
      assert(start == BorderSide.none);
      assert(end == BorderSide.none);
      return Border(
        top: BorderSide.merge(typedOther.top, top),
        right: typedOther.right,
        bottom: BorderSide.merge(typedOther.bottom, bottom),
        left: typedOther.left,
      );
    }
    return null;
  }

  @override
  BorderDirectional scale(double t) {
    return BorderDirectional(
      top: top.scale(t),
      start: start.scale(t),
      end: end.scale(t),
      bottom: bottom.scale(t),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is BorderDirectional) {
      return BorderDirectional.lerp(a, this, t);
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is BorderDirectional) {
      return BorderDirectional.lerp(this, b, t);
    }
    return super.lerpTo(b, t);
  }

  /// Linearly interpolate between two borders.
  ///
  /// If a border is null, it is treated as having four [BorderSide.none]
  /// borders.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static BorderDirectional? lerp(BorderDirectional? a, BorderDirectional? b, double t) {
    assert(t != null);
    if (a == null && b == null) {
      return null;
    }
    if (a == null) {
      return b!.scale(t);
    }
    if (b == null) {
      return a.scale(1.0 - t);
    }
    return BorderDirectional(
      top: BorderSide.lerp(a.top, b.top, t),
      end: BorderSide.lerp(a.end, b.end, t),
      bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      start: BorderSide.lerp(a.start, b.start, t),
    );
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
  /// The `textDirection` argument is used to determine which of [start] and
  /// [end] map to the left and right. For [TextDirection.ltr], the [start] is
  /// the left and the [end] is the right; for [TextDirection.rtl], it is the
  /// reverse.
  ///
  /// See also:
  ///
  ///  * [paintBorder], which is used if the border is not uniform.
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          switch (shape) {
            case BoxShape.circle:
              assert(borderRadius == null, 'A borderRadius can only be given for rectangular boxes.');
              BoxBorder._paintUniformBorderWithCircle(canvas, rect, top);
              break;
            case BoxShape.rectangle:
              if (borderRadius != null) {
                BoxBorder._paintUniformBorderWithRadius(canvas, rect, top, borderRadius);
                return;
              }
              BoxBorder._paintUniformBorderWithRectangle(canvas, rect, top);
              break;
          }
          return;
      }
    }

    assert(borderRadius == null, 'A borderRadius can only be given for uniform borders.');
    assert(shape == BoxShape.rectangle, 'A border can only be drawn as a circle if it is uniform.');
    assert(_strokeAlignIsUniform && top.strokeAlign == BorderSide.strokeAlignInside, 'A Border can only draw strokeAlign different than strokeAlignInside on uniform borders.');

    final BorderSide left, right;
    assert(textDirection != null, 'Non-uniform BorderDirectional objects require a TextDirection when painting.');
    switch (textDirection!) {
      case TextDirection.rtl:
        left = end;
        right = start;
        break;
      case TextDirection.ltr:
        left = start;
        right = end;
        break;
    }
    paintBorder(canvas, rect, top: top, left: left, bottom: bottom, right: right);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is BorderDirectional
        && other.top == top
        && other.start == start
        && other.end == end
        && other.bottom == bottom;
  }

  @override
  int get hashCode => Object.hash(top, start, end, bottom);

  @override
  String toString() {
    final List<String> arguments = <String>[
      if (top != BorderSide.none) 'top: $top',
      if (start != BorderSide.none) 'start: $start',
      if (end != BorderSide.none) 'end: $end',
      if (bottom != BorderSide.none) 'bottom: $bottom',
    ];
    return '${objectRuntimeType(this, 'BorderDirectional')}(${arguments.join(", ")})';
  }
}
