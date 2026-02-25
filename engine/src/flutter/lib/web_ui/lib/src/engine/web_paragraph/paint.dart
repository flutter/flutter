// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:ui/ui.dart' as ui;
import '../../engine.dart';

// TODO(jlavrova): We use it to paint shadows (with vertical shifts) so we need to make it tall enough as well.
double? currentDevicePixelRatio;
//final DomOffscreenCanvas paintCanvas = createDomOffscreenCanvas(0, 0);
//final paintContext =
//    paintCanvas.getContext('2d', {'willReadFrequently': true})! as DomCanvasRenderingContext2D;

final DomHTMLCanvasElement paintCanvas =
    domDocument.createElement('canvas') as DomHTMLCanvasElement;
final paintContext =
    paintCanvas.getContext('2d', {'willReadFrequently': true})! as DomCanvasRenderingContext2D;

/// Paints on a [WebParagraph].
///
/// It uses a [DomCanvasElement] to get text information
abstract class TextPaint {
  TextPaint(this.paragraph);

  final WebParagraph paragraph;

  /// Calculates the source (on Canvas2D) and target (on the output canvas) rectangles for a text cluster
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

  /// Calculates the source (on Canvas2D) and target (on the output canvas) rectangles for a text block
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

    if (WebParagraphDebug.logging) {
      WebParagraphDebug.log(
        'calculateBlock "${block.span.text}" ${block.textRange}-${block.span.start} ${block.clusterRange} '
        'source: ${sourceRect.left}:${sourceRect.right}x${sourceRect.top}:${sourceRect.bottom} => '
        'target: ${targetRect.left}:${targetRect.right}x${targetRect.top}:${targetRect.bottom}',
      );
    }

    return (sourceRect, targetRect);
  }

  /// Calculates the source (on Canvas2D) and target (on the output canvas) rectangles for the entire paragraph
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

    if (WebParagraphDebug.logging) {
      WebParagraphDebug.log(
        'calculateParagraph source: ${sourceRect.left}:${sourceRect.right}x${sourceRect.top}:${sourceRect.bottom} => '
        'target: ${targetRect.left}:${targetRect.right}x${targetRect.top}:${targetRect.bottom}',
      );
    }

    return (sourceRect, targetRect);
  }

  /// Calculates the thickness of the decoration line
  double calculateThickness(WebTextStyle textStyle) {
    return (textStyle.fontSize! / 14.0) * (textStyle.decorationThickness ?? 1.0);
  }

  /// Calculates the position of the decoration line
  double calculatePosition(
    ui.TextDecoration decoration,
    double thickness,
    double height,
    double ascent,
  ) {
    switch (decoration) {
      case ui.TextDecoration.underline:
        return thickness + ascent;
      case ui.TextDecoration.overline:
        return thickness / 2;
      case ui.TextDecoration.lineThrough:
        return height / 2;
    }
    return 0;
  }

  /// Calculates and the position of the decoration line and paints it on Canvas2D
  void calculateWaves(
    double x,
    double y,
    WebTextStyle textStyle,
    ui.Rect textBounds,
    double thickness,
  ) {
    final quarterWave = thickness;

    var waveCount = 0;
    double xStart = 0;
    final double yStart = y + quarterWave;

    paintContext.beginPath();
    paintContext.moveTo(x, yStart);
    while (xStart + quarterWave * 2 < textBounds.width) {
      final x1 = xStart;
      final double y1 = yStart + quarterWave * (waveCount.isEven ? 1 : -1);
      final double x2 = xStart + quarterWave * 2;
      final y2 = yStart;
      paintContext.quadraticCurveTo(x1, y1, x2, y2);
      xStart += quarterWave * 2;
      ++waveCount;
    }

    // The rest of the wave
    final double remaining = textBounds.width - xStart;
    if (remaining > 0) {
      final x1 = xStart;
      final double y1 = yStart + quarterWave * (waveCount.isEven ? 1 : -1);
      final double x2 = xStart + remaining;
      final y2 = yStart;
      paintContext.quadraticCurveTo(x1, y1, x2, y2);
    }
    paintContext.stroke();
  }

  // TODO(jlavrova): implement decorations entirely on the resulting Canvas
  /// Paints text decorations on Canvas2D
  void fillDecorations(TextBlock block, ui.Rect sourceRect) {
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

      final double height =
          block.multipliedFontBoundingBoxAscent + block.multipliedFontBoundingBoxDescent;
      final double ascent = block.multipliedFontBoundingBoxAscent;
      final double position = calculatePosition(decoration, thickness, height, ascent);

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

        case ui.TextDecorationStyle.solid:
          paintContext.beginPath();
          paintContext.moveTo(x, y);
          paintContext.lineTo(x + width, y);
          paintContext.stroke();
      }

      paintContext.restore();
    }
  }

  /// Paints shadows of a text cluster on Canvas2D
  void fillTextCluster(WebCluster webTextCluster, bool isDefaultLtr);

  /// Paints shadows of a text cluster on Canvas2D
  void fillShadowCluster(WebCluster webTextCluster, ui.Shadow shadow, bool isDefaultLtr);

  /// Paints the entire paragraph on Canvas2D
  void paint(ui.Canvas canvas, TextLayout layout, Painter painter, double x, double y);
}
