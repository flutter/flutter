// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

/// Bumped whenever any shader library hot reloads. [UniformSlot] and
/// [StorageBufferSlot] cache reflection indices against this epoch, since a reload replaces the
/// shaders' reflection data in place and invalidates cached indices.
int _shaderReloadEpoch = 0;

const int _kSlotIndexUnresolved = -2;

base class UniformSlot {
  UniformSlot._(this.shader, this.uniformName);
  final Shader shader;
  final String uniformName;

  // Reflection indices for the name-free bind path, resolved through one
  // native call on first use and cached until a shader hot reload. -1
  // means the shader has no struct/texture with this slot's name.
  int _structIndex = _kSlotIndexUnresolved;
  int _textureIndex = _kSlotIndexUnresolved;
  int _epoch = _shaderReloadEpoch;

  void _syncEpoch() {
    if (_epoch != _shaderReloadEpoch) {
      _structIndex = _kSlotIndexUnresolved;
      _textureIndex = _kSlotIndexUnresolved;
      _epoch = _shaderReloadEpoch;
    }
  }

  int get _resolvedStructIndex {
    _syncEpoch();
    if (_structIndex == _kSlotIndexUnresolved) {
      _structIndex = shader._getUniformStructIndex(uniformName);
    }
    return _structIndex;
  }

  int get _resolvedTextureIndex {
    _syncEpoch();
    if (_textureIndex == _kSlotIndexUnresolved) {
      _textureIndex = shader._getUniformTextureIndex(uniformName);
    }
    return _textureIndex;
  }

  /// The reflected total size of a shader's uniform struct by name.
  ///
  /// Returns [null] if the shader does not contain a uniform struct with the
  /// given name.
  int? get sizeInBytes {
    int size = shader._getUniformStructSize(uniformName);
    return size < 0 ? null : size;
  }

  /// Get the reflected offset of a named member in the uniform struct.
  ///
  /// Returns [null] if the shader does not contain a uniform struct with the
  /// given name, or if the uniform struct does not contain a member with the
  /// given name.
  int? getMemberOffsetInBytes(String memberName) {
    int offset = shader._getUniformMemberOffset(uniformName, memberName);
    return offset < 0 ? null : offset;
  }
}

/// A storage buffer declared by a compute shader, looked up by its block name
/// with [Shader.getStorageBufferSlot].
///
/// Bind a [BufferView] to it with [ComputePass.bindStorageBuffer], or through
/// a [BindingSet]. A bound view must cover at least [sizeInBytes]. When the
/// block ends in a runtime-sized array, the bytes past [sizeInBytes] must be a
/// whole number of [runtimeArrayStrideInBytes]-sized elements. The view's
/// offset must be a multiple of
/// [GpuContext.minimumStorageBufferByteAlignment].
base class StorageBufferSlot {
  StorageBufferSlot._(this.shader, this.storageBufferName);

  /// The shader that declares the storage buffer.
  final Shader shader;

  /// The name of the storage buffer's block in the shader.
  final String storageBufferName;

  // The reflection index for the name-free bind path, resolved through one
  // native call on first use and cached until a shader hot reload, along with
  // the block layout the bind-time checks read. -1 means the shader has no
  // storage buffer with this slot's name.
  int _index = _kSlotIndexUnresolved;
  int _sizeInBytes = 0;
  int _runtimeArrayStride = 0;
  int _epoch = _shaderReloadEpoch;

  int get _resolvedIndex {
    if (_epoch != _shaderReloadEpoch) {
      _index = _kSlotIndexUnresolved;
      _epoch = _shaderReloadEpoch;
    }
    if (_index == _kSlotIndexUnresolved) {
      _index = shader._getStorageBufferIndex(storageBufferName);
      if (_index >= 0) {
        _sizeInBytes = shader._getStorageBufferSizeAt(_index);
        _runtimeArrayStride = shader._getStorageBufferRuntimeArrayStrideAt(
          _index,
        );
      }
    }
    return _index;
  }

  /// The reflected size of the storage buffer's block, counting a trailing
  /// runtime-sized array as empty.
  ///
  /// Returns null if the shader does not declare a storage buffer with this
  /// name, including one the shader compiler removed because the shader never
  /// uses it.
  int? get sizeInBytes {
    return _resolvedIndex < 0 ? null : _sizeInBytes;
  }

  /// The stride of the runtime-sized array the block ends in, or 0 if it does
  /// not end in one.
  ///
  /// Returns null if the shader does not declare a storage buffer with this
  /// name.
  int? get runtimeArrayStrideInBytes {
    return _resolvedIndex < 0 ? null : _runtimeArrayStride;
  }

  /// Returns the reflection index of this slot after checking that [view]
  /// can back the storage buffer: it lies within its buffer, covers the
  /// block, holds whole runtime array elements, and starts at an offset
  /// aligned to [alignment]. Throws otherwise.
  int _validateView(BufferView view, int alignment) {
    final int index = _resolvedIndex;
    if (index < 0) {
      throw Exception(
        "Failed to bind storage buffer (no storage buffer named '$storageBufferName')",
      );
    }
    if (view.offsetInBytes < 0 ||
        view.lengthInBytes <= 0 ||
        view.offsetInBytes + view.lengthInBytes > view.buffer.sizeInBytes) {
      throw ArgumentError(
        "The BufferView for storage buffer '$storageBufferName' "
        '(offset ${view.offsetInBytes}, length ${view.lengthInBytes}) must be '
        'non-empty and lie within its DeviceBuffer '
        '(${view.buffer.sizeInBytes} bytes)',
      );
    }
    if (alignment > 1 && view.offsetInBytes % alignment != 0) {
      throw ArgumentError(
        "The BufferView offset for storage buffer '$storageBufferName' "
        '(${view.offsetInBytes}) must be a multiple of '
        'GpuContext.minimumStorageBufferByteAlignment ($alignment)',
      );
    }
    if (view.lengthInBytes < _sizeInBytes) {
      throw ArgumentError(
        "Storage buffer '$storageBufferName' needs at least $_sizeInBytes "
        'bytes, but the BufferView is ${view.lengthInBytes} bytes',
      );
    }
    if (_runtimeArrayStride > 0 &&
        (view.lengthInBytes - _sizeInBytes) % _runtimeArrayStride != 0) {
      throw ArgumentError(
        "Storage buffer '$storageBufferName' ends in an array of "
        '$_runtimeArrayStride-byte elements after $_sizeInBytes bytes, but '
        'the BufferView length (${view.lengthInBytes}) leaves a partial '
        'element',
      );
    }
    return index;
  }
}

