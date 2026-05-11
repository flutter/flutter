// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

/// The format of a single vertex attribute.
///
/// Each value names a component count, scalar type, and bit width. The enum
/// currently covers the 32-bit-per-component scalar types (float, signed
/// integer, unsigned integer) in 1, 2, 3, and 4 component widths. Normalized
/// integer, packed, half-float, BGRA-swizzled, and 64-bit attribute formats
/// will be added in a future release; new values are purely additive and
/// won't affect callers using existing values.
// TODO(https://github.com/flutter/flutter/issues/186309): Add normalized,
// packed, half-float, BGRA-swizzled, and 64-bit vertex attribute formats.
enum VertexFormat {
  float32(bytesPerElement: 4, componentCount: 1),
  float32x2(bytesPerElement: 8, componentCount: 2),
  float32x3(bytesPerElement: 12, componentCount: 3),
  float32x4(bytesPerElement: 16, componentCount: 4),

  uint32(bytesPerElement: 4, componentCount: 1),
  uint32x2(bytesPerElement: 8, componentCount: 2),
  uint32x3(bytesPerElement: 12, componentCount: 3),
  uint32x4(bytesPerElement: 16, componentCount: 4),

  sint32(bytesPerElement: 4, componentCount: 1),
  sint32x2(bytesPerElement: 8, componentCount: 2),
  sint32x3(bytesPerElement: 12, componentCount: 3),
  sint32x4(bytesPerElement: 16, componentCount: 4);

  const VertexFormat({
    required this.bytesPerElement,
    required this.componentCount,
  });

  /// Total size in bytes of a single attribute element of this format.
  final int bytesPerElement;

  /// Number of scalar components in a single attribute element.
  final int componentCount;
}

/// Describes a single vertex attribute: which shader input it feeds (by name),
/// which vertex buffer slot it reads from, the byte offset within that
/// buffer's element, and its format.
///
/// The [name] must exactly match an `in` (or equivalent stage input)
/// declaration in the bound vertex shader. Looking the attribute up by name
/// (rather than by raw location index) keeps Dart-side layouts robust to
/// shader source edits, mirroring how uniform bindings are resolved by name
/// via `Shader.getUniformSlot`.
final class VertexAttribute {
  const VertexAttribute({
    required this.name,
    required this.bufferBinding,
    required this.offsetInBytes,
    required this.format,
  });

  /// Name of the shader-side input this attribute feeds (e.g. `position`).
  final String name;

  /// Vertex buffer slot that this attribute reads from. Must reference a
  /// [VertexBufferLayout.binding] present in the same [VertexLayout].
  final int bufferBinding;

  /// Byte offset of this attribute from the start of each element in the
  /// referenced vertex buffer. Must satisfy
  /// `offsetInBytes + format.bytesPerElement <= layout.strideInBytes`.
  final int offsetInBytes;

  /// Format of each attribute element.
  final VertexFormat format;
}

/// Describes one vertex buffer slot: its binding index and per-element stride.
///
/// Step mode (vertex vs instance) and instance step rate are not yet
/// configurable; every binding currently advances per vertex. Both options
/// will be added later as named parameters with sensible defaults, and the
/// addition will be a non-breaking change for existing call sites.
///
/// The [binding] indices used across a [VertexLayout] must be densely
/// packed starting from 0 (i.e. `0, 1, 2, ...`), and every binding
/// declared in the layout must have a buffer bound via
/// [RenderPass.bindVertexBuffer] before drawing. Sparse binding indices
/// are not currently supported.
// TODO(https://github.com/flutter/flutter/issues/186307): Allow specifying
// vertex step mode and instance step rate.
// TODO(https://github.com/flutter/flutter/issues/186308): Allow sparse
// vertex buffer binding indices.
final class VertexBufferLayout {
  const VertexBufferLayout({
    required this.binding,
    required this.strideInBytes,
  });

  /// Binding index for this vertex buffer slot.
  final int binding;

  /// Byte distance between consecutive elements in this vertex buffer.
  final int strideInBytes;
}

/// A complete vertex input layout: zero or more vertex buffer slots and the
/// attributes that read from them.
///
/// Pass an instance of this class to `GpuContext.createRenderPipeline` to
/// override the default interleaved layout that the shader bundle declares
/// (e.g. to bind position and color attributes from separate buffers, or to
/// consume a structure-of-arrays mesh without converting to interleaved
/// form on the CPU).
final class VertexLayout {
  const VertexLayout({required this.buffers, required this.attributes});

  /// Vertex buffer slots this layout uses. Each entry's [VertexBufferLayout
  /// .binding] must be referenced by at least one [VertexAttribute].
  final List<VertexBufferLayout> buffers;

  /// Attributes consumed by the vertex shader. Each [VertexAttribute
  /// .bufferBinding] must reference a [VertexBufferLayout.binding] present
  /// in [buffers].
  final List<VertexAttribute> attributes;
}
