// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'debug.dart';
import 'layout.dart';
import 'painter.dart';
import 'paragraph.dart';

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
      if (!block.style.hasElement(styleElement)) {
        continue;
      }
      // Placeholders do not need painting, just reserving the space
      if (block is PlaceholderBlock) {
        continue;
      }
      // Let's calculate the sizes
      final (ui.Rect sourceRect, ui.Rect targetRect) = calculateBlock(
        layout,
        block as TextBlock,
        ui.Offset(
          line.advance.left + line.formattingShift,
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
      if (!block.style.hasElement(styleElement)) {
        continue;
      }
      // Placeholders do not need painting, just reserving the space
      if (block.clusterRange.size == 1 &&
          layout.allClusters[block.clusterRange.start] is PlaceholderCluster) {
        continue;
      }

      WebParagraphDebug.log(
        '+paintByClusters: ${block.textRange} ${block.clusterRange} ${(block as TextBlock).clusterRangeWithoutWhitespaces} ${block.whitespacesWidth} ${block.isLtr} ${line.advance.left} + ${line.formattingShift} + ${block.shiftFromLineStart}',
      );
      // We are painting clusters in visual order so that if they step on each other, the paint
      // order is correct.
      final int start = block.isLtr
          ? block.clusterRangeWithoutWhitespaces.start
          : block.clusterRangeWithoutWhitespaces.end - 1;
      final int end = block.isLtr
          ? block.clusterRangeWithoutWhitespaces.end
          : block.clusterRangeWithoutWhitespaces.start - 1;
      final int step = block.isLtr ? 1 : -1;
      for (int i = start; i != end; i += step) {
        final clusterText = layout.allClusters[i];
        final (ui.Rect sourceRect, ui.Rect targetRect) = calculateCluster(
          layout,
          block,
          clusterText,
          ui.Offset(
            // TODO(mdebbar): Avoid use of `block.spanShiftFromLineStart` (similar to `getPositionForOffset`)
            line.advance.left + line.formattingShift + block.spanShiftFromLineStart,
            line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
          ),
          ui.Offset(x, y),
        );
        switch (styleElement) {
          case StyleElements.shadows:
            paintContext.save();
            for (final ui.Shadow shadow in clusterText.style.shadows!) {
              painter.fillShadow(clusterText, shadow, layout.isDefaultLtr);
              painter.paintShadow(canvas, sourceRect, targetRect);
            }
            paintContext.restore();
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
    WebCluster webTextCluster,
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

    if (WebParagraphDebug.logging) {
      final String text = paragraph.getText1(webTextCluster.start, webTextCluster.end);
      WebParagraphDebug.log(
        'calculateCluster "$text" webTextCluster.bounds.width=${webTextCluster.bounds.width} clusterOffset.dx=${clusterOffset.dx}+webTextCluster.advance.left=${webTextCluster.advance.left}+lineOffset.dx=${lineOffset.dx}\nsource: $sourceRect => target: $targetRect',
      );
    }

    return (sourceRect, targetRect);
  }

  (ui.Rect sourceRect, ui.Rect targetRect) calculateBlock(
    TextLayout layout,
    TextBlock block,
    ui.Offset blockOffset,
    ui.Offset paragraphOffset,
  ) {
    final ui.Rect advance = block.advance;

    // Define the text clusters rect (using advances, not selected rects)
    final ui.Rect zeroRect = ui.Rect.fromLTWH(0, 0, advance.width, advance.height);
    final ui.Rect sourceRect = zeroRect;

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)
    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        // TODO(jlavrova): Can we use `block.advance.left` instead of the cluster? That way
        //                 we don't have to worry about LTR vs RTL to get first cluster.
        .translate(blockOffset.dx + block.advance.left, blockOffset.dy)
        .translate(paragraphOffset.dx, paragraphOffset.dy);

    final String text = paragraph.getText(block.textRange);
    WebParagraphDebug.log(
      'calculateBlock "$text" ${block.textRange}-${block.span.start} ${block.clusterRange} '
      'source: ${sourceRect.left}:${sourceRect.right}x${sourceRect.top}:${sourceRect.bottom} => '
      'target: ${targetRect.left}:${targetRect.right}x${targetRect.top}:${targetRect.bottom}',
    );

    return (sourceRect, targetRect);
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
