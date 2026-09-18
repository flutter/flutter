// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// The implementation of [ui.Paint] used by the CanvasKit backend.
///
/// This class is backed by a Skia object that must be explicitly
/// deleted to avoid a memory leak. This is done by extending [SkiaObject].
// TODO(154281): try to unify with SkwasmPaint
class CkPaint implements ui.Paint {
  CkPaint();

  /// Creates a new [SkPaint] object and returns it.
  ///
  /// The caller is responsible for deleting the returned object when it's no
  /// longer needed.
  SkPaint toSkPaint({ui.TileMode defaultBlurTileMode = ui.TileMode.decal}) {
    final skPaint = SkPaint();
    skPaint.setAntiAlias(isAntiAlias);
    skPaint.setBlendMode(toSkBlendMode(blendMode));
    skPaint.setStyle(toSkPaintStyle(style));
    skPaint.setStrokeWidth(strokeWidth);
    skPaint.setStrokeCap(toSkStrokeCap(strokeCap));
    skPaint.setStrokeJoin(toSkStrokeJoin(strokeJoin));
    skPaint.setColorInt(_colorValue);
    skPaint.setStrokeMiter(strokeMiterLimit);

    final EngineColorFilter? colorFilter = _engineColorFilter;
    SkColorFilter? composedSkColorFilter;
    if (invertColors) {
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

    final shader = _shader?.getBackendShader(filterQuality) as CkShader?;
    if (shader != null) {
      skPaint.setShader(shader.skShader);
      if (shader.isGradient) {
        skPaint.setDither(true);
      }
    }

    final localMaskFilter = maskFilter as EngineMaskFilter?;
    if (localMaskFilter != null) {
      // CanvasKit returns `null` if the sigma is `0` or infinite.
      if (localMaskFilter.webOnlySigma.isFinite && localMaskFilter.webOnlySigma > 0) {
        final backendFilter = localMaskFilter.backendFilter as CkMaskFilter;
        skPaint.setMaskFilter(backendFilter.skiaObject);
      }
    }

    final EngineImageFilter? localImageFilter = _imageFilter;
    if (localImageFilter != null) {
      final backendFilter = localImageFilter.getBackendFilter(
        defaultBlurTileMode: defaultBlurTileMode,
      ) as CkImageFilter;
      final SkImageFilter? skImageFilter = backendFilter.nativeFilter;
      if (skImageFilter != null) {
        skPaint.setImageFilter(skImageFilter);
      }
    }

    if (composedSkColorFilter != null) {
      composedSkColorFilter.delete();
    }

    return skPaint;
  }

  @override
  ui.BlendMode blendMode = ui.BlendMode.srcOver;

  @override
  ui.PaintingStyle style = ui.PaintingStyle.fill;

  @override
  double strokeWidth = 0.0;

  @override
  ui.StrokeCap strokeCap = ui.StrokeCap.butt;

  @override
  ui.StrokeJoin strokeJoin = ui.StrokeJoin.miter;

  @override
  bool isAntiAlias = true;

  @override
  ui.Color get color => ui.Color(_colorValue);
  @override
  set color(ui.Color value) {
    _colorValue = value.value;
  }

  static const int _defaultPaintColorValue = 0xFF000000;
  int _colorValue = _defaultPaintColorValue;

  @override
  bool get invertColors => _invertColors;
  @override
  set invertColors(bool value) {
    _invertColors = value;
  }

  bool _invertColors = false;

  @override
  ui.Shader? get shader => _shader;
  @override
  set shader(ui.Shader? value) {
    if (_shader == value) {
      return;
    }
    _shader = value as EngineShader?;
  }

  EngineShader? _shader;

  @override
  ui.MaskFilter? maskFilter;

  @override
  ui.FilterQuality filterQuality = ui.FilterQuality.none;

  @override
  ui.ColorFilter? get colorFilter => _engineColorFilter;

  @override
  set colorFilter(ui.ColorFilter? value) {
    _engineColorFilter = value as EngineColorFilter?;
  }

  /// The original color filter objects passed by the framework.
  EngineColorFilter? _engineColorFilter;

  @override
  double strokeMiterLimit = 4.0;

  @override
  ui.ImageFilter? get imageFilter => _imageFilter;
  @override
  set imageFilter(ui.ImageFilter? value) {
    if (_imageFilter == value) {
      return;
    }

    if (value is ui.ColorFilter) {
      _imageFilter = EngineColorFilterImageFilter(colorFilter: value as EngineColorFilter);
    } else {
      _imageFilter = value as EngineImageFilter?;
    }
  }

  EngineImageFilter? _imageFilter;

  // Must be kept in sync with the default in paint.cc.
  static const double _kStrokeMiterLimitDefault = 4.0;

  // Must be kept in sync with the default in paint.cc.
  static const int _kColorDefault = 0xFF000000;

  // Must be kept in sync with the default in paint.cc.
  static final int _kBlendModeDefault = ui.BlendMode.srcOver.index;

  @override
  String toString() {
    var resultString = 'Paint()';

    assert(() {
      final result = StringBuffer();
      var semicolon = '';
      result.write('Paint(');
      if (style == ui.PaintingStyle.stroke) {
        result.write('$style');
        if (strokeWidth != 0.0) {
          result.write(' ${strokeWidth.toStringAsFixed(1)}');
        } else {
          result.write(' hairline');
        }
        if (strokeCap != ui.StrokeCap.butt) {
          result.write(' $strokeCap');
        }
        if (strokeJoin == ui.StrokeJoin.miter) {
          if (strokeMiterLimit != _kStrokeMiterLimitDefault) {
            result.write(' $strokeJoin up to ${strokeMiterLimit.toStringAsFixed(1)}');
          }
        } else {
          result.write(' $strokeJoin');
        }
        semicolon = '; ';
      }
      if (!isAntiAlias) {
        result.write('${semicolon}antialias off');
        semicolon = '; ';
      }
      if (color != const ui.Color(_kColorDefault)) {
        result.write('$semicolon$color');
        semicolon = '; ';
      }
      if (blendMode.index != _kBlendModeDefault) {
        result.write('$semicolon$blendMode');
        semicolon = '; ';
      }
      if (colorFilter != null) {
        result.write('${semicolon}colorFilter: $colorFilter');
        semicolon = '; ';
      }
      if (maskFilter != null) {
        result.write('${semicolon}maskFilter: $maskFilter');
        semicolon = '; ';
      }
      if (filterQuality != ui.FilterQuality.none) {
        result.write('${semicolon}filterQuality: $filterQuality');
        semicolon = '; ';
      }
      if (shader != null) {
        result.write('${semicolon}shader: $shader');
        semicolon = '; ';
      }
      if (imageFilter != null) {
        result.write('${semicolon}imageFilter: $imageFilter');
        semicolon = '; ';
      }
      if (invertColors) {
        result.write('${semicolon}invert: $invertColors');
      }
      result.write(')');
      resultString = result.toString();
      return true;
    }());

    return resultString;
  }
}
