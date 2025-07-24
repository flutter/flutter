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
import 'paragraph.dart';

abstract class Painter {
  Painter();

  void paintTextCluster(
    CanvasKitCanvas canvas,
    ExtendedTextCluster webTextCluster,
    bool isDefaultLtr,
    ui.Rect sourceRect,
    ui.Rect targetRect,
  );

  void paintShadows(
    CanvasKitCanvas canvas,
    ExtendedTextCluster webTextCluster,
    bool isDefaultLtr,
    ui.Rect sourceRect,
    ui.Rect targetRect,
  );

  void paintBackground(
    CanvasKitCanvas canvas,
    LineClusterBlock block,
    ui.Rect sourceRect,
    ui.Rect targetRect,
  );

  void paintDecorations(
    CanvasKitCanvas canvas,
    LineClusterBlock block,
    ui.Rect sourceRect,
    ui.Rect targetRect,
  );
}

final DomOffscreenCanvas _paintCanvas = createDomOffscreenCanvas(500, 500);
final paintContext = _paintCanvas.getContext('2d')! as DomCanvasRenderingContext2D;

class Canvas2DPainter extends Painter {
  @override
  void paintBackground(
    CanvasKitCanvas canvas,
    LineBlock block,
    ui.Rect sourceRect,
    ui.Rect targetRect,
  ) {
    canvas.drawRect(targetRect, block.textStyle.background!);
  }

  @override
  void paintDecorations(
    CanvasKitCanvas canvas,
    LineClusterBlock block,
    ui.Rect sourceRect,
    ui.Rect targetRect,
  ) {
    paintContext.fillStyle = block.textStyle.foreground?.color.toCssString();

    final double thickness = calculateThickness(block.textStyle);

    const double DoubleDecorationSpacing = 3.0;

    for (final ui.TextDecoration decoration in [
      ui.TextDecoration.lineThrough,
      ui.TextDecoration.underline,
      ui.TextDecoration.overline,
    ]) {
      if (!block.textStyle.decoration!.contains(decoration)) {
        continue;
      }

      final double height =
          block.textMetrics!.fontBoundingBoxAscent + block.textMetrics!.fontBoundingBoxDescent;
      final double ascent = block.textMetrics!.fontBoundingBoxAscent;
      final double position = calculatePosition(decoration, thickness, height, ascent);
      WebParagraphDebug.log('decoration=$decoration thickness=$thickness position=$position');

      final double width = sourceRect.width;
      final double x = sourceRect.left;
      final double y = sourceRect.top + position;

      // TODO(jlavrova): setup style
      paintContext.reset();
      paintContext.lineWidth = thickness;
      paintContext.strokeStyle = block.textStyle.decorationColor!.toCssString();

      switch (block.textStyle.decorationStyle!) {
        case ui.TextDecorationStyle.wavy:
          calculateWaves(x, y, block.textStyle, sourceRect, thickness);

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
          final Float32List dashes = Float32List(2)
            ..[0] =
                thickness *
                (block.textStyle.decorationStyle! == ui.TextDecorationStyle.dotted ? 1 : 4)
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
            'solid: $x:${x + width}, $y ${block.textStyle.decorationColor!.toCssString()}',
          );
      }
    }

    final DomImageBitmap bitmap = _paintCanvas.transferToImageBitmap();

    final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    if (skImage == null) {
      throw Exception('Failed to convert text image bitmap to an SkImage.');
    }

