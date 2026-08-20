// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

class CkFragmentProgram implements ui.FragmentProgram {
  CkFragmentProgram(this.name, this.effect, this.uniforms, this.floatCount, this.textureCount);

  factory CkFragmentProgram.fromBytes(String name, Uint8List data) {
    final shaderData = ShaderData.fromBytes(data);
    final SkRuntimeEffect? effect = MakeRuntimeEffect(shaderData.source);
    if (effect == null) {
      throw const FormatException('Invalid Shader Source');
    }

    return CkFragmentProgram(
      name,
      effect,
      shaderData.uniforms,
      shaderData.floatCount,
      shaderData.textureCount,
    );
  }

  final String name;
  final SkRuntimeEffect effect;
  final List<UniformData> uniforms;
  final int floatCount;
  final int textureCount;

  @override
  ui.FragmentShader fragmentShader() {
    return EngineFragmentShader(CkFragmentShader(name, effect, this));
  }

  UniformData _getUniformFloatInfo(String name) {
    for (final UniformData uniform in uniforms) {
      if (uniform.name == name) {
        return uniform;
      }
    }
    throw ArgumentError('No uniform named "$name".');
  }
}

class CkFragmentShader extends BackendFragmentShader implements CkShader {
  CkFragmentShader(this.name, this.effect, this._program)
    : floats = mallocFloat32List(_program.floatCount + _program.textureCount * 2),
      samplers = List<SkShader?>.filled(_program.textureCount, null),
      lastFloatIndex = _program.floatCount;

  final String name;
  final SkRuntimeEffect effect;
  final int lastFloatIndex;
  final SkFloat32List floats;
  final List<SkShader?> samplers;
  final CkFragmentProgram _program;

  @visibleForTesting
  CkUniqueRef<SkShader>? ref;

  @override
  bool get isGradient => false;

  @override
  SkShader get skShader {
    assert(!_debugDisposed, 'FragmentShader has been disposed of.');
    ref?.dispose();

    final SkShader? result = samplers.isEmpty
        ? effect.makeShader(floats)
        : effect.makeShaderWithChildren(floats, samplers);
    if (result == null) {
      throw Exception(
        'Invalid uniform data for shader $name:'
        '  floatUniforms: $floats \n'
        '  samplerUniforms: $samplers \n',
      );
    }

    ref = CkUniqueRef<SkShader>(this, result, 'FragmentShader');
    return result;
  }

  @override
  void setFloat(int index, double value) {
    assert(!_debugDisposed, 'FragmentShader has been disposed of.');
    floats.toTypedArray()[index] = value;
  }

  @override
  void setImageSampler(int index, BackendImageShader shader, double width, double height) {
    assert(!_debugDisposed, 'FragmentShader has been disposed of.');
    samplers[index] = (shader as CkImageShader).skShader;
    setFloat(lastFloatIndex + 2 * index, width);
    setFloat(lastFloatIndex + 2 * index + 1, height);
  }

  @override
  void dispose() {
    assert(!_debugDisposed, 'Cannot dispose FragmentShader more than once.');
    assert(() {
      _debugDisposed = true;
      return true;
    }());
    ref?.dispose();
    ref = null;
    free(floats);
  }

  bool _debugDisposed = false;

  bool get debugDisposed => _debugDisposed;

  @override
  ui.UniformFloatSlot getUniformFloat(String name, [int? index]) {
    index ??= 0;
    final UniformData info = _program._getUniformFloatInfo(name);

    IndexError.check(index, info.floatCount, message: 'Index `$index` out of bounds for `$name`.');

    return CkUniformFloatSlot._(this, index, name, info.floatOffset + index);
  }

  @override
  ui.UniformVec2Slot getUniformVec2(String name) {
    final List<CkUniformFloatSlot> slots = _getUniformFloatSlots(name, 2);
    return _CkUniformVec2Slot._(slots[0], slots[1]);
  }

  @override
  ui.UniformVec3Slot getUniformVec3(String name) {
    final List<CkUniformFloatSlot> slots = _getUniformFloatSlots(name, 3);
    return _CkUniformVec3Slot._(slots[0], slots[1], slots[2]);
  }

  @override
  ui.UniformVec4Slot getUniformVec4(String name) {
    final List<CkUniformFloatSlot> slots = _getUniformFloatSlots(name, 4);
    return _CkUniformVec4Slot._(slots[0], slots[1], slots[2], slots[3]);
  }

  ui.UniformArray<T> _getUniformArray<T extends ui.UniformType>(
    String name,
    int elementSize,
    T Function(List<CkUniformFloatSlot> slots) elementFactory,
  ) {
    final UniformData info = _program._getUniformFloatInfo(name);

    if (info.floatCount % elementSize != 0) {
      throw ArgumentError(
        'Uniform size (${info.floatCount}) for "$name" is not a multiple of $elementSize.',
      );
    }
    final int numElements = info.floatCount ~/ elementSize;

    final elements = List<T>.generate(numElements, (i) {
      final slots = List<CkUniformFloatSlot>.generate(
        info.floatCount,
        (j) => CkUniformFloatSlot._(this, j, name, info.floatOffset + i * elementSize + j),
      );
      return elementFactory(slots);
    });

    return _CkUniformFloatArray<T>._(elements);
  }

