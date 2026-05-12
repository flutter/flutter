// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  /// One 32-bit float (4 bytes).
  float32(bytesPerElement: 4, componentCount: 1),

  /// Two 32-bit floats (8 bytes).
  float32x2(bytesPerElement: 8, componentCount: 2),

  /// Three 32-bit floats (12 bytes).
  float32x3(bytesPerElement: 12, componentCount: 3),

  /// Four 32-bit floats (16 bytes).
  float32x4(bytesPerElement: 16, componentCount: 4),

  /// One 32-bit unsigned integer (4 bytes).
  uint32(bytesPerElement: 4, componentCount: 1),

  /// Two 32-bit unsigned integers (8 bytes).
  uint32x2(bytesPerElement: 8, componentCount: 2),

  /// Three 32-bit unsigned integers (12 bytes).
  uint32x3(bytesPerElement: 12, componentCount: 3),

  /// Four 32-bit unsigned integers (16 bytes).
  uint32x4(bytesPerElement: 16, componentCount: 4),

  /// One 32-bit signed integer (4 bytes).
  sint32(bytesPerElement: 4, componentCount: 1),

  /// Two 32-bit signed integers (8 bytes).
  sint32x2(bytesPerElement: 8, componentCount: 2),

  /// Three 32-bit signed integers (12 bytes).
  sint32x3(bytesPerElement: 12, componentCount: 3),

  /// Four 32-bit signed integers (16 bytes).
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
/// its byte offset within the owning vertex buffer's element, and its format.
///
/// The [name] must exactly match an `in` (or equivalent stage input)
/// declaration in the bound vertex shader. Looking the attribute up by name
/// (rather than by raw location index) keeps Dart-side layouts robust to
/// shader source edits, mirroring how uniform bindings are resolved by name
/// via `Shader.getUniformSlot`.
///
/// Two attributes within the same [VertexBuffer] must not occupy overlapping
/// byte ranges (i.e. `[offsetInBytes, offsetInBytes + format.bytesPerElement)`
/// ranges must be disjoint across the buffer's attributes).
final class VertexAttribute {
  /// Creates a vertex attribute description bound to the shader-side input
  /// named [name], reading its data in the given [format] starting at byte
  /// [offsetInBytes] into each element of the owning vertex buffer.
  const VertexAttribute({
    required this.name,
    required this.format,
    this.offsetInBytes = 0,
  });

  /// Name of the shader-side input this attribute feeds (e.g. `position`).
  final String name;

  /// Format of each attribute element.
  final VertexFormat format;

  /// Byte offset of this attribute from the start of each element in the
  /// owning vertex buffer. Must satisfy
  /// `offsetInBytes + format.bytesPerElement <= VertexBuffer.strideInBytes`.
  ///
  /// Defaults to 0, which is the common case for a structure-of-arrays
  /// layout where each buffer holds exactly one attribute.
  final int offsetInBytes;
}

/// Describes one vertex buffer slot: its per-element stride and the
/// attributes that are read from it.
///
/// A buffer's position in [VertexLayout.buffers] determines the binding
/// slot it is bound to via [RenderPass.bindVertexBuffer]; the first buffer
/// is slot 0, the second is slot 1, and so on. Sparse binding slots are
/// not currently supported.
///
/// Step mode (vertex vs instance) and instance step rate are not yet
/// configurable; every buffer currently advances per vertex. Both options
/// will be added later as named parameters with sensible defaults, and the
/// addition will be a non-breaking change for existing call sites.
// TODO(https://github.com/flutter/flutter/issues/186307): Allow specifying
// vertex step mode and instance step rate.
// TODO(https://github.com/flutter/flutter/issues/186308): Allow sparse
// vertex buffer binding slots.
final class VertexBuffer {
  /// Creates a vertex buffer slot description with the given per-element
  /// [strideInBytes] and the list of [attributes] that the vertex shader
  /// reads from this buffer.
  const VertexBuffer({required this.strideInBytes, required this.attributes});

  /// Byte distance from the start of one element to the start of the next
  /// element in this vertex buffer (not the gap between an element's end and
  /// the next element's start). Equivalent to the size of a single vertex
  /// element plus any trailing padding before the next element begins. For a
  /// tightly packed structure-of-arrays buffer carrying a single attribute,
  /// this is the same as `attributes[0].format.bytesPerElement`.
  final int strideInBytes;

  /// Attributes read from this vertex buffer by the vertex shader.
  final List<VertexAttribute> attributes;
}

/// A complete vertex input layout: zero or more vertex buffer slots and the
/// attributes that read from each one.
///
/// Pass an instance of this class to `GpuContext.createRenderPipeline` to
/// override the default interleaved layout that the shader bundle declares
/// (e.g. to bind position and color attributes from separate buffers, or to
/// consume a structure-of-arrays mesh without converting to interleaved
/// form on the CPU).
final class VertexLayout {
  /// Creates a vertex input layout that reads from the given [buffers].
  const VertexLayout({required this.buffers});

  /// Vertex buffer slots this layout uses. Each buffer's position in this
  /// list determines the binding slot it must be bound to via
  /// [RenderPass.bindVertexBuffer] before drawing.
  final List<VertexBuffer> buffers;
}
