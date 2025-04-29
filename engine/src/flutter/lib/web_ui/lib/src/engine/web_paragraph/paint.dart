// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart' as engine;
import 'package:ui/src/engine/web_paragraph/debug.dart';
import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import 'layout.dart';
import 'paragraph.dart';

final engine.DomOffscreenCanvas textCanvas = engine.createDomOffscreenCanvas(500, 500);
final textContext = textCanvas.getContext('2d')! as DomCanvasRenderingContext2D;

/// Performs layout on a [CanvasParagraph].
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
    engine.CanvasKitCanvas canvas,
    TextLayout layout,
    TextLine line,
    double x,
    double y,
  ) {
    double clusterShiftX = 0.0;
    for (final BidiRun run in line.visualRuns) {
      final int start = run.bidiLevel.isEven ? run.clusterRange.start : run.clusterRange.end - 1;
      final int end = run.bidiLevel.isEven ? run.clusterRange.end : run.clusterRange.start - 1;
      final int step = run.bidiLevel.isEven ? 1 : -1;
      for (int i = start; i != end; i += step) {
        final clusterText = layout.textClusters[i];
        paintCluster(
          canvas,
          clusterText,
          ui.Offset(line.shift + clusterShiftX, line.bounds.top),
          ui.Offset(x, y),
        );
        clusterShiftX += clusterText.bounds.width;
      }
    }
  }

  void paintCluster(
    engine.CanvasKitCanvas canvas,
    ExtendedTextCluster webTextCluster,
    ui.Offset clusterOffset,
    ui.Offset lineOffset,
  ) {
    final WebTextStyle textStyle = webTextCluster.textStyle!;

    // Define the text cluster bounds
    final ui.Rect sourceRect = ui.Rect.fromLTWH(
      0,
      0,
      webTextCluster.bounds.width,
      webTextCluster.bounds.height,
    );

    // We shift the target rect to the correct x position inside the line and
    // the correct y position of the line itself
    // (and then to the paragraph.paint x and y)
    double tail = webTextCluster.bounds.left - webTextCluster.bounds.left.floorToDouble();
    if (tail >= 0.5) {
      tail -= 1.0;
    }
    final ui.Rect targetRect = sourceRect
        .translate(clusterOffset.dx, clusterOffset.dy)
        .translate(lineOffset.dx, lineOffset.dy)
        .translate(-tail, 0);

    if (textStyle.background != null) {
      // Draw the background color
      final ui.Rect backgroundRect = ui.Rect.fromLTWH(
        targetRect.left + tail,
        targetRect.top,
        targetRect.width + 1,
        targetRect.height,
      );
      canvas.drawRect(backgroundRect, textStyle.background!);
    }

    textContext.fillStyle = textStyle.foreground?.color.toCssString();
    // We fill the text cluster into a rectange [0,0,w,h]
    // but we need to shift the y coordinate by the font ascent
    // becase the text is drawn at the ascent, not at 0
    textContext.fillTextCluster(
      webTextCluster.cluster!,
      /*left:*/ 0,
      /*top:*/ webTextCluster.textMetrics!.fontBoundingBoxAscent,
      /*ignore the text cluster shift from the text run*/ {'x': 0, 'y': 0},
    );

    final engine.DomImageBitmap bitmap = textCanvas.transferToImageBitmap();

    final engine.SkImage? skImage = engine.canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    if (skImage == null) {
      throw Exception('Failed to convert text image bitmap to an SkImage.');
    }

    final engine.CkImage ckImage = engine.CkImage(
      skImage,
      imageSource: engine.ImageBitmapImageSource(bitmap),
    );

    canvas.drawImageRect(
      ckImage,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
    final String text = paragraph.text!.substring(
      webTextCluster.textRange.start,
      webTextCluster.textRange.end,
    );
    WebParagraphDebug.log(
      'cluster "$text" ${webTextCluster.bounds.left}:${webTextCluster.bounds.right} ${webTextCluster.bounds.top}:${webTextCluster.bounds.bottom} @${clusterOffset.dx},${clusterOffset.dy}',
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
