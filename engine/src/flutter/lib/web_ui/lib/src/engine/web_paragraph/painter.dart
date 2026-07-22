// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../util.dart';
import 'decorations.dart';
import 'layout.dart';
import 'paragraph.dart';

final DomHTMLCanvasElement _paintCanvas = createDomCanvasElement(width: 0, height: 0);
final _paintContext =
    _paintCanvas.getContext('2d', {'willReadFrequently': true})! as DomCanvasRenderingContext2D;

typedef ParagraphImageGenerator = Uint8List Function();

/// Resizes the global paint canvas to the given width and height and updates the device pixel ratio.
///
/// The paint canvas is scaled by the device pixel ratio to avoid pixelation
/// that would happen if it wasn't resized.
void _resizePaintCanvas(double devicePixelRatio, ui.Rect rect) {
  _paintCanvas.width = rect.width.ceil();
  _paintCanvas.height = rect.height.ceil();
  _paintCanvas.style.width = '${rect.width / devicePixelRatio}px';
  _paintCanvas.style.height = '${rect.height / devicePixelRatio}px';
  _paintContext.scale(devicePixelRatio, devicePixelRatio);
}

/// Calculates the source (on Canvas2D) and target (on the output canvas) rectangles for a text block.
(ui.Rect sourceRect, ui.Rect targetRect) _calculateBlock(TextBlock block, ui.Offset offset) {
  final double dpr = ui.window.devicePixelRatio;
  final ui.Rect advance = block.advance;

  // Define the text clusters rect (using advances, not selected rects)
  // Source rect must take in account the scaling
  final sourceRect = ui.Rect.fromLTWH(0, 0, advance.width * dpr, advance.height * dpr);

  // We shift the target rect to the correct x position inside the line and
  // the correct y position of the line itself
  // (and then to the paragraph.paint x and y)
  final targetRect = ui.Rect.fromLTWH(offset.dx, offset.dy, advance.width, advance.height);

  return (sourceRect, targetRect);
}

/// Calculates the source (on Canvas2D) and target (on the output canvas) rectangles for the entire paragraph
(ui.Rect sourceRect, ui.Rect targetRect) _calculateParagraph(
  WebParagraph paragraph,
  ui.Offset offset,
  double devicePixelRatio,
) {
  // Define the paragraph rect (using advances, not selected rects)
  // Source rect must take in account the scaling
  final sourceRect = ui.Rect.fromLTWH(
    0,
    0,
    ((paragraph.paintBounds.width) * devicePixelRatio).ceilToDouble(),
    ((paragraph.paintBounds.height) * devicePixelRatio).ceilToDouble(),
  );
  // Target rect will be scaled by the canvas transform, so we don't scale it here
  final targetRect = ui.Rect.fromLTWH(
    (offset.dx + paragraph.paintBounds.left).floorToDouble(),
    (offset.dy + paragraph.paintBounds.top).floorToDouble(),
    (sourceRect.width / devicePixelRatio).ceilToDouble(),
    (sourceRect.height / devicePixelRatio).ceilToDouble(),
  );

  return (sourceRect, targetRect);
}

/// Paints a [WebParagraph].
///
/// It uses a [DomHTMLCanvasElement] to paint Text Clusters on, then extracts the pixels and draws
/// an image on the Flutter canvas.
abstract class WebParagraphPainter {
  WebParagraphPainter(this._paragraph);

  final WebParagraph _paragraph;

  bool get hasCache;
  void clearCache();

  void _paintAllBlocks(StyleElements styleElement, ui.Canvas canvas, ui.Offset offset) {
    for (final TextLine line in _paragraph.getLayout().lines) {
      for (final LineBlock block in line.visualBlocks) {
        if (block is PlaceholderBlock) {
          // Placeholders do not need painting, just reserving the space
          continue;
        }

        // Let's calculate the sizes
        final (ui.Rect sourceRect, ui.Rect targetRect) = _calculateBlock(
          block as TextBlock,
          offset.translate(
            line.advance.left + line.formattingShift + block.shiftFromLineStart,
            line.advance.top + line.fontBoundingBoxAscent - block.multipliedFontBoundingBoxAscent,
          ),
        );

        switch (styleElement) {
          case StyleElements.background:
            // TODO(jlavrova): We use calculateBlock in several places and it may need to calculate the rect height
            // differently for background blocks (to include the entire line height instead of just the text height).
            // I correct the value in place for now, but it may need to be fixed in calculateBlock itself.
            final correctedTargetRect = ui.Rect.fromLTWH(
              targetRect.left,
              targetRect.top,
              targetRect.width,
              block.multipliedHeight,
            );
            _paintBlockBackground(canvas, correctedTargetRect, block.style.background!);
          case StyleElements.decorations:
          case StyleElements.shadows:
          case StyleElements.text:
            throw Exception('Only the background is drawn directly on the output canvas');
        }
      }
    }
  }

  /// Paints the background of a [TextBlock] on a [ui.Canvas].
  void _paintBlockBackground(ui.Canvas canvas, ui.Rect rect, ui.Paint paint) {
    // We need to snap the block edges because Skia draws rectangles with subpixel accuracy
    // and we end up with overlaps (this is only a problem when colors have transparency)
    // or gaps between blocks (which looks unacceptable - vertical lines between blocks).
    // Whether we snap to floor or ceil is irrelevant as long as we are consistent on both sides
    // (and will possibly have problems when glyph boundaries are outside of advance rectangles)
    final snappedRect = ui.Rect.fromLTRB(
      rect.left.roundToDouble(),
      rect.top.roundToDouble(),
      rect.right.roundToDouble(),
      rect.bottom.roundToDouble(),
    );
    canvas.drawRect(snappedRect, paint);
  }

