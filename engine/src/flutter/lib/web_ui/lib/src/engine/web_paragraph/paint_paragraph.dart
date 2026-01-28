// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

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

        WebParagraphDebug.log(
          '+_fillAllBlocks: ${block.textRange} ${block.clusterRange} ${paragraph.getText(block.textRange.start, block.textRange.end)} '
          '${(block as TextBlock).clusterRangeWithoutWhitespaces} ${block.whitespacesWidth} '
          '${block.isLtr} ${line.advance.left} + ${block.spanShiftFromLineStart}',
        );

        paintContext.save();
        switch (styleElement) {
          case StyleElements.shadows:
            // For text and shadows we need to shift to the start of the block
            paintContext.translate(
              block.spanShiftFromLineStart,
              line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
            );
            _fillBlockShadows(layout, block);
          case StyleElements.text:
            // For text and shadows we need to shift to the start of the block
            paintContext.translate(
              block.spanShiftFromLineStart,
              line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
            );
            _fillBlockText(layout, block);
          case StyleElements.decorations:
            // For decorations we need to shift to the start of the line
            paintContext.translate(block.shiftFromLineStart, 0);
            // Let's calculate the sizes
            final (ui.Rect sourceRect, ui.Rect targetRect) = calculateBlock(
              layout,
              block,
              ui.Offset(line.advance.left + line.formattingShift, line.advance.top),
              ui.Offset.zero, // We only need sourceRect here so we don't need the offset
              ui.window.devicePixelRatio,
            );
            _fillBlockDecorations(block, sourceRect);
          default:
            // We only need to draw backgrounds only
            assert(false);
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
          default:
            // We only need to draw backgrounds only
            assert(false);
        }
      }
    }
  }

  void _fillBlockText(TextLayout layout, TextBlock block) {
    final int start = block.isLtr
        ? block.clusterRangeWithoutWhitespaces.start
        : block.clusterRangeWithoutWhitespaces.end - 1;
    final int end = block.isLtr
        ? block.clusterRangeWithoutWhitespaces.end
        : block.clusterRangeWithoutWhitespaces.start - 1;
    final step = block.isLtr ? 1 : -1;
    for (var i = start; i != end; i += step) {
      final WebCluster clusterText = block is EllipsisBlock
          ? layout.ellipsisClusters[i]
          : layout.allClusters[i];

      fillTextCluster(
        clusterText,
        block is EllipsisBlock
            ? block.isLtr
            // TODO(jlavrova): override isLtr for ellipsis block?
            : layout.paragraph.paragraphStyle.textDirection == ui.TextDirection.ltr,
      );
    }
  }

  void _fillBlockShadows(TextLayout layout, TextBlock block) {
    if (!block.style.hasElement(StyleElements.shadows) || block.style.shadows == null) {
      return;
    }

    final int start = block.isLtr
        ? block.clusterRangeWithoutWhitespaces.start
        : block.clusterRangeWithoutWhitespaces.end - 1;
    final int end = block.isLtr
        ? block.clusterRangeWithoutWhitespaces.end
        : block.clusterRangeWithoutWhitespaces.start - 1;
    final step = block.isLtr ? 1 : -1;
    for (var i = start; i != end; i += step) {
      final WebCluster clusterText = block is EllipsisBlock
          ? layout.ellipsisClusters[i]
          : layout.allClusters[i];

      for (final ui.Shadow shadow in clusterText.style.shadows!) {
        fillShadowCluster(clusterText, shadow, block.isLtr);
      }
    }
  }

  void _fillBlockDecorations(TextBlock block, ui.Rect sourceRect) {
    if (!block.style.hasElement(StyleElements.decorations) || block.style.decoration == null) {
      return;
    }
    paintContext.fillStyle = block.style.getForegroundColor().toCssString();

    final double thickness = calculateThickness(block.style);
    const DoubleDecorationSpacing = 3.0;

    for (final ui.TextDecoration decoration in [
      ui.TextDecoration.lineThrough,
      ui.TextDecoration.underline,
      ui.TextDecoration.overline,
    ]) {
      if (!block.style.decoration!.contains(decoration)) {
        continue;
      }

      // TODO(jlavrova): Why using these instead of multiplied values?
      final double height = block.rawFontBoundingBoxAscent + block.rawFontBoundingBoxDescent;
      final double ascent = block.rawFontBoundingBoxAscent;
      final double position = calculatePosition(decoration, thickness, height, ascent);
      WebParagraphDebug.log('decoration=$decoration thickness=$thickness position=$position');

      final double width = sourceRect.width;
      final double x = sourceRect.left;
      final double y = sourceRect.top + position;

      paintContext.save();
      paintContext.lineWidth = thickness;
      paintContext.strokeStyle = block.style.decorationColor!.toCssString();

      switch (block.style.decorationStyle!) {
        case ui.TextDecorationStyle.wavy:
          calculateWaves(x, y, block.style, sourceRect, thickness);

        case ui.TextDecorationStyle.double:
          final double bottom = y + DoubleDecorationSpacing + thickness;
          paintContext.beginPath();
          paintContext.moveTo(x, y);
          paintContext.lineTo(x + width, y);
          paintContext.moveTo(x, bottom);
          paintContext.lineTo(x + width, bottom);
          paintContext.stroke();
          WebParagraphDebug.log('double: $x:${x + width}, $y:$bottom');

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
          WebParagraphDebug.log('dashed/dotted: $x:${x + width}, $y');

        case ui.TextDecorationStyle.solid:
          paintContext.beginPath();
          paintContext.moveTo(x, y);
          paintContext.lineTo(x + width, y);
          paintContext.stroke();
          WebParagraphDebug.log(
            'solid: $x:${x + width}, $y ${block.style.decorationColor!.toCssString()}',
          );
      }
      paintContext.restore();
    }
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

    // TODO(jlavrova): calculate the proper shift for the shadow
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
      _drawAllBlocks(StyleElements.background, canvas, layout, painter, x, y);
    } else {
      // We already have cached image for the entire paragraph (including the backgrounds)
    }

    // Draw the content of Canvas2D on the output canvas
    painter.drawParagraph(canvas, sourceRect, targetRect);
  }
}