base class Shader extends NativeFieldWrapperClass1 {
  // [Shader] handles are instantiated when interacting with a [ShaderLibrary].
  Shader._();

  // Memoized so per-draw lookups return the same slot instance, whose
  // cached reflection indices make repeat binds name-free.
  final Map<String, UniformSlot> _uniformSlots = <String, UniformSlot>{};

  UniformSlot getUniformSlot(String uniformName) {
    return _uniformSlots[uniformName] ??= UniformSlot._(this, uniformName);
  }

  final Map<String, StorageBufferSlot> _storageBufferSlots =
      <String, StorageBufferSlot>{};

  /// Returns the slot for the storage buffer whose block is named
  /// [storageBufferName] in this compute shader.
  ///
  /// The lookup is lazy: a name the shader does not declare still returns a
  /// slot, whose [StorageBufferSlot.sizeInBytes] is null and which throws when
  /// bound. Repeated calls with the same name return the same slot.
  StorageBufferSlot getStorageBufferSlot(String storageBufferName) {
    return _storageBufferSlots[storageBufferName] ??= StorageBufferSlot._(
      this,
      storageBufferName,
    );
  }

  @Native<Int Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_Shader_GetUniformStructSize',
  )
  external int _getUniformStructSize(String uniformStructName);

  @Native<Int Function(Pointer<Void>, Handle, Handle)>(
    symbol: 'InternalFlutterGpu_Shader_GetUniformMemberOffset',
  )
  external int _getUniformMemberOffset(
    String uniformStructName,
    String memberName,
  );

  @Native<Int Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_Shader_GetUniformStructIndex',
  )
  external int _getUniformStructIndex(String uniformStructName);

  @Native<Int Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_Shader_GetUniformTextureIndex',
  )
  external int _getUniformTextureIndex(String uniformTextureName);

  @Native<Int Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_Shader_GetStorageBufferIndex',
  )
  external int _getStorageBufferIndex(String storageBufferName);

  @Native<Int Function(Pointer<Void>, Int)>(
    symbol: 'InternalFlutterGpu_Shader_GetStorageBufferSizeAt',
  )
  external int _getStorageBufferSizeAt(int storageBufferIndex);

  @Native<Int Function(Pointer<Void>, Int)>(
    symbol: 'InternalFlutterGpu_Shader_GetStorageBufferRuntimeArrayStrideAt',
  )
  external int _getStorageBufferRuntimeArrayStrideAt(int storageBufferIndex);

  /// Test-only. Whether this shader is currently marked dirty (will be
  /// evicted and re-registered with the impeller shader library on next
  /// pipeline build). Used by tests to assert that reload dedupe keeps
  /// unchanged shaders clean.
  bool get debugIsDirty => _debugIsDirty();

  @Native<Bool Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Shader_DebugIsDirty',
  )
  external bool _debugIsDirty();
}
