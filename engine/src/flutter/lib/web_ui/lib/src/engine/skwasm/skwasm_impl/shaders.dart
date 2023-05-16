// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

abstract class SkwasmShader implements ui.Shader {
  ShaderHandle get handle;

  @override
  bool get debugDisposed => handle == nullptr;

  @override
  void dispose() {
    if (handle != nullptr) {
      shaderDispose(handle);
    }
  }
}

class SkwasmGradient extends SkwasmShader implements ui.Gradient {
  factory SkwasmGradient.linear({
    required ui.Offset from,
    required ui.Offset to,
    required List<ui.Color> colors,
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  }) => withStackScope((StackScope scope) {
    final RawPointArray endPoints =
      scope.convertPointArrayToNative(<ui.Offset>[from, to]);
    final RawColorArray nativeColors = scope.convertColorArrayToNative(colors);
    final Pointer<Float> stops = colorStops != null
      ? scope.convertDoublesToNative(colorStops)
      : nullptr;
    final Pointer<Float> matrix = matrix4 != null
      ? scope.convertMatrix4toSkMatrix(matrix4)
      : nullptr;
    final ShaderHandle handle = shaderCreateLinearGradient(
      endPoints,
      nativeColors,
      stops,
      colors.length,
      tileMode.index,
      matrix
    );
    return SkwasmGradient._(handle);
  });

  factory SkwasmGradient.radial({
    required ui.Offset center,
    required double radius,
    required List<ui.Color> colors,
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  }) => withStackScope((StackScope scope) {
    final RawColorArray rawColors = scope.convertColorArrayToNative(colors);
    final Pointer<Float> rawStops = colorStops != null
      ? scope.convertDoublesToNative(colorStops)
      : nullptr;
    final Pointer<Float> matrix = matrix4 != null
      ? scope.convertMatrix4toSkMatrix(matrix4)
      : nullptr;
    final ShaderHandle handle = shaderCreateRadialGradient(
      center.dx,
      center.dy,
      radius,
      rawColors,
      rawStops,
      colors.length,
      tileMode.index,
      matrix,
    );
    return SkwasmGradient._(handle);
  });

  factory SkwasmGradient.conical({
    required ui.Offset focal,
    required double focalRadius,
    required ui.Offset center,
    required double centerRadius,
    required List<ui.Color> colors,
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  }) => withStackScope((StackScope scope) {
    final RawPointArray endPoints =
      scope.convertPointArrayToNative(<ui.Offset>[focal, center]);
    final RawColorArray rawColors = scope.convertColorArrayToNative(colors);
    final Pointer<Float> rawStops = colorStops != null
      ? scope.convertDoublesToNative(colorStops)
      : nullptr;
    final Pointer<Float> matrix = matrix4 != null
      ? scope.convertMatrix4toSkMatrix(matrix4)
      : nullptr;
    final ShaderHandle handle = shaderCreateConicalGradient(
      endPoints,
      focalRadius,
      centerRadius,
      rawColors,
      rawStops,
      colors.length,
      tileMode.index,
      matrix
    );
    return SkwasmGradient._(handle);
  });

  factory SkwasmGradient.sweep({
    required ui.Offset center,
    required List<ui.Color> colors,
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    required double startAngle,
    required double endAngle,
    Float32List? matrix4,
  }) => withStackScope((StackScope scope) {
    final RawColorArray rawColors = scope.convertColorArrayToNative(colors);
    final Pointer<Float> rawStops = colorStops != null
      ? scope.convertDoublesToNative(colorStops)
      : nullptr;
    final Pointer<Float> matrix = matrix4 != null
      ? scope.convertMatrix4toSkMatrix(matrix4)
      : nullptr;
    final ShaderHandle handle = shaderCreateSweepGradient(
      center.dx,
      center.dy,
      rawColors,
      rawStops,
      colors.length,
      tileMode.index,
      ui.toDegrees(startAngle),
      ui.toDegrees(endAngle),
      matrix
    );
    return SkwasmGradient._(handle);
  });

  SkwasmGradient._(this.handle);

  @override
  ShaderHandle handle;

  @override
  void dispose() {
    super.dispose();
    handle = nullptr;
  }
}

class SkwasmImageShader extends SkwasmShader implements ui.ImageShader {
  SkwasmImageShader._(this.handle);

