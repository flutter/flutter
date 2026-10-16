// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../util.dart';
import 'layout.dart';
import 'paragraph.dart';

class DomCanvasDecorationPainter {
  /// Calculates the thickness of the decoration line
  static double _calculateThickness(WebTextStyle textStyle) {
    return (textStyle.fontSize! / 14.0) * (textStyle.decorationThickness ?? 1.0);
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

  static void _paintWaves(
    DomCanvasRenderingContext2D paintContext,
    double x,
    double y,
    WebTextStyle textStyle,
    ui.Rect textBounds,
    double thickness,
  ) {
    final quarterWave = thickness;

    var waveCount = 0;
    double xStart = 0;
    final double yStart = y + quarterWave;

    paintContext.beginPath();
    paintContext.moveTo(x, yStart);
    while (xStart + quarterWave * 2 < textBounds.width) {
      final x1 = xStart;
      final double y1 = yStart + quarterWave * (waveCount.isEven ? 1 : -1);
      final double x2 = xStart + quarterWave * 2;
      final y2 = yStart;
      paintContext.quadraticCurveTo(x1, y1, x2, y2);
      xStart += quarterWave * 2;
      ++waveCount;
    }

    // The rest of the wave
    final double remaining = textBounds.width - xStart;
    if (remaining > 0) {
      final x1 = xStart;
      final double y1 = yStart + quarterWave * (waveCount.isEven ? 1 : -1);
      final double x2 = xStart + remaining;
      final y2 = yStart;
      paintContext.quadraticCurveTo(x1, y1, x2, y2);
    }
    paintContext.stroke();
  }

  static void fillDecorations(
    DomCanvasRenderingContext2D paintContext,
    TextBlock block,
    ui.Rect rect,
  ) {
    if (!block.style.hasElement(StyleElements.decorations) || block.style.decoration == null) {
      return;
    }
    paintContext.fillStyle = block.style.getForegroundColor().toCssString();

    final double thickness = _calculateThickness(block.style);

    const DoubleDecorationSpacing = 3.0;

    for (final ui.TextDecoration decoration in [
      ui.TextDecoration.lineThrough,
      ui.TextDecoration.underline,
      ui.TextDecoration.overline,
    ]) {
      if (!block.style.decoration!.contains(decoration)) {
        continue;
      }

      final double height = block.multipliedHeight;
      final double ascent = block.multipliedFontBoundingBoxAscent;
      final double position = _calculatePosition(decoration, thickness, height, ascent);

      final double width = rect.width;
      final double x = rect.left;
      final double y = rect.top + position;

      paintContext.save();
      paintContext.lineWidth = thickness;
      paintContext.strokeStyle = block.style.decorationColor!.toCssString();

      switch (block.style.decorationStyle!) {
        case ui.TextDecorationStyle.wavy:
          _paintWaves(paintContext, x, y, block.style, rect, thickness);

        case ui.TextDecorationStyle.double:
          final double bottom = y + DoubleDecorationSpacing + thickness;
          paintContext.beginPath();
          paintContext.moveTo(x, y);
          paintContext.lineTo(x + width, y);
          paintContext.moveTo(x, bottom);
          paintContext.lineTo(x + width, bottom);
          paintContext.stroke();

        case ui.TextDecorationStyle.dashed:
        case ui.TextDecorationStyle.dotted:
          final dashes = Float32List(2)
            ..[0] =
                thickness * (block.style.decorationStyle! == ui.TextDecorationStyle.dotted ? 1 : 4)
            ..[1] = thickness;

          paintContext.setLineDash(dashes);
          paintContext.beginPath();
          paintContext.moveTo(x, y);
          paintContext.lineTo(x + width, y);
          paintContext.stroke();

        case ui.TextDecorationStyle.solid:
          paintContext.beginPath();
          paintContext.moveTo(x, y);
          paintContext.lineTo(x + width, y);
          paintContext.stroke();
      }

      paintContext.restore();
    }
  }
}
