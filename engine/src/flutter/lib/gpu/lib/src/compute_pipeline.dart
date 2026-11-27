// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_gpu;

/// A compute pipeline built from a single compute [Shader], which a
/// [ComputePass] dispatches.
///
/// Create one with [GpuContext.createComputePipeline]. The workgroup size is
/// the `local_size` the shader declares.
///
/// When the shader's [ShaderLibrary] hot reloads, the next dispatch with this
/// pipeline runs the reloaded code.
base class ComputePipeline extends NativeFieldWrapperClass1 {
  /// Creates a new ComputePipeline.
  ComputePipeline._(GpuContext gpuContext, this.shader) {
    final String? error = _initialize(gpuContext, shader);
    if (error != null) {
      throw Exception(error);
    }
  }

  /// The compute shader this pipeline runs.
  final Shader shader;

  /// Wrap with native counterpart.
  @Native<Handle Function(Handle, Pointer<Void>, Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_ComputePipeline_Initialize',
  )
  external String? _initialize(GpuContext gpuContext, Shader shader);
}
