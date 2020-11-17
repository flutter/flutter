// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// A concrete [ManagedSkiaObject] subclass that owns a [SkColorFilter] and
/// manages its lifecycle.
///
/// Seealso:
///
/// * [CkPaint.colorFilter], which uses a [_ManagedSkColorFilter] to manage
///   the lifecycle of its [SkColorFilter].
class _ManagedSkColorFilter extends ManagedSkiaObject<SkColorFilter> {
  _ManagedSkColorFilter(CkColorFilter ckColorFilter)
    : this.ckColorFilter = ckColorFilter;

  final CkColorFilter ckColorFilter;

  @override
  SkColorFilter createDefault() => ckColorFilter._initRawColorFilter();

  @override
  SkColorFilter resurrect() => ckColorFilter._initRawColorFilter();

  @override
  void delete() {
    rawSkiaObject?.delete();
  }

  @override
  int get hashCode => ckColorFilter.hashCode;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType)
      return false;
    return other is _ManagedSkColorFilter
        && other.ckColorFilter == ckColorFilter;
  }

  @override
  String toString() => ckColorFilter.toString();
}

/// A [ui.ColorFilter] backed by Skia's [SkColorFilter].
///
/// Additionally, this class provides the interface for converting itself to a
/// [ManagedSkiaObject] that manages a skia image filter.
abstract class CkColorFilter implements _CkManagedSkImageFilterConvertible<SkImageFilter>, EngineColorFilter {
  const CkColorFilter();

  /// Called by [ManagedSkiaObject.createDefault] and
  /// [ManagedSkiaObject.resurrect] to create a new [SKImageFilter], when this
  /// filter is used as an [ImageFilter].
  SkImageFilter _initRawImageFilter() => canvasKit.ImageFilter.MakeColorFilter(_initRawColorFilter(), null);

  /// Called by [ManagedSkiaObject.createDefault] and
  /// [ManagedSkiaObject.resurrect] to create a new [SKColorFilter], when this
  /// filter is used as a [ColorFilter].
  SkColorFilter _initRawColorFilter();

  ManagedSkiaObject<SkImageFilter> get _imageFilter => _CkColorFilterImageFilter(colorFilter: this);
}

class _CkBlendModeColorFilter extends CkColorFilter {
  const _CkBlendModeColorFilter(this.color, this.blendMode);

  final ui.Color color;
  final ui.BlendMode blendMode;

  @override
  SkColorFilter _initRawColorFilter() {
    return canvasKit.ColorFilter.MakeBlend(
      toSharedSkColor1(color),
      toSkBlendMode(blendMode),
    );
  }

  @override
  int get hashCode => ui.hashValues(color, blendMode);

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType)
      return false;
    return other is _CkBlendModeColorFilter
        && other.color == color
        && other.blendMode == blendMode;
  }

  @override
  String toString() => 'ColorFilter.mode($color, $blendMode)';
}

class _CkMatrixColorFilter extends CkColorFilter {
  const _CkMatrixColorFilter(this.matrix);

  final List<double> matrix;

  @override
  SkColorFilter _initRawColorFilter() {
    assert(this.matrix.length == 20,  'Color Matrix must have 20 entries.');
    final List<double> matrix = this.matrix;
    if (matrix is Float32List)
      return canvasKit.ColorFilter.MakeMatrix(matrix);
    final Float32List float32Matrix = Float32List(20);
    for (int i = 0; i < 20; i++) {
      float32Matrix[i] = matrix[i];
    }
    return canvasKit.ColorFilter.MakeMatrix(float32Matrix);
  }

  @override
  int get hashCode => ui.hashList(matrix);

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType
      && other is _CkMatrixColorFilter
      && _listEquals<double>(matrix, other.matrix);
  }

  @override
  String toString() => 'ColorFilter.matrix($matrix)';
}

class _CkLinearToSrgbGammaColorFilter extends CkColorFilter {
  const _CkLinearToSrgbGammaColorFilter();
  @override
  SkColorFilter _initRawColorFilter() => canvasKit.ColorFilter.MakeLinearToSRGBGamma();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  String toString() => 'ColorFilter.linearToSrgbGamma()';
}

class _CkSrgbToLinearGammaColorFilter extends CkColorFilter {
  const _CkSrgbToLinearGammaColorFilter();
  @override
  SkColorFilter _initRawColorFilter() => canvasKit.ColorFilter.MakeSRGBToLinearGamma();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  String toString() => 'ColorFilter.srgbToLinearGamma()';
}
