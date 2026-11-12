// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// The implementation of [ui.Paint] shared by all renderers.
///
/// This class only holds Dart-side state. A native paint is created from it
/// for each draw call using [createBackendPaint].
class EnginePaint implements ui.Paint {
  EnginePaint();

  // Must be kept in sync with the default in paint.cc.
  static const ui.BlendMode _kBlendModeDefault = ui.BlendMode.srcOver;

  // Must be kept in sync with the default in paint.cc.
  static const int _kColorDefault = 0xFF000000;

  // Must be kept in sync with the default in paint.cc.
  static const double _kStrokeMiterLimitDefault = 4.0;

  /// Creates a new native paint for this paint's current state.
  ///
  /// The caller owns the returned [BackendPaint] and must call
  /// [BackendPaint.dispose] after the draw call that uses it.
  ///
  /// [defaultBlurTileMode] is the tile mode used by a blur [imageFilter] that
  /// doesn't specify one.
  BackendPaint createBackendPaint({ui.TileMode defaultBlurTileMode = ui.TileMode.decal}) =>
      renderer.createPaint(this, defaultBlurTileMode: defaultBlurTileMode);

  @override
  ui.BlendMode blendMode = _kBlendModeDefault;

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

  int _colorValue = _kColorDefault;

  /// The color of this paint as an ARGB integer.
  int get colorValue => _colorValue;

  @override
  bool invertColors = false;

  @override
  EngineShader? get shader => _shader;
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

  /// The mask filter to apply when drawing with this paint.
  ///
  /// Null unless `webOnlySigma.isFinite && webOnlySigma > 0`. Skia cannot
  /// create a blur mask filter for any other sigma, so the shape is drawn
  /// without a mask filter instead.
  EngineMaskFilter? get effectiveMaskFilter {
    final localMaskFilter = maskFilter as EngineMaskFilter?;
    if (localMaskFilter == null) {
      return null;
    }
    final double sigma = localMaskFilter.webOnlySigma;
    if (sigma.isFinite && sigma > 0) {
      return localMaskFilter;
    }
    return null;
  }

  @override
  ui.FilterQuality filterQuality = ui.FilterQuality.none;

  @override
  EngineColorFilter? get colorFilter => _colorFilter;
  @override
  set colorFilter(ui.ColorFilter? value) {
    if (_colorFilter == value) {
      return;
    }
    _colorFilter = value as EngineColorFilter?;
  }

  EngineColorFilter? _colorFilter;

  @override
  double strokeMiterLimit = _kStrokeMiterLimitDefault;

  @override
  ui.ImageFilter? get imageFilter => _imageFilter;
  @override
  set imageFilter(ui.ImageFilter? value) {
    if (_imageFilter == value) {
      return;
    }
    _imageFilter = value;
    if (value == null) {
      _effectiveImageFilter = null;
    } else if (value is ui.ColorFilter) {
      _effectiveImageFilter = EngineColorFilterImageFilter(colorFilter: value as EngineColorFilter);
    } else {
      _effectiveImageFilter = value as EngineImageFilter;
    }
  }

  /// The image filter exactly as it was set.
  ui.ImageFilter? _imageFilter;

  /// The [EngineImageFilter] computed from [_imageFilter], cached so that
  /// repeated draws don't create new wrappers.
  EngineImageFilter? _effectiveImageFilter;

  /// The image filter to apply when drawing with this paint.
  ///
  /// Wraps a [ui.ColorFilter] in [EngineColorFilterImageFilter]; otherwise
  /// casts to [EngineImageFilter].
  EngineImageFilter? get effectiveImageFilter => _effectiveImageFilter;

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
      if (blendMode.index != _kBlendModeDefault.index) {
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
