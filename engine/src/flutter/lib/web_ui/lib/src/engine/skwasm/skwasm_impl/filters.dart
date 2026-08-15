// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

typedef ImageFilterHandleBorrow<T> = T Function(ImageFilterHandle handle);

abstract class SkwasmImageFilter implements LayerImageFilter {
  const SkwasmImageFilter();

  factory SkwasmImageFilter.blur({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode? tileMode,
  }) => SkwasmBlurFilter(sigmaX, sigmaY, tileMode);

  factory SkwasmImageFilter.dilate({double radiusX = 0.0, double radiusY = 0.0}) =>
      SkwasmDilateFilter(radiusX, radiusY);

  factory SkwasmImageFilter.erode({double radiusX = 0.0, double radiusY = 0.0}) =>
      SkwasmErodeFilter(radiusX, radiusY);

  factory SkwasmImageFilter.matrix(
    Float64List matrix4, {
    ui.FilterQuality filterQuality = ui.FilterQuality.low,
  }) => SkwasmMatrixFilter(matrix4, filterQuality);

  factory SkwasmImageFilter.fromColorFilter(SkwasmColorFilter filter) =>
      SkwasmColorImageFilter(filter);

  factory SkwasmImageFilter.fromUiFilter(ui.ImageFilter filter) {
    if (filter is ui.ColorFilter) {
      return SkwasmImageFilter.fromColorFilter(
        (filter as EngineColorFilter).backendFilter as SkwasmColorFilter,
      );
    } else {
      return filter as SkwasmImageFilter;
    }
  }

  factory SkwasmImageFilter.compose(ui.ImageFilter outer, ui.ImageFilter inner) =>
      SkwasmComposedImageFilter(
        SkwasmImageFilter.fromUiFilter(outer),
        SkwasmImageFilter.fromUiFilter(inner),
      );

  /// Creates a temporary [ImageFilterHandle] and passes it to the [borrow]
  /// function.
  ///
  /// If (and only if) the filter is a blur ImageFilter, then the indicated
  /// [defaultBlurTileMode] is used in place of a missing (null) tile mode.
  ///
  /// The handle is deleted immediately after [borrow] returns. The [borrow]
  /// function must not store the handle to avoid dangling pointer bugs.
  T withRawImageFilter<T>(
    ImageFilterHandleBorrow<T> borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  });

  @override
  ui.Rect filterBounds(ui.Rect inputBounds) => withRawImageFilter((handle) {
    return withStackScope((StackScope scope) {
      final RawIRect rawRect = scope.convertIRectToNative(inputBounds);
      imageFilterGetFilterBounds(handle, rawRect);
      return scope.convertIRectFromNative(rawRect);
    });
  });

  @override
  String toString() => 'ImageFilter.$debugShortDescription';
}

class SkwasmBlurFilter extends SkwasmImageFilter {
  const SkwasmBlurFilter(this.sigmaX, this.sigmaY, this.tileMode);

  final double sigmaX;
  final double sigmaY;
  final ui.TileMode? tileMode;

  @override
  T withRawImageFilter<T>(
    ImageFilterHandleBorrow<T> borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    final ImageFilterHandle rawImageFilter = imageFilterCreateBlur(
      sigmaX,
      sigmaY,
      (tileMode ?? defaultBlurTileMode).index,
    );
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  }

  @override
  Matrix4? get transform => null;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is SkwasmBlurFilter &&
        other.sigmaX == sigmaX &&
        other.sigmaY == sigmaY &&
        other.tileMode == tileMode;
  }

  @override
  int get hashCode => Object.hash(sigmaX, sigmaY, tileMode);

  @override
  String get debugShortDescription => 'blur($sigmaX, $sigmaY, ${tileModeString(tileMode)})';
}

class SkwasmDilateFilter extends SkwasmImageFilter {
  const SkwasmDilateFilter(this.radiusX, this.radiusY);

  final double radiusX;
  final double radiusY;

  @override
  T withRawImageFilter<T>(
    ImageFilterHandleBorrow<T> borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    final ImageFilterHandle rawImageFilter = imageFilterCreateDilate(radiusX, radiusY);
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  }

  @override
  Matrix4? get transform => null;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is SkwasmDilateFilter && other.radiusX == radiusX && other.radiusY == radiusY;
  }

  @override
  int get hashCode => Object.hash(radiusX, radiusY);

  @override
  String get debugShortDescription => 'dilate($radiusX, $radiusY)';
}

