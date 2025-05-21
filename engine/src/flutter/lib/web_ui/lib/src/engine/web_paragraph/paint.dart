// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_api.dart';
import '../canvaskit/canvaskit_canvas.dart';
import '../canvaskit/image.dart';
import '../dom.dart';
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
      'paintLineOnCanvasKit: [${line.textRange.start}:${line.textRange.end}) @$x,$y + @${line.bounds.left},${line.bounds.top + line.fontBoundingBoxAscent} ${line.shift}->${line.bounds.width}x${line.bounds.height}',
    );

    for (final BidiRun run in line.visualRuns) {
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
      }
    }
  }

  void paintCluster(
    CanvasKitCanvas canvas,
    ExtendedTextCluster webTextCluster,
    ui.Offset clusterOffset,
    ui.Offset lineOffset,
  ) {
    paintContext.fillTextCluster(webTextCluster.cluster!, clusterOffset.dx, clusterOffset.dy);

    final DomImageBitmap bitmap = _paintCanvas.transferToImageBitmap();

    final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    if (skImage == null) {
      throw Exception('Failed to convert text image bitmap to an SkImage.');
    }

    final CkImage ckImage = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
    final ui.Rect clusterRect = webTextCluster.bounds.translate(clusterOffset.dx, clusterOffset.dy);
    canvas.drawImageRect(
      ckImage,
      clusterRect,
      clusterRect.translate(lineOffset.dx, lineOffset.dy),
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
    WebParagraphDebug.log(
      '[${webTextCluster.start}:${webTextCluster.end}) ${webTextCluster.bounds.left},${webTextCluster.bounds.top},${clusterRect.width}${clusterRect.height} => ${clusterOffset.dx},${clusterOffset.dy}',
    );
  }

  void printTextCluster(ExtendedTextCluster webTextCluster) {
    final String text = paragraph.text!.substring(webTextCluster.start, webTextCluster.end);
    final ui.Rect box = webTextCluster.bounds;
    print(
      '[${webTextCluster.start}:${webTextCluster.end}) = "$text", ${box.width}, ${box.height}\n',
    );
  }
}
