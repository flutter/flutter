// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_api.dart';
import '../canvaskit/image.dart';
import '../dom.dart';
import 'debug.dart';
import 'layout.dart';
import 'paint.dart';

/// Abstracts the interface for painting text clusters, shadows, and decorations.
abstract class Painter {
  Painter();

  bool get hasSingleImageCache => false;

  /// Draws the previously filled on Canvas2D text cluster
  void drawTextCluster(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect);

  /// Draws the previously filled on Canvas2D text cluster shadow
  void drawShadowCluster(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect);

  /// Draws the background directly on canvas
  void drawBackground(ui.Canvas canvas, TextBlock block, ui.Rect sourceRect, ui.Rect targetRect);

  /// Draws the previously filled on Canvas2D text decorations
  void drawDecorations(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect);

  void drawParagraph(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect);

  void resetCache();
  bool hasCache();

  /// Adjust the _paintCanvas scale based on device pixel ratio
  void resizePaintCanvas(double devicePixelRatio, double width, double height) {
    if (currentDevicePixelRatio == devicePixelRatio &&
        paintCanvas.width == (width * devicePixelRatio).ceilToDouble() &&
        paintCanvas.height == (height * devicePixelRatio).ceilToDouble()) {
      // We need to resize canvas whenever the requested size changes
      return;
    }

    // Since the output canvas is zoomed by device pixel ratio,
    // we need to adjust our offscreen canvas accordingly to avoid pixelation
    // that would happen if didn't resize it.
    if (currentDevicePixelRatio != null) {
      paintContext.restore(); // Restore to unscaled state
    }
    paintCanvas.width = (width * devicePixelRatio).ceilToDouble();
    paintCanvas.height = (height * devicePixelRatio).ceilToDouble();
    paintContext.scale(devicePixelRatio, devicePixelRatio);
    paintContext.save();

    currentDevicePixelRatio = devicePixelRatio;

    WebParagraphDebug.log(
      'resizePaintCanvas: ${paintCanvas.width}x${paintCanvas.height} @ $devicePixelRatio',
    );
  }
}

final DomHTMLCanvasElement? _domHtmlCanvasElement = null;
    //domDocument.createElement('canvas') as DomHTMLCanvasElement;

class CanvasKitPainter extends Painter {
  CkImage? singleImageCache;

  @override
  bool get hasSingleImageCache => singleImageCache != null;

  @override
  void drawBackground(ui.Canvas canvas, LineBlock block, ui.Rect sourceRect, ui.Rect targetRect) {
    // We need to snap the block edges because Skia draws rectangles with subpixel accuracy
    // and we end up with overlaps (this is only a problem when colors have transparency)
    // or gaps between blocks (which looks unacceptable - vertical lines between blocks).
    // Whether we snap to floor or ceil is irrelevant as long as we are consistent on both sides
    // (and will possibly have problems when glyph boundaries are outside of advance rectangles)
    final snappedRect = ui.Rect.fromLTRB(
      targetRect.left.roundToDouble(),
      targetRect.top.roundToDouble(),
      targetRect.right.roundToDouble(),
      targetRect.bottom.roundToDouble(),
    );
    canvas.drawRect(snappedRect, block.style.background!);
  }

  @override
  void drawDecorations(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
    final DomImageBitmap bitmap = paintCanvas.transferToImageBitmap();

    final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    if (skImage == null) {
      throw Exception('Failed to convert text image bitmap to an SkImage.');
    }

    final ckImage = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
    canvas.drawImageRect(
      ckImage,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  @override
  void drawShadowCluster(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
    // TODO(jlavrova): calculate the shadow bounds properly
    final ui.Rect shadowSourceRect = sourceRect.inflate(100).translate(100, 100);
    final ui.Rect shadowTargetRect = targetRect.inflate(100);

    final DomImageBitmap bitmap = paintCanvas.transferToImageBitmap();

    final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    if (skImage == null) {
      throw Exception('Failed to convert text image bitmap to an SkImage.');
    }
    final ckImage = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
    canvas.drawImageRect(
      ckImage,
      shadowSourceRect,
      shadowTargetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  @override
  void drawTextCluster(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
    final DomImageBitmap bitmap = paintCanvas.transferToImageBitmap();

    final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    if (skImage == null) {
      throw Exception('Failed to convert text image bitmap to an SkImage.');
    }

    final ckImage = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
    canvas.drawImageRect(
      ckImage,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  @override
  void drawParagraph(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
    if (!hasSingleImageCache) {
      // We should have resized the small canvas before calling this method
      if (sourceRect.width != paintCanvas.width || sourceRect.height != paintCanvas.height) {
        WebParagraphDebug.error(
          '_resizePaintCanvas needed: '
          'canvas=${paintCanvas.width}x${paintCanvas.height} vs bounds=${sourceRect.width}x${sourceRect.height}',
        );
        assert(false);
      }

      SkImage? skImage;
      if (_domHtmlCanvasElement != null) {
        _domHtmlCanvasElement!.width = sourceRect.width;
        _domHtmlCanvasElement!.height = sourceRect.height;

        final context2D =
            _domHtmlCanvasElement!.getContext('2d', {'willReadFrequently': true})!
                as DomCanvasRenderingContext2D;
        context2D.drawImage(paintCanvas, 0, 0);

        final DomImageData imageData = context2D.getImageData(
          0,
          0,
          sourceRect.width.ceil(),
          sourceRect.height.ceil(),
        );

        final imageInfo = SkImageInfo(
          alphaType: canvasKit.AlphaType.Premul,
          colorType: canvasKit.ColorType.RGBA_8888,
          colorSpace: SkColorSpaceSRGB,
          width: sourceRect.width,
          height: sourceRect.height,
        );

        skImage = canvasKit.MakeImage(
          imageInfo,
          Uint8List.view(imageData.data.buffer),
          4 * sourceRect.width,
        );
      } else {
        // Transfer the buffer from the small canvas
        // This is synchronous and returns the handle immediately
        final DomImageBitmap bitmap = paintCanvas.transferToImageBitmap();
        skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
      }

      if (skImage == null) {
        throw Exception('Failed to convert text image bitmap to an SkImage.');
      }
      singleImageCache = CkImage(skImage);
    }

    canvas.drawImageRect(
      singleImageCache!,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  void drawParagraph1(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
    if (!hasSingleImageCache) {
      // We should have resized the small canvas before calling this method
      if (sourceRect.width != paintCanvas.width || sourceRect.height != paintCanvas.height) {
        WebParagraphDebug.error(
          '_resizePaintCanvas needed: '
          'canvas=${paintCanvas.width}x${paintCanvas.height} vs bounds=${sourceRect.width}x${sourceRect.height}',
        );
        assert(false);
      }
      // Transfer the buffer from the small canvas
      // This is synchronous and returns the handle immediately
      final DomImageBitmap bitmap = paintCanvas.transferToImageBitmap();

      final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
      if (skImage == null) {
        throw Exception('Failed to convert text image bitmap to an SkImage.');
      }
      singleImageCache = CkImage(skImage, imageSource: ImageBitmapImageSource(bitmap));
    }

    canvas.drawImageRect(
      singleImageCache!,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  @override
  void resetCache() {
    singleImageCache = null;
  }

  @override
  bool hasCache() {
    return singleImageCache != null;
  }
}
