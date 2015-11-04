// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

enum StrokeCap {
  /// Begin/end contours with no extension.
  butt,

  /// Begin/end contours with a semi-circle extension.
  round,

  /// Begin/end contours with a half square extension.
  square,
}

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
  StrokeCap strokeCap;

  // Must match PaintFields enum in Paint.cpp.
  dynamic get _value {
    // The most common usage is a Paint with no options besides a color and
    // anti-aliasing.  In this case, save time by just returning the color
    // as an int.
    if (strokeWidth == null &&
        isAntiAlias &&
        colorFilter == null &&
        drawLooper == null &&
        filterQuality == null &&
        maskFilter == null &&
        shader == null &&
        style == null &&
        transferMode == null &&
        strokeCap == null) {
      return color.value;
    }

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
      strokeCap,
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
