// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

abstract class CkImageFilter implements BackendImageFilter {
  /// Returns the Skia native filter.
  ///
  /// Returns null if the filter is invalid (e.g. non-invertible matrix) or if
  /// it's a no-op (e.g. an erode/dilate with a radius of 0).
  SkImageFilter? get nativeFilter => _skImageFilter;
  SkImageFilter? _skImageFilter;

  @override
  void dispose() {
    _skImageFilter?.delete();
    _skImageFilter = null;
  }

  @override
  ui.Rect filterBounds(ui.Rect inputBounds) {
    final SkImageFilter? skFilter = nativeFilter;
    if (skFilter == null) {
      return inputBounds;
    }
    final Int32List? outputBounds = skFilter.getOutputBounds(toSkRect(inputBounds));
    // The CanvasKit C++ API may return null if the output bounds cannot be
    // computed. In such cases we fall back to the input bounds.
    if (outputBounds == null) {
      return inputBounds;
    }
    return rectFromSkIRect(outputBounds);
  }
}

class CkColorFilterImageFilter extends CkImageFilter {
  CkColorFilterImageFilter(BackendColorFilter colorFilter) {
    _skImageFilter = canvasKit.ImageFilter.MakeColorFilter(
      (colorFilter as CkColorFilter).skiaObject,
      null,
    );
  }
}

class CkBlurImageFilter extends CkImageFilter {
  CkBlurImageFilter({
    required double sigmaX,
    required double sigmaY,
    required ui.TileMode tileMode,
  }) {
    _skImageFilter = canvasKit.ImageFilter.MakeBlur(sigmaX, sigmaY, toSkTileMode(tileMode), null);
  }
}

class CkMatrixImageFilter extends CkImageFilter {
  CkMatrixImageFilter({required Float64List matrix, required ui.FilterQuality filterQuality}) {
    _skImageFilter = canvasKit.ImageFilter.MakeMatrixTransform(
      toSkMatrixFromFloat64(matrix),
      toSkFilterOptions(filterQuality),
      null,
    );
  }
}

class CkDilateImageFilter extends CkImageFilter {
  CkDilateImageFilter({required double radiusX, required double radiusY}) {
    _skImageFilter = canvasKit.ImageFilter.MakeDilate(radiusX, radiusY, null);
  }
}

class CkErodeImageFilter extends CkImageFilter {
  CkErodeImageFilter({required double radiusX, required double radiusY}) {
    _skImageFilter = canvasKit.ImageFilter.MakeErode(radiusX, radiusY, null);
  }
}

class CkComposeImageFilter extends CkImageFilter {
  CkComposeImageFilter({required BackendImageFilter outer, required BackendImageFilter inner}) {
    final SkImageFilter? skOuter = (outer as CkImageFilter).nativeFilter;
    final SkImageFilter? skInner = (inner as CkImageFilter).nativeFilter;
    _skImageFilter = canvasKit.ImageFilter.MakeCompose(skOuter, skInner);
  }
}
