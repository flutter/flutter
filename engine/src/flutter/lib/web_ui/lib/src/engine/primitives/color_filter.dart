// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

enum ColorFilterType { mode, matrix, linearToSrgbGamma, srgbToLinearGamma }

final Expando<BackendColorFilter> _backendColorFilters = Expando<BackendColorFilter>();

final Finalizer _colorFilterFinalizer = NativeMemoryFinalizer((Object filter) {
  (filter as BackendColorFilter).dispose();
});

/// A description of a color filter to apply when drawing a shape or compositing
/// a layer with a particular [Paint].
class EngineColorFilter implements LayerImageFilter, ui.ColorFilter {
  const EngineColorFilter.mode(ui.Color this.color, ui.BlendMode this.blendMode)
    : matrix = null,
      inner = null,
      outer = null,
      type = ColorFilterType.mode;

  const EngineColorFilter.matrix(List<double> this.matrix)
    : color = null,
      blendMode = null,
      inner = null,
      outer = null,
      type = ColorFilterType.matrix;

  const EngineColorFilter.linearToSrgbGamma()
    : color = null,
      blendMode = null,
      matrix = null,
      inner = null,
      outer = null,
      type = ColorFilterType.linearToSrgbGamma;

  const EngineColorFilter.srgbToLinearGamma()
    : color = null,
      blendMode = null,
      matrix = null,
      inner = null,
      outer = null,
      type = ColorFilterType.srgbToLinearGamma;

  factory EngineColorFilter.saturation(double saturation) {
    const rLuminance = 0.2126;
    const gLuminance = 0.7152;
    const bLuminance = 0.0722;
    final double invSat = 1 - saturation;

    return EngineColorFilter.matrix(<double>[
      // dart format off
      invSat * rLuminance + saturation, invSat * gLuminance,              invSat * bLuminance,              0, 0,
      invSat * rLuminance,              invSat * gLuminance + saturation, invSat * bLuminance,              0, 0,
      invSat * rLuminance,              invSat * gLuminance,              invSat * bLuminance + saturation, 0, 0,
      0,                                0,                                0,                                1, 0,
      // dart format on
    ]);
  }

  static const EngineColorFilter invert = EngineColorFilter.matrix(<double>[
    -1.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    -1.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    -1.0,
    1.0,
    0.0,
    1.0,
    1.0,
    1.0,
    1.0,
    0.0,
  ]);

  final ui.Color? color;
  final ui.BlendMode? blendMode;
  final List<double>? matrix;
  final EngineColorFilter? inner;
  final EngineColorFilter? outer;
  final ColorFilterType type;

  /// The backend implementation of this color filter.
  BackendColorFilter get backendFilter {
    BackendColorFilter? filter = _backendColorFilters[this];
    if (filter == null) {
      filter = renderer.createColorFilter(this);
      _backendColorFilters[this] = filter;
      _colorFilterFinalizer.attach(this, filter, detach: filter);
    }
    return filter;
  }

  @override
  ui.Rect filterBounds(ui.Rect inputBounds) => inputBounds;

  @override
  String get debugShortDescription => toString();

  @override
  String toString() {
    return switch (type) {
      ColorFilterType.mode => 'ColorFilter.mode($color, $blendMode)',
      ColorFilterType.matrix => 'ColorFilter.matrix($matrix)',
      ColorFilterType.linearToSrgbGamma => 'ColorFilter.linearToSrgbGamma()',
      ColorFilterType.srgbToLinearGamma => 'ColorFilter.srgbToLinearGamma()',
    };
  }

  @override
  Matrix4? get transform => null;

  @override
  bool operator ==(Object other) {
    if (other is! EngineColorFilter) {
      return false;
    }
    return other.type == type &&
        other.color == color &&
        other.blendMode == blendMode &&
        other.inner == inner &&
        other.outer == outer &&
        listEquals(other.matrix, matrix);
  }

  @override
  int get hashCode =>
      Object.hash(type, color, blendMode, inner, outer, Object.hashAll(matrix ?? const <double>[]));
}
