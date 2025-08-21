// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_canvas.dart';
import '../dom.dart';
import 'debug.dart';
import 'layout.dart';
import 'painter.dart';
import 'paragraph.dart';

typedef PaintBlock =
    void Function(CanvasKitCanvas canvas, LineBlock block, ui.Rect sourceRect, ui.Rect targetRect);

// TODO(jlavrova): switch to abstract
typedef PaintCluster =
    void Function(
      CanvasKitCanvas canvas,
      ExtendedTextCluster cluster,
      bool isDefaultLtr,
      ui.Rect sourceRect,
      ui.Rect targetRect,
    );

/// Paints on a [WebParagraph].
///
/// It uses a [DomCanvasElement] to get text information
class TextPaint {
  TextPaint(this.paragraph, this.painter);

  final WebParagraph paragraph;
  final Painter painter;

  // TODO(jlavrova): painting the entire block could require a really big canvas
  // Answer: we only do blocks for background and decorations which we do not draw on canvas
  // but rather implement ourselves via CanvasKit API
  void fillByBlocks(
    StyleElements styleElement,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    // We traverse text in visual blocks order (broken by text styles and bidi runs, then reordered)
    for (final LineBlock block in line.visualBlocks) {
      if (!block.textStyle.hasElement(styleElement)) {
        continue;
      }
      // Placeholders do not need painting, just reserving the space
      if (block is LinePlaceholdeBlock) {
        continue;
      }
      // Let's calculate the sizes
      final (ui.Rect sourceRect, ui.Rect targetRect) = calculateBlock(
        block as LineClusterBlock,
        ui.Offset(
          line.advance.left + line.formattingShift + block.clusterShiftInLine,
          line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
        ),
        ui.Offset(x, y),
      );
      // Let's draw whatever has to be drawn
      switch (styleElement) {
        case StyleElements.background:
          break;
        case StyleElements.decorations:
          painter.fillDecorations(block, sourceRect);
        case StyleElements.shadows:
          painter.fillShadows(block, sourceRect);
        case StyleElements.text:
          painter.fillText(block, x, y);
      }
    }
  }

  void reset(double width, double height) {
    painter.reset(width, height);
  }

  void paintByBlocks(
    StyleElements styleElement,
    ui.Canvas canvas,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    // We traverse text in visual blocks order (broken by text styles and bidi runs, then reordered)
    for (final LineBlock block in line.visualBlocks) {
      if (!block.textStyle.hasElement(styleElement)) {
        continue;
      }
      // Placeholders do not need painting, just reserving the space
      if (block is LinePlaceholdeBlock) {
        continue;
      }
      // Let's calculate the sizes
      final (ui.Rect sourceRect, ui.Rect targetRect) = calculateBlock(
        block as LineClusterBlock,
        ui.Offset(
          line.advance.left + line.formattingShift + block.clusterShiftInLine,
          line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
        ),
        ui.Offset(x, y),
      );
      // Let's draw whatever has to be drawn
      switch (styleElement) {
        case StyleElements.background:
          painter.paintBackground(canvas, block, sourceRect, targetRect);
        case StyleElements.decorations:
          painter.paintDecorations(canvas, sourceRect, targetRect);
        case StyleElements.shadows:
          painter.paintShadows(canvas, sourceRect, targetRect);
        case StyleElements.text:
          painter.paintText(canvas, block, sourceRect, targetRect);
      }
    }
  }

  (ui.Rect sourceRect, ui.Rect targetRect) calculateLine(
    TextLine line,
    ui.Offset blockOffset,
    ui.Offset paragraphOffset,
  ) {
    // Define the text clusters rect (using advances, not selected rects)
    final ui.Rect sourceRect = ui.Rect.fromLTWH(0, 0, line.advance.width, line.advance.height);

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)
    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = sourceRect
        .translate(line.advance.left, line.advance.top)
        .translate(paragraphOffset.dx, paragraphOffset.dy);

    final String text = paragraph.getText(line.textRange);
    //print(
    //  'calculateLine "$text" ${line.allLineTextRange} '
    //  'source: ${sourceRect.left}:${sourceRect.right}x${sourceRect.top}:${sourceRect.bottom} => '
    //  'target: ${targetRect.left}:${targetRect.right}x${targetRect.top}:${targetRect.bottom}',
    //);

    return (sourceRect, targetRect);
  }

  (ui.Rect sourceRect, ui.Rect targetRect) calculateBlock(
    LineClusterBlock block,
    ui.Offset blockOffset,
    ui.Offset paragraphOffset,
  ) {
    final ui.Rect advance = block.textMetrics!.getAdvance(
      block.textRange.translate(-block.textMetricsZero),
    );

    final int start = block.bidiLevel.isEven
        ? block.clusterRange.start
        : block.clusterRange.end - 1;
    final ExtendedTextCluster startCluster = block.layout!.textClusters[start];

    // Define the text clusters rect (using advances, not selected rects)
    final ui.Rect zeroRect = ui.Rect.fromLTWH(0, 0, advance.width, advance.height);
    final ui.Rect sourceRect = zeroRect;

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)
    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        .translate(blockOffset.dx + startCluster.advance.left, blockOffset.dy)
        .translate(paragraphOffset.dx, paragraphOffset.dy);

    final String text = paragraph.getText(block.textRange);
    WebParagraphDebug.log(
      'calculateBlock "$text" ${block.textRange}-${block.textMetricsZero} ${block.clusterRange} '
      'source: ${sourceRect.left}:${sourceRect.right}x${sourceRect.top}:${sourceRect.bottom} => '
      'target: ${targetRect.left}:${targetRect.right}x${targetRect.top}:${targetRect.bottom}',
    );

    return (sourceRect, targetRect);
  }

  void paintLineOnCanvas2D(
    DomHTMLCanvasElement canvas,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    for (int i = line.textRange.start; i < line.textRange.end; i++) {
      final clusterText = layout.textClusters[i];
      final DomCanvasRenderingContext2D context = canvas.context2D;
      context.font = '50px arial';
      context.fillStyle = 'black';
      context.fillTextCluster(clusterText.cluster!, x, y);
    }
  }

  void fillByLine(
    StyleElements styleElement,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    if (!painter.cached()) {
      fillByBlocks(StyleElements.text, layout, line, x, y);
    }
  }

  void paintAll(ui.Canvas canvas, double x, double y) {
    painter.paintAll(canvas, x, y);
  }
}
