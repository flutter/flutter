// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Styles to use for line endings.
///
/// See [Paint.strokeCap].
enum StrokeCap {
  /// Begin and end contours with a flat edge and no extension.
  butt,

  /// Begin and end contours with a semi-circle extension.
  round,

  /// Begin and end contours with a half square extension. This is
  /// similar to extending each contour by half the stroke width (as
  /// given by [Paint.strokeWidth]).
  square,
}

/// A description of the style to use when drawing on a [Canvas].
///
/// Most APIs on [Canvas] take a [Paint] object to describe the style
/// to use for that operation.
class Paint {
  /// Whether to paint inside shapes, the edges of shapes, or both.
  ///
  /// If null, defaults to [PaintingStyle.fill].
  PaintingStyle style;

  /// How wide to make edges drawn when [style] is set to
  /// [PaintingStyle.stroke] or [PaintingStyle.strokeAndFill]. The
  /// width is given in logical pixels measured in the direction
  /// orthogonal to the direction of the path.
  ///
  /// The values null and 0.0 correspond to a hairline width.
  double strokeWidth;

  /// The kind of finish to place on the end of lines drawn when
  /// [style] is set to [PaintingStyle.stroke] or
  /// [PaintingStyle.strokeAndFill].
  ///
  /// If null, defaults to [StrokeCap.butt], i.e. no caps.
  StrokeCap strokeCap;

  /// Whether to apply anti-aliasing to lines and images drawn on the
  /// canvas.
  ///
  /// Defaults to true. The value null is treated as false.
  bool isAntiAlias = true;

  Color color = _kDefaultPaintColor;
  static const Color _kDefaultPaintColor = const Color(0xFF000000);

  TransferMode transferMode;

  ColorFilter colorFilter;

  MaskFilter maskFilter;

  FilterQuality filterQuality;

  Shader shader;

  // Must match PaintFields enum in Paint.cpp.
  dynamic get _value {
    // The most common usage is a Paint with no options besides a color and
    // anti-aliasing.  In this case, save time by just returning the color
    // as an int.
    if ((style == null || style == PaintingStyle.fill) &&
        (strokeWidth == null || strokeWidth == 0.0) &&
        (strokeCap == null || strokeCap == StrokeCap.butt) &&
        isAntiAlias &&
        color != null &&
        transferMode == null &&
        colorFilter == null &&
        maskFilter == null &&
        filterQuality == null &&
        shader == null) {
      return color.value;
    }

    return <dynamic>[
      style?.index,
      strokeWidth,
      strokeCap?.index,
      isAntiAlias,
      color.value,
      transferMode?.index,
      colorFilter,
      maskFilter,
      filterQuality?.index,
      shader,
    ];
  }

  String toString() {
    StringBuffer result = new StringBuffer();
    String semicolon = '';
    result.write('Paint(');
    if (style == PaintingStyle.stroke || style == PaintingStyle.strokeAndFill) {
      result.write('$style');
      if (strokeWidth != null && strokeWidth != 0.0)
        result.write(' $strokeWidth');
      else
        result.write(' hairline');
      if (strokeCap != null && strokeCap != StrokeCap.butt)
        result.write(' $strokeCap');
      semicolon = '; ';
    }
    if (isAntiAlias != true) {
      result.write('${semicolon}antialias off');
      semicolon = '; ';
    }
    if (color != _kDefaultPaintColor) {
      if (color != null)
        result.write('$semicolon$color');
      else
        result.write('${semicolon}no color');
      semicolon = '; ';
    }
    if (transferMode != null) {
      result.write('$semicolon$transferMode');
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
    if (filterQuality != null) {
      result.write('${semicolon}filterQuality: $filterQuality');
      semicolon = '; ';
    }
    if (shader != null)
      result.write('${semicolon}shader: $shader');
    result.write(')');
    return result.toString();
  }
}
