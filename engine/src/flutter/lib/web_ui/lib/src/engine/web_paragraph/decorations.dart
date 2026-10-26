// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:ui/ui.dart' as ui;

import 'layout.dart';
import 'paragraph.dart';

/// Paints text decorations directly on the output [ui.Canvas].
///
/// Decorations are not part of the paragraph raster because its size follows the glyph ink,
/// and decorations can extend past it.
class DecorationPainter {
  // Reused on every paint so decorations do not allocate on the paint path.
  static final ui.Paint _paint = ui.Paint();
  static final ui.Path _path = ui.Path();

  /// Calculates the thickness of the decoration line
  static double _calculateThickness(WebTextStyle textStyle) {
    return (textStyle.fontSize! / 14.0) * (textStyle.decorationThickness ?? 1.0);
  }

  /// Calculates the position of the decoration line
  ///
  /// As in SkParagraph, the overline and the line-through follow the font metrics without the
  /// height multiplier. Canvas2D has no x-height or strikeout metrics, so the line-through goes
  /// through the middle of the font box.
  static double _calculatePosition(
    ui.TextDecoration decoration,
    double thickness,
    TextBlock block,
    double baseline,
  ) {
    switch (decoration) {
      case ui.TextDecoration.underline:
        return baseline + thickness;
      case ui.TextDecoration.overline:
        return baseline - block.rawFontBoundingBoxAscent;
      case ui.TextDecoration.lineThrough:
        return baseline + (block.rawFontBoundingBoxDescent - block.rawFontBoundingBoxAscent) / 2;
    }
    return 0;
  }

  /// Fills a line of [thickness] centered on [y], the way SkParagraph draws solid lines, so a
  /// zero thickness paints nothing.
  static void _fillLine(ui.Canvas canvas, double left, double right, double y, double thickness) {
    _paint.style = ui.PaintingStyle.fill;
    canvas.drawRect(ui.Rect.fromLTRB(left, y - thickness / 2, right, y + thickness / 2), _paint);
  }

  /// Adds a wave of [width] starting at ([x], [y]) to [path], the same shape as SkParagraph.
  static void _addWaves(ui.Path path, double x, double y, double width, double thickness) {
    final quarterWave = thickness;

    var waveCount = 0;
    double xStart = 0;

    path.moveTo(x, y);
    // Terminates because the caller only draws waves with a positive period.
    while (xStart + quarterWave * 2 < width) {
      path.relativeQuadraticBezierTo(
        quarterWave,
        waveCount.isOdd ? quarterWave : -quarterWave,
        quarterWave * 2,
        0,
      );
      xStart += quarterWave * 2;
      ++waveCount;
    }

    // The rest of the wave
    final double remaining = width - xStart;
    if (remaining > 0) {
      final double sign = waveCount.isEven ? -1 : 1;
      path.relativeQuadraticBezierTo(
        remaining / 2,
        remaining / 2 * sign,
        remaining,
        (remaining - remaining * remaining / (quarterWave * 2)) * sign,
      );
    }
  }

  /// Adds dashes of [dash] length separated by [gap] to [path], cutting the last dash at [width].
  ///
  /// [ui.Paint] has no dash path effect, so the dashes are separate segments.
  static void _addDashes(ui.Path path, double x, double y, double width, double dash, double gap) {
    final double right = x + width;
    // Terminates because the caller only draws dashes with a positive period.
    for (var left = x; left < right; left += dash + gap) {
      path.moveTo(left, y);
      path.lineTo(math.min(left + dash, right), y);
    }
  }

  /// Paints the decorations of [block] from [left] to [right] around [baseline], in canvas
  /// coordinates.
  ///
  /// [physicalPixel] is the horizontal size of one physical pixel in canvas coordinates.
  static void paintDecorations(
    ui.Canvas canvas,
    TextBlock block,
    double left,
    double right,
    double baseline,
    double physicalPixel,
  ) {
    assert(physicalPixel > 0);
    final double thickness = _calculateThickness(block.style);
    // SkParagraph defaults to a solid line, and treats a transparent decoration color as unset
    // and uses the text color instead.
    final ui.TextDecorationStyle style =
        block.style.decorationStyle ?? ui.TextDecorationStyle.solid;
    final ui.Color? decorationColor = block.style.decorationColor;
    _paint
      ..strokeWidth = thickness
      ..color = decorationColor == null || decorationColor == const ui.Color(0x00000000)
          ? block.style.getForegroundColor()
          : decorationColor;

    // The same patterns as SkParagraph: dash intervals scale with the font size but not with
    // the decoration thickness.
    const doubleDecorationSpacing = 3.0;
    final double patternScale = block.style.fontSize! / 14.0;

    for (final ui.TextDecoration decoration in const [
      ui.TextDecoration.lineThrough,
      ui.TextDecoration.underline,
      ui.TextDecoration.overline,
    ]) {
      if (!block.style.decoration!.contains(decoration)) {
        continue;
      }

      final double y = _calculatePosition(decoration, thickness, block, baseline);

      switch (style) {
        case ui.TextDecorationStyle.wavy:
          // A wave finer than a physical pixel looks like a line and would cost one segment per
          // period on every paint.
          if (thickness * 2 < physicalPixel) {
            _fillLine(canvas, left, right, y, thickness);
          } else {
            _path.reset();
            _addWaves(_path, left, y, right - left, thickness);
            _paint.style = ui.PaintingStyle.stroke;
            canvas.drawPath(_path, _paint);
          }

        case ui.TextDecorationStyle.double:
          _fillLine(canvas, left, right, y, thickness);
          _fillLine(canvas, left, right, y + doubleDecorationSpacing, thickness);

        case ui.TextDecorationStyle.dashed:
        case ui.TextDecorationStyle.dotted:
          final dotted = style == ui.TextDecorationStyle.dotted;
          final double dash = (dotted ? 1.0 : 4.0) * patternScale;
          final double gap = (dotted ? 1.5 : 2.0) * patternScale;
          // Dashes finer than a physical pixel look like a line and would cost one segment per
          // period on every paint.
          if (dash + gap < physicalPixel) {
            _fillLine(canvas, left, right, y, thickness);
          } else {
            _path.reset();
            _addDashes(_path, left, y, right - left, dash, gap);
            _paint.style = ui.PaintingStyle.stroke;
            canvas.drawPath(_path, _paint);
          }

        case ui.TextDecorationStyle.solid:
          _fillLine(canvas, left, right, y, thickness);
      }
    }
  }
}
