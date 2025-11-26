// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

typedef SkImageFilterBorrow = void Function(SkImageFilter);

/// An [ImageFilter] that can create a managed skia [SkImageFilter] object.
///
/// Concrete subclasses of this interface must provide efficient implementation
/// of [operator==], to avoid re-creating the underlying skia filters
/// whenever possible.
///
/// Currently implemented by [CkImageFilter] and [CkColorFilter].
abstract class CkManagedSkImageFilterConvertible implements ui.ImageFilter {
  /// Creates a temporary [SkImageFilter], passes it to [borrow], and then
  /// immediately deletes it.
  ///
  /// If (and only if) the filter is a blur ImageFilter, then the indicated
  /// [defaultBlurTileMode] is used in place of a missing (null) tile mode.
  ///
  /// [SkImageFilter] objects are not kept around so that their memory is
  /// reclaimed immediately, rather than waiting for the GC cycle.
  void withSkImageFilter(
    SkImageFilterBorrow borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  });

  ui.TileMode? get backdropTileMode;

  Matrix4 get transform;
}

/// The CanvasKit implementation of [ui.ImageFilter].
///
/// Currently only supports `blur`, `matrix`, and ColorFilters.
abstract class CkImageFilter implements CkManagedSkImageFilterConvertible, LayerImageFilter {
  factory CkImageFilter.blur({
    required double sigmaX,
    required double sigmaY,
    required ui.TileMode? tileMode,
  }) = _CkBlurImageFilter;
  factory CkImageFilter.color({required CkColorFilter colorFilter}) = CkColorFilterImageFilter;
  factory CkImageFilter.matrix({
    required Float64List matrix,
    required ui.FilterQuality filterQuality,
  }) = _CkMatrixImageFilter;
  factory CkImageFilter.dilate({required double radiusX, required double radiusY}) =
      _CkDilateImageFilter;
  factory CkImageFilter.erode({required double radiusX, required double radiusY}) =
      _CkErodeImageFilter;
  factory CkImageFilter.compose({required CkImageFilter outer, required CkImageFilter inner}) =
      _CkComposeImageFilter;

  CkImageFilter._();

  /// Returns the identity matrix image filter.
  /// This is used to replicate effect of applying no filter.
  static SkImageFilter _createIdentityMatrixFilter() {
    return canvasKit.ImageFilter.MakeMatrixTransform(
      toSkMatrixFromFloat32(Matrix4.identity().storage),
      toSkFilterOptions(ui.FilterQuality.none),
      null,
    );
  }

  // The blur ImageFilter will override this and return the necessary
  // value to hand to the saveLayer call. It is the only filter type that
  // needs to pass along a tile mode so we just return a default value of
  // clamp for all other image filters.
  @override
  ui.TileMode? get backdropTileMode => ui.TileMode.clamp;

  @override
  Matrix4 get transform => Matrix4.identity();

  @override
  ui.Rect filterBounds(ui.Rect input) {
    late ui.Rect result;
    withSkImageFilter((SkImageFilter filter) {
      result = rectFromSkIRect(filter.getOutputBounds(toSkRect(input)));
    }, defaultBlurTileMode: ui.TileMode.decal);
    return result;
  }
}

class CkColorFilterImageFilter extends CkImageFilter {
  CkColorFilterImageFilter({required this.colorFilter}) : super._();

  final CkColorFilter colorFilter;

  @override
  void withSkImageFilter(
    SkImageFilterBorrow borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    final SkImageFilter skImageFilter = colorFilter.initRawImageFilter();
    borrow(skImageFilter);
    skImageFilter.delete();
  }

  @override
  int get hashCode => colorFilter.hashCode;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is CkColorFilterImageFilter && other.colorFilter == colorFilter;
  }

  @override
  String toString() => colorFilter.toString();
}

class _CkBlurImageFilter extends CkImageFilter {
  _CkBlurImageFilter({required this.sigmaX, required this.sigmaY, required this.tileMode})
    : super._();

  final double sigmaX;
  final double sigmaY;
  final ui.TileMode? tileMode;

  @override
  ui.TileMode? get backdropTileMode => tileMode;

  @override
  void withSkImageFilter(
    SkImageFilterBorrow borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    /// Returns the identity matrix filter when both sigmaX and sigmaY are 0.
    final SkImageFilter skImageFilter;
    if (sigmaX == 0 && sigmaY == 0) {
      skImageFilter = CkImageFilter._createIdentityMatrixFilter();
    } else {
      skImageFilter = canvasKit.ImageFilter.MakeBlur(
        sigmaX,
        sigmaY,
        toSkTileMode(tileMode ?? defaultBlurTileMode),
        null,
      );
    }

    borrow(skImageFilter);
    skImageFilter.delete();
  }

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is _CkBlurImageFilter &&
        other.sigmaX == sigmaX &&
        other.sigmaY == sigmaY &&
        other.tileMode == tileMode;
  }

  @override
  int get hashCode => Object.hash(sigmaX, sigmaY, tileMode);

  @override
  String toString() {
    return 'ImageFilter.blur($sigmaX, $sigmaY, ${tileModeString(tileMode)})';
  }
}

