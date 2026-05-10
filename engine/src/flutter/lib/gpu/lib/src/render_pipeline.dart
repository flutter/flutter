// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

base class RenderPipeline extends NativeFieldWrapperClass1 {
  /// Creates a new RenderPipeline.
  ///
  /// If [vertexLayout] is null, the default interleaved layout declared by
  /// the bound vertex shader's shader bundle is used. Supply a layout to
  /// override the default, e.g. to bind multiple structure-of-arrays vertex
  /// buffers or to reorder attributes.
  RenderPipeline._(
    GpuContext gpuContext,
    Shader vertexShader,
    Shader fragmentShader, {
    VertexLayout? vertexLayout,
  }) : vertexShader = vertexShader,
       fragmentShader = fragmentShader {
    final (ByteData?, ByteData?) packed = vertexLayout == null
        ? (null, null)
        : _packVertexLayout(vertexLayout);
    String? error = _initialize(
      gpuContext,
      vertexShader,
      fragmentShader,
      packed.$1,
      packed.$2,
    );
    if (error != null) {
      throw Exception(error);
    }
  }

  final Shader vertexShader;
  final Shader fragmentShader;

  /// Packs a [VertexLayout] into the two `Int32List` ByteData buffers expected
  /// by the C++ side: `[binding, stride]` per buffer entry, and
  /// `[location, bufferBinding, offset, formatIndex]` per attribute entry.
  static (ByteData, ByteData) _packVertexLayout(VertexLayout layout) {
    final Int32List buffersData = Int32List(2 * layout.buffers.length);
    for (int i = 0; i < layout.buffers.length; i++) {
      final VertexBufferLayout buf = layout.buffers[i];
      buffersData[i * 2 + 0] = buf.binding;
      buffersData[i * 2 + 1] = buf.strideInBytes;
    }
    final Int32List attributesData = Int32List(4 * layout.attributes.length);
    for (int i = 0; i < layout.attributes.length; i++) {
      final VertexAttribute attr = layout.attributes[i];
      attributesData[i * 4 + 0] = attr.location;
      attributesData[i * 4 + 1] = attr.bufferBinding;
      attributesData[i * 4 + 2] = attr.offsetInBytes;
      attributesData[i * 4 + 3] = attr.format.index;
    }
    return (
      buffersData.buffer.asByteData(),
      attributesData.buffer.asByteData(),
    );
  }

  /// Wrap with native counterpart.
  @Native<
    Handle Function(
      Handle,
      Pointer<Void>,
      Pointer<Void>,
      Pointer<Void>,
      Handle,
      Handle,
    )
  >(symbol: 'InternalFlutterGpu_RenderPipeline_Initialize')
  external String? _initialize(
    GpuContext gpuContext,
    Shader vertexShader,
    Shader fragmentShader,
    ByteData? bufferLayoutsData,
    ByteData? attributesData,
  );
}
