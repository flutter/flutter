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
  static const PaintingStyle _kDefaultStyle = PaintingStyle.fill;

  /// How wide to make edges drawn when [style] is set to
  /// [PaintingStyle.stroke] or [PaintingStyle.strokeAndFill]. The
  /// width is given in logical pixels measured in the direction
  /// orthogonal to the direction of the path.
  ///
  /// The values null and 0.0 correspond to a hairline width.
  double strokeWidth;
  static const double _kDefaultStrokeWidth = 0.0;

  /// The kind of finish to place on the end of lines drawn when
  /// [style] is set to [PaintingStyle.stroke] or
  /// [PaintingStyle.strokeAndFill].
  ///
  /// If null, defaults to [StrokeCap.butt], i.e. no caps.
  StrokeCap strokeCap;
  static const StrokeCap _kDefaultStrokeCap = StrokeCap.butt;

  /// Whether to apply anti-aliasing to lines and images drawn on the
  /// canvas.
  ///
  /// Defaults to true. The value null is treated as false.
  bool isAntiAlias = true;

  /// The color to use when stroking or filling a shape.
  ///
  /// Defaults to black.
  ///
  /// See also:
  ///
  ///  * [style], which controls whether to stroke or fill (or both).
  ///  * [colorFilter], which overrides [color].
  ///  * [shader], which overrides [color] with more elaborate effects.
  ///
  /// This color is not used when compositing. To colorize a layer, use
  /// [colorFilter].
  Color color = _kDefaultPaintColor;
  static const Color _kDefaultPaintColor = const Color(0xFF000000);

  /// A mask filter (for example, a blur) to apply to a shape after it has been
  /// drawn but before it has been composited into the image.
  ///
  /// See [MaskFilter] for details.
  MaskFilter maskFilter;

  /// Controls the performance vs quality trade-off to use when applying
  /// filters, such as [maskFilter], or when drawing images, as with
  /// [Canvas.drawImageRect] or [Canvas.drawImageNine].
  // TODO(ianh): verify that the image drawing methods actually respect this
  FilterQuality filterQuality;

  /// The shader to use when stroking or filling a shape.
  ///
  /// When this is null, the [color] is used instead.
  ///
  /// See also:
  ///
  ///  * [Gradient], a shader that paints a color gradient.
  ///  * [ImageShader], a shader that tiles an [Image].
  ///  * [colorFilter], which overrides [shader].
  ///  * [color], which is used if [shader] and [colorFilter] are null.
  Shader shader;

  /// A color filter to apply when a shape is drawn or when a layer is
  /// composited.
  ///
  /// See [ColorFilter] for details.
  ///
  /// When a shape is being drawn, [colorFilter] overrides [color] and [shader].
  ColorFilter colorFilter;

  /// A transfer mode to apply when a shape is drawn or a layer is composited.
  ///
  /// The source colors are from the shape being drawn (e.g. from
  /// [Canvas.drawPath]) or layer being composited (the graphics that were drawn
  /// between the [Canvas.saveLayer] and [Canvas.restore] calls), after applying
  /// the [colorFilter], if any.
  ///
  /// The destination colors are from the background onto which the shape or
  /// layer is being composited.
  ///
  /// If null, defaults to [TransferMode.srcOver].
  TransferMode transferMode;
  static const TransferMode _kDefaultTransferMode = TransferMode.srcOver;


  // Must match PaintFields enum in Paint.cpp.
  dynamic get _value {
    // The most common usage is a Paint with no options besides a color and
    // anti-aliasing.  In this case, save time by just returning the color
    // as an int.
    if ((style == null || style == _kDefaultStyle) &&
        (strokeWidth == null || strokeWidth == _kDefaultStrokeWidth) &&
        (strokeCap == null || strokeCap == _kDefaultStrokeCap) &&
        isAntiAlias &&
        color != null &&
        (transferMode == null || transferMode == _kDefaultTransferMode) &&
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

  @override
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
      if (strokeCap != null && strokeCap != _kDefaultStrokeCap)
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