  /// Paints the entire paragraph on Canvas2D
  void paint(ui.Canvas canvas, ui.Offset offset) {
    if (_paragraph.text.isEmpty) {
      return;
    }

    final TextLayout layout = _paragraph.getLayout();

    final (ui.Rect sourceRect, ui.Rect targetRect) = _calculateParagraph(
      _paragraph,
      offset,
      ui.window.devicePixelRatio,
    );

    const epsilon = 0.001;
    if (sourceRect.width.abs() < epsilon || sourceRect.height.abs() < epsilon) {
      // If there is nothing to draw getImageData fails
      return;
    }

    // Draw background blocks directly on the output canvas
    // so it will be cached together with the text blocks on Canvas2D canvas
    _paintAllBlocks(StyleElements.background, canvas, offset);

    paintParagraphText(
      canvas,
      sourceRect,
      targetRect,
      generateParagraphImage: () {
        _resizePaintCanvas(ui.window.devicePixelRatio, sourceRect);

        // We only want to paint the actual paint bounds of the paragraph.
        _paintContext.translate(-_paragraph.paintBounds.left, -_paragraph.paintBounds.top);

        // Fill out all the blocks on Canvas2D canvas
        DomCanvasParagraphPainter._fillAllBlocks(StyleElements.shadows, layout);
        DomCanvasParagraphPainter._fillAllBlocks(StyleElements.text, layout);
        DomCanvasParagraphPainter._fillAllBlocks(StyleElements.decorations, layout);

        final DomImageData imageData = _paintContext.getImageData(
          0,
          0,
          sourceRect.width.ceil(),
          sourceRect.height.ceil(),
        );
        return imageData.data.buffer.asUint8List();
      },
    );
  }

  /// This is the core implementation that paints the paragraph text on a [ui.Canvas].
  ///
  /// It is meant to be implemented by subclasses that are specialized for each renderer.
  void paintParagraphText(
    ui.Canvas canvas,
    ui.Rect sourceRect,
    ui.Rect targetRect, {
    required ParagraphImageGenerator generateParagraphImage,
  });
}

/// Paints a [WebParagraph] on a [DomHTMLCanvasElement].
class DomCanvasParagraphPainter {
  static void _fillAllBlocks(StyleElements styleElement, TextLayout layout) {
    // Paint the entire paragraph as a single image on Canvas2D
    for (final TextLine line in layout.lines) {
      _paintContext.save();
      _paintContext.translate(line.formattingShift, line.baseline);

      for (final LineBlock block in line.visualBlocks) {
        if (block is PlaceholderBlock) {
          // Placeholders do not need painting, just reserving the space
          continue;
        }

        _paintContext.save();
        switch (styleElement) {
          case StyleElements.shadows:
            // For text and shadows we need to shift to the start of the span
            _paintContext.translate(block.spanShiftFromLineStart, 0);
            _fillBlockShadows(layout, block as TextBlock);
          case StyleElements.text:
            // For text and shadows we need to shift to the start of the span
            _paintContext.translate(block.spanShiftFromLineStart, 0);
            _fillBlockText(layout, block as TextBlock);
          case StyleElements.decorations:
            // For decorations we need to shift to the start of the block
            _paintContext.translate(block.shiftFromLineStart, -line.fontBoundingBoxAscent);
            // Let's calculate the sizes
            final (ui.Rect sourceRect, ui.Rect targetRect) = _calculateBlock(
              block as TextBlock,
              ui.Offset(line.advance.left + line.formattingShift, line.advance.top),
            );
            // TODO(jlavrova): Implement decorations entirely on ui.Canvas
            DomCanvasDecorationPainter.fillDecorations(_paintContext, block, sourceRect);
          case StyleElements.background:
            throw Exception(
              'Background is drawn directly on the output canvas, not on the canvas2D',
            );
        }
        _paintContext.restore();
      }

      _paintContext.restore();
    }
  }

  static void _fillBlockText(TextLayout layout, TextBlock block) {
    for (final (WebCluster clusterText, bool isLtr) in block.getTextClustersInVisualOrder(layout)) {
      _fillTextCluster(clusterText, isLtr);
    }
  }

  static void _fillBlockShadows(TextLayout layout, TextBlock block) {
    if (!block.style.hasElement(StyleElements.shadows) || block.style.shadows == null) {
      return;
    }

    for (final (WebCluster clusterText, bool isLtr) in block.getTextClustersInVisualOrder(layout)) {
      for (final ui.Shadow shadow in clusterText.style.shadows!) {
        _fillShadowCluster(clusterText, shadow, isLtr);
      }
    }
  }

  static void _fillTextCluster(WebCluster webTextCluster, bool isDefaultLtr) {
    final WebTextStyle style = webTextCluster.style;
    _paintContext.fillStyle = style.getForegroundColor().toCssString();
    webTextCluster.addToContext(_paintContext, 0, 0);
  }

  static void _fillShadowCluster(WebCluster webTextCluster, ui.Shadow shadow, bool isDefaultLtr) {
    // It's not clear how to draw the shadow directly on ui.Canvas without going through canvas2d.
    _paintContext.shadowColor = shadow.color.toCssString();
    _paintContext.shadowBlur = shadow.blurRadius;
    _paintContext.shadowOffsetX = shadow.offset.dx;
    _paintContext.shadowOffsetY = shadow.offset.dy;

    webTextCluster.addToContext(_paintContext, 0, 0);
  }
}
