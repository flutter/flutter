// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// A configuration for a [ui.ImageFilter].
///
/// This class provides a framework-level abstraction for image filters that can
/// be applied to widgets or render objects. Unlike [ui.ImageFilter], which is an
/// engine-level object, [ImageFilterConfig] instances are created at the widget
/// or render object level and can be resolved into a [ui.ImageFilter] at layout
/// time, allowing them to incorporate layout-dependent information such as the
/// widget's bounds.
///
/// Most filters can be used via [ImageFilterConfig.filter]. The most notable
/// filter that requires this class is [ImageFilterConfig.blur] with the
/// `bounded` option set to true.
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

  /// Creates a configuration that directly uses the given filter.
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
  /// If `bounded` is true, the filter performs a "bounded blur". This means the
  /// blur kernel will only sample pixels from within the provided attached
  /// render object, treating all pixels outside of it as transparent. This
  /// mode is typically used to implement high-fidelity iOS-style blurs.
  factory ImageFilterConfig.blur({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode tileMode = ui.TileMode.clamp,
    bool bounded = false,
  }) {
    return _BlurImageFilterConfig(
      sigmaX: sigmaX,
      sigmaY: sigmaY,
      tileMode: tileMode,
      bounded: bounded,
    );
  }

  /// Composes the `inner` filter configuration with `outer`, to combine their
  /// effects.
  ///
  /// Creates a single [ImageFilterConfig] that when applied, has the same
  /// effect as subsequently applying `inner` and `outer`, i.e., result =
  /// outer(inner(source)).
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
           other.bounded == bounded;
  }

  @override
  int get hashCode => Object.hash(sigmaX, sigmaY, tileMode, bounded);
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
