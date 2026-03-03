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
    // TODO(jlavrova): we need to investigate different approaches to resizing the canvas.
    // 1. Do we resize to 0, 0 at the end of each paint so we do not hold on to large buffers?
    // 2. Do we keep the canvas around (even big ones) and only resize when needed?
    // 3. Do we have a max size and reuse the canvas up to that size?
    if (currentDevicePixelRatio == devicePixelRatio &&
        paintCanvas.width == (width * devicePixelRatio).ceilToDouble() &&
        paintCanvas.height == (height * devicePixelRatio).ceilToDouble()) {
      // We need to resize canvas whenever the requested size changes
      return;
    }

    if (currentDevicePixelRatio != devicePixelRatio) {
      // We need to reset the scale transform whenever the device pixel ratio changes
      resetCache();
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

    if (WebParagraphDebug.logging) {
      WebParagraphDebug.log(
        'resizePaintCanvas: ${paintCanvas.width}x${paintCanvas.height} @ $devicePixelRatio',
      );
    }
  }
}

class CanvasKitPainter extends Painter {
  CkImage? _singleImageCache;

  @override
  bool get hasSingleImageCache => _singleImageCache != null;

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
    throw UnimplementedError('Decoration drawing is not implemented yet');
  }

  @override
  void drawShadowCluster(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
    throw UnimplementedError('Shadow drawing is not implemented yet');
  }

  @override
  void drawTextCluster(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
    throw UnimplementedError('Text cluster drawing is not implemented yet');
  }

  @override
  void drawParagraph(ui.Canvas canvas, ui.Rect sourceRect, ui.Rect targetRect) {
    if (!hasSingleImageCache) {
      // We should have resized the small canvas before calling this method
      if (sourceRect.width != paintCanvas.width || sourceRect.height != paintCanvas.height) {
        assert(
          false,
          'resizePaintCanvas needed: '
          'canvas=${paintCanvas.width}x${paintCanvas.height} vs bounds=${sourceRect.width}x${sourceRect.height}',
        );
      }

      final DomImageData imageData = paintContext.getImageData(
        0,
        0,
        sourceRect.width.ceil(),
        sourceRect.height.ceil(),
      );

      final imageInfo = SkImageInfo(
        alphaType: canvasKit.AlphaType.Unpremul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
        width: sourceRect.width,
        height: sourceRect.height,
      );
      final SkImage? skImage = canvasKit.MakeImage(
        imageInfo,
        Uint8List.view(imageData.data.buffer),
        4 * sourceRect.width,
      );

      // Transfer the buffer from the small canvas
      // This is synchronous and returns the handle immediately
      //final DomImageBitmap bitmap = paintCanvas.transferToImageBitmap();
      //final SkImage? skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);

      if (skImage == null) {
        throw Exception('Failed to convert text image bitmap to an SkImage.');
      }
      _singleImageCache = CkImage(skImage);
    }

    canvas.drawImageRect(
      _singleImageCache!,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  @override
  void resetCache() {
    if (_singleImageCache != null) {
      _singleImageCache!.dispose();
      _singleImageCache = null;
    }
  }

  @override
  bool hasCache() {
    return _singleImageCache != null;
  }
}
