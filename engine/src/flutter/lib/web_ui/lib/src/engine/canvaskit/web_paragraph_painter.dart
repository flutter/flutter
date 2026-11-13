// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../primitives/image.dart';
import '../web_paragraph/painter.dart';
import 'canvaskit_api.dart';
import 'image.dart';

/// Represents a cached rasterized paragraph image along with the effective scale
/// (combining device pixel ratio and canvas matrix scale) it was rendered at.
class _ParagraphCacheEntry {
  _ParagraphCacheEntry({
    required this.image,
    required this.effectiveScaleX,
    required this.effectiveScaleY,
  });

  static const double _scaleEpsilon = 0.001;

  final EngineImage image;
  final double effectiveScaleX;
  final double effectiveScaleY;

  /// Checks if the cached image scale matches the requested effective scales within [_scaleEpsilon].
  bool matchesScale({required double effectiveScaleX, required double effectiveScaleY}) {
    return (this.effectiveScaleX - effectiveScaleX).abs() < _scaleEpsilon &&
        (this.effectiveScaleY - effectiveScaleY).abs() < _scaleEpsilon;
  }
}

class CanvasKitPainter extends WebParagraphPainter {
  CanvasKitPainter(super.paragraph);

  _ParagraphCacheEntry? _cacheEntry;

  /// For a specific paragraph, how many times it was rasterized in the current test
  @override
  @visibleForTesting
  int debugRasterizeCount = 0;

  @override
  bool get hasCache => _cacheEntry != null;

  @override
  void clearCache() {
    _cacheEntry?.image.dispose();
    _cacheEntry = null;
  }

  @override
  void paintParagraphText(
    ui.Canvas canvas,
    ui.Rect sourceRect,
    ui.Rect targetRect, {
    required ParagraphImageGenerator generateParagraphImage,
    required double effectiveScaleX,
    required double effectiveScaleY,
  }) {
    final _ParagraphCacheEntry? cacheEntry = _cacheEntry;
    if (cacheEntry != null &&
        !cacheEntry.matchesScale(
          effectiveScaleX: effectiveScaleX,
          effectiveScaleY: effectiveScaleY,
        )) {
      clearCache();
    }

    if (!hasCache) {
      assert(() {
        debugRasterizeCount++;
        return true;
      }());
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
      _cacheEntry = _ParagraphCacheEntry(
        image: EngineImage(
          CkImageDelegate(skImage),
          skImage.width().toInt(),
          skImage.height().toInt(),
        ),
        effectiveScaleX: effectiveScaleX,
        effectiveScaleY: effectiveScaleY,
      );
    }

    canvas.drawImageRect(
      _cacheEntry!.image,
      sourceRect,
      targetRect,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }
}
