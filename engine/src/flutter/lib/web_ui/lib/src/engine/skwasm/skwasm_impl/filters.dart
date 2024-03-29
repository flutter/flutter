// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

abstract class SkwasmImageFilter extends SkwasmObjectWrapper<RawImageFilter> implements SceneImageFilter {
  SkwasmImageFilter(ImageFilterHandle handle) : super(handle, _registry);

  factory SkwasmImageFilter.blur({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode tileMode = ui.TileMode.clamp,
  }) => SkwasmBlurFilter(sigmaX, sigmaY, tileMode);

  factory SkwasmImageFilter.dilate({
    double radiusX = 0.0,
    double radiusY = 0.0,
  }) => SkwasmDilateFilter(radiusX, radiusY);

  factory SkwasmImageFilter.erode({
    double radiusX = 0.0,
    double radiusY = 0.0,
  }) => SkwasmErodeFilter(radiusX, radiusY);

  factory SkwasmImageFilter.matrix(
    Float64List matrix4, {
    ui.FilterQuality filterQuality = ui.FilterQuality.low
  }) => SkwasmMatrixFilter(matrix4, filterQuality);

  factory SkwasmImageFilter.fromColorFilter(SkwasmColorFilter filter) =>
    SkwasmColorImageFilter(filter);

  factory SkwasmImageFilter.fromUiFilter(ui.ImageFilter filter) {
    if (filter is ui.ColorFilter) {
      final SkwasmColorFilter colorFilter =
        SkwasmColorFilter.fromEngineColorFilter(filter as EngineColorFilter);
      final SkwasmImageFilter outputFilter = SkwasmImageFilter.fromColorFilter(colorFilter);
      colorFilter.dispose();
      return outputFilter;
    } else {
      return filter as SkwasmImageFilter;
    }
  }

  factory SkwasmImageFilter.compose(
    ui.ImageFilter outer,
    ui.ImageFilter inner,
  ) => SkwasmComposedImageFilter(
    SkwasmImageFilter.fromUiFilter(outer),
    SkwasmImageFilter.fromUiFilter(inner),
  );

  static final SkwasmFinalizationRegistry<RawImageFilter> _registry =
    SkwasmFinalizationRegistry<RawImageFilter>(imageFilterDispose);

  @override
  ui.Rect filterBounds(ui.Rect inputBounds) => withStackScope((StackScope scope) {
    final RawIRect rawRect = scope.convertIRectToNative(inputBounds);
    imageFilterGetFilterBounds(handle, rawRect);
    return scope.convertIRectFromNative(rawRect);
  });
}

class SkwasmBlurFilter extends SkwasmImageFilter {
  SkwasmBlurFilter(
    this.sigmaX,
    this.sigmaY,
    this.tileMode,
  ) : super(imageFilterCreateBlur(sigmaX, sigmaY, tileMode.index));

  final double sigmaX;
  final double sigmaY;
  ui.TileMode tileMode;

  @override
  String toString() => 'ImageFilter.blur($sigmaX, $sigmaY, ${tileModeString(tileMode)})';
}

class SkwasmDilateFilter extends SkwasmImageFilter {
  SkwasmDilateFilter(
    this.radiusX,
    this.radiusY,
  ) : super(imageFilterCreateDilate(radiusX, radiusY));

  final double radiusX;
  final double radiusY;

  @override
  String toString() => 'ImageFilter.dilate($radiusX, $radiusY)';
}

class SkwasmErodeFilter extends SkwasmImageFilter {
  SkwasmErodeFilter(
    this.radiusX,
    this.radiusY,
  ) : super(imageFilterCreateErode(radiusX, radiusY));

  final double radiusX;
  final double radiusY;

  @override
  String toString() => 'ImageFilter.erode($radiusX, $radiusY)';
}

class SkwasmMatrixFilter extends SkwasmImageFilter {
  SkwasmMatrixFilter(
    this.matrix4,
    this.filterQuality,
  ) : super(withStackScope((StackScope scope) => imageFilterCreateMatrix(
    scope.convertMatrix4toSkMatrix(matrix4),
    filterQuality.index,
  )));

  final Float64List matrix4;
  final ui.FilterQuality filterQuality;

