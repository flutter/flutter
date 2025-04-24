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
    WebParagraphDebug.log(
      'paintLineOnCanvasKit: [${line.textRange.start}:${line.textRange.end}) *${line.visualRuns.length} @$x,$y + @${line.bounds.left},${line.bounds.top + line.fontBoundingBoxAscent} ${line.shift}->${line.bounds.width}x${line.bounds.height}',
    );

    double clusterShift = 0.0;
    for (final BidiRun run in line.visualRuns) {
      WebParagraphDebug.log(
        'run: [${run.clusterRange.start}:${run.clusterRange.end}) ${run.shift}',
      );
      for (int i = run.clusterRange.start; i < run.clusterRange.end; ++i) {
        final clusterText = layout.textClusters[i];
        paintCluster(
          canvas,
          clusterText,
          ui.Offset(
            line.shift - line.bounds.left + run.shift,
            line.bounds.top + line.fontBoundingBoxAscent,
          ),
          ui.Offset(x, y),
        );
        clusterShift += clusterText.bounds.width;
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
    textContext.fillStyle = textStyle.foreground?.color.toCssString();
    textContext.fillTextCluster(webTextCluster.cluster!, clusterOffset.dx, clusterOffset.dy);

    final engine.DomImageBitmap bitmap = textCanvas.transferToImageBitmap();

    final engine.SkImage? skImage = engine.canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    if (skImage == null) {
      throw Exception('Failed to convert text image bitmap to an SkImage.');
    }

    final engine.CkImage ckImage = engine.CkImage(
      skImage,
      imageSource: engine.ImageBitmapImageSource(bitmap),
    );
    final ui.Rect clusterRect = webTextCluster.bounds.translate(clusterOffset.dx, clusterOffset.dy);
    canvas.drawImageRect(
      ckImage,
      clusterRect,
      clusterRect.translate(lineOffset.dx + webTextCluster.shift, lineOffset.dy),
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
    final String text = paragraph.text!.substring(
      webTextCluster.textRange.start,
      webTextCluster.textRange.end,
    );
    WebParagraphDebug.log(
      'cluster "$text" "${textStyle.foreground?.color.toCssString()}" ${webTextCluster.bounds.left}:${webTextCluster.bounds.right} @${lineOffset.dx},${lineOffset.dy}',
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
