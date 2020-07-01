// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// The CanvasKit implementation of [ui.MaskFilter].
class CkMaskFilter extends ResurrectableSkiaObject {
  CkMaskFilter.blur(ui.BlurStyle blurStyle, double sigma)
      : _blurStyle = blurStyle,
        _sigma = sigma;

  final ui.BlurStyle _blurStyle;
  final double _sigma;

  @override
  js.JsObject createDefault() => _initSkiaObject();

  @override
  js.JsObject resurrect() => _initSkiaObject();

  js.JsObject _initSkiaObject() {
    js.JsObject skBlurStyle;
    switch (_blurStyle) {
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

    return canvasKit
        .callMethod('MakeBlurMaskFilter', <dynamic>[skBlurStyle, _sigma, true]);
  }
}
