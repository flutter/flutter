// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

/// A texture and the sampler configuration used to read it, for use in a
/// [BindingSet].
base class TextureBinding {
  const TextureBinding(this.texture, {this.sampler});

  /// The texture to read.
  final Texture texture;

  /// The sampler to read [texture] with. Defaults to the same nearest
  /// filtering and clamped addressing as [RenderPass.bindTexture] when null.
  final SamplerOptions? sampler;
}

/// An immutable group of uniform, texture and storage buffer bindings,
/// resolved against shader reflection once at creation and reusable across
/// draws and passes.
///
/// Create one with [GpuContext.createBindingSet] and bind it with
/// [RenderPass.bindSet] or [ComputePass.bindSet]. Binding costs one slot
/// assignment no matter how many resources the set holds, so a renderer that
/// draws one material across many nodes stops paying per-resource bind work
/// on every draw. A render pass uses a set's vertex and fragment shader
/// bindings, and a compute pass its compute shader bindings.
///
/// A set references its resources rather than copying them, so it stays valid
/// for as long as the bound buffers and textures do. Data that changes from
/// frame to frame produces a new [BufferView] each frame (see
/// [HostBuffer.emplace]) and belongs in a per-draw [RenderPass.bindUniform]
/// instead.
base class BindingSet extends NativeFieldWrapperClass1 {
  BindingSet._(
    this._gpuContext,
    Map<UniformSlot, BufferView> uniforms,
    Map<UniformSlot, TextureBinding> textures,
    Map<StorageBufferSlot, BufferView> storageBuffers,
  ) : _uniforms = Map<UniformSlot, BufferView>.unmodifiable(uniforms),
      _textures = Map<UniformSlot, TextureBinding>.unmodifiable(textures),
      _storageBuffers = Map<StorageBufferSlot, BufferView>.unmodifiable(
        storageBuffers,
      ) {
    _initialize();
    _populate();
  }

  final GpuContext _gpuContext;
  final Map<UniformSlot, BufferView> _uniforms;
  final Map<UniformSlot, TextureBinding> _textures;
  final Map<StorageBufferSlot, BufferView> _storageBuffers;

  /// The shader reload epoch the native bindings were resolved against. A
  /// reload replaces the reflection data they point at, so the set is
  /// repopulated the next time it is bound.
  int _epoch = -1;

  /// Resolves every entry against shader reflection and hands it to the
  /// native set. Throws for a name the shader does not declare, a buffer view
  /// that runs past the end of its buffer or cannot back its storage buffer,
  /// or an invalid sampler.
  void _populate() {
    for (final MapEntry<UniformSlot, BufferView> entry in _uniforms.entries) {
      final UniformSlot slot = entry.key;
      final int structIndex = slot._resolvedStructIndex;
      if (structIndex < 0) {
        throw Exception(
          "Failed to bind uniform (no uniform struct named '${slot.uniformName}')",
        );
      }
      final BufferView view = entry.value;
      if (!_addUniform(
        slot.shader,
        structIndex,
        view.buffer,
        view.offsetInBytes,
        view.lengthInBytes,
      )) {
        throw Exception("Failed to bind uniform '${slot.uniformName}'");
      }
    }

    for (final MapEntry<UniformSlot, TextureBinding> entry
        in _textures.entries) {
      final UniformSlot slot = entry.key;
      final int textureIndex = slot._resolvedTextureIndex;
      if (textureIndex < 0) {
        throw Exception(
          "Failed to bind texture (no texture named '${slot.uniformName}')",
        );
      }
      final TextureBinding binding = entry.value;
      final SamplerOptions sampler = binding.sampler ?? SamplerOptions();
      _validateBindableTexture(binding.texture);
      sampler._validate();
      if (!_addTexture(
        _gpuContext,
        slot.shader,
        textureIndex,
        binding.texture,
        sampler.minFilter.index,
        sampler.magFilter.index,
        sampler.mipFilter.index,
        sampler.widthAddressMode.index,
        sampler.heightAddressMode.index,
        sampler.maxAnisotropy,
      )) {
        throw Exception("Failed to bind texture '${slot.uniformName}'");
      }
    }

    final int storageAlignment = _gpuContext.minimumStorageBufferByteAlignment;
    for (final MapEntry<StorageBufferSlot, BufferView> entry
        in _storageBuffers.entries) {
      final StorageBufferSlot slot = entry.key;
      final BufferView view = entry.value;
      final int storageBufferIndex = slot._validateView(view, storageAlignment);
      if (!_addStorageBuffer(
        slot.shader,
        storageBufferIndex,
        view.buffer,
        view.offsetInBytes,
        view.lengthInBytes,
      )) {
        throw Exception(
          "Failed to bind storage buffer '${slot.storageBufferName}'. Only "
          'compute shaders take storage buffers.',
        );
      }
    }

    _epoch = _shaderReloadEpoch;
  }

  /// Re-resolves the set after a shader hot reload. Cheap no-op otherwise.
  void _syncReloadEpoch() {
    if (_epoch == _shaderReloadEpoch) {
      return;
    }
    _clear();
    _populate();
  }

  /// Wrap with native counterpart.
  @Native<Void Function(Handle)>(
    symbol: 'InternalFlutterGpu_BindingSet_Initialize',
  )
  external void _initialize();

  @Native<
    Bool Function(Pointer<Void>, Pointer<Void>, Int, Pointer<Void>, Int, Int)
  >(symbol: 'InternalFlutterGpu_BindingSet_AddUniform')
  external bool _addUniform(
    Shader shader,
    int uniformStructIndex,
    DeviceBuffer buffer,
    int offsetInBytes,
    int lengthInBytes,
  );

  @Native<
    Bool Function(Pointer<Void>, Pointer<Void>, Int, Pointer<Void>, Int, Int)
  >(symbol: 'InternalFlutterGpu_BindingSet_AddStorageBuffer')
  external bool _addStorageBuffer(
    Shader shader,
    int storageBufferIndex,
    DeviceBuffer buffer,
    int offsetInBytes,
    int lengthInBytes,
  );

  @Native<
    Bool Function(
      Pointer<Void>,
      Pointer<Void>,
      Pointer<Void>,
      Int,
      Pointer<Void>,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
    )
  >(symbol: 'InternalFlutterGpu_BindingSet_AddTexture')
  external bool _addTexture(
    GpuContext gpuContext,
    Shader shader,
    int uniformTextureIndex,
    Texture texture,
    int minFilter,
    int magFilter,
    int mipFilter,
    int widthAddressMode,
    int heightAddressMode,
    int maxAnisotropy,
  );

  @Native<Void Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_BindingSet_Clear',
  )
  external void _clear();
}
