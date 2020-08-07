// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// A [ui.ColorFilter] backed by Skia's [CkColorFilter].
class CkColorFilter extends ManagedSkiaObject<SkColorFilter> {
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
        skColorFilter = canvasKit.SkColorFilter.MakeBlend(
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
        skColorFilter = canvasKit.SkColorFilter.MakeMatrix(colorMatrix);
        break;
      case EngineColorFilter._TypeLinearToSrgbGamma:
        skColorFilter = canvasKit.SkColorFilter.MakeLinearToSRGBGamma();
        break;
      case EngineColorFilter._TypeSrgbToLinearGamma:
        skColorFilter = canvasKit.SkColorFilter.MakeSRGBToLinearGamma();
        break;
      default:
        throw StateError(
            'Unknown mode ${_engineFilter._type} for ColorFilter.');
    }
    return skColorFilter;
  }

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
