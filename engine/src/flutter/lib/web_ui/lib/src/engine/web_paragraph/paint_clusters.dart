// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../../engine.dart';

/// Paints on a [WebParagraph].
///
/// It uses a [DomCanvasElement] to get text information
class PaintClusters extends TextPaint {
  PaintClusters(super.paragraph);

  // TODO(jlavrova): painting the entire block could require a really big canvas
  // Answer: we only do blocks for background and decorations which we do not draw on canvas
  // but rather implement ourselves via CanvasKit API
  void _paintByBlocks(
    StyleElements styleElement,
    ui.Canvas canvas,
    TextLayout layout,
    TextLine line,
    Painter painter,
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
          line.advance.left + line.formattingShift + block.shiftFromLineStart,
          line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
        ),
        ui.Offset(x, y),
        ui.window.devicePixelRatio,
      );

      if (WebParagraphDebug.logging) {
        WebParagraphDebug.log(
          '+_paintByBlocks: ${block.textRange} ${block.spanShiftFromLineStart} ${block.shiftFromLineStart} '
          '${line.advance} + ${line.formattingShift} '
          '\nsourceRect: $sourceRect targetRect: $targetRect',
        );
      }
      // Let's draw whatever has to be drawn
      switch (styleElement) {
        case StyleElements.background:
          painter.drawBackground(canvas, block, sourceRect, targetRect);
        case StyleElements.decorations:
          painter.resizePaintCanvas(
            ui.window.devicePixelRatio,
            sourceRect.width,
            sourceRect.height,
          );
          fillDecorations(block, sourceRect);
          painter.drawDecorations(canvas, sourceRect, targetRect);
        case StyleElements.text:
          throw Exception('Text should be drawn by clusters, not blocks');
        case StyleElements.shadows:
          throw Exception('Shadows should be drawn by clusters, not blocks');
      }
    }
  }

  void _paintByClusters(
    StyleElements styleElement,
    ui.Canvas canvas,
    TextLayout layout,
    TextLine line,
    Painter painter,
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
      if (block is PlaceholderBlock) {
        continue;
      }

      if (WebParagraphDebug.logging) {
        WebParagraphDebug.log(
          '+paintByClusters: ${block.textRange} ${block.clusterRange} ${(block as TextBlock).clusterRangeWithoutWhitespaces} ${block.whitespacesWidth} ${block.isLtr} ${line.advance.left} + ${line.formattingShift} + ${block.shiftFromLineStart}',
        );
      }

      // We are painting clusters in visual order so that if they step on each other, the paint
      // order is correct.
      final int start = block.isLtr
          ? (block as TextBlock).clusterRangeWithoutWhitespaces.start
          : (block as TextBlock).clusterRangeWithoutWhitespaces.end - 1;
      final int end = block.isLtr
          ? block.clusterRangeWithoutWhitespaces.end
          : block.clusterRangeWithoutWhitespaces.start - 1;
      final step = block.isLtr ? 1 : -1;
      for (var i = start; i != end; i += step) {
        final WebCluster clusterText = block is EllipsisBlock
            ? layout.ellipsisClusters[i]
            : layout.allClusters[i];
        // We need to adjust the canvas size to fit the block in case there is scaling or zoom involved
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
          ui.window.devicePixelRatio,
        );

        if (sourceRect.isEmpty) {
          // Let's skip empty clusters
          continue;
        }
        painter.resizePaintCanvas(ui.window.devicePixelRatio, sourceRect.width, sourceRect.height);
        switch (styleElement) {
          case StyleElements.shadows:
            paintContext.save();
            for (final ui.Shadow shadow in clusterText.style.shadows!) {
              fillShadowCluster(
                clusterText,
                shadow,
                // We shape ellipsis with default direction coming from the attaching block
                // and all the other blocks with the default paragraph direction
                block is EllipsisBlock
                    ? block.isLtr
                    : layout.paragraph.paragraphStyle.textDirection == ui.TextDirection.ltr,
              );
              painter.drawShadowCluster(canvas, sourceRect, targetRect);
            }
            paintContext.restore();
          case StyleElements.text:
            fillTextCluster(
              clusterText,
              // We shape ellipsis with default direction coming from the attaching block
              // and all the other blocks with the default paragraph direction.
              // The reason for shaping ellipsis this way is that we literally attach it to the block
              // that overflows and we want to keep all the styling attributes (including text direction) consistent.
              block is EllipsisBlock
                  ? block.isLtr
                  : layout.paragraph.paragraphStyle.textDirection == ui.TextDirection.ltr,
            );
            painter.drawTextCluster(canvas, sourceRect, targetRect);
          case StyleElements.background:
            throw Exception('Background should be drawn by blocks, not clusters');
          case StyleElements.decorations:
            throw Exception('Decorations should be drawn by blocks, not clusters');
        }
      }
    }
  }

  @override
  void paint(ui.Canvas canvas, TextLayout layout, Painter painter, double x, double y) {
    for (final TextLine line in layout.lines) {
      // Paint background first
      _paintByBlocks(StyleElements.background, canvas, layout, line, painter, x, y);

      // Paint all shadows on the line
      _paintByClusters(StyleElements.shadows, canvas, layout, line, painter, x, y);

      // Paint the text on the line
      _paintByClusters(StyleElements.text, canvas, layout, line, painter, x, y);

      // Paint decorations last
      _paintByBlocks(StyleElements.decorations, canvas, layout, line, painter, x, y);
    }
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

    // We fill the text cluster into a rectange [0,0,w,h]
    // but we need to shift the y coordinate by the font ascent
    // becase the text is drawn at the ascent, not at 0
    webTextCluster.fillOnContext(
      paintContext,
      /*ignore the text cluster shift from the text run*/
      // TODO(jlavrova): calculate the shadow bounds without hardcoding the inflation
      // values. It is good enough for now to demonstrate the shadow effect
      x: (isDefaultLtr ? 0 : webTextCluster.advance.width) + 100,
      y: 100,
    );
  }

  @override
  void fillTextCluster(WebCluster webTextCluster, bool isDefaultLtr) {
    final WebTextStyle style = webTextCluster.style;
    paintContext.fillStyle = style.getForegroundColor().toCssString();
    // We fill the text cluster into a rectange [0,0,w,h]
    // but we need to shift the y coordinate by the font ascent
    // becase the text is drawn at the ascent, not at 0
    webTextCluster.fillOnContext(
      paintContext,
      /*ignore the text cluster shift from the text run*/
      x: (isDefaultLtr ? 0 : webTextCluster.advance.width),
      y: 0,
    );
  }
}
