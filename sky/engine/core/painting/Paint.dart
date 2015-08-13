// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

class Paint {
  void setColorFilter(ColorFilter colorFilter) {
    _colorFilter = colorFilter;
  }

  void setDrawLooper(DrawLooper drawLooper) {
    _drawLooper = drawLooper;
  }

  void setFilterQuality(FilterQuality filterQuality) {
    _filterQuality = filterQuality;
  }

  void setMaskFilter(MaskFilter maskFilter) {
    _maskFilter = maskFilter;
  }

  void setStyle(PaintingStyle style) {
    _style = style;
  }

  void setShader(Shader shader) {
    _shader = shader;
  }

  void setTransferMode(TransferMode transferMode) {
    _transferMode = transferMode;
  }

  double strokeWidth;
  bool isAntiAlias = true;
  Color color = const Color(0xFF000000);
  ColorFilter _colorFilter;
  DrawLooper _drawLooper;
  FilterQuality _filterQuality;
  MaskFilter _maskFilter;
  Shader _shader;
  PaintingStyle _style;
  TransferMode _transferMode;
  Typeface typeface;

  // Must match PaintFields enum in Paint.cpp.
  List<dynamic> get _value {
    return [
      strokeWidth,
      isAntiAlias,
      color,
      _colorFilter,
      _drawLooper,
      _filterQuality,
      _maskFilter,
      _shader,
      _style,
      _transferMode,
    ];
  }

  String toString() {
    String result = 'Paint(color:$color';
    if (_shader != null)
      result += ', shader: $_shader';
    if (_colorFilter != null)
      result += ', colorFilter: $_colorFilter';
    if (_maskFilter != null)
      result += ', maskFilter: $_maskFilter';
    // TODO(mpcomplete): Figure out how to show a drawLooper.
    if (_drawLooper != null)
      result += ', drawLooper:true';
    result += ')';
    return result;
  }
}
