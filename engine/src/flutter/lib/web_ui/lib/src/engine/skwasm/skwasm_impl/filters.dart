// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

abstract class SkwasmImageFilter implements BackendImageFilter {
  /// Returns the native WebAssembly handle for this image filter.
  ///
  /// Returns a null pointer (nullptr) if the filter is invalid (e.g. non-invertible matrix).
  ImageFilterHandle get nativeFilter => _handle;
  ImageFilterHandle _handle = nullptr;

  @override
  void dispose() {
    if (_handle != nullptr) {
      imageFilterDispose(_handle);
      _handle = nullptr;
    }
  }

  @override
  ui.Rect filterBounds(ui.Rect inputBounds) {
    if (_handle == nullptr) {
      return inputBounds;
    }
    return withStackScope((StackScope scope) {
      final RawIRect rawRect = scope.convertIRectToNative(inputBounds);
      // The skwasm C++ backend allocates a bounding box and writes to the memory address
      // of `rawRect` safely in-place without returning a nullable pointer.
      imageFilterGetFilterBounds(_handle, rawRect);
      return scope.convertIRectFromNative(rawRect);
    });
  }
}

class SkwasmColorFilterImageFilter extends SkwasmImageFilter {
  SkwasmColorFilterImageFilter(BackendColorFilter colorFilter) {
    _handle = imageFilterCreateFromColorFilter((colorFilter as SkwasmColorFilter).handle);
  }
}

class SkwasmBlurImageFilter extends SkwasmImageFilter {
  SkwasmBlurImageFilter({
    required double sigmaX,
    required double sigmaY,
    required ui.TileMode tileMode,
  }) {
    _handle = imageFilterCreateBlur(sigmaX, sigmaY, tileMode.index);
  }
}

class SkwasmMatrixImageFilter extends SkwasmImageFilter {
  SkwasmMatrixImageFilter({required Float64List matrix, required ui.FilterQuality filterQuality}) {
    _handle = withStackScope((StackScope scope) {
      final Pointer<Float> matrixPtr = scope.convertMatrix4toSkMatrix(matrix);
      return imageFilterCreateMatrix(matrixPtr, filterQuality.index);
    });
  }
}

class SkwasmDilateImageFilter extends SkwasmImageFilter {
  SkwasmDilateImageFilter({required double radiusX, required double radiusY}) {
    _handle = imageFilterCreateDilate(radiusX, radiusY);
  }
}

class SkwasmErodeImageFilter extends SkwasmImageFilter {
  SkwasmErodeImageFilter({required double radiusX, required double radiusY}) {
    _handle = imageFilterCreateErode(radiusX, radiusY);
  }
}

class SkwasmComposeImageFilter extends SkwasmImageFilter {
  SkwasmComposeImageFilter({required BackendImageFilter outer, required BackendImageFilter inner}) {
    final ImageFilterHandle outerHandle = (outer as SkwasmImageFilter).nativeFilter;
    final ImageFilterHandle innerHandle = (inner as SkwasmImageFilter).nativeFilter;
    _handle = imageFilterCompose(outerHandle, innerHandle);
  }
}

/// Skwasm implementation of [ui.ColorFilter].
///
/// This class acts as a thin wrapper around a [ColorFilterHandle].
/// The memory lifecycle of the underlying native object is managed by the
/// [FinalizationRegistry] associated with the shared `EngineColorFilter`.
class SkwasmColorFilter implements BackendColorFilter {
  SkwasmColorFilter(EngineColorFilter colorFilter) : handle = _initHandle(colorFilter);

  final ColorFilterHandle handle;

  static ColorFilterHandle _initHandle(EngineColorFilter colorFilter) {
    switch (colorFilter.type) {
      case ColorFilterType.mode:
        final ui.Color? color = colorFilter.color;
        final ui.BlendMode? blendMode = colorFilter.blendMode;
        if (color == null || blendMode == null) {
          throw StateError('ColorFilter.mode must have a color and blend mode.');
        }
        return colorFilterCreateMode(color.value, blendMode.index);
      case ColorFilterType.linearToSrgbGamma:
        return colorFilterCreateLinearToSRGBGamma();
      case ColorFilterType.srgbToLinearGamma:
        return colorFilterCreateSRGBToLinearGamma();
      case ColorFilterType.matrix:
        final List<double>? matrix = colorFilter.matrix;
        if (matrix == null) {
          throw StateError('ColorFilter.matrix must have a matrix.');
        }
        return withStackScope((scope) {
          final Pointer<Float> rawMatrix = scope.convertDoublesToNative(matrix);
          const translationIndices = <int>[4, 9, 14, 19];
          for (final i in translationIndices) {
            // Flutter documentation says the translation column of the color matrix
            // is specified in unnormalized 0..255 space. Skia expects the
            // translation values to be normalized to 0..1 space.
            rawMatrix[i] /= 255.0;
          }
          return colorFilterCreateMatrix(rawMatrix);
        });
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    colorFilterDispose(handle);
  }
}

class SkwasmMaskFilter implements BackendMaskFilter {
  SkwasmMaskFilter(EngineMaskFilter maskFilter)
    : handle = maskFilterCreateBlur(maskFilter.webOnlyBlurStyle.index, maskFilter.webOnlySigma);

  final MaskFilterHandle handle;

  bool _isDisposed = false;

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    maskFilterDispose(handle);
  }
}
