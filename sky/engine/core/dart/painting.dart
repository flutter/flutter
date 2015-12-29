// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

typedef void _ImageDecoderCallback(Image result);

void decodeImageFromDataPipe(int handle, _ImageDecoderCallback callback)
    native "decodeImageFromDataPipe";

void decodeImageFromList(Uint8List list, _ImageDecoderCallback callback)
    native "decodeImageFromList";

abstract class DrawLooper extends NativeFieldWrapperClass2 {
}

/// Paint masks for DrawLooperLayerInfo.setPaintBits. These specify which
/// aspects of the layer's paint should replace the corresponding aspects on
/// the draw's paint.
///
/// PaintBits.all means use the layer's paint completely.
/// 0 means ignore the layer's paint... except for colorMode, which is
/// always applied.
class PaintBits {
  static const int style       = 0x1;
  static const int testSkewx   = 0x2;
  static const int pathEffect  = 0x4;
  static const int maskFilter  = 0x8;
  static const int shader      = 0x10;
  static const int colorFilter = 0x20;
  static const int xfermode    = 0x40;
  static const int all         = 0xFFFFFFFF;
}

class DrawLooperLayerInfo extends NativeFieldWrapperClass2 {
  void _constructor() native "DrawLooperLayerInfo_constructor";
  DrawLooperLayerInfo() { _constructor(); }

  void setPaintBits(int bits) native "DrawLooperLayerInfo_setPaintBits";
  void setColorMode(TransferMode mode) native "DrawLooperLayerInfo_setColorMode";
  void setOffset(Offset offset) native "DrawLooperLayerInfo_setOffset";
  void setPostTranslate(bool postTranslate) native "DrawLooperLayerInfo_setPostTranslate";
}

class LayerDrawLooperBuilder extends NativeFieldWrapperClass2 {
  void _constructor() native "LayerDrawLooperBuilder_constructor";
  LayerDrawLooperBuilder() { _constructor(); }

  DrawLooper build() native "LayerDrawLooperBuilder_build";
  void addLayerOnTop(DrawLooperLayerInfo info, Paint paint) native "LayerDrawLooperBuilder_addLayerOnTop";
}

/// Blur styles. These mirror SkBlurStyle and must be kept in sync.
enum BlurStyle {
  normal,  /// Fuzzy inside and outside.
  solid,  /// Solid inside, fuzzy outside.
  outer,  /// Nothing inside, fuzzy outside.
  inner,  /// Fuzzy inside, nothing outside.
}

// Convert constructor parameters to the SkBlurMaskFilter::BlurFlags type.
int _makeBlurFlags(bool ignoreTransform, bool highQuality) {
  int flags = 0;
  if (ignoreTransform)
    flags |= 0x01;
  if (highQuality)
    flags |= 0x02;
  return flags;
}

class MaskFilter extends NativeFieldWrapperClass2 {
  void _constructor(int style, double sigma, int flags) native "MaskFilter_constructor";
  MaskFilter.blur(BlurStyle style, double sigma,
                  {bool ignoreTransform: false, bool highQuality: false}) {
    _constructor(style.index, sigma, _makeBlurFlags(ignoreTransform, highQuality));
  }
}

class ColorFilter extends NativeFieldWrapperClass2 {
  void _constructor(Color color, TransferMode transferMode) native "ColorFilter_constructor";
  ColorFilter.mode(Color color, TransferMode transferMode) {
    _constructor(color, transferMode);
  }
}

abstract class Shader extends NativeFieldWrapperClass2 {
}

/// Defines what happens at the edge of the gradient.
enum TileMode {
  /// Edge is clamped to the final color.
  clamp,
  /// Edge is repeated from first color to last.
  repeated,
  /// Edge is mirrored from last color to first.
  mirror
}

void _validateColorStops(List<Color> colors, List<double> colorStops) {
  if (colorStops != null && (colors == null || colors.length != colorStops.length)) {
    throw new ArgumentError(
        "[colors] and [colorStops] parameters must be equal length.");
  }
}

class Gradient extends Shader {
  void _constructor() native "Gradient_constructor";
  void _initLinear(List<Point> endPoints, List<Color> colors, List<double> colorStops, int tileMode) native "Gradient_initLinear";
  void _initRadial(Point center, double radius, List<Color> colors, List<double> colorStops, int tileMode) native "Gradient_initRadial";

  /// Creates a linear gradient from [endPoint[0]] to [endPoint[1]]. If
  /// [colorStops] is provided, [colorStops[i]] is a number from 0 to 1 that
  /// specifies where [color[i]] begins in the gradient.
  // TODO(mpcomplete): Maybe pass a list of (color, colorStop) pairs instead?
  Gradient.linear(List<Point> endPoints,
                  List<Color> colors,
                  [List<double> colorStops = null,
                  TileMode tileMode = TileMode.clamp]) {
    _constructor();
    if (endPoints == null || endPoints.length != 2)
      throw new ArgumentError("Expected exactly 2 [endPoints].");
    _validateColorStops(colors, colorStops);
    _initLinear(endPoints, colors, colorStops, tileMode.index);
  }

  /// Creates a radial gradient centered at [center] that ends at [radius]
  /// distance from the center. If [colorStops] is provided, [colorStops[i]] is
  /// a number from 0 to 1 that specifies where [color[i]] begins in the
  /// gradient.
  Gradient.radial(Point center,
                  double radius,
                  List<Color> colors,
                  [List<double> colorStops = null,
                  TileMode tileMode = TileMode.clamp]) {
    _constructor();
    _validateColorStops(colors, colorStops);
    _initRadial(center, radius, colors, colorStops, tileMode.index);
  }
}

class ImageShader extends Shader {
  void _constructor() native "ImageShader_constructor";
  void _initWithImage(Image image, int tmx, int tmy, Float64List matrix4) native "ImageShader_initWithImage";

  ImageShader(Image image, TileMode tmx, TileMode tmy, Float64List matrix4) {
    if (image == null)
      throw new ArgumentError("[image] argument cannot be null");
    if (tmx == null)
      throw new ArgumentError("[tmx] argument cannot be null");
    if (tmy == null)
      throw new ArgumentError("[tmy] argument cannot be null");
    if (matrix4 == null)
      throw new ArgumentError("[matrix4] argument cannot be null");
    _initWithImage(image, tmx.index, tmy.index, matrix4);
  }
}

