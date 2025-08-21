// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_api.dart';
import '../canvaskit/image.dart';
import '../dom.dart';
import '../util.dart';
import 'debug.dart';
import 'layout.dart';
import 'paragraph.dart';

abstract class Painter {
  Painter();

  void fillTextCluster(ExtendedTextCluster webTextCluster, bool isDefaultLtr);
  void paintTextCluster(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect);

  void fillShadow(ExtendedTextCluster webTextCluster, ui.Shadow shadow, bool isDefaultLtr);
  void paintShadow(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect);

  void paintBackground(
    ui.Canvas canvas,
    LineClusterBlock block,
    ui.Rect sourceRect,
    ui.Rect targetRect,
  );

  void fillDecorations(LineClusterBlock block, ui.Rect sourceRect);
  void paintDecorations(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect);

  void fillText(LineClusterBlock block, double x, double y);
  void paintText(ui.Canvas canvas, LineClusterBlock block, ui.Rect sourceRect, ui.Rect targetRect);

  void fillShadows(LineClusterBlock block, ui.Rect sourceRect);
  void paintShadows(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect);

  bool cached();
  void paintAll(ui.Canvas canvas, double x, double y);
  void reset(double width, double height);
  (Duration d1, Duration d2, Duration d3) getDurations();
}

DomOffscreenCanvas _paintCanvas = createDomOffscreenCanvas(0, 0);
DomCanvasRenderingContext2D? paintContext;

class CanvasKitPainter extends Painter {
  static HashMap<String, DomImageBitmap> clusterCache = HashMap<String, DomImageBitmap>();
  HashMap<TextRange, CkImage> blockCache = HashMap<TextRange, CkImage>();
  static HashMap<String, SkImage> imageCache = HashMap<String, SkImage>();
  CkImage? allCache;
  Stopwatch transferToImageBitmap = Stopwatch();
  Stopwatch makeImageFromImageBitmap = Stopwatch();
  Stopwatch drawImage = Stopwatch();

  @override
  bool cached() {
    return allCache != null;
  }

  @override
  (Duration d1, Duration d2, Duration d3) getDurations() {
    return (transferToImageBitmap.elapsed, makeImageFromImageBitmap.elapsed, drawImage.elapsed);
  }

  @override
  void paintAll(ui.Canvas canvas, double x, double y) {
    transferToImageBitmap.reset();
    makeImageFromImageBitmap.reset();
    drawImage.reset();
    if (allCache == null) {
      transferToImageBitmap.start();
      final DomImageBitmap bitmap = _paintCanvas.transferToImageBitmap();
      transferToImageBitmap.stop();
      makeImageFromImageBitmap.start();
      final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
      if (skImage == null) {
        throw Exception('Failed to convert text image bitmap to an SkImage.');
      }
      allCache = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
      makeImageFromImageBitmap.stop();
    }
    if (allCache != null) {
      drawImage.start();
      canvas.drawImage(
        allCache!,
        ui.Offset(x, y),
        ui.Paint()..filterQuality = ui.FilterQuality.none,
      );
      drawImage.stop();
    }
  }

  @override
  void reset(double width, double height) {
    paintContext = null;
    _paintCanvas = createDomOffscreenCanvas(width.ceil(), height.ceil());
    paintContext =
        _paintCanvas.getContext('2d', {'willReadFrequently': true})! as DomCanvasRenderingContext2D;
  }

  @override
  void paintBackground(ui.Canvas canvas, LineBlock block, ui.Rect sourceRect, ui.Rect targetRect) {
    canvas.drawRect(targetRect, block.textStyle.background!);
  }

