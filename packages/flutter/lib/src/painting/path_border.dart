// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'border_radius.dart';
import 'borders.dart';
import 'box_border.dart';
import 'edge_insets.dart';

/// The signature of a method that creates a [Path] for a [PathBorder].
///
/// The `bounds` parameter will not be null.
typedef PathBorderBuilder = Path Function(Rect bounds, TextDirection textDirection);

/// A [BoxBorder] that delegates painting its border to a [PathBorderBuilder].
///
/// This class can be used draw a customized border as a [BoxDecoration], for
/// example a path that has been dashed or trimmed.
///
/// {@tool sample}
/// This will draw a container with a red elliptical border:
///
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     border: PathBorder(
///       pathBuilder: (Rect bounds, TextDirection textDirection) =>
///           Path()..addOval(bounds),
///       border: const BorderSide(color: Colors.red),
///     ),
///   ),
///   padding: const EdgeInsets.all(20.0),
///   child: const Text('You have pushed the button this many times:'),
/// );
/// ```
/// {@end-tool}
///
/// [PathBorders] are defined as being uniform regardless of inputs, although
/// there is no constraint in this class forcing a uniform path to be drawn by
/// the [PathBorderBuilder].
class PathBorder extends BoxBorder {
  /// Cretes a [PathBorder] with the specified border.
  ///
  /// Using this constructor will result in the default values for
  /// [Paint.strokeCap], [Paint.strokeJoin], and [Paint.strokeMiterLimit], and
  /// does not allow setting custom shaders such as gradients on the paint. To
  /// specify these propertues, use the [PathBorder.withPaint] constructor.
  ///
  /// The [pathBuilder] and border properties must not be null..
  PathBorder({
    @required this.pathBuilder,
    BorderSide border = const BorderSide(),
  })  : assert(pathBuilder != null),
        assert(border != null),
        _border = border,
        pathPaint = border.toPaint();

  /// Cretes a [PathBorder] with the specified paint.
  ///
  /// This constructor is useful if you wish to directly control the [Paint]
  /// used to paint the border, such as applying a gradient or setting
  /// [Paint.strokeCap], [Paint.strokeJoin], or [Paint.strokeMiterLimit] to a
  /// non-default value.
  ///
  /// The [pathPaint] must have a [PaintingStyle.stroke] style. The fill color
  /// for a [BoxDecoration] is specified by [BoxDecoration.color].
  ///
  /// The [pathPaint] and [pathBuilder] properties must not be null.
  PathBorder.withPaint({
    @required this.pathBuilder,
    @required this.pathPaint,
  })  : assert(pathBuilder != null),
        assert(pathPaint != null),
        assert(pathPaint.style == PaintingStyle.stroke, 'PathBorder does not support drawing a border with a fill.'),
        _border = BorderSide(
          color: pathPaint.color,
          width: pathPaint.strokeWidth,
          style: BorderStyle.solid,
        );

  /// The callback to use when creating a path in a given [Rect].
  ///
  /// This callback fire at paint time with the boundary and [TextDirection] for
  /// the border. The implementation is free to return any path it wishes. No
  /// transformations will be applied to the resulting path, which will be
  /// rendered on the same canvas as the box it is decorating. If it draws
  /// outside of the boundary, it may or may not be visible as larger than the
  /// box. Alternatively , if it draws a path that is much smaller than the
  /// boundary, it will draw inside the decorated box rather than at the edges.
  ///
  /// {@tool sample}
  /// The [Path] class has several methods which take a [Rect] as a parameter,
  /// which are useful in implementing this callback.
  ///
  /// ```dart
  /// (Rect boundary, TextDirection textDirection) {
  ///   return Path()..addRRect(
  ///     RRect.fromRectAndRadius(
  ///       boundary,
  ///       Radius.circular(5.0),
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final PathBorderBuilder pathBuilder;

  /// The [Paint] used to draw the path border.
  ///
  /// This paint must have its [Paint.style] set to [PaintingStyle.stroke]. To
  /// set the fill on a [BoxDecoration], use the [BoxDecoration.color] property.
  final Paint pathPaint;

  @override
  bool get isUniform => true;

  final BorderSide _border;

  @override
  BorderSide get bottom => _border;

  @override
  BorderSide get top => _border;

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return pathBuilder(rect, textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return pathBuilder(rect, textDirection);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius,
  }) {
    assert(pathPaint.style == PaintingStyle.stroke);
    assert(borderRadius == null,
        'A borderRadius cannot be applied for a $runtimeType.');
    assert(shape == BoxShape.rectangle,
        'A custom shape cannot be specified via the path for this $runtimeType.');
    assert(rect != null);

    switch (top.style) {
      case BorderStyle.none:
        return;
      case BorderStyle.solid:
        final Path path = pathBuilder(rect, textDirection);
        if (path == null) {
          return;
        }
        canvas.drawPath(path, pathPaint);
        return;
    }
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(pathPaint.strokeWidth);

  @override
  PathBorder scale(double t) {
    assert(t != null);
    return PathBorder.withPaint(
      pathBuilder: pathBuilder,
      pathPaint: Paint()
        ..blendMode = pathPaint.blendMode
        ..color = pathPaint.color
        ..colorFilter = pathPaint.colorFilter
        ..filterQuality = pathPaint.filterQuality
        ..invertColors = pathPaint.invertColors
        ..isAntiAlias = pathPaint.isAntiAlias
        ..maskFilter = pathPaint.maskFilter
        ..shader = pathPaint.shader
        ..strokeCap = pathPaint.strokeCap
        ..strokeJoin = pathPaint.strokeJoin
        ..strokeMiterLimit = pathPaint.strokeMiterLimit
        ..style = PaintingStyle.stroke
        ..strokeWidth = pathPaint.strokeWidth * t,
    );
  }
}
