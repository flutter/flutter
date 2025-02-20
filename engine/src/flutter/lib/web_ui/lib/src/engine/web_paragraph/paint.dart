// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'paragraph.dart';
import 'layout.dart';

final DomOffscreenCanvas textCanvas = createDomOffscreenCanvas(500, 500);
final textContext = textCanvas.getContext('2d')! as DomCanvasRenderingContext2D;

/// Performs layout on a [CanvasParagraph].
///
/// It uses a [DomCanvasElement] to get text information
class TextPaint {
  TextPaint(this.paragraph);

  final WebParagraph paragraph;

  void paintLineOnCanvas2D(DomCanvasElement canvas, TextLayout layout, TextLine line, double x, double y) {

    for (int i = line.clusterRange.start; i < line.clusterRange.end; i++) {
      final clusterText = layout.textClusters[i];
      String text = this.paragraph.text.substring(clusterText.begin, clusterText.end);
      final DomCanvasRenderingContext2D context = canvas.context2D;
      context.font = '50px arial';
      context.fillStyle = 'black';
      context.fillTextCluster(clusterText, x, y);
    }
  }

  void paintLineOnCanvasKit(CanvasKitCanvas canvas, TextLayout layout, TextLine line, double x, double y) {
    for (int i = line.clusterRange.start; i < line.clusterRange.end; i++) {
      final clusterText = layout.textClusters[i];
      paintCluster(canvas, layout.textMetrics!, clusterText, x, y);
    }
  }

  void paintCluster(CanvasKitCanvas canvas, DomTextMetrics textMetrics, WebTextCluster webTextCluster, double x, double y) {
    String text = this.paragraph.text.substring(webTextCluster.begin, webTextCluster.end);
    final DomRectReadOnly box = textMetrics.getActualBoundingBox(
      webTextCluster.begin,
      webTextCluster.end,
    );

    textContext.font = '50px arial';
    textContext.fillStyle = 'black';
    textContext.fillTextCluster(webTextCluster, x, y);

    final DomImageBitmap bitmap = textCanvas.transferToImageBitmap();

    final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    if (skImage == null) {
      throw Exception('Failed to convert text image bitmap to an SkImage.');
    }

    final CkImage ckImage = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
    canvas.drawImage(ckImage, ui.Offset(x, y), ui.Paint()..filterQuality = ui.FilterQuality.none);
  }

  void printTextCluster(DomTextMetrics textMetrics, WebTextCluster webTextCluster) {
    String text = this.paragraph.text.substring(webTextCluster.begin, webTextCluster.end);
    final DomRectReadOnly box = textMetrics.getActualBoundingBox(
      webTextCluster.begin,
      webTextCluster.end,
    );
    print(
      '[${webTextCluster.begin}:${webTextCluster.end}) = "${text}", ${box.width}, ${box.height}\n',
    );
  }
}
