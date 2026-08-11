// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

final Finalizer _imageFilterFinalizer = NativeMemoryFinalizer((Object filter) {
  (filter as BackendImageFilter).dispose();
});

/// A shared engine representation of an [ImageFilter].
abstract class EngineImageFilter implements ui.ImageFilter {
  EngineImageFilter();

  factory EngineImageFilter.blur({
    required double sigmaX,
    required double sigmaY,
    required ui.TileMode? tileMode,
  }) = EngineBlurImageFilter;

  factory EngineImageFilter.color({required EngineColorFilter colorFilter}) =
      EngineColorFilterImageFilter;

  factory EngineImageFilter.matrix({
    required Float64List matrix,
    required ui.FilterQuality filterQuality,
  }) = EngineMatrixImageFilter;

  factory EngineImageFilter.dilate({required double radiusX, required double radiusY}) =
      EngineDilateImageFilter;

  factory EngineImageFilter.erode({required double radiusX, required double radiusY}) =
      EngineErodeImageFilter;

  factory EngineImageFilter.compose({
    required EngineImageFilter outer,
    required EngineImageFilter inner,
  }) = EngineComposeImageFilter;

  /// Attaches the native backend object to this Dart object's finalizer.
  BackendImageFilter _cacheAndAttach(BackendImageFilter filter) {
    _imageFilterFinalizer.attach(this, filter, detach: filter);
    return filter;
  }

  /// Returns the backend implementation of this image filter.
  ///
  /// Since an [ui.ImageFilter] can be reused in different contexts (like a
  /// BackdropFilter, which implicitly defaults to `TileMode.mirror`, versus a
  /// normal ImageFilter which defaults to `TileMode.clamp`), this method allows
  /// the caller to inject the [defaultBlurTileMode] context. The engine can
  /// dynamically cache the backend implementation tailored for that context.
  BackendImageFilter getBackendFilter({required ui.TileMode defaultBlurTileMode});

  /// The native tile mode to be applied when the filter is used as a backdrop filter.
  ui.TileMode? get backdropTileMode => null;

  Matrix4 get transform => Matrix4.identity();

  ui.Rect filterBounds(ui.Rect inputBounds) =>
      getBackendFilter(defaultBlurTileMode: ui.TileMode.decal).filterBounds(inputBounds);

  @override
  String get debugShortDescription => toString();

  @override
  String toString() => 'ImageFilter.$debugShortDescription';
}

class EngineColorFilterImageFilter extends EngineImageFilter {
  EngineColorFilterImageFilter({required this.colorFilter});

  final EngineColorFilter colorFilter;

  BackendImageFilter? _cachedFilter;

  @override
  BackendImageFilter getBackendFilter({required ui.TileMode defaultBlurTileMode}) {
    return _cachedFilter ??= _cacheAndAttach(
      renderer.createColorFilterImageFilter(filter: colorFilter.backendFilter),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EngineColorFilterImageFilter && other.colorFilter == colorFilter;
  }

  @override
  int get hashCode => colorFilter.hashCode;

  @override
  String get debugShortDescription => colorFilter.toString();
}

class EngineBlurImageFilter extends EngineImageFilter {
  EngineBlurImageFilter({required this.sigmaX, required this.sigmaY, required this.tileMode});

  final double sigmaX;
  final double sigmaY;
  final ui.TileMode? tileMode;

  BackendImageFilter? _cachedFilter;
  ui.TileMode? _cachedTileMode;

  @override
  BackendImageFilter getBackendFilter({required ui.TileMode defaultBlurTileMode}) {
    if (sigmaX == 0 && sigmaY == 0) {
      return _cachedFilter ??= _cacheAndAttach(
        renderer.createMatrixImageFilter(
          matrix: Matrix4.identity().toFloat64(),
          filterQuality: ui.FilterQuality.none,
        ),
      );
    }

    final ui.TileMode mode = tileMode ?? defaultBlurTileMode;
    if (_cachedFilter != null && _cachedTileMode == mode) {
      return _cachedFilter!;
    }

    if (_cachedFilter != null) {
      _imageFilterFinalizer.detach(_cachedFilter!);
      _cachedFilter!.dispose();
    }

    _cachedTileMode = mode;
    return _cachedFilter = _cacheAndAttach(
      renderer.createBlurImageFilter(sigmaX: sigmaX, sigmaY: sigmaY, tileMode: mode),
    );
  }

  @override
  ui.TileMode? get backdropTileMode => tileMode;

