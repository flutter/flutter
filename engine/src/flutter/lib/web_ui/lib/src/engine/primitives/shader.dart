// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

final Finalizer _shaderFinalizer = NativeMemoryFinalizer((Object shader) {
  (shader as BackendShader).dispose();
});

abstract class EngineShader implements ui.Shader {
  @override
  void dispose() {
    if (!_debugDisposed) {
      _debugDisposed = true;
      final BackendShader? cached = cachedBackendShader;
      if (cached != null) {
        _shaderFinalizer.detach(cached);
        cached.dispose();
      }
    }
  }

  @override
  bool get debugDisposed => _debugDisposed;
  bool _debugDisposed = false;

  BackendShader getBackendShader(ui.FilterQuality contextualQuality) => backendShader;
  BackendShader get backendShader;

  /// Returns the cached backend shader without creating it, or null if it
  /// hasn't been created yet.
  BackendShader? get cachedBackendShader;

  BackendShader _cacheAndAttach(BackendShader shader) {
    _shaderFinalizer.attach(this, shader, detach: shader);
    return shader;
  }
}

abstract class EngineGradient extends EngineShader implements ui.Gradient {
  EngineGradient._();

  factory EngineGradient.linear(
    ui.Offset from,
    ui.Offset to,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode,
    Float32List? matrix4,
  ]) = EngineLinearGradient;

  factory EngineGradient.radial(
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode,
    Float32List? matrix4,
    ui.Offset? focal,
    double focalRadius,
  ]) = EngineRadialGradient;

  factory EngineGradient.sweep(
    ui.Offset center,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode,
    double startAngle,
    double endAngle,
    Float32List? matrix4,
  ]) = EngineSweepGradient;

  @override
  String toString() => 'Gradient()';
}

class EngineLinearGradient extends EngineGradient {
  EngineLinearGradient(
    this.from,
    this.to,
    this.colors, [
    this.colorStops,
    this.tileMode = ui.TileMode.clamp,
    this.matrix4,
  ]) : assert(_offsetIsValid(from)),
       assert(_offsetIsValid(to)),
       assert(matrix4 == null || _matrix4IsValid(matrix4)),
       super._();

  final ui.Offset from;
  final ui.Offset to;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  BackendShader? _backendShader;

  @override
  BackendShader? get cachedBackendShader => _backendShader;

  @override
  BackendShader get backendShader {
    if (_backendShader == null) {
      final endPoints = Float32List(4)
        ..[0] = from.dx
        ..[1] = from.dy
        ..[2] = to.dx
        ..[3] = to.dy;
      final Uint32List colorsList = _encodeColors(colors);
      final Float32List? stopsList = colorStops != null ? Float32List.fromList(colorStops!) : null;

      _backendShader = _cacheAndAttach(
        renderer.createGradientLinear(endPoints, colorsList, stopsList, tileMode, matrix4),
      );
    }
    return _backendShader!;
  }
}

class EngineRadialGradient extends EngineGradient {
  EngineRadialGradient(
    this.center,
    this.radius,
    this.colors, [
    this.colorStops,
    this.tileMode = ui.TileMode.clamp,
    this.matrix4,
    this.focal,
    this.focalRadius = 0.0,
  ]) : assert(_offsetIsValid(center)),
       assert(matrix4 == null || _matrix4IsValid(matrix4)),
       assert(
         focal == null ||
             (focal == center && focalRadius == 0.0) ||
             center != ui.Offset.zero ||
             focal != ui.Offset.zero,
       ),
       super._();

  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;
  final ui.Offset? focal;
  final double focalRadius;

  BackendShader? _backendShader;

  @override
  BackendShader? get cachedBackendShader => _backendShader;

