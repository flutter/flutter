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

final DomOffscreenCanvas _paintCanvas = createDomOffscreenCanvas(500, 500);
final paintContext = _paintCanvas.getContext('2d')! as DomCanvasRenderingContext2D;

/// Performs layout on a [WebParagraph].
///
/// It uses a [DomCanvasElement] to get text information
class TextPaint {
  TextPaint(this.paragraph);

  final WebParagraph paragraph;

  void paintLineOnCanvas2D(
    DomHTMLCanvasElement canvas,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    for (int i = line.textRange.start; i < line.textRange.end; i++) {
      final clusterText = layout.textClusters[i];
      final DomCanvasRenderingContext2D context = canvas.context2D;
      context.font = '50px arial';
      context.fillStyle = 'black';
      context.fillTextCluster(clusterText.cluster!, x, y);
    }
  }

  void paintLineOnCanvasKit(
    CanvasKitCanvas canvas,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    // TODO(jlavrova): We need to traverse clusters in the order of visual bidi runs
    // (by line, then by reordered visual runs)
    WebParagraphDebug.log(
      'paintLineBackgroundOnCanvasKit: [${line.textRange.start}:${line.textRange.end}) @$x,$y + @${line.bounds.left},${line.bounds.top + line.fontBoundingBoxAscent} ${line.formattingShift}->${line.bounds.width}x${line.bounds.height}',
    );
    for (final LineRun run in line.visualRuns) {
      final int start = run.bidiLevel.isEven ? run.clusterRange.start : run.clusterRange.end - 1;
      final int end = run.bidiLevel.isEven ? run.clusterRange.end : run.clusterRange.start - 1;
      final int step = run.bidiLevel.isEven ? 1 : -1;
      for (int i = start; i != end; i += step) {
        final clusterText = layout.textClusters[i];
        WebParagraphDebug.log(
          '$i: ${line.formattingShift} + ${run.shiftInsideLine} + ${clusterText.shift}',
        );
        paintClusterBackground(
          canvas,
          clusterText,
          ui.Offset(
            line.formattingShift + run.shiftInsideLine + clusterText.shift,
            line.bounds.top,
          ),
          ui.Offset(x, y),
          run.bidiLevel.isEven,
        );
      }
    }

    WebParagraphDebug.log(
      'paintLineShadowsOnCanvasKit: [${line.textRange.start}:${line.textRange.end}) @$x,$y + @${line.bounds.left},${line.bounds.top + line.fontBoundingBoxAscent} ${line.formattingShift}->${line.bounds.width}x${line.bounds.height}',
    );
    for (final LineRun run in line.visualRuns) {
      final int start = run.bidiLevel.isEven ? run.clusterRange.start : run.clusterRange.end - 1;
      final int end = run.bidiLevel.isEven ? run.clusterRange.end : run.clusterRange.start - 1;
      final int step = run.bidiLevel.isEven ? 1 : -1;
      for (int i = start; i != end; i += step) {
        final clusterText = layout.textClusters[i];
        WebParagraphDebug.log(
          '$i: ${line.formattingShift} + ${run.shiftInsideLine} + ${clusterText.shift}',
        );
        paintClusterShadows(
          canvas,
          clusterText,
          ui.Offset(
            line.formattingShift + run.shiftInsideLine + clusterText.shift,
            line.bounds.top,
          ),
          ui.Offset(x, y),
          run.bidiLevel.isEven,
        );
      }
    }

    WebParagraphDebug.log(
      'paintLineOnCanvasKit: [${line.textRange.start}:${line.textRange.end}) @$x,$y + @${line.bounds.left},${line.bounds.top + line.fontBoundingBoxAscent} ${line.formattingShift}->${line.bounds.width}x${line.bounds.height}',
    );
    for (final LineRun run in line.visualRuns) {
      WebParagraphDebug.log(
        'run: ${run.clusterRange} ${run.shiftInsideLine} line.formattingShift: ${line.formattingShift}',
      );
      final int start = run.bidiLevel.isEven ? run.clusterRange.start : run.clusterRange.end - 1;
      final int end = run.bidiLevel.isEven ? run.clusterRange.end : run.clusterRange.start - 1;
      final int step = run.bidiLevel.isEven ? 1 : -1;
      for (int i = start; i != end; i += step) {
        final clusterText = layout.textClusters[i];
        WebParagraphDebug.log(
          '$i: ${line.formattingShift} + ${run.shiftInsideLine} + ${clusterText.shift}',
        );
        paintCluster(
          canvas,
          clusterText,
          ui.Offset(
            line.formattingShift + run.shiftInsideLine + clusterText.shift,
            line.bounds.top,
          ),
          ui.Offset(x, y),
          run.bidiLevel.isEven,
        );
      }
    }

    WebParagraphDebug.log(
      'paintLineDecorationOnCanvasKit: [${line.textRange.start}:${line.textRange.end}) ${line.visualRuns.length} ${line.styledTextRanges.length}',
    );
    for (final s in line.styledTextRanges) {
      WebParagraphDebug.log('${s.textRange}');
    }
    // We need to iterate throught the blocks of clusters that belong to the same visual run and the same text style
    // We need it to garantee the same direction and the same text metrics
    // TODO(jlavrova): we actually cannot assume that the text metrics will be the same since Chrome does not garantee it. Should we make sure by comparing ascents/descents (since we only care about them)
    // TODO(jlavrova): do we decorate whitespaces?
    // TODO(jlavrova): we need to treat each style block as a separate entity with separate ascent&descent (regardless of what Chrome does with fonts) one for all the text, not for each line
    int visualRunIndex = 0;
    int styledTextIndex = 0;
    int textStart = -1;
    while (visualRunIndex < line.visualRuns.length &&
        styledTextIndex < line.styledTextRanges.length) {
      final LineRun visualRun = line.visualRuns[visualRunIndex];
      final LineStyledTextRange styledTextRange = line.styledTextRanges[styledTextIndex];
      if (textStart == -1) {
        textStart = styledTextRange.textRange.start;
      }
      int textEnd;
      if (visualRun.textRange.end < styledTextRange.textRange.end) {
        textEnd = visualRun.textRange.end;
        visualRunIndex++;
      } else if (visualRun.textRange.end > styledTextRange.textRange.end) {
        textEnd = styledTextRange.textRange.end;
        styledTextIndex++;
      } else {
        textEnd = styledTextRange.textRange.end;
        visualRunIndex++;
        styledTextIndex++;
      }
      if (textStart == textEnd) {
        continue;
      }
      final ClusterRange clusterRange = layout.convertTextToClusterRange(textStart, textEnd);
      final ClusterRange lineClusterRange = paragraph.getLayout().intersectClusterRange(
        clusterRange,
        line.textRange,
      );

      // Decorate [start: end)
      final double styleShift = layout.textClusters[textStart].shift;
      final DomTextMetrics textMetrics = layout.textClusters[clusterRange.start].textMetrics!;
      WebParagraphDebug.log(
        'paintClustersDecoration text:[$textStart:$textEnd) clusters:$clusterRange lineClusters:$lineClusterRange run:${visualRun.textRange} style:${styledTextRange.textRange} shift: $styleShift posX: ${layout.textClusters[lineClusterRange.start].advance.left}',
      );
      paintClustersDecoration(
        canvas,
        lineClusterRange.start,
        lineClusterRange.end,
        styledTextRange.textRange.start,
        styledTextRange.offset,
        styledTextRange.textStyle,
        textMetrics,
        layout.textClusters[lineClusterRange.start].advance.left,
        ui.Offset(line.formattingShift + visualRun.shiftInsideLine + styleShift, line.bounds.top),
        ui.Offset(x, y),
        visualRun.bidiLevel.isEven,
        line.fontBoundingBoxAscent,
      );
      // Move forward
      textStart = textEnd;
    }
  }

