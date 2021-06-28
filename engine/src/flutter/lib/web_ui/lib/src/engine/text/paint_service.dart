// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart' show BitmapCanvas, SurfacePaint;

import 'canvas_paragraph.dart';
import 'layout_service.dart';
import 'paragraph.dart';

/// Responsible for painting a [CanvasParagraph] on a [BitmapCanvas].
class TextPaintService {
  TextPaintService(this.paragraph);

  final CanvasParagraph paragraph;

  void paint(BitmapCanvas canvas, ui.Offset offset) {
    // Loop through all the lines, for each line, loop through all the boxes and
    // paint them. The boxes have enough information so they can be painted
    // individually.
    final List<EngineLineMetrics> lines = paragraph.computeLineMetrics();

    for (final EngineLineMetrics line in lines) {
      for (final RangeBox box in line.boxes!) {
        _paintBox(canvas, offset, line, box);
      }
    }
  }

  void _paintBox(
    BitmapCanvas canvas,
    ui.Offset offset,
    EngineLineMetrics line,
    RangeBox box,
  ) {
    // Placeholder spans don't need any painting. Their boxes should remain
    // empty so that their underlying widgets do their own painting.
    if (box is SpanBox) {
      final FlatTextSpan span = box.span;

      // Paint the background of the box, if the span has a background.
      final SurfacePaint? background = span.style.background as SurfacePaint?;
      if (background != null) {
        canvas.drawRect(
          box.toTextBox(line).toRect().shift(offset),
          background.paintData,
        );
      }

      // Paint the actual text.
      _applySpanStyleToCanvas(span, canvas);
      final double x = offset.dx + line.left + box.left;
      final double y = offset.dy + line.baseline;
      final String text = paragraph.toPlainText().substring(
            box.start.index,
            box.end.indexWithoutTrailingNewlines,
          );
      final double? letterSpacing = span.style.letterSpacing;
      if (letterSpacing == null || letterSpacing == 0.0) {
        canvas.fillText(text, x, y, shadows: span.style.shadows);
      } else {
        // TODO(mdebbar): Implement letter-spacing on canvas more efficiently:
        //                https://github.com/flutter/flutter/issues/51234
        double charX = x;
        final int len = text.length;
        for (int i = 0; i < len; i++) {
          final String char = text[i];
          canvas.fillText(char, charX.roundToDouble(), y,
              shadows: span.style.shadows);
          charX += letterSpacing + canvas.measureText(char).width!;
        }
      }

      // Paint the ellipsis using the same span styles.
      final String? ellipsis = line.ellipsis;
      if (ellipsis != null && box == line.boxes!.last) {
        final double x = offset.dx + line.left + box.right;
        canvas.fillText(ellipsis, x, y);
      }

      canvas.tearDownPaint();
    }
  }

  void _applySpanStyleToCanvas(FlatTextSpan span, BitmapCanvas canvas) {
    final SurfacePaint? paint;
    final ui.Paint? foreground = span.style.foreground;
    if (foreground != null) {
      paint = foreground as SurfacePaint;
    } else {
      paint = (ui.Paint()..color = span.style.color!) as SurfacePaint;
    }

    canvas.setCssFont(span.style.cssFontString);
    canvas.setUpPaint(paint.paintData, null);
  }
}
