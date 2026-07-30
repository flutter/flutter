// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// CanvasKit implementation of [ui.ColorFilter].
///
/// This class acts as a thin wrapper around a [SkColorFilter].
/// The memory lifecycle of the underlying [SkColorFilter] is managed by the
/// [FinalizationRegistry] associated with the shared `EngineColorFilter`.
class CkColorFilter implements BackendColorFilter {
  CkColorFilter(EngineColorFilter colorFilter) : skiaObject = _initSkiaObject(colorFilter);
  CkColorFilter.fromSkColorFilter(this.skiaObject);

  final SkColorFilter skiaObject;

  static SkColorFilter _initSkiaObject(EngineColorFilter colorFilter) {
    switch (colorFilter.type) {
      case ColorFilterType.mode:
        final ui.Color? color = colorFilter.color;
        final ui.BlendMode? blendMode = colorFilter.blendMode;
        if (color == null || blendMode == null) {
          return canvasKit.ColorFilter.MakeMatrix(_identityTransform);
        }
        final SkColorFilter? filter = canvasKit.ColorFilter.MakeBlend(
          toSharedSkColor1(color),
          toSkBlendMode(blendMode),
        );
        return filter ?? canvasKit.ColorFilter.MakeMatrix(_identityTransform);
      case ColorFilterType.matrix:
        final List<double>? matrix = colorFilter.matrix;
        if (matrix == null) {
          return canvasKit.ColorFilter.MakeMatrix(_identityTransform);
        }
        return canvasKit.ColorFilter.MakeMatrix(_normalizeMatrix(matrix));
      case ColorFilterType.linearToSrgbGamma:
        return canvasKit.ColorFilter.MakeLinearToSRGBGamma();
      case ColorFilterType.srgbToLinearGamma:
        return canvasKit.ColorFilter.MakeSRGBToLinearGamma();
    }
  }

  static Float32List _normalizeMatrix(List<double> matrix) {
    assert(matrix.length == 20, 'Color Matrix must have 20 entries.');
    final result = Float32List(20);
    const translationIndices = <int>[4, 9, 14, 19];
    for (var i = 0; i < 20; i++) {
      if (translationIndices.contains(i)) {
        // Flutter documentation says the translation column of the color matrix
        // is specified in unnormalized 0..255 space. Skia expects the
        // translation values to be normalized to 0..1 space.
        //
        // See [https://api.flutter.dev/flutter/dart-ui/ColorFilter/ColorFilter.matrix.html].
        result[i] = matrix[i] / 255.0;
      } else {
        result[i] = matrix[i];
      }
    }
    return result;
  }

  @override
  void dispose() {
    skiaObject.delete();
  }
}

/// A reusable identity transform matrix.
///
/// WARNING: DO NOT MUTATE THIS MATRIX! It is a shared global singleton.
Float32List _identityTransform = _computeIdentityTransform();

Float32List _computeIdentityTransform() {
  final result = Float32List(20);
  const translationIndices = <int>[0, 6, 12, 18];
  for (final i in translationIndices) {
    result[i] = 1;
  }
  _identityTransform = result;
  return result;
}
