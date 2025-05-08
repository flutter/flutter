// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
      'paintLineOnCanvasKit: [${line.textRange.start}:${line.textRange.end}) @$x,$y + @${line.bounds.left},${line.bounds.top + line.fontBoundingBoxAscent} ${line.formattingShift}->${line.bounds.width}x${line.bounds.height}',
    );
    for (final LineRun run in line.visualRuns) {
      final int start = run.bidiLevel.isEven ? run.clusterRange.start : run.clusterRange.end - 1;
      final int end = run.bidiLevel.isEven ? run.clusterRange.end : run.clusterRange.start - 1;
      final int step = run.bidiLevel.isEven ? 1 : -1;
      WebParagraphDebug.log(
        'run.shiftInsideLine: ${run.shiftInsideLine} line.formattingShift: ${line.formattingShift}',
      );
      for (int i = start; i != end; i += step) {
        final clusterText = layout.textClusters[i];
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
    final pos = webTextCluster.bounds.left - webTextCluster.cluster!.x;
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

    final double left = clusterOffset.dx + webTextCluster.cluster!.x + lineOffset.dx;
    final double shift = left - left.floorToDouble();
    // TODO(jlavrova): Make translation in a single operation so it's actually an integer
    final ui.Rect targetRect = zeroRect
        .translate(clusterOffset.dx + webTextCluster.cluster!.x, clusterOffset.dy)
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
          .translate(clusterOffset.dx + webTextCluster.cluster!.x, clusterOffset.dy)
          .translate(lineOffset.dx, lineOffset.dy)
          .translate(-shift, 0);
      canvas.drawRect(backgroundRect, textStyle.background!);
    }

    final String text = paragraph.text!.substring(
      webTextCluster.textRange.start,
      webTextCluster.textRange.end,
    );

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
      /*ignore the text cluster shift from the text run*/ {'x': 0, 'y': 0},
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
