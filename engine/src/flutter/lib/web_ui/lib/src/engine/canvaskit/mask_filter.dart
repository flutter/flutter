// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'canvaskit_api.dart';
import 'native_memory.dart';

/// The CanvasKit implementation of [ui.MaskFilter].
class CkMaskFilter {
  CkMaskFilter.blur(ui.BlurStyle blurStyle, double sigma)
      : _blurStyle = blurStyle,
        _sigma = sigma {
    final SkMaskFilter skMaskFilter = canvasKit.MaskFilter.MakeBlur(
      toSkBlurStyle(_blurStyle),
      _sigma,
      true,
    )!;
    _ref = UniqueRef<SkMaskFilter>(this, skMaskFilter, 'MaskFilter');
  }

  final ui.BlurStyle _blurStyle;
  final double _sigma;

  late final UniqueRef<SkMaskFilter> _ref;

  SkMaskFilter get skiaObject => _ref.nativeObject;
}
