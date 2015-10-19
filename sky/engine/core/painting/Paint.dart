// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

class Paint {
  double strokeWidth;
  bool isAntiAlias = true;
  Color color = const Color(0xFF000000);
  ColorFilter colorFilter;
  DrawLooper drawLooper;
  FilterQuality filterQuality;
  MaskFilter maskFilter;
  Shader shader;
  PaintingStyle style;
  TransferMode transferMode;

  // Must match PaintFields enum in Paint.cpp.
  List<dynamic> get _value {
    return [
      strokeWidth,
      isAntiAlias,
      color,
      colorFilter,
      drawLooper,
      filterQuality,
      maskFilter,
      shader,
      style,
      transferMode,
    ];
  }

  String toString() {
    String result = 'Paint(color:$color';
    if (shader != null)
      result += ', shader: $shader';
    if (colorFilter != null)
      result += ', colorFilter: $colorFilter';
    if (maskFilter != null)
      result += ', maskFilter: $maskFilter';
    // TODO(mpcomplete): Figure out how to show a drawLooper.
    if (drawLooper != null)
      result += ', drawLooper:true';
    result += ')';
    return result;
  }
}
