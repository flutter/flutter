// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

/// A helper class to build a [ui.DrawLooper] for drawing shadows
class ShadowDrawLooperBuilder {
  ui.LayerDrawLooperBuilder _builder = new ui.LayerDrawLooperBuilder();

  /// Adds a shadow with the given parameters.
  void addShadow(ui.Offset offset, ui.Color color, double blur) {
    _builder.addLayerOnTop(
      new ui.DrawLooperLayerInfo()
        ..setPaintBits(ui.PaintBits.all)
        ..setOffset(offset)
        ..setColorMode(ui.TransferMode.src),
      new ui.Paint()
        ..color = color
        ..maskFilter = new ui.MaskFilter.blur(ui.BlurStyle.normal, blur)
    );
  }

  /// Returns the draw looper built for the added shadows
  ui.DrawLooper build() {
    _builder.addLayerOnTop(new ui.DrawLooperLayerInfo(), new ui.Paint());
    return _builder.build();
  }
}
