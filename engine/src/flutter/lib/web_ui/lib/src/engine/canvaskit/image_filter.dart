// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// An [ImageFilter] that can create a managed skia [SkImageFilter] object.
///
/// Concrete subclasses of this interface must provide efficient implementation
/// of [operator==], to avoid re-creating the underlying skia filters
/// whenever possible.
///
/// Currently implemented by [CkImageFilter] and [CkColorFilter].
abstract class _CkManagedSkImageFilterConvertible<T extends Object> implements ui.ImageFilter {
  ManagedSkiaObject<SkImageFilter> get _imageFilter;
}

/// The CanvasKit implementation of [ui.ImageFilter].
///
/// Currently only supports `blur`.
abstract class CkImageFilter extends ManagedSkiaObject<SkImageFilter> implements _CkManagedSkImageFilterConvertible<SkImageFilter> {
  factory CkImageFilter.blur({ required double sigmaX, required double sigmaY }) = _CkBlurImageFilter;
  factory CkImageFilter.color({ required CkColorFilter colorFilter }) = _CkColorFilterImageFilter;

  CkImageFilter._();

  @override
  ManagedSkiaObject<SkImageFilter> get _imageFilter => this;

  SkImageFilter _initSkiaObject();

  @override
  SkImageFilter createDefault() => _initSkiaObject();

  @override
  SkImageFilter resurrect() => _initSkiaObject();

  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}

class _CkColorFilterImageFilter extends CkImageFilter {
  _CkColorFilterImageFilter({ required this.colorFilter }) : super._();

  final CkColorFilter colorFilter;

  @override
  SkImageFilter _initSkiaObject() => colorFilter._initRawImageFilter();

  @override
  int get hashCode => colorFilter.hashCode;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType)
      return false;
    return other is _CkColorFilterImageFilter
        && other.colorFilter == colorFilter;
  }

  @override
  String toString() => colorFilter.toString();
}

class _CkBlurImageFilter extends CkImageFilter {
  _CkBlurImageFilter({ required this.sigmaX, required this.sigmaY }) : super._();

  final double sigmaX;
  final double sigmaY;

  @override
  SkImageFilter _initSkiaObject() {
    return canvasKit.ImageFilter.MakeBlur(
      sigmaX,
      sigmaY,
      canvasKit.TileMode.Clamp,
      null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType)
      return false;
    return other is _CkBlurImageFilter
        && other.sigmaX == sigmaX
        && other.sigmaY == sigmaY;
  }

  @override
  int get hashCode => ui.hashValues(sigmaX, sigmaY);

  @override
  String toString() {
    return 'ImageFilter.blur($sigmaX, $sigmaY)';
  }
}

