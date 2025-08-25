// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

typedef ImageFilterHandleBorrow<T> = T Function(ImageFilterHandle handle);

abstract class SkwasmImageFilter implements SceneImageFilter {
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
        SkwasmColorFilter.fromEngineColorFilter(filter as EngineColorFilter),
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
    if (handle == nullptr) {
      return inputBounds;
    }
    return withStackScope((StackScope scope) {
      final RawIRect rawRect = scope.convertIRectToNative(inputBounds);
      imageFilterGetFilterBounds(handle, rawRect);
      return scope.convertIRectFromNative(rawRect);
    });
  });
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
    final rawImageFilter = imageFilterCreateBlur(
      sigmaX,
      sigmaY,
      (tileMode ?? defaultBlurTileMode).index,
    );
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  }

  @override
  String toString() => 'ImageFilter.blur($sigmaX, $sigmaY, ${tileModeString(tileMode)})';

  @override
  Matrix4? get transform => null;
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
    final rawImageFilter = imageFilterCreateDilate(radiusX, radiusY);
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  }

  @override
  String toString() => 'ImageFilter.dilate($radiusX, $radiusY)';

  @override
  Matrix4? get transform => null;
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
    final rawImageFilter = imageFilterCreateErode(radiusX, radiusY);
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  }

  @override
  String toString() => 'ImageFilter.erode($radiusX, $radiusY)';

  @override
  Matrix4? get transform => null;
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
    final rawImageFilter = imageFilterCreateMatrix(
      scope.convertMatrix4toSkMatrix(matrix4),
      filterQuality.index,
    );
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  });

  @override
  String toString() => 'ImageFilter.matrix($matrix4, $filterQuality)';

  @override
  Matrix4? get transform => Matrix4.fromFloat32List(toMatrix32(matrix4));
}

class SkwasmColorImageFilter extends SkwasmImageFilter {
  const SkwasmColorImageFilter(this.filter);

  final SkwasmColorFilter filter;

  @override
  T withRawImageFilter<T>(
    ImageFilterHandleBorrow<T> borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) => filter.withRawColorFilter((colorFilterHandle) {
    final rawImageFilter = imageFilterCreateFromColorFilter(colorFilterHandle);
    final T result = borrow(rawImageFilter);
    imageFilterDispose(rawImageFilter);
    return result;
  });

  @override
  String toString() => filter.toString();

  @override
  Matrix4? get transform => null;
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
      final rawImageFilter = imageFilterCompose(outerHandle, innerHandle);
      final T result = borrow(rawImageFilter);
      imageFilterDispose(rawImageFilter);
      return result;
    }, defaultBlurTileMode: defaultBlurTileMode),
    defaultBlurTileMode: defaultBlurTileMode,
  );

  @override
  String toString() => 'ImageFilter.compose($outer, $inner)';

  @override
  Matrix4? get transform {
    final outerTransform = outer.transform;
    final innerTransform = inner.transform;
    if (outerTransform != null && innerTransform != null) {
      return outerTransform.multiplied(innerTransform);
    }
    return outerTransform ?? innerTransform;
  }
}

typedef ColorFilterHandleBorrow<T> = T Function(ColorFilterHandle handle);

abstract class SkwasmColorFilter {
  const SkwasmColorFilter();

  factory SkwasmColorFilter.fromEngineColorFilter(EngineColorFilter colorFilter) =>
      switch (colorFilter.type) {
        ColorFilterType.mode => SkwasmModeColorFilter(colorFilter.color!, colorFilter.blendMode!),
        ColorFilterType.linearToSrgbGamma => const SkwasmLinearToSrgbGammaColorFilter(),
        ColorFilterType.srgbToLinearGamma => const SkwasmSrgbToLinearGammaColorFilter(),
        ColorFilterType.matrix => SkwasmMatrixColorFilter(colorFilter.matrix!),
      };

  /// Creates a temporary [ColorFilterHandle] and passes it to the [borrow]
  /// function.
  ///
  /// The handle is deleted immediately after [borrow] returns. The [borrow]
  /// function must not store the handle to avoid dangling pointer bugs.
  T withRawColorFilter<T>(ColorFilterHandleBorrow<T> borrow);
}

class SkwasmModeColorFilter extends SkwasmColorFilter {
  const SkwasmModeColorFilter(this.color, this.blendMode);

  final ui.Color color;
  final ui.BlendMode blendMode;

  @override
  T withRawColorFilter<T>(ColorFilterHandleBorrow<T> borrow) {
    final rawColorFilter = colorFilterCreateMode(color.value, blendMode.index);
    final T result = borrow(rawColorFilter);
    colorFilterDispose(rawColorFilter);
    return result;
  }

  @override
  String toString() => 'ColorFilter.mode($color, $blendMode)';
}

class SkwasmLinearToSrgbGammaColorFilter extends SkwasmColorFilter {
  const SkwasmLinearToSrgbGammaColorFilter();

  /// This filter does not need to be deleted, because the same instance can
  /// reused everywhere (it's not configurable).
  static final _rawColorFilter = colorFilterCreateLinearToSRGBGamma();

  @override
  T withRawColorFilter<T>(ColorFilterHandleBorrow<T> borrow) => borrow(_rawColorFilter);

  @override
  String toString() => 'ColorFilter.linearToSrgbGamma()';
}

class SkwasmSrgbToLinearGammaColorFilter extends SkwasmColorFilter {
  const SkwasmSrgbToLinearGammaColorFilter();

  /// This filter does not need to be deleted, because the same instance can
  /// reused everywhere (it's not configurable).
  static final _rawColorFilter = colorFilterCreateSRGBToLinearGamma();

  @override
  T withRawColorFilter<T>(ColorFilterHandleBorrow<T> borrow) => borrow(_rawColorFilter);

  @override
  String toString() => 'ColorFilter.srgbToLinearGamma()';
}

class SkwasmMatrixColorFilter extends SkwasmColorFilter {
  const SkwasmMatrixColorFilter(this.matrix);

  final List<double> matrix;

  @override
  T withRawColorFilter<T>(ColorFilterHandleBorrow<T> borrow) => withStackScope((scope) {
    assert(matrix.length == 20);
    final Pointer<Float> rawMatrix = scope.convertDoublesToNative(matrix);

    /// Flutter documentation says the translation column of the color matrix
    /// is specified in unnormalized 0..255 space. Skia expects the
    /// translation values to be normalized to 0..1 space.
    ///
    /// See [https://api.flutter.dev/flutter/dart-ui/ColorFilter/ColorFilter.matrix.html].
    for (final i in <int>[4, 9, 14, 19]) {
      rawMatrix[i] /= 255.0;
    }
    final rawColorFilter = colorFilterCreateMatrix(rawMatrix);
    final T result = borrow(rawColorFilter);
    colorFilterDispose(rawColorFilter);
    return result;
  });

  @override
  String toString() => 'ColorFilter.matrix($matrix)';
}

class SkwasmMaskFilter extends SkwasmObjectWrapper<RawMaskFilter> {
  SkwasmMaskFilter._(MaskFilterHandle handle) : super(handle, _registry);

  factory SkwasmMaskFilter.fromUiMaskFilter(ui.MaskFilter maskFilter) => SkwasmMaskFilter._(
    maskFilterCreateBlur(maskFilter.webOnlyBlurStyle.index, maskFilter.webOnlySigma),
  );

  static final SkwasmFinalizationRegistry<RawMaskFilter> _registry =
      SkwasmFinalizationRegistry<RawMaskFilter>(
        (MaskFilterHandle handle) => maskFilterDispose(handle),
      );
}
