// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// The implementation of [ui.Paint] used by the CanvasKit backend.
///
/// This class is backed by a Skia object that must be explicitly
/// deleted to avoid a memory leak. This is done by extending [SkiaObject].
class CkPaint extends ManagedSkiaObject<SkPaint> implements ui.Paint {
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
    skiaObject.setBlendMode(toSkBlendMode(value));
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
    skiaObject.setStyle(toSkPaintStyle(value));
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
    skiaObject.setStrokeWidth(value);
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
    skiaObject.setStrokeCap(toSkStrokeCap(value));
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
    skiaObject.setStrokeJoin(toSkStrokeJoin(value));
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
    skiaObject.setAntiAlias(value);
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
    skiaObject.setColorInt(value.value);
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
  ui.Shader? get shader => _shader;
  @override
  set shader(ui.Shader? value) {
    if (_shader == value) {
      return;
    }
    _shader = value as CkShader?;
    skiaObject.setShader(_shader?.skiaObject);
  }

  CkShader? _shader;

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
    skiaObject.setMaskFilter(_ckMaskFilter?.skiaObject);
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
    skiaObject.setFilterQuality(toSkFilterQuality(value));
  }

  ui.FilterQuality _filterQuality = ui.FilterQuality.none;

  @override
  ui.ColorFilter? get colorFilter => _managedColorFilter?.ckColorFilter;
  @override
  set colorFilter(ui.ColorFilter? value) {
    if (colorFilter == value) {
      return;
    }

    if (value == null) {
      _managedColorFilter = null;
    } else {
      _managedColorFilter = _ManagedSkColorFilter(value as CkColorFilter);
    }
    skiaObject.setColorFilter(_managedColorFilter?.skiaObject);
  }

  _ManagedSkColorFilter? _managedColorFilter;

  @override
  double get strokeMiterLimit => _strokeMiterLimit;
  @override
  set strokeMiterLimit(double value) {
    if (_strokeMiterLimit == value) {
      return;
    }
    _strokeMiterLimit = value;
    skiaObject.setStrokeMiter(value);
  }

  double _strokeMiterLimit = 0.0;

  @override
  ui.ImageFilter? get imageFilter => _imageFilter;
  @override
  set imageFilter(ui.ImageFilter? value) {
    if (_imageFilter == value) {
      return;
    }

    _imageFilter = value as _CkManagedSkImageFilterConvertible?;
    _managedImageFilter = _imageFilter?._imageFilter;
    skiaObject.setImageFilter(_managedImageFilter?.skiaObject);
  }

  _CkManagedSkImageFilterConvertible? _imageFilter;
  ManagedSkiaObject<SkImageFilter>? _managedImageFilter;

  @override
  SkPaint createDefault() {
    final SkPaint paint = SkPaint();
    paint.setAntiAlias(_isAntiAlias);
    paint.setColorInt(_color.value);
    return paint;
  }

  @override
  SkPaint resurrect() {
    final SkPaint paint = SkPaint();
    paint.setBlendMode(toSkBlendMode(_blendMode));
    paint.setStyle(toSkPaintStyle(_style));
    paint.setStrokeWidth(_strokeWidth);
    paint.setAntiAlias(_isAntiAlias);
    paint.setColorInt(_color.value);
    paint.setShader(_shader?.skiaObject);
    paint.setMaskFilter(_ckMaskFilter?.skiaObject);
    paint.setColorFilter(_managedColorFilter?.skiaObject);
    paint.setImageFilter(_managedImageFilter?.skiaObject);
    paint.setFilterQuality(toSkFilterQuality(_filterQuality));
    paint.setStrokeCap(toSkStrokeCap(_strokeCap));
    paint.setStrokeJoin(toSkStrokeJoin(_strokeJoin));
    paint.setStrokeMiter(_strokeMiterLimit);
    return paint;
  }

  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}
