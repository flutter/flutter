// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


part of engine;

/// A [ui.ColorFilter] backed by Skia's [CkColorFilter].
class CkColorFilter extends ResurrectableSkiaObject<SkColorFilter> {
  final EngineColorFilter _engineFilter;

  CkColorFilter.mode(EngineColorFilter filter) : _engineFilter = filter;

  CkColorFilter.matrix(EngineColorFilter filter) : _engineFilter = filter;

  CkColorFilter.linearToSrgbGamma(EngineColorFilter filter)
      : _engineFilter = filter;

  CkColorFilter.srgbToLinearGamma(EngineColorFilter filter)
      : _engineFilter = filter;

  SkColorFilter _createSkiaObjectFromFilter() {
    SkColorFilter skColorFilter;
    switch (_engineFilter._type) {
      case EngineColorFilter._TypeMode:
        skColorFilter = canvasKitJs.SkColorFilter.MakeBlend(
          toSharedSkColor1(_engineFilter._color!),
          toSkBlendMode(_engineFilter._blendMode!),
        );
        break;
      case EngineColorFilter._TypeMatrix:
        final Float32List colorMatrix = Float32List(20);
        final List<double> matrix = _engineFilter._matrix!;
        for (int i = 0; i < 20; i++) {
          colorMatrix[i] = matrix[i];
        }
        skColorFilter = canvasKitJs.SkColorFilter.MakeMatrix(colorMatrix);
        break;
      case EngineColorFilter._TypeLinearToSrgbGamma:
        skColorFilter = canvasKitJs.SkColorFilter.MakeLinearToSRGBGamma();
        break;
      case EngineColorFilter._TypeSrgbToLinearGamma:
        skColorFilter = canvasKitJs.SkColorFilter.MakeSRGBToLinearGamma();
        break;
      default:
        throw StateError(
            'Unknown mode ${_engineFilter._type} for ColorFilter.');
    }
    return skColorFilter;
  }

  @override
  js.JsObject get legacySkiaObject => _jsObjectWrapper.wrapSkColorFilter(skiaObject);

  @override
  SkColorFilter createDefault() {
    return _createSkiaObjectFromFilter();
  }

  @override
  SkColorFilter resurrect() {
    return _createSkiaObjectFromFilter();
  }

  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}