  void paintClusterBackground(
    CanvasKitCanvas canvas,
    ExtendedTextCluster webTextCluster,
    ui.Offset clusterOffset,
    ui.Offset lineOffset,
    bool ltr,
  ) {
    final WebTextStyle textStyle = webTextCluster.textStyle!;
    if (textStyle.background == null) {
      return;
    }

    final List<DomRectReadOnly> rects = webTextCluster.textMetrics!.getSelectionRects(
      webTextCluster.cluster!.begin,
      webTextCluster.cluster!.end,
    );

    // Define the text cluster bounds
    WebParagraphDebug.log(
      'pos = ${webTextCluster.bounds.left - webTextCluster.advance.left} = ${webTextCluster.bounds.left} - ${webTextCluster.advance.left} ',
    );
    final pos = webTextCluster.bounds.left - webTextCluster.advance.left;
    final ui.Rect zeroRect = ui.Rect.fromLTWH(
      pos,
      0,
      webTextCluster.bounds.width,
      rects.first.height,
    );
    final ui.Rect sourceRect = zeroRect;

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)

    final double left = clusterOffset.dx + webTextCluster.advance.left + lineOffset.dx;
    final double shift = left - left.floorToDouble();
    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        .translate(clusterOffset.dx + webTextCluster.advance.left, clusterOffset.dy)
        .translate(lineOffset.dx, lineOffset.dy)
        .translate(-shift, 0);

