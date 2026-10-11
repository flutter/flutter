// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_gpu;

/// A size along the three dimensions of a compute dispatch, such as a
/// workgroup's invocations or a dispatch's workgroups.
///
/// See [GpuContext.maxComputeWorkgroupSize] and
/// [GpuContext.maxComputeWorkgroupCount].
final class ComputeExtent {
  /// Creates an extent of [x] by [y] by [z].
  const ComputeExtent(this.x, this.y, this.z);

  /// The size along the x dimension.
  final int x;

  /// The size along the y dimension.
  final int y;

  /// The size along the z dimension.
  final int z;

  @override
  bool operator ==(Object other) {
    return other is ComputeExtent &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'ComputeExtent($x, $y, $z)';
}

/// A pass that dispatches compute shaders, created by
/// [CommandBuffer.createComputePass].
///
/// Bind a [ComputePipeline] and the resources its shader declares, then call
/// [dispatch]. Bindings persist across dispatches until they are replaced or
/// [clearBindings] is called, so a dispatch only needs to rebind what changed.
///
/// Every dispatch sees the writes of the dispatches and passes recorded before
/// it, and its writes are visible to every later dispatch, pass and copy,
/// without a manual barrier.
///
/// A pass records until [end] is called, or until its command buffer creates
/// the next pass, records a copy, or is submitted. After that, every method
/// except [end] throws a [StateError] naming what ended the pass.
///
/// ```dart
/// final gpu.ComputePass pass = commandBuffer.createComputePass();
/// pass.bindPipeline(pipeline);
/// pass.bindStorageBuffer(
///   pipeline.shader.getStorageBufferSlot('Particles'),
///   particles,
/// );
/// pass.dispatch((particleCount + 63) ~/ 64);
/// ```
base class ComputePass extends NativeFieldWrapperClass1
    implements _CommandBufferPass {
  /// The number of binding set slots that can be bound to a single dispatch.
  /// Matches `flutter::gpu::ComputePass::kMaxBindingSets` on the native side;
  /// keep them in sync. See [bindSet].
  static const int maxBindingSets = 4;

  final GpuContext _gpuContext;

  final CommandBuffer _commandBuffer;

  /// The call that ended this pass, or null while it is recording.
  String? _endedBy;

  /// The bound pipeline, or null until [bindPipeline] is called.
  ComputePipeline? _pipeline;

  /// Creates a new ComputePass.
  ComputePass._(this._gpuContext, this._commandBuffer) {
    _initialize();
    _commandBuffer._endOpenPass('CommandBuffer.createComputePass()');
    final String? error = _begin(_commandBuffer);
    if (error != null) {
      throw Exception(error);
    }
    _commandBuffer._openPass = this;
  }

  @override
  void _markEnded(String endedBy) {
    _endedBy = endedBy;
  }

  /// Ends this pass. Nothing more can be recorded into it.
  ///
  /// A pass also ends when its [CommandBuffer] creates the next pass, records
  /// a copy, or is submitted, so calling this is optional. Calling it on a pass
  /// that has already ended does nothing.
  void end() {
    if (_endedBy != null) {
      return;
    }
    _commandBuffer._openPass = null;
    _endedBy = 'ComputePass.end()';
    final String? error = _end();
    if (error != null) {
      throw Exception(error);
    }
  }

  void _checkNotEnded() {
    final String? endedBy = _endedBy;
    if (endedBy != null) {
      throw StateError('This ComputePass was ended by $endedBy.');
    }
  }

  /// Binds [pipeline] for subsequent dispatches.
  ///
  /// Bindings made for another pipeline's shader are kept, and apply again if
  /// that pipeline is bound later in the pass.
  void bindPipeline(ComputePipeline pipeline) {
    _checkNotEnded();
    _pipeline = pipeline;
    _bindPipeline(pipeline);
  }

  /// Binds [bufferView] to the storage buffer [slot] for subsequent
  /// dispatches.
  ///
  /// Throws if the shader declares no storage buffer named by [slot], or if
  /// [bufferView] cannot back it: the view must lie within its buffer, cover
  /// [StorageBufferSlot.sizeInBytes], hold whole elements of a trailing
  /// runtime-sized array, and start at a multiple of
  /// [GpuContext.minimumStorageBufferByteAlignment]. Out-of-bounds storage
  /// buffer access is undefined on the GPU, so these are checked here.
  void bindStorageBuffer(StorageBufferSlot slot, BufferView bufferView) {
    _checkNotEnded();
    final int storageBufferIndex = slot._validateView(
      bufferView,
      _gpuContext.minimumStorageBufferByteAlignment,
    );
    if (!_bindStorageBufferIndexed(
      slot.shader,
      storageBufferIndex,
      bufferView.buffer,
      bufferView.offsetInBytes,
      bufferView.lengthInBytes,
    )) {
      throw Exception(
        "Failed to bind storage buffer '${slot.storageBufferName}'. Only "
        'compute shaders take storage buffers in a ComputePass.',
      );
    }
  }

  /// Binds [bufferView] to the uniform struct [slot] of a compute shader for
  /// subsequent dispatches.
  ///
  /// Throws if the shader declares no uniform struct named by [slot], if the
  /// shader is not a compute shader, or if [bufferView] runs past the end of
  /// its buffer.
  void bindUniform(UniformSlot slot, BufferView bufferView) {
    _checkNotEnded();
    // The slot's index is resolved once and cached, so steady-state binds
    // pass an integer across the native boundary instead of the name.
    final int uniformStructIndex = slot._resolvedStructIndex;
    if (uniformStructIndex < 0) {
      throw Exception(
        "Failed to bind uniform (no uniform struct named '${slot.uniformName}')",
      );
    }
    if (!_bindUniformIndexed(
      slot.shader,
      uniformStructIndex,
      bufferView.buffer,
      bufferView.offsetInBytes,
      bufferView.lengthInBytes,
    )) {
      throw Exception(
        "Failed to bind uniform '${slot.uniformName}'. The shader must be a "
        'compute shader, and the BufferView must lie within its DeviceBuffer.',
      );
    }
  }

  /// Binds [texture] to the sampled texture [slot] of a compute shader for
  /// subsequent dispatches, read with [sampler].
  ///
  /// [sampler] defaults to the same nearest filtering and clamped addressing
  /// as [RenderPass.bindTexture]. Throws if the shader declares no texture
  /// named by [slot], if the shader is not a compute shader, or if [sampler]
  /// is invalid.
  void bindTexture(
    UniformSlot slot,
    Texture texture, {
    SamplerOptions? sampler,
  }) {
    _checkNotEnded();
    sampler ??= SamplerOptions();
    _validateBindableTexture(texture);
    sampler._validate();

    final int uniformTextureIndex = slot._resolvedTextureIndex;
    if (uniformTextureIndex < 0) {
      throw Exception(
        "Failed to bind texture (no texture named '${slot.uniformName}')",
      );
    }
    if (!_bindTextureIndexed(
      slot.shader,
      uniformTextureIndex,
      texture,
      sampler.minFilter.index,
      sampler.magFilter.index,
      sampler.mipFilter.index,
      sampler.widthAddressMode.index,
      sampler.heightAddressMode.index,
      sampler.maxAnisotropy,
    )) {
      throw Exception(
        "Failed to bind texture '${slot.uniformName}'. The shader must be a "
        'compute shader.',
      );
    }
  }

  /// Binds the compute shader bindings in [bindingSet] for subsequent
  /// dispatches, replacing whatever set was bound to [slot].
  ///
  /// Set bindings are applied before individual [bindStorageBuffer],
  /// [bindUniform] and [bindTexture] calls, so an individual bind to the same
  /// shader binding overrides the set's. Where two bound sets declare the
  /// same binding, the higher slot wins. [clearBindings] empties every slot.
  ///
  /// [slot] must be in `[0, maxBindingSets)`.
  void bindSet(BindingSet bindingSet, {int slot = 0}) {
    _checkNotEnded();
    if (slot < 0 || slot >= maxBindingSets) {
      throw RangeError.range(
        slot,
        0,
        maxBindingSets - 1,
        'slot',
        'bindSet slot must be in [0, $maxBindingSets)',
      );
    }
    bindingSet._syncReloadEpoch();
    _bindSet(bindingSet, slot);
  }

  /// Unbinds every storage buffer, uniform, texture and binding set. The
  /// bound pipeline stays bound.
  void clearBindings() {
    _checkNotEnded();
    _clearBindings();
  }

  /// Dispatches a grid of [workgroupCountX] by [workgroupCountY] by
  /// [workgroupCountZ] workgroups of the bound pipeline's shader.
  ///
  /// The counts are numbers of workgroups, not invocations. Each workgroup
  /// runs as many invocations as the shader's `local_size` declares, so a
  /// shader with `local_size_x = 64` covers 1000 elements with
  /// `dispatch((1000 + 63) ~/ 64)`. A count of 0 along any dimension is valid
  /// and records no work.
  ///
  /// Throws a [StateError] if no pipeline is bound and the grid is not
  /// empty. Throws if a storage buffer, uniform or texture the shader
  /// declares has nothing bound to it, or if a count exceeds the device's
  /// maximum workgroup count.
  ///
  /// This includes a resource the shader declares but never uses, so that a
  /// pass that dispatches on one backend dispatches on every backend.
  void dispatch(
    int workgroupCountX, [
    int workgroupCountY = 1,
    int workgroupCountZ = 1,
  ]) {
    _checkNotEnded();
    RangeError.checkValueInInterval(
      workgroupCountX,
      0,
      _kMaxWorkgroupCount,
      'workgroupCountX',
    );
    RangeError.checkValueInInterval(
      workgroupCountY,
      0,
      _kMaxWorkgroupCount,
      'workgroupCountY',
    );
    RangeError.checkValueInInterval(
      workgroupCountZ,
      0,
      _kMaxWorkgroupCount,
      'workgroupCountZ',
    );
    if (workgroupCountX == 0 || workgroupCountY == 0 || workgroupCountZ == 0) {
      return;
    }
    if (_pipeline == null) {
      throw StateError(
        'ComputePass.dispatch() was called before a ComputePipeline was '
        'bound with ComputePass.bindPipeline().',
      );
    }
    final String? error = _dispatch(
      workgroupCountX,
      workgroupCountY,
      workgroupCountZ,
    );
    if (error != null) {
      throw Exception(error);
    }
  }

  /// The largest count the native call takes along one dimension. Devices
  /// allow far fewer workgroups than this; the native side checks the
  /// device's limit.
  static const int _kMaxWorkgroupCount = 0x7FFFFFFF;

  /// Wrap with native counterpart.
  @Native<Void Function(Handle)>(
    symbol: 'InternalFlutterGpu_ComputePass_Initialize',
  )
  external void _initialize();

  @Native<Handle Function(Pointer<Void>, Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_ComputePass_Begin',
  )
  external String? _begin(CommandBuffer commandBuffer);

  @Native<Handle Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_ComputePass_End',
  )
  external String? _end();

