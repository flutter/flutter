// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
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
/// The paint canvas is scaled by the device pixel ratio and canvas matrix scale to avoid pixelation.
void _resizePaintCanvas(ui.Rect rect, double effectiveScaleX, double effectiveScaleY) {
  _paintCanvas.width = rect.width.ceil();
  _paintCanvas.height = rect.height.ceil();
  _paintContext.scale(effectiveScaleX, effectiveScaleY);
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

/// Represents the combined geometry of the canvas transformation matrix and device pixel ratio,
/// providing physical-to-local coordinate snapping and projection for WebParagraph painting.
@visibleForTesting
class ParagraphTransform {
  ParagraphTransform({
    required this.effectiveScaleX,
    required this.effectiveScaleY,
    required this.transformX,
    required this.transformY,
    required this.devicePixelRatio,
  });

  factory ParagraphTransform.from(Float64List transform, double devicePixelRatio) {
    if (transformKindOf(transform) == TransformKind.identity) {
      return ParagraphTransform(
        effectiveScaleX: devicePixelRatio,
        effectiveScaleY: devicePixelRatio,
        transformX: 0.0,
        transformY: 0.0,
        devicePixelRatio: devicePixelRatio,
      );
    }

    final double matrixScaleX = math.sqrt(
      transform[0] * transform[0] + transform[1] * transform[1],
    );
    final double matrixScaleY = math.sqrt(
      transform[4] * transform[4] + transform[5] * transform[5],
    );

    return ParagraphTransform(
      effectiveScaleX: devicePixelRatio * (matrixScaleX > 0 ? matrixScaleX : 1.0),
      effectiveScaleY: devicePixelRatio * (matrixScaleY > 0 ? matrixScaleY : 1.0),
      transformX: transform[12],
      transformY: transform[13],
      devicePixelRatio: devicePixelRatio,
    );
  }

  final double effectiveScaleX;
  final double effectiveScaleY;
  final double transformX;
  final double transformY;
  final double devicePixelRatio;

  /// Snaps a logical [offset] to the nearest whole integer device pixel on screen.
  (double physicalX, double physicalY) snapOffset(ui.Offset offset) {
    return (
      (offset.dx * effectiveScaleX + transformX * devicePixelRatio).roundToDouble(),
      (offset.dy * effectiveScaleY + transformY * devicePixelRatio).roundToDouble(),
    );
  }

  /// Maps a physical screen rectangle back to local canvas coordinates.
  ui.Rect toLocalRect({
    required double physicalLeft,
    required double physicalTop,
    required double physicalWidth,
    required double physicalHeight,
  }) {
    return ui.Rect.fromLTWH(
      (physicalLeft - transformX * devicePixelRatio) / effectiveScaleX,
      (physicalTop - transformY * devicePixelRatio) / effectiveScaleY,
      physicalWidth / effectiveScaleX,
      physicalHeight / effectiveScaleY,
    );
  }

  /// Snaps a logical [rect] to whole integer physical device pixels,
  /// returning the rectangle in local canvas coordinates.
  ui.Rect snapRect(ui.Rect rect) {
    final double physicalLeft = (rect.left * effectiveScaleX + transformX * devicePixelRatio)
        .roundToDouble();
    final double physicalTop = (rect.top * effectiveScaleY + transformY * devicePixelRatio)
        .roundToDouble();
    final double physicalRight = (rect.right * effectiveScaleX + transformX * devicePixelRatio)
        .roundToDouble();
    final double physicalBottom = (rect.bottom * effectiveScaleY + transformY * devicePixelRatio)
        .roundToDouble();

    return ui.Rect.fromLTRB(
      (physicalLeft - transformX * devicePixelRatio) / effectiveScaleX,
      (physicalTop - transformY * devicePixelRatio) / effectiveScaleY,
      (physicalRight - transformX * devicePixelRatio) / effectiveScaleX,
      (physicalBottom - transformY * devicePixelRatio) / effectiveScaleY,
    );
  }
}

/// Calculates the source (on Canvas2D) and target (on the output canvas) rectangles for the entire paragraph,
/// as well as the translation shift on Canvas2D.
@visibleForTesting
(ui.Rect sourceRect, ui.Rect targetRect, ui.Offset canvas2dShift) calculateParagraph(
  WebParagraph paragraph,
  ui.Offset offset,
  ParagraphTransform transform,
) {
  final (double physicalOffsetX, double physicalOffsetY) = transform.snapOffset(offset);

  final physicalPaintBounds = ui.Rect.fromLTRB(
    paragraph.paintBounds.left * transform.effectiveScaleX,
    paragraph.paintBounds.top * transform.effectiveScaleY,
    paragraph.paintBounds.right * transform.effectiveScaleX,
    paragraph.paintBounds.bottom * transform.effectiveScaleY,
  );

  // Add 2 physical pixels of safety padding so font antialiasing bleeding in all directions is not clipped
  const kAntialiasingPadding = 2.0;

  // Canvas2D translation shift (always integer device pixels, phase = 0.0)
  // Include safety padding on the left and top so font antialiasing bleeding is not clipped
  final double shiftPhysicalX = (-physicalPaintBounds.left + kAntialiasingPadding).ceilToDouble();
  final double shiftPhysicalY = (-physicalPaintBounds.top + kAntialiasingPadding).ceilToDouble();

  // Width and height include the shift (which contains left/top padding) plus right/bottom padding
  final double physicalWidth = (shiftPhysicalX + physicalPaintBounds.right + kAntialiasingPadding)
      .ceilToDouble();
  final double physicalHeight = (shiftPhysicalY + physicalPaintBounds.bottom + kAntialiasingPadding)
      .ceilToDouble();

  // Source rect in physical device pixels (rasterized at effective DPR)
  final sourceRect = ui.Rect.fromLTWH(0, 0, physicalWidth, physicalHeight);

  // Target rect in local canvas units:
  // Map physical integer destination coordinates back to local canvas space
  final double screenLeft = physicalOffsetX - shiftPhysicalX;
  final double screenTop = physicalOffsetY - shiftPhysicalY;
  final ui.Rect targetRect = transform.toLocalRect(
    physicalLeft: screenLeft,
    physicalTop: screenTop,
    physicalWidth: physicalWidth,
    physicalHeight: physicalHeight,
  );

  // Convert shift to logical units for Canvas2D context translation
  final canvas2dShift = ui.Offset(
    shiftPhysicalX / transform.effectiveScaleX,
    shiftPhysicalY / transform.effectiveScaleY,
  );

  return (sourceRect, targetRect, canvas2dShift);
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

  /// The number of times this painter has rasterized the paragraph, exposed for testing.
  int get debugRasterizeCount => 0;

  void _paintAllBlocks(
    StyleElements styleElement,
    ui.Canvas canvas,
    ui.Offset offset,
    ParagraphTransform transform,
  ) {
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
            _paintBlockBackground(canvas, correctedTargetRect, block.style.background!, transform);
          case StyleElements.decorations:
          case StyleElements.shadows:
          case StyleElements.text:
            throw Exception('Only the background is drawn directly on the output canvas');
        }
      }
    }
  }

  /// Paints the background of a [TextBlock] on a [ui.Canvas].
  void _paintBlockBackground(
    ui.Canvas canvas,
    ui.Rect rect,
    ui.Paint paint,
    ParagraphTransform transform,
  ) {
    // We snap the block edges to whole physical screen pixels to prevent
    // subpixel rendering overlaps (which causes artifacts when colors have
    // transparency) or gaps between blocks.
    final ui.Rect snappedRect = transform.snapRect(rect);
    canvas.drawRect(snappedRect, paint);
  }

  /// Paints the entire paragraph on Canvas2D
  void paint(ui.Canvas canvas, ui.Offset offset) {
    if (_paragraph.text.isEmpty) {
      return;
    }

    final TextLayout layout = _paragraph.getLayout();
    final Float64List canvasTransform = canvas.getTransform();
    final double dpr = ui.window.devicePixelRatio;
    final transform = ParagraphTransform.from(canvasTransform, dpr);

    final (ui.Rect sourceRect, ui.Rect targetRect, ui.Offset canvas2dShift) = calculateParagraph(
      _paragraph,
      offset,
      transform,
    );

    const epsilon = 0.001;
    if (sourceRect.width.abs() < epsilon || sourceRect.height.abs() < epsilon) {
      // If there is nothing to draw getImageData fails
      return;
    }

    // Draw background blocks directly on the output canvas
    _paintAllBlocks(StyleElements.background, canvas, offset, transform);

    paintParagraphText(
      canvas,
      sourceRect,
      targetRect,
      effectiveScaleX: transform.effectiveScaleX,
      effectiveScaleY: transform.effectiveScaleY,
      generateParagraphImage: () {
        _resizePaintCanvas(sourceRect, transform.effectiveScaleX, transform.effectiveScaleY);

        // We translate Canvas2D context by canvas2dShift in logical units
        _paintContext.translate(canvas2dShift.dx, canvas2dShift.dy);

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
    required double effectiveScaleX,
    required double effectiveScaleY,
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