  @override
  BackendShader get backendShader {
    if (_backendShader == null) {
      final Uint32List colorsList = _encodeColors(colors);
      final Float32List? stopsList = colorStops != null ? Float32List.fromList(colorStops!) : null;

      if (focal == null || (focal == center && focalRadius == 0.0)) {
        _backendShader = _cacheAndAttach(
          renderer.createGradientRadial(
            center.dx,
            center.dy,
            radius,
            colorsList,
            stopsList,
            tileMode,
            matrix4,
          ),
        );
      } else {
        assert(
          center != ui.Offset.zero || focal != ui.Offset.zero,
        ); // will result in exception(s) in Skia side
        _backendShader = _cacheAndAttach(
          renderer.createGradientConical(
            focal!.dx,
            focal!.dy,
            focalRadius,
            center.dx,
            center.dy,
            radius,
            colorsList,
            stopsList,
            tileMode,
            matrix4,
          ),
        );
      }
    }
    return _backendShader!;
  }
}

class EngineSweepGradient extends EngineGradient {
  EngineSweepGradient(
    this.center,
    this.colors, [
    this.colorStops,
    this.tileMode = ui.TileMode.clamp,
    this.startAngle = 0.0,
    this.endAngle = math.pi * 2,
    this.matrix4,
  ]) : assert(_offsetIsValid(center)),
       assert(startAngle < endAngle),
       assert(matrix4 == null || _matrix4IsValid(matrix4)),
       super._();

  final ui.Offset center;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final double startAngle;
  final double endAngle;
  final Float32List? matrix4;

  BackendShader? _backendShader;

  @override
  BackendShader? get cachedBackendShader => _backendShader;

  @override
  BackendShader get backendShader {
    if (_backendShader == null) {
      final Uint32List colorsList = _encodeColors(colors);
      final Float32List? stopsList = colorStops != null ? Float32List.fromList(colorStops!) : null;

      _backendShader = _cacheAndAttach(
        renderer.createGradientSweep(
          center.dx,
          center.dy,
          colorsList,
          stopsList,
          tileMode,
          startAngle,
          endAngle,
          matrix4,
        ),
      );
    }
    return _backendShader!;
  }
}

Uint32List _encodeColors(List<ui.Color> colors) {
  final result = Uint32List(colors.length);
  for (var i = 0; i < colors.length; i++) {
    result[i] = colors[i].value;
  }
  return result;
}

bool _offsetIsValid(ui.Offset offset) {
  assert(!offset.dx.isNaN && !offset.dy.isNaN, 'Offset argument contained a NaN value.');
  return true;
}

bool _matrix4IsValid(Float32List matrix4) {
  assert(matrix4.length == 16, 'Matrix4 must have 16 entries.');
  assert(matrix4.every((double value) => value.isFinite), 'Matrix4 entries must be finite.');
  return true;
}

class EngineImageShader extends EngineShader implements ui.ImageShader {
  EngineImageShader(ui.Image image, this.tmx, this.tmy, this.matrix4, {this.filterQuality})
    : assert(!image.debugDisposed),
      image = image.clone() {
    if (matrix4 != null && matrix4!.length != 16) {
      throw ArgumentError('"matrix4" must have 16 entries.');
    }
  }

  final ui.Image image;
  final ui.TileMode tmx;
  final ui.TileMode tmy;
  final Float64List? matrix4;
  final ui.FilterQuality? filterQuality;

  ui.FilterQuality? _cachedFilterQuality;
  BackendShader? _backendShader;

  @override
  BackendShader? get cachedBackendShader => _backendShader;

  /// Returns the underlying native shader delegate.
  ///
  /// The [contextualQuality] is provided by the [ui.Paint] object that this shader
  /// is being used with. It is necessary because [ui.ImageShader] can be constructed
  /// with a null `filterQuality`, in which case it dynamically inherits the quality
  /// of the paint. If the quality changes, the backend shader must be recreated.
  @override
  BackendShader getBackendShader(ui.FilterQuality contextualQuality) {
    final ui.FilterQuality qualityToUse = filterQuality ?? contextualQuality;
    if (_backendShader == null || _cachedFilterQuality != qualityToUse) {
      if (_backendShader != null) {
        _shaderFinalizer.detach(_backendShader!);
        _backendShader!.dispose();
      }
      _cachedFilterQuality = qualityToUse;
      _backendShader = _cacheAndAttach(
        renderer.createImageShader(image as EngineImage, tmx, tmy, matrix4, qualityToUse),
      );
    }
    return _backendShader!;
  }

  @override
  BackendShader get backendShader => getBackendShader(ui.FilterQuality.none);

