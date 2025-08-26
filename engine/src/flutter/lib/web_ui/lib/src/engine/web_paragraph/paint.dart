// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;
import '../dom.dart';
import 'debug.dart';
import 'layout.dart';
import 'painter.dart';
import 'paragraph.dart';

typedef PaintBlock =
    void Function(ui.Canvas canvas, LineBlock block, ui.Rect sourceRect, ui.Rect targetRect);

// TODO(jlavrova): switch to abstract
typedef PaintCluster =
    void Function(
      ui.Canvas canvas,
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
  void _paintByBlocks(
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
        layout,
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
          painter.fillDecorations(block, sourceRect);
          painter.paintDecorations(canvas, sourceRect, targetRect);
        default:
          assert(false);
      }
    }
  }

  void _paintByClusters(
    StyleElements styleElement,
    ui.Canvas canvas,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    // We traverse clusters in the order of visual blocks (broken by text styles and bidi runs, then reordered)
    // and then in visual order inside blocks
    for (final LineBlock block in line.visualBlocks) {
      if (!block.textStyle.hasElement(styleElement)) {
        continue;
      }
      // Placeholders do not need painting, just reserving the space
      if (block.clusterRange.size == 1 &&
          layout.textClusters[block.clusterRange.start].placeholder) {
        continue;
      }
      WebParagraphDebug.log(
        'paintByClusters: ${line.fontBoundingBoxAscent} - ${block.rawFontBoundingBoxAscent}',
      );
      final int start = block.bidiLevel.isEven
          ? block.clusterRange.start
          : block.clusterRange.end - 1;
      final int end = block.bidiLevel.isEven
          ? block.clusterRange.end
          : block.clusterRange.start - 1;
      final int step = block.bidiLevel.isEven ? 1 : -1;
      for (int i = start; i != end; i += step) {
        final clusterText = layout.textClusters[i];
        final (ui.Rect sourceRect, ui.Rect targetRect) = calculateCluster(
          layout,
          block,
          clusterText,
          ui.Offset(
            line.advance.left + line.formattingShift + block.clusterShiftInLine,
            line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
          ),
          ui.Offset(x, y),
        );
        switch (styleElement) {
          case StyleElements.shadows:
            for (final ui.Shadow shadow in clusterText.textStyle!.shadows!) {
              painter.fillShadow(clusterText, shadow, layout.isDefaultLtr);
              painter.paintShadow(canvas, sourceRect, targetRect);
            }
          case StyleElements.text:
            painter.fillTextCluster(clusterText, layout.isDefaultLtr);
            painter.paintTextCluster(canvas, sourceRect, targetRect);
          default:
            assert(false);
        }
      }
    }
  }

  (ui.Rect sourceRect, ui.Rect targetRect) calculateCluster(
    TextLayout layout,
    LineBlock block,
    ExtendedTextCluster webTextCluster,
    ui.Offset clusterOffset,
    ui.Offset lineOffset,
  ) {
    // Define the text cluster bounds
    final pos = webTextCluster.bounds.left - webTextCluster.advance.left;
    final ui.Rect zeroRect = ui.Rect.fromLTWH(
      pos,
      0,
      webTextCluster.bounds.width,
      webTextCluster.advance.height,
    );
    final ui.Rect sourceRect = zeroRect;

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)

    final double left = clusterOffset.dx + webTextCluster.advance.left + lineOffset.dx;
    final double shift = left - left.floorToDouble();
    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        .translate(clusterOffset.dx + webTextCluster.advance.left, clusterOffset.dy)
        .translate(lineOffset.dx, lineOffset.dy)
        .translate(-shift, 0);

    final String text = paragraph.getText(webTextCluster.textRange);
    WebParagraphDebug.log(
      'calculateBlock "$text" ${block.textRange}-${block.textMetricsZero} ${block.clusterRange} source: $sourceRect => target: $targetRect',
    );

    return (sourceRect, targetRect);
  }

  (ui.Rect sourceRect, ui.Rect targetRect) calculateBlock(
    TextLayout layout,
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
    final ExtendedTextCluster startCluster = layout.textClusters[start];

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

  void paintLine(ui.Canvas canvas, TextLayout layout, TextLine line, double x, double y) {
    WebParagraphDebug.log('paintLineOnCanvasKit.Background: ${line.textRange}');
    _paintByBlocks(StyleElements.background, canvas, layout, line, x, y);

    WebParagraphDebug.log('paintLineOnCanvasKit.Shadows: ${line.textRange}');
    _paintByClusters(StyleElements.shadows, canvas, layout, line, x, y);

    WebParagraphDebug.log('paintLineOnCanvasKit.Text: ${line.textRange}');
    _paintByClusters(StyleElements.text, canvas, layout, line, x, y);

    WebParagraphDebug.log('paintLineOnCanvasKit.Decorations: ${line.textRange}');
    _paintByBlocks(StyleElements.decorations, canvas, layout, line, x, y);
  }
}
