// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';

class CkMaskFilter implements BackendMaskFilter {
  CkMaskFilter(EngineMaskFilter maskFilter) {
    _skMaskFilter = canvasKit.MaskFilter.MakeBlur(
      toSkBlurStyle(maskFilter.webOnlyBlurStyle),
      maskFilter.webOnlySigma,
      true,
    )!;
  }

  late final SkMaskFilter _skMaskFilter;

  SkMaskFilter get skiaObject => _skMaskFilter;

  @override
  void dispose() {
    _skMaskFilter.delete();
  }
}