class SkwasmErodeFilter extends SkwasmImageFilter {
  const SkwasmErodeFilter(this.radiusX, this.radiusY);

  final double radiusX;
  final double radiusY;

  @override
  T withRawImageFilter<T>(
    ImageFilterHandleBorrow<T> borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    final ImageFilterHandle rawImageFilter = imageFilterCreateErode(radiusX, radiusY);
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  }

  @override
  Matrix4? get transform => null;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is SkwasmErodeFilter && other.radiusX == radiusX && other.radiusY == radiusY;
  }

  @override
  int get hashCode => Object.hash(radiusX, radiusY);

  @override
  String get debugShortDescription => 'erode($radiusX, $radiusY)';
}

class SkwasmMatrixFilter extends SkwasmImageFilter {
  const SkwasmMatrixFilter(this.matrix4, this.filterQuality);

  final Float64List matrix4;
  final ui.FilterQuality filterQuality;

  @override
  T withRawImageFilter<T>(
    ImageFilterHandleBorrow<T> borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) => withStackScope((scope) {
    final ImageFilterHandle rawImageFilter = imageFilterCreateMatrix(
      scope.convertMatrix4toSkMatrix(matrix4),
      filterQuality.index,
    );
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  });

  @override
  Matrix4? get transform => Matrix4.fromFloat32List(toMatrix32(matrix4));

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SkwasmMatrixFilter &&
        other.filterQuality == filterQuality &&
        listEquals<double>(other.matrix4, matrix4);
  }

  @override
  int get hashCode => Object.hash(filterQuality, Object.hashAll(matrix4));

  @override
  String get debugShortDescription => 'matrix($matrix4, $filterQuality)';
}

class SkwasmColorImageFilter extends SkwasmImageFilter {
  SkwasmColorImageFilter(this.filter);

  final SkwasmColorFilter filter;

  @override
  T withRawImageFilter<T>(
    ImageFilterHandleBorrow<T> borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    final ImageFilterHandle rawImageFilter = imageFilterCreateFromColorFilter(filter.handle);
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  }

  @override
  Matrix4? get transform => null;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is SkwasmColorImageFilter && other.filter == filter;
  }

  @override
  int get hashCode => filter.hashCode;

  @override
  String get debugShortDescription => filter.toString();

  @override
  String toString() => filter.toString();
}

class SkwasmComposedImageFilter extends SkwasmImageFilter {
  const SkwasmComposedImageFilter(this.outer, this.inner);

  final SkwasmImageFilter outer;
  final SkwasmImageFilter inner;

  @override
  T withRawImageFilter<T>(
    ImageFilterHandleBorrow<T> borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) => outer.withRawImageFilter(
    (outerHandle) => inner.withRawImageFilter((innerHandle) {
      final ImageFilterHandle rawImageFilter = imageFilterCompose(outerHandle, innerHandle);
      final T result = borrow(rawImageFilter);
      imageFilterDispose(rawImageFilter);
      return result;
    }, defaultBlurTileMode: defaultBlurTileMode),
    defaultBlurTileMode: defaultBlurTileMode,
  );

  @override
  Matrix4? get transform {
    final Matrix4? outerTransform = outer.transform;
    final Matrix4? innerTransform = inner.transform;
    if (outerTransform != null && innerTransform != null) {
      return outerTransform.multiplied(innerTransform);
    }
    return outerTransform ?? innerTransform;
  }

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is SkwasmComposedImageFilter && other.outer == outer && other.inner == inner;
  }

  @override
  int get hashCode => Object.hash(outer, inner);

  @override
  String get debugShortDescription =>
      '${inner.debugShortDescription} -> ${outer.debugShortDescription}';

  @override
  String toString() => 'ImageFilter.compose(source -> $debugShortDescription -> result)';
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

  @override
  void dispose() {
    colorFilterDispose(handle);
  }
}

class SkwasmMaskFilter implements BackendMaskFilter {
  SkwasmMaskFilter(EngineMaskFilter maskFilter)
    : handle = maskFilterCreateBlur(maskFilter.webOnlyBlurStyle.index, maskFilter.webOnlySigma);

  final MaskFilterHandle handle;

  @override
  void dispose() {
    maskFilterDispose(handle);
  }
}