  @override
  ui.UniformArray<ui.UniformFloatSlot> getUniformFloatArray(String name) {
    return _getUniformArray(name, 1, (components) => components.first);
  }

  @override
  ui.UniformArray<ui.UniformVec2Slot> getUniformVec2Array(String name) {
    return _getUniformArray<_CkUniformVec2Slot>(
      name,
      2, // 2 floats per element
      (components) => _CkUniformVec2Slot._(
        components[0],
        components[1],
      ), // Create Vec2 from two UniformFloat components
    );
  }

  @override
  ui.UniformArray<ui.UniformVec3Slot> getUniformVec3Array(String name) {
    return _getUniformArray<_CkUniformVec3Slot>(
      name,
      3, // 3 floats per element
      (components) =>
          _CkUniformVec3Slot._(components[0], components[1], components[2]), // Create Vec3
    );
  }

  @override
  ui.UniformArray<ui.UniformVec4Slot> getUniformVec4Array(String name) {
    return _getUniformArray<_CkUniformVec4Slot>(
      name,
      4, // 4 floats per element
      (components) => _CkUniformVec4Slot._(
        components[0],
        components[1],
        components[2],
        components[3],
      ), // Create Vec4
    );
  }

  @override
  ui.UniformMat2Slot getUniformMat2(String name) {
    final List<CkUniformFloatSlot> slots = _getUniformFloatSlots(name, 4);
    return _CkUniformMat2Slot._(slots[0], slots[1], slots[2], slots[3]);
  }

  @override
  ui.UniformMat3Slot getUniformMat3(String name) {
    final List<CkUniformFloatSlot> slots = _getUniformFloatSlots(name, 9);
    return _CkUniformMat3Slot._(
      slots[0],
      slots[1],
      slots[2],
      slots[3],
      slots[4],
      slots[5],
      slots[6],
      slots[7],
      slots[8],
    );
  }

  @override
  ui.UniformMat4Slot getUniformMat4(String name) {
    final List<CkUniformFloatSlot> slots = _getUniformFloatSlots(name, 16);
    return _CkUniformMat4Slot._(
      slots[0],
      slots[1],
      slots[2],
      slots[3],
      slots[4],
      slots[5],
      slots[6],
      slots[7],
      slots[8],
      slots[9],
      slots[10],
      slots[11],
      slots[12],
      slots[13],
      slots[14],
      slots[15],
    );
  }

  @override
  ui.UniformArray<ui.UniformMat2Slot> getUniformMat2Array(String name) {
    return _getUniformArray<_CkUniformMat2Slot>(
      name,
      4,
      (components) =>
          _CkUniformMat2Slot._(components[0], components[1], components[2], components[3]),
    );
  }

  @override
  ui.UniformArray<ui.UniformMat3Slot> getUniformMat3Array(String name) {
    return _getUniformArray<_CkUniformMat3Slot>(
      name,
      9,
      (components) => _CkUniformMat3Slot._(
        components[0],
        components[1],
        components[2],
        components[3],
        components[4],
        components[5],
        components[6],
        components[7],
        components[8],
      ),
    );
  }

  @override
  ui.UniformArray<ui.UniformMat4Slot> getUniformMat4Array(String name) {
    return _getUniformArray<_CkUniformMat4Slot>(
      name,
      16,
      (components) => _CkUniformMat4Slot._(
        components[0],
        components[1],
        components[2],
        components[3],
        components[4],
        components[5],
        components[6],
        components[7],
        components[8],
        components[9],
        components[10],
        components[11],
        components[12],
        components[13],
        components[14],
        components[15],
      ),
    );
  }

  @override
  ui.ImageSamplerSlot getImageSampler(String name) {
    throw UnsupportedError('getImageSampler is not supported on the web.');
  }

  List<CkUniformFloatSlot> _getUniformFloatSlots(String name, int size) {
    final UniformData info = _program._getUniformFloatInfo(name);

    if (info.floatCount != size) {
      throw ArgumentError('Uniform `$name` has size ${info.floatCount}, not size $size.');
    }

    return List<CkUniformFloatSlot>.generate(
      size,
      (i) => CkUniformFloatSlot._(this, i, name, info.floatOffset + i),
    );
  }
}

class CkUniformFloatSlot implements ui.UniformFloatSlot {
  CkUniformFloatSlot._(this._shader, this.index, this.name, this.shaderIndex);

  final CkFragmentShader _shader;

  @override
  final int index;

  @override
  final String name;

