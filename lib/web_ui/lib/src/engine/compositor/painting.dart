// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// The implementation of [ui.Paint] used by the CanvasKit backend.
///
/// This class is backed by a Skia object that must be explicitly
/// deleted to avoid a memory leak. This is done by extending [SkiaObject].
class SkPaint extends SkiaObject implements ui.Paint {
  SkPaint();

  static const ui.Color _defaultPaintColor = ui.Color(0xFF000000);
  static final js.JsObject _skPaintStyleStroke = canvasKit['PaintStyle']['Stroke'];
  static final js.JsObject _skPaintStyleFill = canvasKit['PaintStyle']['Fill'];

  @override
  ui.BlendMode get blendMode => _blendMode;
  @override
  set blendMode(ui.BlendMode value) {
    _blendMode = value;
    _syncBlendMode(skiaObject);
  }
  void _syncBlendMode(js.JsObject object) {
    final js.JsObject skBlendMode = makeSkBlendMode(_blendMode);
    object.callMethod('setBlendMode', <js.JsObject>[skBlendMode]);
  }
  ui.BlendMode _blendMode = ui.BlendMode.srcOver;

  @override
  ui.PaintingStyle get style => _style;

  @override
  set style(ui.PaintingStyle value) {
    _style = value;
    _syncStyle(skiaObject);
  }
  void _syncStyle(js.JsObject object) {
    js.JsObject skPaintStyle;
    switch (_style) {
      case ui.PaintingStyle.stroke:
        skPaintStyle = _skPaintStyleStroke;
        break;
      case ui.PaintingStyle.fill:
        skPaintStyle = _skPaintStyleFill;
        break;
    }
    object.callMethod('setStyle', <js.JsObject>[skPaintStyle]);
  }
  ui.PaintingStyle _style = ui.PaintingStyle.fill;

  @override
  double get strokeWidth => _strokeWidth;
  @override
  set strokeWidth(double value) {
    _strokeWidth = value;
    _syncStrokeWidth(skiaObject);
  }
  void _syncStrokeWidth(js.JsObject object) {
    object.callMethod('setStrokeWidth', <double>[strokeWidth]);
  }
  double _strokeWidth = 0.0;

  // TODO(yjbanov): implement
  @override
  ui.StrokeCap get strokeCap => _strokeCap;
  @override
  set strokeCap(ui.StrokeCap value) {
    _strokeCap = value;
  }
  ui.StrokeCap _strokeCap = ui.StrokeCap.butt;

  // TODO(yjbanov): implement
  @override
  ui.StrokeJoin get strokeJoin => _strokeJoin;
  @override
  set strokeJoin(ui.StrokeJoin value) {
    _strokeJoin = value;
  }
  ui.StrokeJoin _strokeJoin = ui.StrokeJoin.miter;

  @override
  bool get isAntiAlias => _isAntiAlias;
  @override
  set isAntiAlias(bool value) {
    _isAntiAlias = value;
    _syncAntiAlias(skiaObject);
  }
  void _syncAntiAlias(js.JsObject object) {
    object.callMethod('setAntiAlias', <bool>[_isAntiAlias]);
  }
  bool _isAntiAlias = true;

  @override
  ui.Color get color => _color;
  @override
  set color(ui.Color value) {
    _color = value;
    _syncColor(skiaObject);
  }
  void _syncColor(js.JsObject object) {
    int colorValue = _defaultPaintColor.value;
    if (_color != null) {
      colorValue = _color.value;
    }
    object.callMethod('setColor', <int>[colorValue]);
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
  ui.Shader get shader => _shader;
  @override
  set shader(ui.Shader value) {
    _shader = value;
    _syncShader(skiaObject);
  }
  void _syncShader(js.JsObject object) {
    js.JsObject skShader;
    if (_shader != null) {
      skShader = _shader.createSkiaShader();
    }
    object.callMethod('setShader', <js.JsObject>[skShader]);
  }
  EngineGradient _shader;

  @override
  ui.MaskFilter get maskFilter => _maskFilter;
  @override
  set maskFilter(ui.MaskFilter value) {
    _maskFilter = value;
    _syncMaskFilter(skiaObject);
  }
  void _syncMaskFilter(js.JsObject object) {
    js.JsObject skMaskFilter;
    if (_maskFilter != null) {
      final ui.BlurStyle blurStyle = _maskFilter.webOnlyBlurStyle;
      final double sigma = _maskFilter.webOnlySigma;

      js.JsObject skBlurStyle;
      switch (blurStyle) {
        case ui.BlurStyle.normal:
          skBlurStyle = canvasKit['BlurStyle']['Normal'];
          break;
        case ui.BlurStyle.solid:
          skBlurStyle = canvasKit['BlurStyle']['Solid'];
          break;
        case ui.BlurStyle.outer:
          skBlurStyle = canvasKit['BlurStyle']['Outer'];
          break;
        case ui.BlurStyle.inner:
          skBlurStyle = canvasKit['BlurStyle']['Inner'];
          break;
      }

      skMaskFilter = canvasKit
          .callMethod('MakeBlurMaskFilter', <dynamic>[skBlurStyle, sigma, true]);
    }
    object.callMethod('setMaskFilter', <js.JsObject>[skMaskFilter]);
  }
  ui.MaskFilter _maskFilter;

  // TODO(yjbanov): implement
  @override
  ui.FilterQuality get filterQuality => _filterQuality;
  @override
  set filterQuality(ui.FilterQuality value) {
    _filterQuality = value;
  }
  ui.FilterQuality _filterQuality = ui.FilterQuality.none;

  @override
  ui.ColorFilter get colorFilter => _colorFilter;
  @override
  set colorFilter(ui.ColorFilter value) {
    _colorFilter = value;
    _syncColorFilter(skiaObject);
  }
  void _syncColorFilter(js.JsObject object) {
    js.JsObject skColorFilterJs;
    if (_colorFilter != null) {
      SkColorFilter skFilter = _colorFilter._toSkColorFilter();
      skColorFilterJs = skFilter.skColorFilter;
    }
    object.callMethod('setColorFilter', <js.JsObject>[skColorFilterJs]);
  }
  EngineColorFilter _colorFilter;

  // TODO(yjbanov): implement
  @override
  double get strokeMiterLimit => _strokeMiterLimit;
  @override
  set strokeMiterLimit(double value) {
    _strokeMiterLimit = value;
  }
  double _strokeMiterLimit = 0.0;

  @override
  ui.ImageFilter get imageFilter => _imageFilter;
  @override
  set imageFilter(ui.ImageFilter value) {
    _imageFilter = value;
    _syncImageFilter(skiaObject);
  }
  void _syncImageFilter(js.JsObject object) {
    js.JsObject imageFilterJs;
    if (_imageFilter != null) {
      imageFilterJs = _imageFilter.skImageFilter;
    }
    object.callMethod('setImageFilter', <js.JsObject>[imageFilterJs]);
  }
  SkImageFilter _imageFilter;

  @override
  js.JsObject createDefault() {
    final obj = js.JsObject(canvasKit['SkPaint']);
    // Sync fields whose Skia defaults are different from Flutter's.
    _syncAntiAlias(obj);
    _syncColor(obj);
    return obj;
  }

  @override
  js.JsObject resurrect() {
    final obj = js.JsObject(canvasKit['SkPaint']);
    _syncBlendMode(obj);
    _syncStyle(obj);
    _syncStrokeWidth(obj);
    _syncAntiAlias(obj);
    _syncColor(obj);
    _syncShader(obj);
    _syncMaskFilter(obj);
    _syncColorFilter(obj);
    _syncImageFilter(obj);
    return obj;
  }
}
