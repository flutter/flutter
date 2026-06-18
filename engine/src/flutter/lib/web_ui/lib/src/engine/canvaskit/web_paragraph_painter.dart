// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../web_paragraph/painter.dart';
import 'canvaskit_api.dart';
import 'image.dart';

class CanvasKitPainter extends WebParagraphPainter {
  CanvasKitPainter(super.paragraph);

  CkImage? _singleImageCache;

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
      final SkImage? skImage = canvasKit.MakeImage(
        imageInfo,
        imageBytes,
        (4 * sourceRect.width).toInt(),
      );

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
}
