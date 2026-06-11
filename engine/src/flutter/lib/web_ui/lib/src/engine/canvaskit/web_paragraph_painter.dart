// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../primitives/image.dart';
import '../web_paragraph/painter.dart';
import 'canvaskit_api.dart';
import 'image.dart';

class CanvasKitPainter extends WebParagraphPainter {
  CanvasKitPainter(super.paragraph);

  EngineImage? _singleImageCache;

  @override
  bool get hasCache => _singleImageCache != null;

  @override
  void clearCache() {
    _singleImageCache?.dispose();
    _singleImageCache = null;
  }

  double? _lastDevicePixelRatio;

  @override
  void paintParagraphText(
    ui.Canvas canvas,
    ui.Rect sourceRect,
    ui.Rect targetRect, {
    required ParagraphImageGenerator generateParagraphImage,
  }) {
    // Obtain the current device pixel ratio (DPR).
    final double dpr = ui.window.devicePixelRatio;
    if (_lastDevicePixelRatio != dpr) {
      // Clear the image cache whenever the device pixel ratio changes to ensure
      // the cached text is rendered sharply at the new pixel density.
      clearCache();
    }
    _lastDevicePixelRatio = dpr;

    // Generate and cache the paragraph's raster image representation if not already present.
    if (!hasCache) {
      // Define the target pixel layout, specifying unpremultiplied alpha,
      // RGBA 8888 color representation, and sRGB color space.
      final imageInfo = SkImageInfo(
        alphaType: canvasKit.AlphaType.Unpremul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
        width: sourceRect.width,
        height: sourceRect.height,
      );
      // Run the image generator callback to draw the HTML text to a pixel buffer.
      final Uint8List imageBytes = generateParagraphImage();
      // Instantiate a CanvasKit SkImage from the generated raw byte buffer.
      final SkImage? skImage = canvasKit.MakeImage(
        imageInfo,
        imageBytes,
        (4 * sourceRect.width).toInt(),
      );

      if (skImage == null) {
        throw Exception('Failed to convert text image bitmap to an SkImage.');
      }
      // Wrap the SkImage inside an EngineImage for caching.
      _singleImageCache = EngineImage(
        CkImageDelegate(skImage),
        skImage.width().toInt(),
        skImage.height().toInt(),
      );
    }

    // Paint the cached text image on the destination canvas with standard point filtering.
    canvas.drawImageRect(
      _singleImageCache!,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }
}
