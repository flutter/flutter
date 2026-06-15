// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;
import '../../engine.dart';

class DomCanvasDecorationPainter {
  /// Calculates the thickness of the decoration line
  static double _calculateThickness(double fontSize, double? thickness) {
    return (fontSize / 14.0) * (thickness ?? 1.0);
  }

  /// Calculates the position of the decoration line
  static double _calculatePosition(
    ui.TextDecoration decoration,
    double thickness,
    double height,
    double ascent,
  ) {
    switch (decoration) {
      case ui.TextDecoration.underline:
        return thickness + ascent;
      case ui.TextDecoration.overline:
        return thickness / 2;
      case ui.TextDecoration.lineThrough:
        return height / 2;
    }
    return 0;
  }

  static void _drawDashedOrDottedLine(
    LazyPath pathBuilder,
    double x,
    double y,
    double textWidth,
    double dashWidth,
    double dashSpace,
  ) {
    var currentX = x;
    final double endX = x + textWidth;

    while (currentX < endX) {
      // Calculate where the current dash ends, clamping it so it doesn't overshoot the text
      final double nextX = (currentX + dashWidth).clamp(x, endX);

      // Draw the dash (or dot)
      pathBuilder.moveTo(currentX, y);
      pathBuilder.lineTo(nextX, y);

      // Jump forward by the dash width PLUS the empty space to start the next dash
      currentX += dashWidth + dashSpace;
    }
  }

  /// Calculates and the position of the decoration line and paints it on Canvas2D
  static void _drawWaves(
    LazyPath pathBuilder,
    double x,
    double y,
    double textWidth,
    double thickness,
  ) {
    final quarterWave = thickness;

    var waveCount = 0;
    // Initialize xStart with the actual starting x offset
    var xStart = x;
    final double yStart = y + quarterWave;

    pathBuilder.moveTo(xStart, yStart);

    // Calculate width limit relative to the starting x
    while ((xStart - x) + quarterWave * 2 < textWidth) {
      // Control point x1 must be halfway between start and end
      final double x1 = xStart + quarterWave;
      final double y1 = yStart + quarterWave * (waveCount.isOdd ? 1 : -1);
      final double x2 = xStart + quarterWave * 2;
      final y2 = yStart;

      pathBuilder.quadraticBezierTo(x1, y1, x2, y2);
      xStart += quarterWave * 2;
      ++waveCount;
    }

    // The rest of the wave
    final double remaining = textWidth - (xStart - x);
    if (remaining > 0) {
      // Control point in the middle of the remaining distance
      final double x1 = xStart + (remaining / 2);
      final double y1 = yStart + quarterWave * (waveCount.isOdd ? 1 : -1);
      final double x2 = xStart + remaining;
      final y2 = yStart;

      pathBuilder.quadraticBezierTo(x1, y1, x2, y2);
    }
  }

  /// Paints the decorations of a [TextBlock] on a [ui.Canvas].
  static void paintBlockDecorations(ui.Canvas canvas, ui.Rect rect, TextBlock block) {
    if (block.style.decoration == null || block.style.decorationStyle == null) {
      return;
    }

    final snappedRect = ui.Rect.fromLTRB(
      rect.left.roundToDouble(),
      rect.top.roundToDouble(),
      rect.right.roundToDouble(),
      rect.bottom.roundToDouble(),
    );

    final double thickness = _calculateThickness(
      block.style.fontSize!,
      block.style.decorationThickness,
    );

    const DoubleDecorationSpacing = 3.0;

    for (final ui.TextDecoration decoration in [
      ui.TextDecoration.lineThrough,
      ui.TextDecoration.underline,
      ui.TextDecoration.overline,
    ]) {
      if (!block.style.decoration!.contains(decoration)) {
        continue;
      }

      final double height =
          block.multipliedFontBoundingBoxAscent + block.multipliedFontBoundingBoxDescent;
      final double ascent = block.multipliedFontBoundingBoxAscent;
      final double position = _calculatePosition(decoration, thickness, height, ascent);

      final double width = snappedRect.width;
      final double x = snappedRect.left;
      final double y = snappedRect.top + position;

      final strokePaint = CkPaint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = block.style.decorationColor ?? block.style.getForegroundColor();
      final pathBuilder = LazyPath(renderer.pathConstructors);
      switch (block.style.decorationStyle!) {
        case ui.TextDecorationStyle.wavy:
          _drawWaves(pathBuilder, x, y, snappedRect.width, thickness);

        case ui.TextDecorationStyle.double:
          final double bottom = y + DoubleDecorationSpacing + thickness;
          pathBuilder.moveTo(x, y);
          pathBuilder.lineTo(x + width, y);
          pathBuilder.moveTo(x, bottom);
          pathBuilder.lineTo(x + width, bottom);

        case ui.TextDecorationStyle.dashed:
          _drawDashedOrDottedLine(
            pathBuilder,
            x,
            y,
            snappedRect.width,
            thickness * 4,
            thickness * 2,
          );

        case ui.TextDecorationStyle.dotted:
          _drawDashedOrDottedLine(pathBuilder, x, y, snappedRect.width, thickness, thickness * 2);

        case ui.TextDecorationStyle.solid:
          pathBuilder.moveTo(x, y);
          pathBuilder.lineTo(x + width, y);
      }

      final ckCanvas = canvas as CkCanvas;
      ckCanvas.drawPath(pathBuilder, strokePaint);
    }
  }
}
