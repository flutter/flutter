// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_api.dart';
import '../canvaskit/image.dart';

typedef ParagraphImageGenerator = Uint8List Function();

/// Abstracts the interface for painting text clusters, shadows, and decorations.
abstract class Painter {
  bool get hasCache;

  double? _lastDevicePixelRatio;

  /// Draws the background directly on canvas
  void drawBackground(ui.Canvas canvas, ui.Rect rect, ui.Paint paint);

  void drawParagraph(
    ui.Canvas canvas,
    ui.Rect sourceRect,
    ui.Rect targetRect, {
    required ParagraphImageGenerator generateParagraphImage,
  });

  void clearCache();
}

class CanvasKitPainter extends Painter {
  CkImage? _singleImageCache;

  @override
  bool get hasCache => _singleImageCache != null;

  @override
  void drawBackground(ui.Canvas canvas, ui.Rect rect, ui.Paint paint) {
    // We need to snap the block edges because Skia draws rectangles with subpixel accuracy
    // and we end up with overlaps (this is only a problem when colors have transparency)
    // or gaps between blocks (which looks unacceptable - vertical lines between blocks).
    // Whether we snap to floor or ceil is irrelevant as long as we are consistent on both sides
    // (and will possibly have problems when glyph boundaries are outside of advance rectangles)
    final snappedRect = ui.Rect.fromLTRB(
      rect.left.roundToDouble(),
      rect.top.roundToDouble(),
      rect.right.roundToDouble(),
      rect.bottom.roundToDouble(),
    );
    canvas.drawRect(snappedRect, paint);
  }

  @override
  void drawParagraph(
    ui.Canvas canvas,
    ui.Rect sourceRect,
    ui.Rect targetRect, {
    required ParagraphImageGenerator generateParagraphImage,
  }) {
    final double dpr = ui.window.devicePixelRatio;
    if (_lastDevicePixelRatio != dpr) {
      // We need to clear the image cache whenever the device pixel ratio changes
      clearCache();
    }
    _lastDevicePixelRatio = dpr;

    if (!hasCache) {
      final imageInfo = SkImageInfo(
        alphaType: canvasKit.AlphaType.Unpremul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
        width: sourceRect.width,
        height: sourceRect.height,
      );
      final Uint8List imageBytes = generateParagraphImage();
      final SkImage? skImage = canvasKit.MakeImage(imageInfo, imageBytes, 4 * sourceRect.width);

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
  void clearCache() {
    _singleImageCache?.dispose();
    _singleImageCache = null;
  }
}
