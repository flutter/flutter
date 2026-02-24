// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;
import '../../engine.dart';

/// Paints on a [WebParagraph].
///
/// It uses a [DomCanvasElement] to get text information
class PaintParagraph extends TextPaint {
  PaintParagraph(super.paragraph);

  void _fillAllBlocks(StyleElements styleElement, TextLayout layout) {
    // Paint the entire paragraph as a single image on Canvas2D
    double yOffset = 0;
    for (final TextLine line in layout.lines) {
      paintContext.save();
      paintContext.translate(line.formattingShift, yOffset);
      yOffset += line.advance.height;

      for (final LineBlock block in line.visualBlocks) {
        if (block is PlaceholderBlock) {
          // Placeholders do not need painting, just reserving the space
          continue;
        }

        if (WebParagraphDebug.logging) {
          WebParagraphDebug.log(
            '+_fillAllBlocks: ${block.textRange} ${block.clusterRange} ${paragraph.getText(block.textRange.start, block.textRange.end)} '
            '${(block as TextBlock).clusterRangeWithoutWhitespaces} ${block.whitespacesWidth} '
            '${block.isLtr} ${line.advance.left} + ${block.spanShiftFromLineStart}',
          );
        }

        paintContext.save();
        switch (styleElement) {
          case StyleElements.shadows:
            // For text and shadows we need to shift to the start of the block
            paintContext.translate(
              block.spanShiftFromLineStart,
              line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
            );
            _fillBlockShadows(layout, block as TextBlock);
          case StyleElements.text:
            // For text and shadows we need to shift to the start of the block
            paintContext.translate(
              block.spanShiftFromLineStart,
              line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
            );
            _fillBlockText(layout, block as TextBlock);
          case StyleElements.decorations:
            // For decorations we need to shift to the start of the line
            paintContext.translate(block.shiftFromLineStart, 0);
            // Let's calculate the sizes
            final (ui.Rect sourceRect, ui.Rect targetRect) = calculateBlock(
              layout,
              block as TextBlock,
              ui.Offset(line.advance.left + line.formattingShift, line.advance.top),
              ui.Offset.zero, // We only need sourceRect here so we don't need the offset
              ui.window.devicePixelRatio,
            );
            fillDecorations(block, sourceRect);
          case StyleElements.background:
            throw Exception(
              'Background is drawn directly on the output canvas, not on the canvas2D',
            );
        }
        paintContext.restore();
      }

      paintContext.restore();
    }
  }

  void _drawAllBlocks(
    StyleElements styleElement,
    ui.Canvas canvas,
    TextLayout layout,
    Painter painter,
    double x,
    double y,
  ) {
    for (final TextLine line in layout.lines) {
      for (final LineBlock block in line.visualBlocks) {
        if (block is PlaceholderBlock) {
          // Placeholders do not need painting, just reserving the space
          continue;
        }

        // Let's calculate the sizes
        final (ui.Rect sourceRect, ui.Rect targetRect) = calculateBlock(
          layout,
          block as TextBlock,
          ui.Offset(
            line.advance.left + line.formattingShift + block.shiftFromLineStart,
            line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
          ),
          ui.Offset(x, y),
          ui.window.devicePixelRatio,
        );

        WebParagraphDebug.log(
          '+_drawAllBlocks: ${block.textRange} ${block.clusterRange} ${paragraph.getText(block.textRange.start, block.textRange.end)} '
          '${block.clusterRangeWithoutWhitespaces} ${block.whitespacesWidth} '
          '${block.isLtr} ${line.advance.left} + ${block.spanShiftFromLineStart}',
        );

        switch (styleElement) {
          case StyleElements.background:
            painter.drawBackground(canvas, block, sourceRect, targetRect);
          case StyleElements.decorations:
            throw Exception(
              'Decorations are painted on the canvas2D and then drawn as an image on the output canvas, not drawn directly on the output canvas',
            );
          case StyleElements.shadows:
            throw Exception(
              'Shadows are painted on the canvas2D and then drawn as an image on the output canvas, not drawn directly on the output canvas',
            );
          case StyleElements.text:
            throw Exception(
              'Texts are painted on the canvas2D and then drawn as an image on the output canvas, not drawn directly on the output canvas',
            );
        }
      }
    }
  }