  @override
  bool operator ==(Object other) {
    return other is EngineBlurImageFilter &&
        other.sigmaX == sigmaX &&
        other.sigmaY == sigmaY &&
        other.tileMode == tileMode;
  }

  @override
  int get hashCode => Object.hash(sigmaX, sigmaY, tileMode);

  @override
  String get debugShortDescription => 'blur($sigmaX, $sigmaY, ${tileModeString(tileMode)})';
}

class EngineMatrixImageFilter extends EngineImageFilter {
  EngineMatrixImageFilter({required Float64List matrix, required this.filterQuality})
    : matrix = Float64List.fromList(matrix),
      _transform = Matrix4.fromFloat32List(toMatrix32(matrix));

  final Float64List matrix;
  final ui.FilterQuality filterQuality;
  final Matrix4 _transform;

  BackendImageFilter? _cachedFilter;

  @override
  BackendImageFilter getBackendFilter({required ui.TileMode defaultBlurTileMode}) {
    return _cachedFilter ??= _cacheAndAttach(
      renderer.createMatrixImageFilter(matrix: matrix, filterQuality: filterQuality),
    );
  }

  @override
  Matrix4 get transform => _transform;

  @override
  bool operator ==(Object other) {
    return other is EngineMatrixImageFilter &&
        other.filterQuality == filterQuality &&
        listEquals<double>(other.matrix, matrix);
  }

  @override
  int get hashCode => Object.hash(filterQuality, Object.hashAll(matrix));

  @override
  String get debugShortDescription => 'matrix($matrix, $filterQuality)';
}

class EngineDilateImageFilter extends EngineImageFilter {
  EngineDilateImageFilter({required this.radiusX, required this.radiusY});

  final double radiusX;
  final double radiusY;

  BackendImageFilter? _cachedFilter;

  @override
  BackendImageFilter getBackendFilter({required ui.TileMode defaultBlurTileMode}) {
    return _cachedFilter ??= _cacheAndAttach(
      renderer.createDilateImageFilter(radiusX: radiusX, radiusY: radiusY),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EngineDilateImageFilter && other.radiusX == radiusX && other.radiusY == radiusY;
  }

  @override
  int get hashCode => Object.hash(radiusX, radiusY);

  @override
  String get debugShortDescription => 'dilate($radiusX, $radiusY)';
}

class EngineErodeImageFilter extends EngineImageFilter {
  EngineErodeImageFilter({required this.radiusX, required this.radiusY});

  final double radiusX;
  final double radiusY;

  BackendImageFilter? _cachedFilter;

  @override
  BackendImageFilter getBackendFilter({required ui.TileMode defaultBlurTileMode}) {
    return _cachedFilter ??= _cacheAndAttach(
      renderer.createErodeImageFilter(radiusX: radiusX, radiusY: radiusY),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EngineErodeImageFilter && other.radiusX == radiusX && other.radiusY == radiusY;
  }

  @override
  int get hashCode => Object.hash(radiusX, radiusY);

  @override
  String get debugShortDescription => 'erode($radiusX, $radiusY)';
}

class EngineComposeImageFilter extends EngineImageFilter {
  EngineComposeImageFilter({required this.outer, required this.inner});

  final EngineImageFilter outer;
  final EngineImageFilter inner;

  BackendImageFilter? _cachedFilter;
  ui.TileMode? _cachedTileMode;

  @override
  BackendImageFilter getBackendFilter({required ui.TileMode defaultBlurTileMode}) {
    if (_cachedFilter != null && _cachedTileMode == defaultBlurTileMode) {
      return _cachedFilter!;
    }

    if (_cachedFilter != null) {
      _imageFilterFinalizer.detach(_cachedFilter!);
      _cachedFilter!.dispose();
    }

    final BackendImageFilter outerBackend = outer.getBackendFilter(
      defaultBlurTileMode: defaultBlurTileMode,
    );
    final BackendImageFilter innerBackend = inner.getBackendFilter(
      defaultBlurTileMode: defaultBlurTileMode,
    );

    _cachedTileMode = defaultBlurTileMode;
    return _cachedFilter = _cacheAndAttach(
      renderer.createComposeImageFilter(outer: outerBackend, inner: innerBackend),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EngineComposeImageFilter && other.outer == outer && other.inner == inner;
  }

  @override
  int get hashCode => Object.hash(outer, inner);

  @override
  String get debugShortDescription =>
      '${inner.debugShortDescription} -> ${outer.debugShortDescription}';

  @override
  String toString() => 'ImageFilter.compose(source -> $debugShortDescription -> result)';
}
