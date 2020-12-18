// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

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
    final ParagraphSpan span = box.span;

    // Placeholder spans don't need any painting. Their boxes should remain
    // empty so that their underlying widgets do their own painting.
    if (span is FlatTextSpan) {
      // Paint the background of the box, if the span has a background.
      final SurfacePaint? background = span.style._background as SurfacePaint?;
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
      canvas.fillText(text, x, y);

      // Paint the ellipsis using the same span styles.
      final String? ellipsis = line.ellipsis;
      if (ellipsis != null && box == line.boxes!.last) {
        final double x = offset.dx + line.left + box.right;
        canvas.fillText(ellipsis, x, y);
      }

      canvas._tearDownPaint();
    }
  }

  void _applySpanStyleToCanvas(FlatTextSpan span, BitmapCanvas canvas) {
    final SurfacePaint? paint;
    final ui.Paint? foreground = span.style._foreground;
    if (foreground != null) {
      paint = foreground as SurfacePaint;
    } else {
      paint = (ui.Paint()..color = span.style._color!) as SurfacePaint;
    }

    canvas.setCssFont(span.style.cssFontString);
    canvas._setUpPaint(paint.paintData, null);
  }
}
