// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'canvaskit_api.dart';
import 'skia_object_cache.dart';

/// The CanvasKit implementation of [ui.MaskFilter].
class CkMaskFilter extends ManagedSkiaObject<SkMaskFilter> {
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
    return canvasKit.MaskFilter.MakeBlur(
      toSkBlurStyle(_blurStyle),
      _sigma,
      true,
    )!;
  }

  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}
