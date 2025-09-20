// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// A configuration for a [ui.ImageFilter].
///
/// This class is a framework-level representation of a filter that can be
/// applied to a backdrop. Unlike a [ui.ImageFilter], which is an engine-level
/// object, an [ImageFilterConfig] can be created at the widget level and later
/// resolved into a `ui.ImageFilter` at layout time, potentially using
//  layout-dependent information such as the widget's bounds.
///
/// See also:
///
///  * [BackdropFilter.filterConfig], which uses this class to configure its filter.
///  * [ui.ImageFilter], the engine-level class that this config resolves to.
@immutable
abstract class ImageFilterConfig {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ImageFilterConfig();

  factory ImageFilterConfig.filter(ui.ImageFilter filter) {
    return _DirectImageFilterConfig(filter);
  }

  /// Creates a configuration for a Gaussian blur.
  ///
  /// The `sigmaX` and `sigmaY` arguments are the standard deviation of the
  /// Gaussian kernel in the x and y directions, respectively.
  ///
  /// The `tileMode` argument determines how the blur should handle edges.
  ///
  /// If `alphaPremultiplied` is true, the blur will be an alpha-premultiplied
  /// blur, which is a blur that correctly handles transparent edges. This is
  /// often used to match iOS's native blur effect. When this is true, the
  /// [resolve] method will use the provided bounds to create a bounded blur.
  factory ImageFilterConfig.blur({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode tileMode = ui.TileMode.clamp,
    bool bounded = true,
  }) {
    return _BlurImageFilterConfig(
      sigmaX: sigmaX,
      sigmaY: sigmaY,
      tileMode: tileMode,
      bounded: bounded,
    );
  }

  /// Creates a configuration for a matrix transformation.
  ///
  /// The `matrix4` argument is the matrix to apply.
  /// The `filterQuality` argument is the quality of the filter.
  factory ImageFilterConfig.matrix(
    Matrix4 matrix4, {
    ui.FilterQuality filterQuality = ui.FilterQuality.low,
  }) {
    return ImageFilterConfig.filter(
      ui.ImageFilter.matrix(matrix4.storage, filterQuality: filterQuality),
    );
  }

  /// Creates a configuration for a composition of two filters.
  ///
  /// The `outer` filter is applied after the `inner` filter.
  factory ImageFilterConfig.compose({
    required ImageFilterConfig outer,
    required ImageFilterConfig inner,
  }) {
    return _ComposeImageFilterConfig(outer: outer, inner: inner);
  }

  /// Resolves this configuration into a [ui.ImageFilter], given the
  /// `bounds` of the widget applying the filter.
  ///
  /// The `bounds` can be used to create layout-dependent filters, such as
  /// a blur that is clipped to the widget's bounds.
  ui.ImageFilter resolve(ui.Rect bounds);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ImageFilterConfig;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

class _BlurImageFilterConfig extends ImageFilterConfig {
  const _BlurImageFilterConfig({
    this.sigmaX = 0.0,
    this.sigmaY = 0.0,
    this.tileMode = ui.TileMode.clamp,
    this.bounded = false,
  });

  final double sigmaX;
  final double sigmaY;
  final ui.TileMode tileMode;
  final bool bounded;

  @override
  ui.ImageFilter resolve(ui.Rect bounds) {
    return ui.ImageFilter.blur(
      sigmaX: sigmaX,
      sigmaY: sigmaY,
      tileMode: tileMode,
      bounds: bounded ? bounds : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _BlurImageFilterConfig &&
           other.sigmaX == sigmaX &&
           other.sigmaY == sigmaY &&
           other.tileMode == tileMode &&
           other.useObjectBounds == useObjectBounds;
  }

  @override
  int get hashCode => Object.hash(sigmaX, sigmaY, tileMode, useObjectBounds);
}

class _ComposeImageFilterConfig extends ImageFilterConfig {
  const _ComposeImageFilterConfig({required this.outer, required this.inner});

  final ImageFilterConfig outer;
  final ImageFilterConfig inner;

  @override
  ui.ImageFilter resolve(ui.Rect bounds) {
    return ui.ImageFilter.compose(
      outer: outer.resolve(bounds),
      inner: inner.resolve(bounds),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ComposeImageFilterConfig &&
           other.outer == outer &&
           other.inner == inner;
  }

  @override
  int get hashCode => Object.hash(outer, inner);
}

class _DirectImageFilterConfig extends ImageFilterConfig {
  const _DirectImageFilterConfig(this.filter);

  final ui.ImageFilter filter;

  @override
  ui.ImageFilter resolve(ui.Rect bounds) {
    return filter;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _DirectImageFilterConfig &&
           other.filter == filter;
  }

  @override
  int get hashCode => filter.hashCode;
}
