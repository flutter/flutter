// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

class _PlaceholderPainter extends CustomPainter {
  const _PlaceholderPainter({
    this.color,
    this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final Rect rect = Offset.zero & size;
    final Path path = Path()
      ..addRect(rect)
      ..addPolygon(<Offset>[rect.topRight, rect.bottomLeft], false)
      ..addPolygon(<Offset>[rect.topLeft, rect.bottomRight], false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PlaceholderPainter oldPainter) {
    return oldPainter.color != color
        || oldPainter.strokeWidth != strokeWidth;
  }

  @override
  bool hitTest(Offset position) => false;
}

/// A widget that draws a box that represents where other widgets will one day
/// be added.
///
/// This widget is useful during development to indicate that the interface is
/// not yet complete.
///
/// By default, the placeholder is sized to fit its container. If the
/// placeholder is in an unbounded space, it will size itself according to the
/// given [fallbackWidth] and [fallbackHeight].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=LPe56fezmoo}
class Placeholder extends StatelessWidget {
  /// Creates a widget which draws a box.
  const Placeholder({
    Key key,
    this.color = const Color(0xFF455A64), // Blue Grey 700
    this.strokeWidth = 2.0,
    this.fallbackWidth = 400.0,
    this.fallbackHeight = 400.0,
  }) : super(key: key);

  /// The color to draw the placeholder box.
  final Color color;

  /// The width of the lines in the placeholder box.
  final double strokeWidth;

  /// The width to use when the placeholder is in a situation with an unbounded
  /// width.
  ///
  /// See also:
  ///
  ///  * [fallbackHeight], the same but vertically.
  final double fallbackWidth;

  /// The height to use when the placeholder is in a situation with an unbounded
  /// height.
  ///
  /// See also:
  ///
  ///  * [fallbackWidth], the same but horizontally.
  final double fallbackHeight;

  @override
  Widget build(BuildContext context) {
    return LimitedBox(
      maxWidth: fallbackWidth,
      maxHeight: fallbackHeight,
      child: CustomPaint(
        size: Size.infinite,
        foregroundPainter: _PlaceholderPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
