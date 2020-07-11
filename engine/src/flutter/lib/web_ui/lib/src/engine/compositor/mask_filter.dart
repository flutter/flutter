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

  SkMaskFilter? _skMaskFilter;

  @override
  js.JsObject createDefault() => _initSkiaObject();

  @override
  js.JsObject resurrect() => _initSkiaObject();

  js.JsObject _initSkiaObject() {
    final SkMaskFilter skMaskFilter = canvasKitJs.MakeBlurMaskFilter(
      toSkBlurStyle(_blurStyle),
      _sigma,
      true,
    );
    _skMaskFilter = skMaskFilter;
    return _jsObjectWrapper.wrapSkMaskFilter(skMaskFilter);
  }
}
