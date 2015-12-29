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
