// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../../engine.dart';

// TODO(mdebbar): Discuss it: we use this canvas for painting the entire block (entire line)
// so we need to make sure it's big enough to hold the biggest line.
// Also, we use it to paint shadows (with vertical shifts) so we need to make it tall enough as well.
double? currentDevicePixelRatio;
final DomOffscreenCanvas paintCanvas = createDomOffscreenCanvas(0, 0);
final paintContext =
    paintCanvas.getContext('2d', {'willReadFrequently': true})! as DomCanvasRenderingContext2D;

/// Paints on a [WebParagraph].
///
/// It uses a [DomCanvasElement] to get text information
abstract class TextPaint {
  TextPaint(this.paragraph);

  final WebParagraph paragraph;

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

  double calculateThickness(WebTextStyle textStyle) {
    return (textStyle.fontSize! / 14.0) * (textStyle.decorationThickness ?? 1.0);
  }

  double calculatePosition(
    ui.TextDecoration decoration,
    double thickness,
    double height,
    double ascent,
  ) {
    switch (decoration) {
      case ui.TextDecoration.underline:
        WebParagraphDebug.log(
          'calculatePosition underline: $thickness + $ascent = ${thickness + ascent}',
        );
        return thickness + ascent;
      case ui.TextDecoration.overline:
        WebParagraphDebug.log('calculatePosition overline: 0');
        return thickness / 2;
      case ui.TextDecoration.lineThrough:
        WebParagraphDebug.log('calculatePosition through: $height / 2 = ${height / 2}');
        return height / 2;
    }
    return 0;
  }

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

    WebParagraphDebug.log(
      'calculateWaves($x, $y, '
      '${textBounds.left}:${textBounds.right}x${textBounds.top}:${textBounds.bottom} )'
      '$thickness $xStart $yStart',
    );
    paintContext.beginPath();
    //paintContext.moveTo(x, y + quarterWave);
    while (xStart + quarterWave * 2 < textBounds.width) {
      final x1 = xStart;
      final double y1 = yStart + quarterWave * (waveCount.isEven ? 1 : -1);
      final double x2 = xStart + quarterWave * 2;
      final y2 = yStart;
      WebParagraphDebug.log('wave: $x1, $y1, $x2, $y2');
      paintContext.quadraticCurveTo(x1, y1, x2, y2);
      xStart += quarterWave * 2;
      ++waveCount;
    }

    // The rest of the wave
    final double remaining = textBounds.width - xStart;
    if (remaining > 0) {
      final x1 = xStart;
      final double y1 = yStart + quarterWave * (waveCount.isEven ? 1 : -1);
      //final double y1 = yStart + remaining / 2 * (waveCount.isEven ? 1 : -1);
      final double x2 = xStart + remaining;
      final y2 = yStart;
      //final double y2 = yStart + remaining + remaining / quarterWave * y1;
      WebParagraphDebug.log(
        'remaining: ${textBounds.width} - $xStart = $remaining '
        '$x1, $y1, $x2, $y2',
      );
      paintContext.quadraticCurveTo(x1, y1, x2, y2);
    }
    paintContext.stroke();
  }

  void fillDecorations(TextBlock block, ui.Rect sourceRect) {
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

      paintContext.reset();
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
    }
  }

  void fillTextCluster(WebCluster webTextCluster, bool isDefaultLtr);

  void fillShadowCluster(WebCluster webTextCluster, ui.Shadow shadow, bool isDefaultLtr);

  void paint(ui.Canvas canvas, TextLayout layout, Painter painter, double x, double y);
}
