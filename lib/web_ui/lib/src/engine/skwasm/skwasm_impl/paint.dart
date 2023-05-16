// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmPaint implements ui.Paint {
  factory SkwasmPaint() {
    return SkwasmPaint._fromHandle(paintCreate());
  }

  SkwasmPaint._fromHandle(this._handle);
  PaintHandle _handle;

  PaintHandle get handle => _handle;

  ui.BlendMode _cachedBlendMode = ui.BlendMode.srcOver;

  SkwasmShader? _shader;

  @override
  ui.BlendMode get blendMode {
    return _cachedBlendMode;
  }

  @override
  set blendMode(ui.BlendMode blendMode) {
    if (_cachedBlendMode != blendMode) {
      _cachedBlendMode = blendMode;
      paintSetBlendMode(_handle, blendMode.index);
    }
  }

  @override
  ui.PaintingStyle get style => ui.PaintingStyle.values[paintGetStyle(_handle)];

  @override
  set style(ui.PaintingStyle style) => paintSetStyle(_handle, style.index);

  @override
  double get strokeWidth => paintGetStrokeWidth(_handle);

  @override
  set strokeWidth(double width) => paintSetStrokeWidth(_handle, width);

  @override
  ui.StrokeCap get strokeCap => ui.StrokeCap.values[paintGetStrokeCap(_handle)];

  @override
  set strokeCap(ui.StrokeCap cap) => paintSetStrokeCap(_handle, cap.index);

  @override
  ui.StrokeJoin get strokeJoin => ui.StrokeJoin.values[paintGetStrokeJoin(_handle)];

  @override
  set strokeJoin(ui.StrokeJoin join) => paintSetStrokeJoin(_handle, join.index);

  @override
  bool get isAntiAlias => paintGetAntiAlias(_handle);

  @override
  set isAntiAlias(bool value) => paintSetAntiAlias(_handle, value);

  @override
  ui.Color get color => ui.Color(paintGetColorInt(_handle));

  @override
  set color(ui.Color color) => paintSetColorInt(_handle, color.value);

  @override
  double get strokeMiterLimit => paintGetMiterLimit(_handle);

  @override
  set strokeMiterLimit(double limit) => paintSetMiterLimit(_handle, limit);

  @override
  ui.Shader? get shader => _shader;

  @override
  set shader(ui.Shader? uiShader) {
    final SkwasmShader? skwasmShader = uiShader as SkwasmShader?;
    _shader = skwasmShader;
    final ShaderHandle shaderHandle =
      skwasmShader != null ? skwasmShader.handle : nullptr;
    paintSetShader(_handle, shaderHandle);
  }

  @override
  ui.FilterQuality filterQuality = ui.FilterQuality.none;

  // Unimplemented stuff below
  @override
  ui.ColorFilter? colorFilter;

  @override
  ui.ImageFilter? imageFilter;

  @override
  bool invertColors = false;

  @override
  ui.MaskFilter? maskFilter;
}