  void _fillBlockText(TextLayout layout, TextBlock block) {
    for (final (WebCluster clusterText, bool isLtr) in block.getTextClustersInVisualOrder(layout)) {
      fillTextCluster(clusterText, isLtr);
    }
    /*
    final int start = block.visualClusterStart;
    final int end = block.visualClusterEnd;
    final step = block.isLtr ? 1 : -1;
    for (var i = start; i != end; i += step) {
      final WebCluster clusterText = block is EllipsisBlock
          ? layout.ellipsisClusters[i]
          : layout.allClusters[i];

      fillTextCluster(
        clusterText,
        block is EllipsisBlock
            // We shape ellipsis with default direction coming from the attaching block
            // and all the other blocks with the default paragraph direction.
            // The reason for shaping ellipsis this way is that we literally attach it to the block
            // that overflows and we want to keep all the styling attributes (including text direction) consistent.
            ? block.isLtr
            : layout.paragraph.paragraphStyle.textDirection == ui.TextDirection.ltr,
      );
    }
    */
  }

  void _fillBlockShadows(TextLayout layout, TextBlock block) {
    if (!block.style.hasElement(StyleElements.shadows) || block.style.shadows == null) {
      return;
    }

    for (final (WebCluster clusterText, bool isLtr) in block.getTextClustersInVisualOrder(layout)) {
      for (final ui.Shadow shadow in clusterText.style.shadows!) {
        fillShadowCluster(clusterText, shadow, isLtr);
      }
    }
    /*
    final int start = block.visualClusterStart;
    final int end = block.visualClusterEnd;
    final step = block.isLtr ? 1 : -1;
    for (var i = start; i != end; i += step) {
      final WebCluster clusterText = block is EllipsisBlock
          ? layout.ellipsisClusters[i]
          : layout.allClusters[i];

      for (final ui.Shadow shadow in clusterText.style.shadows!) {
        fillShadowCluster(clusterText, shadow, block.isLtr);
      }
    }
    */
  }

  @override
  void fillTextCluster(WebCluster webTextCluster, bool isDefaultLtr) {
    final WebTextStyle style = webTextCluster.style;
    paintContext.fillStyle = style.getForegroundColor().toCssString();
    webTextCluster.addToContext(paintContext, 0, 0);
  }

  @override
  void fillShadowCluster(WebCluster webTextCluster, ui.Shadow shadow, bool isDefaultLtr) {
    final WebTextStyle style = webTextCluster.style;

    // TODO(jlavrova): see if we can implement shadowing ourself avoiding redrawing text clusters many times.
    // Answer: we cannot, and also there is a question of calculating the size of the shadow which we have to
    // take from Chrome as well (performing another measure text operation with shadow attribute set).
    paintContext.fillStyle = style.getForegroundColor().toCssString();
    paintContext.shadowColor = shadow.color.toCssString();
    paintContext.shadowBlur = shadow.blurRadius;
    paintContext.shadowOffsetX = shadow.offset.dx;
    paintContext.shadowOffsetY = shadow.offset.dy;
    WebParagraphDebug.log(
      'Shadow: x=${shadow.offset.dx} y=${shadow.offset.dy} blur=${shadow.blurRadius} color=${shadow.color.toCssString()}',
    );

    webTextCluster.addToContext(paintContext, 0, 0);
  }

  @override
  void paint(ui.Canvas canvas, TextLayout layout, Painter painter, double x, double y) {
    final (ui.Rect sourceRect, ui.Rect targetRect) = calculateParagraph(
      layout,
      ui.Offset(x, y),
      ui.window.devicePixelRatio,
    );
    // TODO(jlavrova): How resizing affects the cached image?
    painter.resizePaintCanvas(ui.window.devicePixelRatio, sourceRect.width, sourceRect.height);

    if (!painter.hasSingleImageCache) {
      // Fill out all the blocks on Canvas2D canvas
      _fillAllBlocks(StyleElements.shadows, layout);
      _fillAllBlocks(StyleElements.text, layout);
      _fillAllBlocks(StyleElements.decorations, layout);

      // Draw background blocks directly on the output canvas
      // so it will be cached together with the text blocks on Canvas2D canvas
      _drawAllBlocks(StyleElements.background, canvas, layout, painter, x, y);
    } else {
      // We already have cached image for the entire paragraph (including the backgrounds)
    }

    // Draw the content of Canvas2D on the output canvas
    painter.drawParagraph(canvas, sourceRect, targetRect);
  }
}
