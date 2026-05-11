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
  /// * `bufferLayouts` (`Int32List`): `[strideInBytes, attributeCount]` per
  ///   buffer entry. The buffer's binding slot is implicit in its position.
  /// * `attributes` (`Int32List`): `[offsetInBytes, formatIndex,
  ///   nameByteLength]` per attribute entry, flattened across buffers in
  ///   buffer-list order. Each buffer's `attributeCount` row tells the C++
  ///   side how many attribute rows belong to it.
  /// * `attributeNames`: concatenated UTF-8 bytes of every attribute name,
  ///   walked in parallel with `attributes` using the per-entry name length.
  ///
  /// Attribute names are ASCII GLSL identifiers, so encoding them as UTF-8
  /// byte sequences via `codeUnits` is sufficient without a separate
  /// dependency on `dart:convert`.
  static (ByteData, ByteData, ByteData) _packVertexLayout(VertexLayout layout) {
    int totalAttributeCount = 0;
    for (int i = 0; i < layout.buffers.length; i++) {
      totalAttributeCount += layout.buffers[i].attributes.length;
    }

    final Int32List buffersData = Int32List(2 * layout.buffers.length);
    for (int i = 0; i < layout.buffers.length; i++) {
      final VertexBuffer buf = layout.buffers[i];
      buffersData[i * 2 + 0] = buf.strideInBytes;
      buffersData[i * 2 + 1] = buf.attributes.length;
    }

    // First pass: encode each name to bytes and compute the total length,
    // walking attributes in buffer-list order.
    final List<Uint8List> nameBytes = <Uint8List>[];
    int totalNameBytes = 0;
    for (int b = 0; b < layout.buffers.length; b++) {
      final List<VertexAttribute> attrs = layout.buffers[b].attributes;
      for (int a = 0; a < attrs.length; a++) {
        final Uint8List bytes = Uint8List.fromList(attrs[a].name.codeUnits);
        nameBytes.add(bytes);
        totalNameBytes += bytes.length;
      }
    }

    // Second pass: pack the attribute integer table and the names blob.
    final Int32List attributesData = Int32List(3 * totalAttributeCount);
    final Uint8List namesData = Uint8List(totalNameBytes);
    int attrIndex = 0;
    int nameCursor = 0;
    for (int b = 0; b < layout.buffers.length; b++) {
      final List<VertexAttribute> attrs = layout.buffers[b].attributes;
      for (int a = 0; a < attrs.length; a++) {
        final VertexAttribute attr = attrs[a];
        final Uint8List bytes = nameBytes[attrIndex];
        attributesData[attrIndex * 3 + 0] = attr.offsetInBytes;
        attributesData[attrIndex * 3 + 1] = attr.format.index;
        attributesData[attrIndex * 3 + 2] = bytes.length;
        namesData.setRange(nameCursor, nameCursor + bytes.length, bytes);
        nameCursor += bytes.length;
        attrIndex++;
      }
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