  @override
  String toString() => 'ImageFilter.matrix($matrix4, $filterQuality)';
}

class SkwasmColorImageFilter extends SkwasmImageFilter {
  SkwasmColorImageFilter(
    this.filter,
  ) : super(imageFilterCreateFromColorFilter(filter.handle));

  final SkwasmColorFilter filter;

  @override
  String toString() => filter.toString();
}

class SkwasmComposedImageFilter extends SkwasmImageFilter {
  SkwasmComposedImageFilter(
    this.outer,
    this.inner,
  ) : super(imageFilterCompose(outer.handle, inner.handle));

  final SkwasmImageFilter outer;
  final SkwasmImageFilter inner;

  @override
  String toString() => 'ImageFilter.compose($outer, $inner)';
}

abstract class SkwasmColorFilter extends SkwasmObjectWrapper<RawColorFilter> {
  SkwasmColorFilter(ColorFilterHandle handle) : super(handle, _registry);

  factory SkwasmColorFilter.fromEngineColorFilter(EngineColorFilter colorFilter) =>
    switch (colorFilter.type) {
      ColorFilterType.mode => SkwasmModeColorFilter(colorFilter.color!, colorFilter.blendMode!),
      ColorFilterType.linearToSrgbGamma => SkwasmLinearToSrgbGammaColorFilter(),
      ColorFilterType.srgbToLinearGamma => SkwasmSrgbToLinearGammaColorFilter(),
      ColorFilterType.matrix => SkwasmMatrixColorFilter(colorFilter.matrix!),
    };

  factory SkwasmColorFilter.composed(
    SkwasmColorFilter outer,
    SkwasmColorFilter inner,
  ) => SkwasmComposedColorFilter(outer, inner);

  static final SkwasmFinalizationRegistry<RawColorFilter> _registry =
    SkwasmFinalizationRegistry<RawColorFilter>(colorFilterDispose);
}

class SkwasmModeColorFilter extends SkwasmColorFilter {
  SkwasmModeColorFilter(
    this.color,
    this.blendMode,
  ) : super(colorFilterCreateMode(
      color.value,
      blendMode.index,
    ));

  final ui.Color color;
  final ui.BlendMode blendMode;

  @override
  String toString() => 'ColorFilter.mode($color, $blendMode)';
}

class SkwasmLinearToSrgbGammaColorFilter extends SkwasmColorFilter {
  SkwasmLinearToSrgbGammaColorFilter() : super(colorFilterCreateLinearToSRGBGamma());

  @override
  String toString() => 'ColorFilter.linearToSrgbGamma()';
}

class SkwasmSrgbToLinearGammaColorFilter extends SkwasmColorFilter {
  SkwasmSrgbToLinearGammaColorFilter() : super(colorFilterCreateSRGBToLinearGamma());

  @override
  String toString() => 'ColorFilter.srgbToLinearGamma()';
}

class SkwasmMatrixColorFilter extends SkwasmColorFilter {
  SkwasmMatrixColorFilter(this.matrix) : super(withStackScope((StackScope scope) =>
    colorFilterCreateMatrix(scope.convertDoublesToNative(matrix))
  ));

  final List<double> matrix;

  @override
  String toString() => 'ColorFilter.matrix($matrix)';
}

class SkwasmComposedColorFilter extends SkwasmColorFilter {
  SkwasmComposedColorFilter(
    this.outer,
    this.inner,
  ) : super(colorFilterCompose(outer.handle, inner.handle));

  final SkwasmColorFilter outer;
  final SkwasmColorFilter inner;

  @override
  String toString() => 'ColorFilter.compose($outer, $inner)';
}

class SkwasmMaskFilter extends SkwasmObjectWrapper<RawMaskFilter> {
  SkwasmMaskFilter._(MaskFilterHandle handle) : super(handle, _registry);

  factory SkwasmMaskFilter.fromUiMaskFilter(ui.MaskFilter maskFilter) =>
    SkwasmMaskFilter._(maskFilterCreateBlur(
      maskFilter.webOnlyBlurStyle.index,
      maskFilter.webOnlySigma
    ));

  static final SkwasmFinalizationRegistry<RawMaskFilter> _registry =
    SkwasmFinalizationRegistry<RawMaskFilter>(maskFilterDispose);
}