    if (textStyle.background != null) {
      // Draw the background color
      final ui.Rect backgroundRect = ui.Rect.fromLTWH(
            0,
            0,
            rects.first.width.ceilToDouble(),
            rects.first.height,
          )
          .translate(clusterOffset.dx + webTextCluster.advance.left, clusterOffset.dy)
          .translate(lineOffset.dx, lineOffset.dy)
          .translate(-shift, 0);
      canvas.drawRect(backgroundRect, textStyle.background!);
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

  void paintClusterShadows(
    CanvasKitCanvas canvas,
    ExtendedTextCluster webTextCluster,
    ui.Offset clusterOffset,
    ui.Offset lineOffset,
    bool ltr,
  ) {
    final WebTextStyle textStyle = webTextCluster.textStyle!;
    if (textStyle.shadows == null || textStyle.shadows!.isEmpty) {
      // No shadows
      paintContext.shadowColor = '';
      paintContext.shadowBlur = 0;
      paintContext.shadowOffsetX = 0;
      paintContext.shadowOffsetY = 0;
      return;
    }

    final List<DomRectReadOnly> rects = webTextCluster.textMetrics!.getSelectionRects(
      webTextCluster.cluster!.begin,
      webTextCluster.cluster!.end,
    );

    // Define the text cluster bounds
    final pos = webTextCluster.bounds.left - webTextCluster.advance.left;
    final ui.Rect zeroRect = ui.Rect.fromLTWH(
      pos,
      0,
      webTextCluster.bounds.width,
      rects.first.height,
    );
    final ui.Rect sourceRect = zeroRect;

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)

    final double left = clusterOffset.dx + webTextCluster.advance.left + lineOffset.dx;
    final double shift = left - left.floorToDouble();
    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        .translate(clusterOffset.dx + webTextCluster.advance.left, clusterOffset.dy)
        .translate(lineOffset.dx, lineOffset.dy)
        .translate(-shift, 0);

    final String text = paragraph.getText(webTextCluster.textRange);

    paintContext.fillStyle = textStyle.foreground?.color.toCssString();

    ui.Rect shadowSourceRect = sourceRect;
    ui.Rect shadowTargetRect = targetRect;
    WebParagraphDebug.log('source: $shadowSourceRect target: $shadowTargetRect');

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
        /*top:*/ webTextCluster.textMetrics!.fontBoundingBoxAscent,
        /*ignore the text cluster shift from the text run*/ {
          'x': (paragraph.getLayout().isDefaultLtr ? 0 : webTextCluster.advance.width) + 100,
          'y': 100,
        },
      );
    }
    WebParagraphDebug.log('paintClusterShadows1: $shadowSourceRect $shadowTargetRect');
    // TODO(jlavrova): calculate the shadow bounds properly
    shadowSourceRect = shadowSourceRect.inflate(100);
    shadowSourceRect = shadowSourceRect.translate(100, 100);
    shadowTargetRect = shadowTargetRect.inflate(100);
    //shadowTargetRect = shadowTargetRect.translate(-100, -100);
    WebParagraphDebug.log('paintClusterShadows2: $shadowSourceRect $shadowTargetRect');

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

    // Clean the shadow context
    paintContext.shadowColor = '';
    paintContext.shadowBlur = 0;
    paintContext.shadowOffsetX = 0;
    paintContext.shadowOffsetY = 0;
  }

  void paintCluster(
    CanvasKitCanvas canvas,
    ExtendedTextCluster webTextCluster,
    ui.Offset clusterOffset,
    ui.Offset lineOffset,
    bool ltr,
  ) {
    final WebTextStyle textStyle = webTextCluster.textStyle!;

    final List<DomRectReadOnly> rects = webTextCluster.textMetrics!.getSelectionRects(
      webTextCluster.cluster!.begin,
      webTextCluster.cluster!.end,
    );

    // Define the text cluster bounds
    WebParagraphDebug.log(
      'pos = ${webTextCluster.bounds.left - webTextCluster.advance.left} = ${webTextCluster.bounds.left} - ${webTextCluster.advance.left} ',
    );
    final pos = webTextCluster.bounds.left - webTextCluster.advance.left;
    final ui.Rect zeroRect = ui.Rect.fromLTWH(
      pos,
      0,
      webTextCluster.bounds.width,
      rects.first.height,
    );
    final ui.Rect sourceRect = zeroRect;

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)

    final double left = clusterOffset.dx + webTextCluster.advance.left + lineOffset.dx;
    final double shift = left - left.floorToDouble();
    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        .translate(clusterOffset.dx + webTextCluster.advance.left, clusterOffset.dy)
        .translate(lineOffset.dx, lineOffset.dy)
        .translate(-shift, 0);

    final String text = paragraph.getText(webTextCluster.textRange);

    WebParagraphDebug.log(
      'cluster "$text" source: ${sourceRect.left}:${sourceRect.right} => target: ${targetRect.left}:${targetRect.right} ${targetRect.top}:${targetRect.bottom} pos $pos shift $shift ',
    );

    paintContext.fillStyle = textStyle.foreground?.color.toCssString();

    // We fill the text cluster into a rectange [0,0,w,h]
    // but we need to shift the y coordinate by the font ascent
    // becase the text is drawn at the ascent, not at 0
    paintContext.fillTextCluster(
      webTextCluster.cluster!,
      /*left:*/ 0,
      /*top:*/ webTextCluster.textMetrics!.fontBoundingBoxAscent,
      /*ignore the text cluster shift from the text run*/ {
        'x': (paragraph.getLayout().isDefaultLtr ? 0 : webTextCluster.advance.width),
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
    int waveCount = 0;
    double xStart = 0;
    final double quarterWave = thickness;
    paintContext.moveTo(x, y);
    while (xStart + quarterWave * 2 < textBounds.width) {
      paintContext.quadraticCurveTo(
        quarterWave,
        waveCount % 2 != 0 ? quarterWave : -quarterWave,
        quarterWave * 2,
        0,
      );
      //result.quadraticCurveTo(
      //  quarterWave,
      //  wave_count % 2 != 0 ? quarterWave : -quarterWave,
      //  quarterWave * 2,
      //  0,
      //);
      xStart += quarterWave * 2;
      ++waveCount;
    }

    // The rest of the wave
    final double remaining = textBounds.width - xStart;
    if (remaining > 0) {
      final double x1 = remaining / 2;
      final double y1 = remaining / 2 * (waveCount.isEven ? -1 : 1);
      final double x2 = remaining;
      final double y2 =
          (remaining - remaining * remaining / (quarterWave * 2)) * (waveCount.isEven ? -1 : 1);
      paintContext.quadraticCurveTo(x1, y1, x2, y2);
      //fPath.rQuadTo(x1, y1, x2, y2);
    }
  }

  void drawLineAsRect(double x, double y, double width, double thickness) {
    final double radius = thickness / 2;
    paintContext.fillRect(x, y - radius, x + width, y + radius);
    WebParagraphDebug.log('paintContext.fillRect($x, $y - $radius, $x + $width, $y + $radius);');
  }

  void paintDecoration(
    WebTextStyle textStyle,
    ui.Rect textBounds,
    double lineAscent,
    double fontAscent,
    double fontHeight,
  ) {
    WebParagraphDebug.log(
      'paintDecoration(textStyle: ${textStyle.decoration}&${textStyle.decorationStyle}, textBounds:$textBounds, lineAscent: $lineAscent, fontAscent: $fontAscent, fontHeight: $fontHeight)',
    );
    // Get thickness and position
    final double thickness = calculateThickness(textStyle);

    const double DoubleDecorationSpacing = 3.0;

    for (final ui.TextDecoration decoration in [
      ui.TextDecoration.lineThrough,
      ui.TextDecoration.underline,
      ui.TextDecoration.overline,
    ]) {
      if (!textStyle.decoration!.contains(decoration)) {
        WebParagraphDebug.log('-decoration=$decoration');
        continue;
      }

      final double position = calculatePosition(decoration, thickness, fontHeight, fontAscent);
      WebParagraphDebug.log('+decoration=$decoration thickness=$thickness position=$position');

      final double width = textBounds.width;
      final double x = textBounds.left;
      final double y = textBounds.top + position;

      // TODO(jlavrova): setup style
      paintContext.reset();
      paintContext.lineWidth = thickness;
      paintContext.strokeStyle = textStyle.decorationColor!.toCssString();

      switch (textStyle.decorationStyle!) {
        case ui.TextDecorationStyle.wavy:
          calculateWaves(x, y, textStyle, textBounds, thickness);
          return;

        case ui.TextDecorationStyle.double:
          final double bottom = y + DoubleDecorationSpacing + thickness;
          paintContext.beginPath();
          paintContext.moveTo(x, y);
          paintContext.lineTo(x + width, y);
          paintContext.moveTo(x, bottom);
          paintContext.lineTo(x + width, bottom);
          paintContext.stroke();
          WebParagraphDebug.log('double1: $x:${x + width}, $y');
          WebParagraphDebug.log('double2: $x:${x + width}, $bottom');
          return;

        case ui.TextDecorationStyle.dashed:
        case ui.TextDecorationStyle.dotted:
          final Float32List dashes =
              Float32List(2)
                ..[0] =
                    thickness *
                    (textStyle.decorationStyle! == ui.TextDecorationStyle.dotted ? 1 : 4)
                ..[1] = thickness;

          paintContext.setLineDash(dashes);
          paintContext.beginPath();
          paintContext.moveTo(x, y);
          paintContext.lineTo(x + width, y);
          paintContext.stroke();
          WebParagraphDebug.log('dashed/dotted: $x:${x + width}, $y');
          return;

        case ui.TextDecorationStyle.solid:
          paintContext.beginPath();
          paintContext.moveTo(x, y);
          paintContext.lineTo(x + width, y);
          paintContext.stroke();
          WebParagraphDebug.log(
            'solid: $x:${x + width}, $y ${textStyle.decorationColor!.toCssString()}',
          );
          return;
      }
    }
  }

  void paintClustersDecoration(
    CanvasKitCanvas canvas,
    int start,
    int end,
    int beginning,
    int offset,
    WebTextStyle textStyle,
    DomTextMetrics textMetrics,
    double posX,
    ui.Offset clusterOffset,
    ui.Offset lineOffset,
    bool ltr,
    double lineAscent,
  ) {
    if (textStyle.decoration == null || textStyle.decoration! == ui.TextDecoration.none) {
      // No decoration
      return;
    }
    WebParagraphDebug.log('[$start:$end) $beginning $offset');
    final String text = paragraph.text!.substring(start, end);
    final List<DomRectReadOnly> rects = textMetrics.getSelectionRects(
      start + offset - beginning,
      end + offset - beginning,
    );
    assert(rects.length == 1); // We worked hard to make it sequential
    final rect = textMetrics.getActualBoundingBox(
      start + offset - beginning,
      end + offset - beginning,
    );
    double sum = 0;
    final textRange = TextRange(start: start, end: end);
    final clusterRange = paragraph.getLayout().convertTextToClusterRange(
      textRange.start,
      textRange.end,
    );
    for (int i = clusterRange.start; i < clusterRange.end; ++i) {
      final cluster = paragraph.getLayout().textClusters[i];
      final text = paragraph.text!.substring(cluster.textRange.start, cluster.textRange.end);
      WebParagraphDebug.log(
        'sum$i: "$text" $sum + ${cluster.advance.width} = ${sum + cluster.advance.width}',
      );
      sum += cluster.advance.width;
    }
    for (int i = start + 1; i <= end; ++i) {
      final text = paragraph.text!.substring(start, i);
      final test = paragraph.getLayout().getAdvance(
        textMetrics,
        TextRange(start: start + offset - beginning, end: i + offset - beginning),
      );
      WebParagraphDebug.log('test$i: "$text" [$start:$i) ${test.left}:${test.right}');
    }
    WebParagraphDebug.log(
      'Compare $sum "$text" ${textMetrics.getTextClusters().length} $textRange  $offset - $beginning = ${offset - beginning} ? ${rects.first.width} ${rect.width} [$start:$end)',
    );

    // Define the text clusters rect (using advances, not selected rects)
    final ui.Rect zeroRect = ui.Rect.fromLTWH(0, 0, rects.first.width, rects.first.height);
    final ui.Rect sourceRect = zeroRect;

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)

    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        .translate(clusterOffset.dx + posX, clusterOffset.dy)
        .translate(lineOffset.dx, lineOffset.dy);

    WebParagraphDebug.log(
      'clusters "$text" source: ${sourceRect.left}:${sourceRect.right} => target: ${targetRect.left}:${targetRect.right}',
    );

    paintContext.fillStyle = textStyle.foreground?.color.toCssString();

    paintDecoration(
      textStyle,
      sourceRect,
      lineAscent,
      textMetrics.fontBoundingBoxAscent,
      textMetrics.fontBoundingBoxAscent + textMetrics.fontBoundingBoxDescent,
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

  void printTextCluster(ExtendedTextCluster webTextCluster) {
    final String text = paragraph.text!.substring(
      webTextCluster.textRange.start,
      webTextCluster.textRange.end,
    );
    final ui.Rect box = webTextCluster.bounds;
    print(
      '[${webTextCluster.textRange.start}:${webTextCluster.textRange.end}) = "$text", ${box.width}, ${box.height}\n',
    );
  }
}