class _CkMatrixImageFilter extends CkImageFilter {
  _CkMatrixImageFilter({required Float64List matrix, required this.filterQuality})
    : matrix = Float64List.fromList(matrix),
      _transform = Matrix4.fromFloat32List(toMatrix32(matrix)),
      super._();

  final Float64List matrix;
  final ui.FilterQuality filterQuality;
  final Matrix4 _transform;

  @override
  void withSkImageFilter(
    SkImageFilterBorrow borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    final SkImageFilter skImageFilter = canvasKit.ImageFilter.MakeMatrixTransform(
      toSkMatrixFromFloat64(matrix),
      toSkFilterOptions(filterQuality),
      null,
    );
    borrow(skImageFilter);
    skImageFilter.delete();
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _CkMatrixImageFilter &&
        other.filterQuality == filterQuality &&
        listEquals<double>(other.matrix, matrix);
  }

  @override
  int get hashCode => Object.hash(filterQuality, Object.hashAll(matrix));

  @override
  String toString() => 'ImageFilter.matrix($matrix, $filterQuality)';

  @override
  Matrix4 get transform => _transform;
}

class _CkDilateImageFilter extends CkImageFilter {
  _CkDilateImageFilter({required this.radiusX, required this.radiusY}) : super._();

  final double radiusX;
  final double radiusY;

  @override
  void withSkImageFilter(
    SkImageFilterBorrow borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    // Returns the identity matrix filter when both radiusX and radiusY are 0.
    final SkImageFilter skImageFilter;
    if (radiusX == 0 && radiusY == 0) {
      skImageFilter = CkImageFilter._createIdentityMatrixFilter();
    } else {
      skImageFilter = canvasKit.ImageFilter.MakeDilate(radiusX, radiusY, null);
    }

    borrow(skImageFilter);
    skImageFilter.delete();
  }

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is _CkDilateImageFilter && other.radiusX == radiusX && other.radiusY == radiusY;
  }

  @override
  int get hashCode => Object.hash(radiusX, radiusY);

  @override
  String toString() {
    return 'ImageFilter.dilate($radiusX, $radiusY)';
  }
}

class _CkErodeImageFilter extends CkImageFilter {
  _CkErodeImageFilter({required this.radiusX, required this.radiusY}) : super._();

  final double radiusX;
  final double radiusY;

  @override
  void withSkImageFilter(
    SkImageFilterBorrow borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    // Returns the identity matrix filter when both radiusX and radiusY are 0.
    final SkImageFilter skImageFilter;
    if (radiusX == 0 && radiusY == 0) {
      skImageFilter = CkImageFilter._createIdentityMatrixFilter();
    } else {
      skImageFilter = canvasKit.ImageFilter.MakeErode(radiusX, radiusY, null);
    }

    borrow(skImageFilter);
    skImageFilter.delete();
  }

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is _CkErodeImageFilter && other.radiusX == radiusX && other.radiusY == radiusY;
  }

  @override
  int get hashCode => Object.hash(radiusX, radiusY);

  @override
  String toString() {
    return 'ImageFilter.erode($radiusX, $radiusY)';
  }
}

class _CkComposeImageFilter extends CkImageFilter {
  _CkComposeImageFilter({required this.outer, required this.inner}) : super._();

  final CkImageFilter outer;
  final CkImageFilter inner;

  @override
  void withSkImageFilter(
    SkImageFilterBorrow borrow, {
    ui.TileMode defaultBlurTileMode = ui.TileMode.clamp,
  }) {
    outer.withSkImageFilter((skOuter) {
      inner.withSkImageFilter((skInner) {
        final SkImageFilter skImageFilter = canvasKit.ImageFilter.MakeCompose(skOuter, skInner);
        borrow(skImageFilter);
        skImageFilter.delete();
      }, defaultBlurTileMode: defaultBlurTileMode);
    }, defaultBlurTileMode: defaultBlurTileMode);
  }

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is _CkComposeImageFilter && other.outer == outer && other.inner == inner;
  }

  @override
  int get hashCode => Object.hash(outer, inner);

  @override
  String toString() {
    return 'ImageFilter.compose($outer, $inner)';
  }
}
