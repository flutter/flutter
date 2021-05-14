// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'canvaskit_api.dart';
import 'color_filter.dart';
import 'skia_object_cache.dart';

/// An [ImageFilter] that can create a managed skia [SkImageFilter] object.
///
/// Concrete subclasses of this interface must provide efficient implementation
/// of [operator==], to avoid re-creating the underlying skia filters
/// whenever possible.
///
/// Currently implemented by [CkImageFilter] and [CkColorFilter].
abstract class CkManagedSkImageFilterConvertible<T extends Object>
    implements ui.ImageFilter {
  ManagedSkiaObject<SkImageFilter> get imageFilter;
}

/// The CanvasKit implementation of [ui.ImageFilter].
///
/// Currently only supports `blur`.
abstract class CkImageFilter extends ManagedSkiaObject<SkImageFilter>
    implements CkManagedSkImageFilterConvertible<SkImageFilter> {
  factory CkImageFilter.blur(
      {required double sigmaX,
      required double sigmaY,
      required ui.TileMode tileMode}) = _CkBlurImageFilter;
  factory CkImageFilter.color({required CkColorFilter colorFilter}) =
      CkColorFilterImageFilter;

  CkImageFilter._();

  @override
  ManagedSkiaObject<SkImageFilter> get imageFilter => this;

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

class CkColorFilterImageFilter extends CkImageFilter {
  CkColorFilterImageFilter({required this.colorFilter}) : super._();

  final CkColorFilter colorFilter;

  @override
  SkImageFilter _initSkiaObject() => colorFilter.initRawImageFilter();

  @override
  int get hashCode => colorFilter.hashCode;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is CkColorFilterImageFilter &&
        other.colorFilter == colorFilter;
  }

  @override
  String toString() => colorFilter.toString();
}

class _CkBlurImageFilter extends CkImageFilter {
  _CkBlurImageFilter(
      {required this.sigmaX, required this.sigmaY, required this.tileMode})
      : super._();

  final double sigmaX;
  final double sigmaY;
  final ui.TileMode tileMode;

  String get _modeString {
    switch (tileMode) {
      case ui.TileMode.clamp:
        return 'clamp';
      case ui.TileMode.mirror:
        return 'mirror';
      case ui.TileMode.repeated:
        return 'repeated';
      case ui.TileMode.decal:
        return 'decal';
    }
  }

  @override
  SkImageFilter _initSkiaObject() {
    return canvasKit.ImageFilter.MakeBlur(
      sigmaX,
      sigmaY,
      toSkTileMode(tileMode),
      null,
    );
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
  int get hashCode => ui.hashValues(sigmaX, sigmaY, tileMode);

  @override
  String toString() {
    return 'ImageFilter.blur($sigmaX, $sigmaY, $_modeString)';
  }
}