  @override
  void dispose() {
    final bool isFirstDispose = !_debugDisposed;
    super.dispose();
    if (isFirstDispose) {
      image.dispose();
    }
  }
}

class EngineFragmentShader extends EngineShader implements ui.FragmentShader {
  EngineFragmentShader(BackendFragmentShader delegate) {
    _backendShader = _cacheAndAttach(delegate) as BackendFragmentShader;
  }

  late final BackendFragmentShader _backendShader;
  final Map<int, BackendImageShader> _imageSamplers = <int, BackendImageShader>{};

  @visibleForTesting
  Map<int, BackendImageShader> get debugImageSamplers => _imageSamplers;

  @override
  BackendShader get backendShader => _backendShader;

  @override
  BackendShader? get cachedBackendShader => _backendShader;

  @override
  void setFloat(int index, double value) {
    assert(!debugDisposed, 'Tried to access uniforms on a disposed Shader: $this');
    _backendShader.setFloat(index, value);
  }

  @override
  void setImageSampler(
    int index,
    ui.Image image, {
    ui.FilterQuality filterQuality = ui.FilterQuality.none,
  }) {
    assert(!debugDisposed, 'Tried to access uniforms on a disposed Shader: $this');
    final BackendImageShader sampler = renderer.createImageShader(
      image as EngineImage,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      null,
      filterQuality,
    );
    final BackendImageShader? oldSampler = _imageSamplers[index];
    if (oldSampler != null) {
      _shaderFinalizer.detach(oldSampler);
      oldSampler.dispose();
    }
    _imageSamplers[index] = sampler;
    _shaderFinalizer.attach(this, sampler, detach: sampler);
    _backendShader.setImageSampler(index, sampler, image.width.toDouble(), image.height.toDouble());
  }

  @override
  void dispose() {
    final bool isFirstDispose = !_debugDisposed;
    // super.dispose() disposes and detaches the cached backend shader.
    super.dispose();
    if (isFirstDispose) {
      for (final BackendImageShader sampler in _imageSamplers.values) {
        _shaderFinalizer.detach(sampler);
        sampler.dispose();
      }
      _imageSamplers.clear();
    }
  }

  @override
  ui.UniformFloatSlot getUniformFloat(String name, [int? index]) =>
      _backendShader.getUniformFloat(name, index);
  @override
  ui.UniformVec2Slot getUniformVec2(String name) => _backendShader.getUniformVec2(name);
  @override
  ui.UniformVec3Slot getUniformVec3(String name) => _backendShader.getUniformVec3(name);
  @override
  ui.UniformVec4Slot getUniformVec4(String name) => _backendShader.getUniformVec4(name);
  @override
  ui.UniformMat2Slot getUniformMat2(String name) => _backendShader.getUniformMat2(name);
  @override
  ui.UniformMat3Slot getUniformMat3(String name) => _backendShader.getUniformMat3(name);
  @override
  ui.UniformMat4Slot getUniformMat4(String name) => _backendShader.getUniformMat4(name);
  @override
  ui.ImageSamplerSlot getImageSampler(String name) => _backendShader.getImageSampler(name);
  @override
  ui.UniformArray<ui.UniformFloatSlot> getUniformFloatArray(String name) =>
      _backendShader.getUniformFloatArray(name);
  @override
  ui.UniformArray<ui.UniformVec2Slot> getUniformVec2Array(String name) =>
      _backendShader.getUniformVec2Array(name);
  @override
  ui.UniformArray<ui.UniformVec3Slot> getUniformVec3Array(String name) =>
      _backendShader.getUniformVec3Array(name);
  @override
  ui.UniformArray<ui.UniformVec4Slot> getUniformVec4Array(String name) =>
      _backendShader.getUniformVec4Array(name);
  @override
  ui.UniformArray<ui.UniformMat2Slot> getUniformMat2Array(String name) =>
      _backendShader.getUniformMat2Array(name);
  @override
  ui.UniformArray<ui.UniformMat3Slot> getUniformMat3Array(String name) =>
      _backendShader.getUniformMat3Array(name);
  @override
  ui.UniformArray<ui.UniformMat4Slot> getUniformMat4Array(String name) =>
      _backendShader.getUniformMat4Array(name);
}
