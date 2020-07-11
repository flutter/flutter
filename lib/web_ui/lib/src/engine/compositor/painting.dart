// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// The implementation of [ui.Paint] used by the CanvasKit backend.
///
/// This class is backed by a Skia object that must be explicitly
/// deleted to avoid a memory leak. This is done by extending [SkiaObject].
class CkPaint extends ResurrectableSkiaObject implements ui.Paint {
  CkPaint();

  static const ui.Color _defaultPaintColor = ui.Color(0xFF000000);

  @override
  ui.BlendMode get blendMode => _blendMode;
  @override
  set blendMode(ui.BlendMode value) {
    if (_blendMode == value) {
      return;
    }
    _blendMode = value;
    _skPaint.setBlendMode(toSkBlendMode(value));
  }

  ui.BlendMode _blendMode = ui.BlendMode.srcOver;

  @override
  ui.PaintingStyle get style => _style;

  @override
  set style(ui.PaintingStyle value) {
    if (_style == value) {
      return;
    }
    _style = value;
    _skPaint.setStyle(toSkPaintStyle(value));
  }

  ui.PaintingStyle _style = ui.PaintingStyle.fill;

  @override
  double get strokeWidth => _strokeWidth;
  @override
  set strokeWidth(double value) {
    if (_strokeWidth == value) {
      return;
    }
    _strokeWidth = value;
    _skPaint.setStrokeWidth(value);
  }

  double _strokeWidth = 0.0;

  @override
  ui.StrokeCap get strokeCap => _strokeCap;
  @override
  set strokeCap(ui.StrokeCap value) {
    if (_strokeCap == value) {
      return;
    }
    _strokeCap = value;
    _skPaint.setStrokeCap(toSkStrokeCap(value));
  }

  ui.StrokeCap _strokeCap = ui.StrokeCap.butt;

  @override
  ui.StrokeJoin get strokeJoin => _strokeJoin;
  @override
  set strokeJoin(ui.StrokeJoin value) {
    if (_strokeJoin == value) {
      return;
    }
    _strokeJoin = value;
    _skPaint.setStrokeJoin(toSkStrokeJoin(value));
  }

  ui.StrokeJoin _strokeJoin = ui.StrokeJoin.miter;

  @override
  bool get isAntiAlias => _isAntiAlias;
  @override
  set isAntiAlias(bool value) {
    if (_isAntiAlias == value) {
      return;
    }
    _isAntiAlias = value;
    _skPaint.setAntiAlias(value);
  }

  bool _isAntiAlias = true;

  @override
  ui.Color get color => _color;
  @override
  set color(ui.Color value) {
    if (_color == value) {
      return;
    }
    _color = value;
    _skPaint.setColorInt(value.value);
  }

  ui.Color _color = _defaultPaintColor;

  // TODO(yjbanov): implement
  @override
  bool get invertColors => _invertColors;
  @override
  set invertColors(bool value) {
    _invertColors = value;
  }

  bool _invertColors = false;

  @override
  ui.Shader? get shader => _shader as ui.Shader?;
  @override
  set shader(ui.Shader? value) {
    if (_shader == value) {
      return;
    }
    _shader = value as EngineShader?;
    _skPaint.setShader(_shader?.createSkiaShader());
  }

  EngineShader? _shader;

  @override
  ui.MaskFilter? get maskFilter => _maskFilter;
  @override
  set maskFilter(ui.MaskFilter? value) {
    if (value == _maskFilter) {
      return;
    }
    _maskFilter = value;
    if (value != null) {
      _ckMaskFilter = CkMaskFilter.blur(
        value.webOnlyBlurStyle,
        value.webOnlySigma,
      );
    } else {
      _ckMaskFilter = null;
    }
    _skPaint.setMaskFilter(_ckMaskFilter?._skMaskFilter);
  }

  ui.MaskFilter? _maskFilter;
  CkMaskFilter? _ckMaskFilter;

  @override
  ui.FilterQuality get filterQuality => _filterQuality;
  @override
  set filterQuality(ui.FilterQuality value) {
    if (_filterQuality == value) {
      return;
    }
    _filterQuality = value;
    _skPaint.setFilterQuality(toSkFilterQuality(value));
  }

  ui.FilterQuality _filterQuality = ui.FilterQuality.none;

  @override
  ui.ColorFilter? get colorFilter => _colorFilter;
  @override
  set colorFilter(ui.ColorFilter? value) {
    if (_colorFilter == value) {
      return;
    }
    final EngineColorFilter? engineValue = value as EngineColorFilter?;
    _colorFilter = engineValue;
    _ckColorFilter = engineValue?._toCkColorFilter();
    _skPaint.setColorFilter(_ckColorFilter?._skColorFilter);
  }

  EngineColorFilter? _colorFilter;
  CkColorFilter? _ckColorFilter;

  @override
  double get strokeMiterLimit => _strokeMiterLimit;
  @override
  set strokeMiterLimit(double value) {
    if (_strokeMiterLimit == value) {
      return;
    }
    _strokeMiterLimit = value;
    _skPaint.setStrokeMiter(value);
  }

  double _strokeMiterLimit = 0.0;

  @override
  ui.ImageFilter? get imageFilter => _imageFilter;
  @override
  set imageFilter(ui.ImageFilter? value) {
    if (_imageFilter == value) {
      return;
    }
    _imageFilter = value as CkImageFilter?;
    _skPaint.setImageFilter(_imageFilter?._skImageFilter);
  }

  CkImageFilter? _imageFilter;

  late SkPaint _skPaint;

  @override
  js.JsObject createDefault() {
    _skPaint = SkPaint();
    _skPaint.setAntiAlias(_isAntiAlias);
    _skPaint.setColorInt(_color.value);
    return _jsObjectWrapper.wrapSkPaint(_skPaint);
  }

  @override
  js.JsObject resurrect() {
    _skPaint = SkPaint();
    _skPaint.setBlendMode(toSkBlendMode(_blendMode));
    _skPaint.setStyle(toSkPaintStyle(_style));
    _skPaint.setStrokeWidth(_strokeWidth);
    _skPaint.setAntiAlias(_isAntiAlias);
    _skPaint.setColorInt(_color.value);
    _skPaint.setShader(_shader?.createSkiaShader());
    _skPaint.setMaskFilter(_ckMaskFilter?._skMaskFilter);
    _skPaint.setColorFilter(_ckColorFilter?._skColorFilter);
    _skPaint.setImageFilter(_imageFilter?._skImageFilter);
    _skPaint.setFilterQuality(toSkFilterQuality(_filterQuality));
    return _jsObjectWrapper.wrapSkPaint(_skPaint);
  }
}