  factory SkwasmImageShader.imageShader(
    SkwasmImage image,
    ui.TileMode tmx,
    ui.TileMode tmy,
    Float64List? matrix4,
    ui.FilterQuality? filterQuality,
  ) {
    if (matrix4 != null) {
      return withStackScope((StackScope scope) {
        final RawMatrix33 localMatrix = scope.convertMatrix4toSkMatrix(matrix4);
        return SkwasmImageShader._(shaderCreateFromImage(
          image.handle,
          tmx.index,
          tmy.index,
          (filterQuality ?? ui.FilterQuality.medium).index,
          localMatrix,
        ));
      });
    } else {
      return SkwasmImageShader._(shaderCreateFromImage(
        image.handle,
        tmx.index,
        tmy.index,
        (filterQuality ?? ui.FilterQuality.medium).index,
        nullptr,
      ));
    }
  }

  @override
  ShaderHandle handle;

  @override
  void dispose() {
    super.dispose();
    handle = nullptr;
  }
}

class SkwasmFragmentProgram implements ui.FragmentProgram {
  SkwasmFragmentProgram._(
    this.name,
    this.handle,
    this.floatUniformCount,
    this.childShaderCount,
  );
  factory SkwasmFragmentProgram.fromBytes(String name, Uint8List bytes) {
    final ShaderData shaderData = ShaderData.fromBytes(bytes);

    // TODO(jacksongardner): Can we avoid this copy?
    final List<int> sourceData = utf8.encode(shaderData.source);
    final SkStringHandle sourceString = skStringAllocate(sourceData.length);
    final Pointer<Int8> sourceBuffer = skStringGetData(sourceString);
    int i = 0;
    for (final int byte in sourceData) {
      sourceBuffer[i] = byte;
      i++;
    }
    final RuntimeEffectHandle handle = runtimeEffectCreate(sourceString);
    skStringFree(sourceString);
    return SkwasmFragmentProgram._(
      name,
      handle,
      shaderData.floatCount,
      shaderData.textureCount
    );
  }

  final RuntimeEffectHandle handle;
  final String name;
  final int floatUniformCount;
  final int childShaderCount;
  bool _isDisposed = false;

  @override
  ui.FragmentShader fragmentShader() => SkwasmFragmentShader(this);

  int get uniformSize => runtimeEffectGetUniformSize(handle);

  void dispose() {
    if (!_isDisposed) {
      runtimeEffectDispose(handle);
      _isDisposed = true;
    }
  }
}

class SkwasmFragmentShader extends SkwasmShader implements ui.FragmentShader {
  SkwasmFragmentShader(
    SkwasmFragmentProgram program
  ) : _program = program,
       _uniformData = skDataCreate(program.uniformSize),
       _floatUniformCount = program.floatUniformCount,
       _childShaders = List<SkwasmShader?>.filled(program.childShaderCount, null);

  @override
  ShaderHandle get handle {
    if (_handle == nullptr) {
      _handle = withStackScope((StackScope s) {
        Pointer<ShaderHandle> childShaders = nullptr;
        if (_childShaders.isNotEmpty) {
          childShaders = s.allocPointerArray(_childShaders.length)
            .cast<ShaderHandle>();
          for (int i = 0; i < _childShaders.length; i++) {
            childShaders[i] = _childShaders[i]!.handle;
          }
        }
        return shaderCreateRuntimeEffectShader(
          _program.handle,
          _uniformData,
          childShaders,
          _childShaders.length,
        );
      });
    }
    return _handle;
  }

  ShaderHandle _handle = nullptr;
  final SkwasmFragmentProgram _program;
  SkDataHandle _uniformData;
  final int _floatUniformCount;
  final List<SkwasmShader?> _childShaders;

  @override
  void setFloat(int index, double value) {
    if (_handle != nullptr) {
      // Invalidate the previous shader so that it is recreated with the new
      // uniform data.
      shaderDispose(_handle);
      _handle = nullptr;
    }
    final Pointer<Float> dataPointer = skDataGetPointer(_uniformData).cast<Float>();
    dataPointer[index] = value;
  }

  @override
  void setImageSampler(int index, ui.Image image) {
    final SkwasmImageShader shader = SkwasmImageShader.imageShader(
      image as SkwasmImage,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      null,
      ui.FilterQuality.none,
    );
    final SkwasmShader? oldShader = _childShaders[index];
    _childShaders[index] = shader;
    oldShader?.dispose();

    final Pointer<Float> dataPointer = skDataGetPointer(_uniformData).cast<Float>();
    dataPointer[_floatUniformCount + index * 2] = image.width.toDouble();
    dataPointer[_floatUniformCount + index * 2 + 1] = image.height.toDouble();
  }

  @override
  void dispose() {
    super.dispose();
    if (_uniformData != nullptr) {
      skDataDispose(_uniformData);
      _uniformData = nullptr;
    }
  }
}
