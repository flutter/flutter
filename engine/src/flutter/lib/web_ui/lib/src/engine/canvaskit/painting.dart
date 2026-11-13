// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// The CanvasKit implementation of [BackendPaint].
///
/// Wraps an [SkPaint] built from an [EnginePaint] for a single draw call. The
/// [SkPaint] must be explicitly deleted by calling [dispose].
class CkPaint implements BackendPaint {
  CkPaint(EnginePaint paint, {required ui.TileMode defaultBlurTileMode}) : skiaObject = SkPaint() {
    final SkPaint skPaint = skiaObject;
    skPaint.setAntiAlias(paint.isAntiAlias);
    skPaint.setBlendMode(toSkBlendMode(paint.blendMode));
    skPaint.setStyle(toSkPaintStyle(paint.style));
    skPaint.setStrokeWidth(paint.strokeWidth);
    skPaint.setStrokeCap(toSkStrokeCap(paint.strokeCap));
    skPaint.setStrokeJoin(toSkStrokeJoin(paint.strokeJoin));
    skPaint.setColorInt(paint.colorValue);
    skPaint.setStrokeMiter(paint.strokeMiterLimit);

    final EngineColorFilter? colorFilter = paint.colorFilter;
    SkColorFilter? composedSkColorFilter;
    if (paint.invertColors) {
      final SkColorFilter invertSkColorFilter =
          (EngineColorFilter.invert.backendFilter as CkColorFilter).skiaObject;
      if (colorFilter != null) {
        composedSkColorFilter = canvasKit.ColorFilter.MakeCompose(
          invertSkColorFilter,
          (colorFilter.backendFilter as CkColorFilter).skiaObject,
        );
        skPaint.setColorFilter(composedSkColorFilter);
      } else {
        skPaint.setColorFilter(invertSkColorFilter);
      }
    } else if (colorFilter != null) {
      skPaint.setColorFilter((colorFilter.backendFilter as CkColorFilter).skiaObject);
    }

    final shader = paint.shader?.getBackendShader(paint.filterQuality) as CkShader?;
    if (shader != null) {
      skPaint.setShader(shader.skShader);
      if (shader.isGradient) {
        skPaint.setDither(true);
      }
    }

    final EngineMaskFilter? maskFilter = paint.effectiveMaskFilter;
    if (maskFilter != null) {
      final backendFilter = maskFilter.backendFilter as CkMaskFilter;
      skPaint.setMaskFilter(backendFilter.skiaObject);
    }

    final EngineImageFilter? imageFilter = paint.effectiveImageFilter;
    if (imageFilter != null) {
      final backendFilter =
          imageFilter.getBackendFilter(defaultBlurTileMode: defaultBlurTileMode) as CkImageFilter;
      final SkImageFilter? skImageFilter = backendFilter.nativeFilter;
      if (skImageFilter != null) {
        skPaint.setImageFilter(skImageFilter);
      }
    }

    // The SkPaint holds its own reference to the composed filter.
    if (composedSkColorFilter != null) {
      composedSkColorFilter.delete();
    }
  }

  /// The native CanvasKit paint.
  final SkPaint skiaObject;

  bool _isDisposed = false;

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      skiaObject.delete();
    }
  }
}
