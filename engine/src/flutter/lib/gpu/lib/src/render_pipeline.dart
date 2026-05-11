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
    final (ByteData?, ByteData?, ByteData?) packed = vertexLayout == null
        ? (null, null, null)
        : _packVertexLayout(vertexLayout);
    String? error = _initialize(
      gpuContext,
      vertexShader,
      fragmentShader,
      packed.$1,
      packed.$2,
      packed.$3,
    );
    if (error != null) {
      throw Exception(error);
    }
  }

  final Shader vertexShader;
  final Shader fragmentShader;

  /// Packs a [VertexLayout] into the three ByteData buffers expected by the
  /// C++ side:
  ///
  /// * `bufferLayouts` (`Int32List`): `[binding, stride]` per buffer entry.
  /// * `attributes` (`Int32List`): `[bufferBinding, offset, formatIndex,
  ///   nameByteLength]` per attribute entry.
  /// * `attributeNames`: concatenated UTF-8 bytes of every attribute name,
  ///   walked in parallel with `attributes` using the per-entry name length.
  ///
  /// Attribute names are ASCII GLSL identifiers, so encoding them as UTF-8
  /// byte sequences via `codeUnits` is sufficient without a separate
  /// dependency on `dart:convert`.
  static (ByteData, ByteData, ByteData) _packVertexLayout(VertexLayout layout) {
    final Int32List buffersData = Int32List(2 * layout.buffers.length);
    for (int i = 0; i < layout.buffers.length; i++) {
      final VertexBufferLayout buf = layout.buffers[i];
      buffersData[i * 2 + 0] = buf.binding;
      buffersData[i * 2 + 1] = buf.strideInBytes;
    }

    // First pass: encode each name to bytes and compute the total length.
    final List<Uint8List> nameBytes = <Uint8List>[];
    int totalNameBytes = 0;
    for (int i = 0; i < layout.attributes.length; i++) {
      final Uint8List bytes = Uint8List.fromList(
        layout.attributes[i].name.codeUnits,
      );
      nameBytes.add(bytes);
      totalNameBytes += bytes.length;
    }

    // Second pass: pack the attribute integer table and the names blob.
    final Int32List attributesData = Int32List(4 * layout.attributes.length);
    final Uint8List namesData = Uint8List(totalNameBytes);
    int nameCursor = 0;
    for (int i = 0; i < layout.attributes.length; i++) {
      final VertexAttribute attr = layout.attributes[i];
      final Uint8List bytes = nameBytes[i];
      attributesData[i * 4 + 0] = attr.bufferBinding;
      attributesData[i * 4 + 1] = attr.offsetInBytes;
      attributesData[i * 4 + 2] = attr.format.index;
      attributesData[i * 4 + 3] = bytes.length;
      namesData.setRange(nameCursor, nameCursor + bytes.length, bytes);
      nameCursor += bytes.length;
    }

    return (
      buffersData.buffer.asByteData(),
      attributesData.buffer.asByteData(),
      namesData.buffer.asByteData(),
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
      Handle,
    )
  >(symbol: 'InternalFlutterGpu_RenderPipeline_Initialize')
  external String? _initialize(
    GpuContext gpuContext,
    Shader vertexShader,
    Shader fragmentShader,
    ByteData? bufferLayoutsData,
    ByteData? attributesData,
    ByteData? attributeNamesData,
  );
}
