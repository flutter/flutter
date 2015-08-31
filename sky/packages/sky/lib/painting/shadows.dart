// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

/// A helper class to build a [sky.DrawLooper] for drawing shadows
class ShadowDrawLooperBuilder {
  var builder_ = new sky.LayerDrawLooperBuilder();

  /// Add a shadow with the given parameters
  void addShadow(sky.Offset offset, sky.Color color, double blur) {
    builder_.addLayerOnTop(
          new sky.DrawLooperLayerInfo()
            ..setPaintBits(sky.PaintBits.all)
            ..setOffset(offset)
            ..setColorMode(sky.TransferMode.src),
          new sky.Paint()
            ..color = color
            ..setMaskFilter(new sky.MaskFilter.blur(sky.BlurStyle.normal, blur)));
  }

  /// Returns the draw looper built for the added shadows
  sky.DrawLooper build() {
    builder_.addLayerOnTop(new sky.DrawLooperLayerInfo(), new sky.Paint());
    return builder_.build();
  }
}
