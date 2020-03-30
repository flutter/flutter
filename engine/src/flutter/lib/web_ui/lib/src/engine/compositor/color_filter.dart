// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// A [ui.ColorFilter] backed by Skia's [SkColorFilter].
class SkColorFilter {
  js.JsObject skColorFilter;

  SkColorFilter.mode(EngineColorFilter filter) {
    skColorFilter =
        canvasKit['SkColorFilter'].callMethod('MakeBlend', <dynamic>[
      filter._color.value,
      makeSkBlendMode(filter._blendMode),
    ]);
  }

  SkColorFilter.matrix(EngineColorFilter filter) {
    // TODO(het): Find a way to remove these array conversions.
    final js.JsArray<double> colorMatrix = js.JsArray<double>();
    colorMatrix.length = 20;
    for (int i = 0; i < 20; i++) {
      colorMatrix[i] = filter._matrix[i];
    }
    skColorFilter = canvasKit['SkColorFilter']
        .callMethod('MakeMatrix', <js.JsArray>[colorMatrix]);
  }

  SkColorFilter.linearToSrgbGamma(EngineColorFilter filter) {
    skColorFilter = canvasKit['SkColorFilter'].callMethod('MakeLinearToSRGBGamma');
  }

  SkColorFilter.srgbToLinearGamma(EngineColorFilter filter) {
    skColorFilter = canvasKit['SkColorFilter'].callMethod('MakeSRGBToLinearGamma');
  }
}
