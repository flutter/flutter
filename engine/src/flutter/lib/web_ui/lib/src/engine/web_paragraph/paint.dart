// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_api.dart';
import '../canvaskit/canvaskit_canvas.dart';
import '../canvaskit/image.dart';
import '../dom.dart';
import '../util.dart';
import 'debug.dart';
import 'layout.dart';
import 'painter.dart';
import 'paragraph.dart';

typedef PaintBlock =
    void Function(CanvasKitCanvas canvas, LineBlock block, ui.Rect sourceRect, ui.Rect targetRect);

typedef PaintCluster =
    void Function(
      CanvasKitCanvas canvas,
      ExtendedTextCluster cluster,
      bool isDefaultLtr,
      ui.Rect sourceRect,
      ui.Rect targetRect,
    );

/// Performs layout on a [WebParagraph].
class TextPaint {
  TextPaint(this.paragraph, this.painter);

  final WebParagraph paragraph;
  final Painter painter;

  // TODO(jlavrova): painting the entire block could require a really big canvas
  void paintByBlocks(
    StyleElements styleElement,
    CanvasKitCanvas canvas,
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
      // Let's calculate the sizes
      final (ui.Rect sourceRect, ui.Rect targetRect) = calculateBlock(
        layout,
        block,
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
          painter.paintDecorations(canvas, block, sourceRect, targetRect);
        default:
          assert(false);
      }
    }
  }

  void paintByClusters(
    StyleElements styleElement,
    CanvasKitCanvas canvas,
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
      WebParagraphDebug.log(
        'paintByClusters: ${line.fontBoundingBoxAscent} - ${block.rawFontBoundingBoxAscent}',
      );
      final int start =
          block.bidiLevel.isEven ? block.clusterRange.start : block.clusterRange.end - 1;
      final int end =
          block.bidiLevel.isEven ? block.clusterRange.end : block.clusterRange.start - 1;
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
            painter.paintShadows(canvas, clusterText, layout.isDefaultLtr, sourceRect, targetRect);
          case StyleElements.text:
            painter.paintTextCluster(
              canvas,
              clusterText,
              layout.isDefaultLtr,
              sourceRect,
              targetRect,
            );
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
    LineBlock block,
    ui.Offset blockOffset,
    ui.Offset paragraphOffset,
  ) {
    final advance = paragraph.getLayout().getAdvance(
      block.textMetrics!,
      block.textRange.translate(-block.textMetricsZero),
    );

    final int start =
        block.bidiLevel.isEven ? block.clusterRange.start : block.clusterRange.end - 1;
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

  void paintLineOnCanvasKit(
    CanvasKitCanvas canvas,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    WebParagraphDebug.log('paintLineOnCanvasKit.Background: ${line.textRange}');
    paintByBlocks(StyleElements.background, canvas, layout, line, x, y);

    WebParagraphDebug.log('paintLineOnCanvasKit.Shadows: ${line.textRange}');
    paintByClusters(StyleElements.shadows, canvas, layout, line, x, y);

    WebParagraphDebug.log('paintLineOnCanvasKit.Text: ${line.textRange}');
    paintByClusters(StyleElements.text, canvas, layout, line, x, y);

    WebParagraphDebug.log('paintLineOnCanvasKit.Decorations: ${line.textRange}');
    paintByBlocks(StyleElements.decorations, canvas, layout, line, x, y);
  }
}
