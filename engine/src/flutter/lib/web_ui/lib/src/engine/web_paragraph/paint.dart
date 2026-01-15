// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../../engine.dart';

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
          line.advance.left + line.formattingShift + block.shiftFromLineStart,
          line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
        ),
        ui.Offset(x, y),
        ui.window.devicePixelRatio,
      );

      WebParagraphDebug.log(
        '+_paintByBlocks: ${block.textRange} ${block.spanShiftFromLineStart} ${block.shiftFromLineStart} '
        '${line.advance} + ${line.formattingShift} '
        '\nsourceRect: $sourceRect targetRect: $targetRect',
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
        switch (styleElement) {
          case StyleElements.shadows:
            paintContext.save();
            for (final ui.Shadow shadow in clusterText.style.shadows!) {
              painter.fillShadow(
                clusterText,
                shadow,
                // We shape ellipsis with default direction coming from the attaching block
                // and all the other blocks with the default paragraph direction
                block is EllipsisBlock
                    ? block.isLtr
                    : layout.paragraph.paragraphStyle.textDirection == ui.TextDirection.ltr,
              );
              painter.paintShadow(canvas, sourceRect, targetRect);
            }
            paintContext.restore();
          case StyleElements.text:
            painter.fillTextCluster(
              clusterText,
              // We shape ellipsis with default direction coming from the attaching block
              // and all the other blocks with the default paragraph direction.
              // The reason for shaping ellipsis this way is that we literally attach it to the block
              // that overflows and we want to keep all the styling attributes (including text direction) consistent.
              block is EllipsisBlock
                  ? block.isLtr
                  : layout.paragraph.paragraphStyle.textDirection == ui.TextDirection.ltr,
            );
            painter.paintTextCluster(canvas, sourceRect, targetRect);
          default:
            assert(false);
        }
      }
    }
  }

  void _paintByClustersOnCanvas2D(
    StyleElements styleElement,
    DomHTMLCanvasElement canvas,
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
      final step = block.isLtr ? 1 : -1;
      for (var i = start; i != end; i += step) {
        final WebCluster clusterText = block is EllipsisBlock
            ? layout.ellipsisClusters[i]
            : layout.allClusters[i];
        // We need to adjust the canvas size to fit the block in case there is scaling or zoom involved
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
        switch (styleElement) {
          case StyleElements.text:
            final WebTextStyle style = clusterText.style;
            paintContext.fillStyle = style.getForegroundColor().toCssString();
            // We fill the text cluster into a rectange [0,0,w,h]
            // but we need to shift the y coordinate by the font ascent
            // becase the text is drawn at the ascent, not at 0
            clusterText.fillOnContext(
              paintContext,
              /*ignore the text cluster shift from the text run*/
              x: (block.isLtr ? 0 : clusterText.advance.width),
              y: 0,
            );

            final DomImageBitmap bitmap = paintCanvas.transferToImageBitmap();
            canvas.context2D.drawImage(
              bitmap,
              sourceRect.left,
              sourceRect.top,
              sourceRect.width,
              sourceRect.height,
              targetRect.left,
              targetRect.top,
              targetRect.width,
              targetRect.height,
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
    WebCluster webTextCluster,
    ui.Offset clusterOffset,
    ui.Offset lineOffset,
    double devicePixelRatio,
  ) {
    // Define the text cluster bounds
    final double pos = webTextCluster.bounds.left - webTextCluster.advance.left;

    // Define the text cluster bounds
    // Source rect must take in account the scaling
    final sourceRect = ui.Rect.fromLTWH(
      pos * devicePixelRatio,
      0,
      webTextCluster.bounds.width.ceilToDouble() * devicePixelRatio,
      webTextCluster.advance.height.ceilToDouble() * devicePixelRatio,
    );
    // Target rect will be scaled by the canvas transform, so we don't scale it here
    final zeroRect = ui.Rect.fromLTWH(
      pos,
      0,
      webTextCluster.bounds.width.ceilToDouble(),
      webTextCluster.advance.height.ceilToDouble(),
    );

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)

    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        .translate(clusterOffset.dx + webTextCluster.advance.left, clusterOffset.dy)
        .translate(lineOffset.dx, lineOffset.dy);

    if (WebParagraphDebug.logging) {
      final String text = block is EllipsisBlock
          ? paragraph.paragraphStyle.ellipsis!
          : paragraph.getText(webTextCluster.start, webTextCluster.end);
      final double left = clusterOffset.dx + webTextCluster.advance.left + lineOffset.dx;
      final double shift = left - left.floorToDouble();
      WebParagraphDebug.log(
        'calculateCluster "$text" bounds: ${webTextCluster.bounds} advance: ${webTextCluster.advance} shift $shift\n'
        'clusterOffset: $clusterOffset lineOffset: $lineOffset\n'
        'source: $sourceRect => target: $targetRect',
      );
    }

    return (sourceRect, targetRect);
  }

  (ui.Rect sourceRect, ui.Rect targetRect) calculateBlock(
    TextLayout layout,
    TextBlock block,
    ui.Offset blockOffset,
    ui.Offset paragraphOffset,
    double devicePixelRatio,
  ) {
    final ui.Rect advance = block.advance;

    // Define the text clusters rect (using advances, not selected rects)
    // Source rect must take in account the scaling
    final sourceRect = ui.Rect.fromLTWH(
      0,
      0,
      advance.width * devicePixelRatio,
      advance.height * devicePixelRatio,
    );
    // Target rect will be scaled by the canvas transform, so we don't scale it here
    final zeroRect = ui.Rect.fromLTWH(0, 0, advance.width, advance.height);

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)
    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        // TODO(jlavrova): Can we use `block.advance.left` instead of the cluster? That way
        //                 we don't have to worry about LTR vs RTL to get first cluster.
        .translate(blockOffset.dx, blockOffset.dy)
        .translate(paragraphOffset.dx, paragraphOffset.dy);

    WebParagraphDebug.log(
      'calculateBlock "${block.span.text}" ${block.textRange}-${block.span.start} ${block.clusterRange} '
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

  void paintLineOnCanvas2D(
    DomHTMLCanvasElement canvas,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    WebParagraphDebug.log('paintLineOnCanvasKit.Text: ${line.textRange}');
    _paintByClustersOnCanvas2D(StyleElements.text, canvas, layout, line, x, y);
  }

  void fillAsSingleImage(
    ui.Canvas canvas,
    TextLayout layout,
    ui.Rect sourceRect,
    ui.Offset offset,
  ) {
    if (painter.hasSingleImageCache) {
      return;
    }

    painter.resizePaintCanvas(ui.window.devicePixelRatio, sourceRect.width, sourceRect.height);
    // Paint the entire paragraph as a single image on Canvas2D
    double yOffset = 0;
    for (final TextLine line in layout.lines) {
      paintContext.save();
      paintContext.translate(line.formattingShift, yOffset);
      WebParagraphDebug.log('fillAsSingleImage line at ${line.formattingShift}, $yOffset');
      yOffset += line.advance.height;

      for (final LineBlock block in line.visualBlocks) {
        // Placeholders do not need painting, just reserving the space
        if (block.clusterRange.size == 1 &&
            layout.allClusters[block.clusterRange.start] is PlaceholderCluster) {
          continue;
        }

        WebParagraphDebug.log(
          '+addClustersToCanvas2D: ${block.textRange} ${block.clusterRange} ${paragraph.getText(block.textRange.start, block.textRange.end)} '
          '${(block as TextBlock).clusterRangeWithoutWhitespaces} ${block.whitespacesWidth} '
          '${block.isLtr} ${line.advance.left} + ${block.spanShiftFromLineStart}',
        );

        paintContext.save();
        paintContext.translate(block.spanShiftFromLineStart, 0);
        addTextClusters(layout, block);
        paintContext.restore();

        paintContext.save();
        paintContext.translate(block.spanShiftFromLineStart, 0);
        addShadows(layout, block);
        paintContext.restore();
      }

      paintContext.restore();
    }
  }

  void paintAsSingleImage(
    ui.Canvas canvas,
    TextLayout layout,
    ui.Rect sourceRectParagraph,
    ui.Rect targetRectParagraph,
    ui.Offset offset,
  ) {
    for (final TextLine line in layout.lines) {
      for (final LineBlock block in line.visualBlocks) {
        // Placeholders do not need painting, just reserving the space
        if (block is! TextBlock) {
          continue;
        }
        // Let's calculate the sizes
        final (ui.Rect sourceRect, ui.Rect targetRect) = calculateBlock(
          layout,
          block,
          ui.Offset(
            line.advance.left + line.formattingShift + block.shiftFromLineStart,
            line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
          ),
          offset,
          ui.window.devicePixelRatio,
        );
        if (block.style.hasElement(StyleElements.background)) {
          painter.paintBackground(canvas, block, sourceRect, targetRect);
        }
      }
    }

    painter.paintTextBlockAsSingleImage(canvas, sourceRectParagraph, targetRectParagraph);

    for (final TextLine line in layout.lines) {
      for (final LineBlock block in line.visualBlocks) {
        // Placeholders do not need painting, just reserving the space
        if (block is! TextBlock) {
          continue;
        }
        // Let's calculate the sizes
        final (ui.Rect sourceRect, ui.Rect targetRect) = calculateBlock(
          layout,
          block,
          ui.Offset(
            line.advance.left + line.formattingShift + block.shiftFromLineStart,
            line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent,
          ),
          offset,
          ui.window.devicePixelRatio,
        );
        if (block.style.hasElement(StyleElements.decorations)) {
          painter.fillDecorations(block, sourceRect);
          painter.paintDecorations(canvas, sourceRect, targetRect);
        }
      }
    }
  }

  void addTextClusters(TextLayout layout, TextBlock block) {
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

      painter.addTextCluster(clusterText);
    }
  }

  void addShadows(TextLayout layout, TextBlock block) {
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
        painter.addShadow(clusterText, shadow, block.isLtr);
      }
    }
  }

  (ui.Rect sourceRect, ui.Rect targetRect) calculateParagraph(
    TextLayout layout,
    ui.Offset offset,
    double devicePixelRatio,
  ) {
    // Calculate the longest line taking in account the formatting shifts
    double maxWidth = 0;
    for (final TextLine line in layout.lines) {
      final double lineWidth = line.advance.width + line.formattingShift + line.trailingSpacesWidth;
      if (lineWidth > maxWidth) {
        maxWidth = lineWidth;
      }
    }

    // Define the paragraph rect (using advances, not selected rects)
    // Source rect must take in account the scaling
    final sourceRect = ui.Rect.fromLTWH(
      0,
      0,
      (maxWidth * devicePixelRatio).ceilToDouble(),
      (layout.paragraph.height * devicePixelRatio).ceilToDouble(),
    );
    // Target rect will be scaled by the canvas transform, so we don't scale it here
    final zeroRect = ui.Rect.fromLTWH(
      0,
      0,
      maxWidth.ceilToDouble(),
      layout.paragraph.height.ceilToDouble(),
    );
    final ui.Rect targetRect = zeroRect.translate(offset.dx, offset.dy);

    WebParagraphDebug.log(
      'calculateParagraph source: ${sourceRect.left}:${sourceRect.right}x${sourceRect.top}:${sourceRect.bottom} => '
      'target: ${targetRect.left}:${targetRect.right}x${targetRect.top}:${targetRect.bottom}',
    );

    return (sourceRect, targetRect);
  }
}