  @Native<Void Function(Pointer<Void>, Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_ComputePass_BindPipeline',
  )
  external void _bindPipeline(ComputePipeline pipeline);

  @Native<
    Bool Function(Pointer<Void>, Pointer<Void>, Int, Pointer<Void>, Int, Int)
  >(symbol: 'InternalFlutterGpu_ComputePass_BindUniformIndexed')
  external bool _bindUniformIndexed(
    Shader shader,
    int uniformStructIndex,
    DeviceBuffer buffer,
    int offsetInBytes,
    int lengthInBytes,
  );

  @Native<
    Bool Function(Pointer<Void>, Pointer<Void>, Int, Pointer<Void>, Int, Int)
  >(symbol: 'InternalFlutterGpu_ComputePass_BindStorageBufferIndexed')
  external bool _bindStorageBufferIndexed(
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
      Int,
      Pointer<Void>,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
    )
  >(symbol: 'InternalFlutterGpu_ComputePass_BindTextureIndexed')
  external bool _bindTextureIndexed(
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

  @Native<Void Function(Pointer<Void>, Pointer<Void>, Int)>(
    symbol: 'InternalFlutterGpu_ComputePass_BindSet',
  )
  external void _bindSet(BindingSet bindingSet, int slot);

  @Native<Void Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_ComputePass_ClearBindings',
  )
  external void _clearBindings();

  @Native<Handle Function(Pointer<Void>, Int, Int, Int)>(
    symbol: 'InternalFlutterGpu_ComputePass_Dispatch',
  )
  external String? _dispatch(
    int workgroupCountX,
    int workgroupCountY,
    int workgroupCountZ,
  );
}