  @override
  void set(double val) {
    _shader.setFloat(shaderIndex, val);
  }

  @override
  final int shaderIndex;
}

class _CkUniformVec2Slot implements ui.UniformVec2Slot {
  _CkUniformVec2Slot._(this._xSlot, this._ySlot);

  @override
  void set(double x, double y) {
    _xSlot.set(x);
    _ySlot.set(y);
  }

  final CkUniformFloatSlot _xSlot, _ySlot;
}

class _CkUniformVec3Slot implements ui.UniformVec3Slot {
  _CkUniformVec3Slot._(this._xSlot, this._ySlot, this._zSlot);

  @override
  void set(double x, double y, double z) {
    _xSlot.set(x);
    _ySlot.set(y);
    _zSlot.set(z);
  }

  final CkUniformFloatSlot _xSlot, _ySlot, _zSlot;
}

class _CkUniformVec4Slot implements ui.UniformVec4Slot {
  _CkUniformVec4Slot._(this._xSlot, this._ySlot, this._zSlot, this._wSlot);

  @override
  void set(double x, double y, double z, double w) {
    _xSlot.set(x);
    _ySlot.set(y);
    _zSlot.set(z);
    _wSlot.set(w);
  }

  final CkUniformFloatSlot _xSlot, _ySlot, _zSlot, _wSlot;
}

class _CkUniformMat2Slot implements ui.UniformMat2Slot {
  _CkUniformMat2Slot._(this._m00, this._m10, this._m01, this._m11);

  // Set the elemnts of the matrix in column-major order.
  @override
  void set(double m00, double m10, double m01, double m11) {
    _m00.set(m00);
    _m01.set(m01);
    _m10.set(m10);
    _m11.set(m11);
  }

  // The elements of the matrix. Where mij referes to the ith row and the jth column.
  final CkUniformFloatSlot _m00, _m10; // Column 0
  final CkUniformFloatSlot _m01, _m11; // Column 1
}

class _CkUniformMat3Slot implements ui.UniformMat3Slot {
  _CkUniformMat3Slot._(
    this._m00,
    this._m10,
    this._m20,
    this._m01,
    this._m11,
    this._m21,
    this._m02,
    this._m12,
    this._m22,
  );

  // The elements of the matrix. mij refers to the ith row and the jth column.
  final CkUniformFloatSlot _m00, _m10, _m20; // Column 0
  final CkUniformFloatSlot _m01, _m11, _m21; // Column 1
  final CkUniformFloatSlot _m02, _m12, _m22; // Column 2

  /// Set the elements of the matrix in column-major order.
  @override
  void set(
    double m00,
    double m10,
    double m20,
    double m01,
    double m11,
    double m21,
    double m02,
    double m12,
    double m22,
  ) {
    _m00.set(m00);
    _m10.set(m10);
    _m20.set(m20);

    _m01.set(m01);
    _m11.set(m11);
    _m21.set(m21);

    _m02.set(m02);
    _m12.set(m12);
    _m22.set(m22);
  }
}

class _CkUniformMat4Slot implements ui.UniformMat4Slot {
  _CkUniformMat4Slot._(
    this._m00,
    this._m10,
    this._m20,
    this._m30,
    this._m01,
    this._m11,
    this._m21,
    this._m31,
    this._m02,
    this._m12,
    this._m22,
    this._m32,
    this._m03,
    this._m13,
    this._m23,
    this._m33,
  );

  // The elements of the matrix. mij refers to the ith row and the jth column.
  final CkUniformFloatSlot _m00, _m10, _m20, _m30; // Column 0
  final CkUniformFloatSlot _m01, _m11, _m21, _m31; // Column 1
  final CkUniformFloatSlot _m02, _m12, _m22, _m32; // Column 2
  final CkUniformFloatSlot _m03, _m13, _m23, _m33; // Column 3

  /// Set the elements of the matrix in column-major order.
  @override
  void set(
    double m00,
    double m10,
    double m20,
    double m30,
    double m01,
    double m11,
    double m21,
    double m31,
    double m02,
    double m12,
    double m22,
    double m32,
    double m03,
    double m13,
    double m23,
    double m33,
  ) {
    _m00.set(m00);
    _m10.set(m10);
    _m20.set(m20);
    _m30.set(m30);

    _m01.set(m01);
    _m11.set(m11);
    _m21.set(m21);
    _m31.set(m31);

    _m02.set(m02);
    _m12.set(m12);
    _m22.set(m22);
    _m32.set(m32);

    _m03.set(m03);
    _m13.set(m13);
    _m23.set(m23);
    _m33.set(m33);
  }
}

class _CkUniformFloatArray<T extends ui.UniformType> implements ui.UniformArray<T> {
  _CkUniformFloatArray._(this._elements);

  @override
  T operator [](int index) {
    return _elements[index];
  }

  @override
  int get length => _elements.length;

  final List<T> _elements;
}
