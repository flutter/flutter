// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart'; // show CkCanvas, Uint8List;
//import 'package:ui/src/engine/safe_browser_api.dart';
import 'package:ui/ui.dart' as ui;

//import '../canvaskit/canvaskit_api.dart';
//import '../dom.dart';
import 'paragraph.dart';

final textCanvas = createDomOffscreenCanvas(200, 200);

/// A single canvas2d context to use for all text information.
@visibleForTesting
final textContext =
    // We don't use this canvas to draw anything, so let's make it as small as
    // possible to save memory.
    textCanvas.getContext('2d')! as DomCanvasRenderingContext2D;

/// Performs layout on a [CanvasParagraph].
///
/// It uses a [DomCanvasElement] to get text information
class TextPaint {
  TextPaint(this.paragraph);

  final WebParagraph paragraph;

  void paint(DomCanvasElement canvas, WebTextCluster webTextCluster, double x, double y) {
    String text = this.paragraph.text.substring(webTextCluster.begin, webTextCluster.end);
    final DomCanvasRenderingContext2D context = canvas.context2D;
    context.font = '50px arial';
    context.fillStyle = 'red';
    context.fillTextCluster(webTextCluster.textCluster!, x, y);
    /*
    // Loop through all the lines, for each line, loop through all fragments and
    // paint them. The fragment objects have enough information to be painted
    // individually.
    final List<ParagraphLine> lines = paragraph.lines;

    for (final ParagraphLine line in lines) {
      for (final LayoutFragment fragment in line.fragments) {
        _paintBackground(canvas, offset, fragment);f
        _paintText(canvas, offset, line, fragment);
      }
    }
     */
  }

  void paintTexture(CanvasKitCanvas canvas, WebTextCluster webTextCluster, double x, double y) {
    String text = this.paragraph.text.substring(webTextCluster.begin, webTextCluster.end);

    textContext.font = '50px arial';
    textContext.fillStyle = 'red';
    textContext.fillTextCluster(webTextCluster.textCluster!, x, y);
    print('fillTextCluster');

    final DomImageBitmap? bitmap = textCanvas.transferToImageBitmap();
    print('createImageBitmap: ${bitmap?.width}, ${bitmap?.height}\n');
    if (bitmap == null) {
      throw Exception('Failed to create a bitmap image.');
    } else {
      //final ui.Image image = canvas.createImageFromImageBitmap(bitmap);
      //print('createImageFromImageBitmap: ${image.width()}, ${image.height()}\n');
      /*
      final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
      if (skImage == null) {
        throw Exception('Failed to convert text image bitmap to an SkImage.');
      }
      print('MakeLazyImageFromImageBitmap: ${skImage.width()}, ${skImage.height()}\n');
      canvas.drawImage(CkImage(skImage) as ui.Image, ui.Offset(x, y), CkPaint());
        */
      final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
      if (skImage == null) {
        throw Exception('Failed to convert text image bitmap to an SkImage.');
      }
      print('MakeLazyImageFromImageBitmap: ${skImage.width()}, ${skImage.height()}\n');

      final CkImage ckImage = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
      canvas.drawImage(ckImage, ui.Offset(x, y), ui.Paint()..filterQuality = ui.FilterQuality.none);
      print('drawImage\n');
    }
  }

  void printTextCluster(WebTextCluster webTextCluster) {
    String text = this.paragraph.text.substring(webTextCluster.begin, webTextCluster.end);
    print(
      '[${webTextCluster.begin}:${webTextCluster.end}) = "${text}", ${webTextCluster.width}, ${webTextCluster.height}\n',
    );
  }
}
