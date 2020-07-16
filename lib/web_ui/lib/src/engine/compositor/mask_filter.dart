// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// The CanvasKit implementation of [ui.MaskFilter].
class CkMaskFilter extends ResurrectableSkiaObject<SkMaskFilter> {
  CkMaskFilter.blur(ui.BlurStyle blurStyle, double sigma)
      : _blurStyle = blurStyle,
        _sigma = sigma;

  final ui.BlurStyle _blurStyle;
  final double _sigma;

  @override
  SkMaskFilter createDefault() => _initSkiaObject();

  @override
  SkMaskFilter resurrect() => _initSkiaObject();

  SkMaskFilter _initSkiaObject() {
    return canvasKitJs.MakeBlurMaskFilter(
      toSkBlurStyle(_blurStyle),
      _sigma,
      true,
    );
  }

  @override
  js.JsObject get legacySkiaObject => _jsObjectWrapper.wrapSkMaskFilter(skiaObject);

  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}
