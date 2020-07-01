// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


part of engine;

/// A [ui.ColorFilter] backed by Skia's [CkColorFilter].
class CkColorFilter extends ResurrectableSkiaObject {
  final EngineColorFilter _engineFilter;

  CkColorFilter.mode(EngineColorFilter filter) : _engineFilter = filter;

  CkColorFilter.matrix(EngineColorFilter filter) : _engineFilter = filter;

  CkColorFilter.linearToSrgbGamma(EngineColorFilter filter)
      : _engineFilter = filter;

  CkColorFilter.srgbToLinearGamma(EngineColorFilter filter)
      : _engineFilter = filter;

  js.JsObject _createSkiaObjectFromFilter() {
    switch (_engineFilter._type) {
      case EngineColorFilter._TypeMode:
        setSharedSkColor1(_engineFilter._color!);
        return canvasKit['SkColorFilter'].callMethod('MakeBlend', <dynamic>[
          sharedSkColor1,
          makeSkBlendMode(_engineFilter._blendMode),
        ]);
      case EngineColorFilter._TypeMatrix:
        final js.JsArray<double> colorMatrix = js.JsArray<double>();
        colorMatrix.length = 20;
        for (int i = 0; i < 20; i++) {
          colorMatrix[i] = _engineFilter._matrix![i];
        }
        return canvasKit['SkColorFilter']
            .callMethod('MakeMatrix', <js.JsArray>[colorMatrix]);
      case EngineColorFilter._TypeLinearToSrgbGamma:
        return canvasKit['SkColorFilter'].callMethod('MakeLinearToSRGBGamma');
      case EngineColorFilter._TypeSrgbToLinearGamma:
        return canvasKit['SkColorFilter'].callMethod('MakeSRGBToLinearGamma');
      default:
        throw StateError(
            'Unknown mode ${_engineFilter._type} for ColorFilter.');
    }
  }

  @override
  js.JsObject createDefault() {
    return _createSkiaObjectFromFilter();
  }

  @override
  js.JsObject resurrect() {
    return _createSkiaObjectFromFilter();
  }
}