  @override
  void fillDecorations(LineClusterBlock block, ui.Rect sourceRect) {
    paintContext!.fillStyle = block.textStyle.foreground?.color.toCssString();

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

      paintContext!.reset();
      paintContext!.lineWidth = thickness;
      paintContext!.strokeStyle = block.textStyle.decorationColor!.toCssString();

      switch (block.textStyle.decorationStyle!) {
        case ui.TextDecorationStyle.wavy:
          calculateWaves(x, y, block.textStyle, sourceRect, thickness);

        case ui.TextDecorationStyle.double:
          final double bottom = y + DoubleDecorationSpacing + thickness;
          paintContext!.beginPath();
          paintContext!.moveTo(x, y);
          paintContext!.lineTo(x + width, y);
          paintContext!.moveTo(x, bottom);
          paintContext!.lineTo(x + width, bottom);
          paintContext!.stroke();
          WebParagraphDebug.log('double: $x:${x + width}, $y:$bottom');

        case ui.TextDecorationStyle.dashed:
        case ui.TextDecorationStyle.dotted:
          final Float32List dashes = Float32List(2)
            ..[0] =
                thickness *
                (block.textStyle.decorationStyle! == ui.TextDecorationStyle.dotted ? 1 : 4)
            ..[1] = thickness;

          paintContext!.setLineDash(dashes);
          paintContext!.beginPath();
          paintContext!.moveTo(x, y);
          paintContext!.lineTo(x + width, y);
          paintContext!.stroke();
          WebParagraphDebug.log('dashed/dotted: $x:${x + width}, $y');

        case ui.TextDecorationStyle.solid:
          paintContext!.beginPath();
          paintContext!.moveTo(x, y);
          paintContext!.lineTo(x + width, y);
          paintContext!.stroke();
          WebParagraphDebug.log(
            'solid: $x:${x + width}, $y ${block.textStyle.decorationColor!.toCssString()}',
          );
      }
    }
  }

  @override
  void paintDecorations(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
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
  void fillShadow(ExtendedTextCluster webTextCluster, ui.Shadow shadow, bool isDefaultLtr) {
    final WebTextStyle textStyle = webTextCluster.textStyle!;

    // TODO(jlavrova): see if we can implement shadowing ourself avoiding redrawing text clusters many times.
    // Answer: we cannot, and also there is a question of calculating the size of the shadow which we have to
    // take from Chrome as well (performing another measure text operation with shadow attribute set).
    paintContext!.fillStyle = textStyle.foreground?.color.toCssString();
    paintContext!.shadowColor = shadow.color.toCssString();
    paintContext!.shadowBlur = shadow.blurRadius;
    paintContext!.shadowOffsetX = shadow.offset.dx;
    paintContext!.shadowOffsetY = shadow.offset.dy;
    WebParagraphDebug.log(
      'Shadow: x=${shadow.offset.dx} y=${shadow.offset.dy} blur=${shadow.blurRadius} color=${shadow.color.toCssString()}',
    );

    // We fill the text cluster into a rectange [0,0,w,h]
    // but we need to shift the y coordinate by the font ascent
    // becase the text is drawn at the ascent, not at 0
    paintContext!.fillTextCluster(
      webTextCluster.cluster!,
      /*left:*/ 0,
      /*top:*/ webTextCluster.fontBoundingBoxAscent,
      /*ignore the text cluster shift from the text run*/ {
        'x': (isDefaultLtr ? 0 : webTextCluster.advance.width) + 100,
        'y': 100,
      },
    );

    // Clean the shadow context
    paintContext!.shadowColor = '';
    paintContext!.shadowBlur = 0;
    paintContext!.shadowOffsetX = 0;
    paintContext!.shadowOffsetY = 0;
  }

  @override
  void paintShadow(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
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

  @override
  void fillText(LineClusterBlock block, double x, double y) {
    final WebTextStyle textStyle = block.textStyle;
    paintContext!.fillStyle = textStyle.foreground?.color.toCssString();

    // Paint all the block text clusters on Canvas2D
    final double ascent = block.textMetrics!.fontBoundingBoxAscent;
    final bool isDefaultLtr = block.bidiLevel.isEven;
    final int start = isDefaultLtr ? block.clusterRange.start : block.clusterRange.end - 1;
    final int end = block.bidiLevel.isEven ? block.clusterRange.end : block.clusterRange.start - 1;
    final int step = block.bidiLevel.isEven ? 1 : -1;
    for (int i = start; i != end; i += step) {
      final clusterText = block.layout!.textClusters[i];
      final int subpixel = calculateSubpixel(
        clusterText,
        ui.Offset(
          block.line.advance.left + block.line.formattingShift + block.clusterShiftInLine,
          block.line.advance.top +
              block.line.fontBoundingBoxAscent -
              block.rawFontBoundingBoxAscent,
        ),
        ui.Offset(x, y),
      );
      // Take the bitmap image from the cache or create it (and remember in the cache if needed)
      DomImageBitmap? bitmap;
      final String key = '${clusterText.cacheId}$subpixel';
      if (clusterText.cacheId.isNotEmpty && clusterCache.containsKey(key)) {
        bitmap = clusterCache[key];
      } else {
        final DomOffscreenCanvas clusterCanvas = createDomOffscreenCanvas(
          clusterText.advance.width.ceil(),
          clusterText.advance.height.ceil(),
        );
        final clusterContext =
            clusterCanvas.getContext('2d', {'willReadFrequently': true})!
                as DomCanvasRenderingContext2D;
        clusterContext.fillTextCluster(
          clusterText.cluster!,
          /*left:*/ 0,
          /*top:*/ ascent,
          /*ignore the text cluster shift from the text run*/ {
            'x': (isDefaultLtr ? 0 : clusterText.advance.width),
            'y': 0,
          },
        );
        bitmap = clusterCanvas.transferToImageBitmap();
        if (clusterText.cacheId.isNotEmpty) {
          clusterCache[key] = bitmap;
        }
      }
      paintContext!.drawImage(bitmap!, 0, 0);
      paintContext!.translate(clusterText.advance.width, 0);
    }
    paintContext!.translate(-block.advance.width, block.line.advance.height);
  }

  @override
  void paintText(ui.Canvas canvas, LineClusterBlock block, ui.Rect sourceRect, ui.Rect targetRect) {
    final CkImage? image = blockCache[block.textRange];
    if (image == null) {
      return;
    }
    canvas.drawImageRect(
      image,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  @override
  void fillShadows(LineClusterBlock block, ui.Rect sourceRect) {}

  @override
  void paintShadows(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {}

  @override
  void fillTextCluster(ExtendedTextCluster webTextCluster, bool isDefaultLtr) {
    final WebTextStyle textStyle = webTextCluster.textStyle!;
    paintContext!.fillStyle = textStyle.foreground?.color.toCssString();

    // We fill the text cluster into a rectange [0,0,w,h]
    // but we need to shift the y coordinate by the font ascent
    // becase the text is drawn at the ascent, not at 0
    paintContext!.fillTextCluster(
      webTextCluster.cluster!,
      /*left:*/ 0,
      /*top:*/ webTextCluster.fontBoundingBoxAscent,
      /*ignore the text cluster shift from the text run*/ {
        'x': (isDefaultLtr ? 0 : webTextCluster.advance.width),
        'y': 0,
      },
    );
  }

  @override
  void paintTextCluster(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
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
    paintContext!.beginPath();
    //paintContext!.moveTo(x, y + quarterWave);
    while (xStart + quarterWave * 2 < textBounds.width) {
      final double x1 = xStart;
      final double y1 = yStart + quarterWave * (waveCount.isEven ? 1 : -1);
      final double x2 = xStart + quarterWave * 2;
      final double y2 = yStart;
      WebParagraphDebug.log('wave: $x1, $y1, $x2, $y2');
      paintContext!.quadraticCurveTo(x1, y1, x2, y2);
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
      paintContext!.quadraticCurveTo(x1, y1, x2, y2);
    }
    paintContext!.stroke();
  }

  void drawLineAsRect(double x, double y, double width, double thickness) {
    final double radius = thickness / 2;
    paintContext!.fillRect(x, y - radius, x + width, y + radius);
    WebParagraphDebug.log('paintContext!.fillRect($x, $y - $radius, $x + $width, $y + $radius);');
  }

  int calculateSubpixel(
    ExtendedTextCluster webTextCluster,
    ui.Offset clusterOffset,
    ui.Offset lineOffset,
  ) {
    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)
    final double left = clusterOffset.dx + webTextCluster.advance.left + lineOffset.dx;
    final double shift = left - left.floorToDouble();
    final subpixel1 = shift + (shift < 0 ? shift.ceilToDouble() : 0);
    final subpixel2 = (subpixel1 * 100).ceil() / 25;

    return subpixel2.floor();
  }
}
