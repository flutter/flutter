// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../html/bitmap_canvas.dart';
import '../html/painting.dart';
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

    if (lines.isEmpty) {
      return;
    }

    final EngineLineMetrics lastLine = lines.last;
    for (final EngineLineMetrics line in lines) {
      if (line.boxes.isEmpty) {
        continue;
      }

      final RangeBox lastBox = line.boxes.last;
      final double justifyPerSpaceBox =
          _calculateJustifyPerSpaceBox(paragraph, line, lastLine, lastBox);

      ui.Offset justifiedOffset = offset;

      for (final RangeBox box in line.boxes) {
        final bool isTrailingSpaceBox =
            box == lastBox && box is SpanBox && box.isSpaceOnly;

        // Don't paint background for the trailing space in the line.
        if (!isTrailingSpaceBox) {
          _paintBackground(canvas, justifiedOffset, line, box, justifyPerSpaceBox);
        }
        _paintText(canvas, justifiedOffset, line, box);

        if (box is SpanBox && box.isSpaceOnly && justifyPerSpaceBox != 0.0) {
          justifiedOffset = justifiedOffset.translate(justifyPerSpaceBox, 0.0);
        }
      }
    }
  }

  void _paintBackground(
    BitmapCanvas canvas,
    ui.Offset offset,
    EngineLineMetrics line,
    RangeBox box,
    double justifyPerSpaceBox,
  ) {
    if (box is SpanBox) {
      final FlatTextSpan span = box.span;

      // Paint the background of the box, if the span has a background.
      final SurfacePaint? background = span.style.background as SurfacePaint?;
      if (background != null) {
        ui.Rect rect = box.toTextBox(line).toRect().shift(offset);
        if (box.isSpaceOnly) {
          rect = ui.Rect.fromPoints(
            rect.topLeft,
            rect.bottomRight.translate(justifyPerSpaceBox, 0.0),
          );
        }
        canvas.drawRect(rect, background.paintData);
      }
    }
  }

  void _paintText(
    BitmapCanvas canvas,
    ui.Offset offset,
    EngineLineMetrics line,
    RangeBox box,
  ) {
    // There's no text to paint in placeholder spans.
    if (box is SpanBox) {
      final FlatTextSpan span = box.span;

      _applySpanStyleToCanvas(span, canvas);
      final double x = offset.dx + line.left + box.left;
      final double y = offset.dy + line.baseline;

      // Don't paint the text for space-only boxes. This is just an
      // optimization, it doesn't have any effect on the output.
      if (!box.isSpaceOnly) {
        final String text = paragraph.toPlainText().substring(
              box.start.index,
              box.end.indexWithoutTrailingNewlines,
            );
        final double? letterSpacing = span.style.letterSpacing;
        if (letterSpacing == null || letterSpacing == 0.0) {
          canvas.drawText(text, x, y,
              style: span.style.foreground?.style, shadows: span.style.shadows);
        } else {
          // TODO(mdebbar): Implement letter-spacing on canvas more efficiently:
          //                https://github.com/flutter/flutter/issues/51234
          double charX = x;
          final int len = text.length;
          for (int i = 0; i < len; i++) {
            final String char = text[i];
            canvas.drawText(char, charX.roundToDouble(), y,
                style: span.style.foreground?.style,
                shadows: span.style.shadows);
            charX += letterSpacing + canvas.measureText(char).width!;
          }
        }
      }

      // Paint the ellipsis using the same span styles.
      final String? ellipsis = line.ellipsis;
      if (ellipsis != null && box == line.boxes.last) {
        final double x = offset.dx + line.left + box.right;
        canvas.drawText(ellipsis, x, y, style: span.style.foreground?.style);
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

/// Calculates for the given [line], the amount of extra width that needs to be
/// added to each space box in order to align the line with the rest of the
/// paragraph.
double _calculateJustifyPerSpaceBox(
  CanvasParagraph paragraph,
  EngineLineMetrics line,
  EngineLineMetrics lastLine,
  RangeBox lastBox,
) {
  // Don't apply any justification on the last line.
  if (line != lastLine &&
      paragraph.width.isFinite &&
      paragraph.paragraphStyle.textAlign == ui.TextAlign.justify) {
    final double justifyTotal = paragraph.width - line.width;

    int spaceBoxesToJustify = line.spaceBoxCount;
    // If the last box is a space box, we can't use it to justify text.
    if (lastBox is SpanBox && lastBox.isSpaceOnly) {
      spaceBoxesToJustify--;
    }
    if (spaceBoxesToJustify > 0) {
      return justifyTotal / spaceBoxesToJustify;
    }
  }

  return 0.0;
}