    final CkImage ckImage = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
    canvas.drawImageRect(
      ckImage,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  @override
  void paintShadows(
    CanvasKitCanvas canvas,
    ExtendedTextCluster webTextCluster,
    bool isDefaultLtr,
    ui.Rect sourceRect,
    ui.Rect targetRect,
  ) {
    final WebTextStyle textStyle = webTextCluster.textStyle!;
    paintContext.fillStyle = textStyle.foreground?.color.toCssString();

    for (final ui.Shadow shadow in textStyle.shadows!) {
      // TODO(jlavrova): see if we can implement shadowing ourself avoiding redrawing text clusters many times
      paintContext.shadowColor = shadow.color.toCssString();
      paintContext.shadowBlur = shadow.blurRadius;
      paintContext.shadowOffsetX = shadow.offset.dx;
      paintContext.shadowOffsetY = shadow.offset.dy;
      WebParagraphDebug.log(
        'Shadow: x=${shadow.offset.dx} y=${shadow.offset.dy} blur=${shadow.blurRadius} color=${shadow.color.toCssString()}',
      );

      // We fill the text cluster into a rectange [0,0,w,h]
      // but we need to shift the y coordinate by the font ascent
      // becase the text is drawn at the ascent, not at 0
      paintContext.fillTextCluster(
        webTextCluster.cluster!,
        /*left:*/ 0,
        /*top:*/ webTextCluster.fontBoundingBoxAscent,
        /*ignore the text cluster shift from the text run*/ {
          'x': (isDefaultLtr ? 0 : webTextCluster.advance.width) + 100,
          'y': 100,
        },
      );

      // Clean the shadow context
      paintContext.shadowColor = '';
      paintContext.shadowBlur = 0;
      paintContext.shadowOffsetX = 0;
      paintContext.shadowOffsetY = 0;

      // TODO(jlavrova): calculate the shadow bounds properly
      final ui.Rect shadowSourceRect = sourceRect.inflate(100).translate(100, 100);
      final ui.Rect shadowTargetRect = targetRect.inflate(100);

      final DomImageBitmap bitmap = _paintCanvas.transferToImageBitmap();

      final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
      if (skImage == null) {
        throw Exception('Failed to convert text image bitmap to an SkImage.');
      }
      final CkImage ckImage = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
      canvas.drawImageRect(
        ckImage,
        shadowSourceRect,
        shadowTargetRect,
        ui.Paint()..filterQuality = ui.FilterQuality.none,
      );
    }
  }

  @override
  void paintTextCluster(
    CanvasKitCanvas canvas,
    ExtendedTextCluster webTextCluster,
    bool isDefaultLtr,
    ui.Rect sourceRect,
    ui.Rect targetRect,
  ) {
    final WebTextStyle textStyle = webTextCluster.textStyle!;
    paintContext.fillStyle = textStyle.foreground?.color.toCssString();

    // We fill the text cluster into a rectange [0,0,w,h]
    // but we need to shift the y coordinate by the font ascent
    // becase the text is drawn at the ascent, not at 0
    paintContext.fillTextCluster(
      webTextCluster.cluster!,
      /*left:*/ 0,
      /*top:*/ webTextCluster.fontBoundingBoxAscent,
      /*ignore the text cluster shift from the text run*/ {
        'x': (isDefaultLtr ? 0 : webTextCluster.advance.width),
        'y': 0,
      },
    );
    final DomImageBitmap bitmap = _paintCanvas.transferToImageBitmap();

    final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    if (skImage == null) {
      throw Exception('Failed to convert text image bitmap to an SkImage.');
    }

    final CkImage ckImage = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
    canvas.drawImageRect(
      ckImage,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  double calculateThickness(WebTextStyle textStyle) {
    return (textStyle.fontSize! / 14.0) * textStyle.decorationThickness!;
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
    final double quarterWave = thickness;

    int waveCount = 0;
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
      final double x1 = xStart;
      final double y1 = yStart + quarterWave * (waveCount.isEven ? 1 : -1);
      final double x2 = xStart + quarterWave * 2;
      final double y2 = yStart;
      WebParagraphDebug.log('wave: $x1, $y1, $x2, $y2');
      paintContext.quadraticCurveTo(x1, y1, x2, y2);
      xStart += quarterWave * 2;
      ++waveCount;
    }

    // The rest of the wave
    final double remaining = textBounds.width - xStart;
    if (remaining > 0) {
      final double x1 = xStart;
      final double y1 = yStart + quarterWave * (waveCount.isEven ? 1 : -1);
      //final double y1 = yStart + remaining / 2 * (waveCount.isEven ? 1 : -1);
      final double x2 = xStart + remaining;
      final double y2 = yStart;
      //final double y2 = yStart + remaining + remaining / quarterWave * y1;
      WebParagraphDebug.log(
        'remaining: ${textBounds.width} - $xStart = $remaining '
        '$x1, $y1, $x2, $y2',
      );
      paintContext.quadraticCurveTo(x1, y1, x2, y2);
    }
    paintContext.stroke();
  }

  void drawLineAsRect(double x, double y, double width, double thickness) {
    final double radius = thickness / 2;
    paintContext.fillRect(x, y - radius, x + width, y + radius);
    WebParagraphDebug.log('paintContext.fillRect($x, $y - $radius, $x + $width, $y + $radius);');
  }
}
