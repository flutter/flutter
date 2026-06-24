// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_gpu;

// ATTENTION! ATTENTION! ATTENTION!
// All enum classes defined in this file must exactly match the contents and
// order of the corresponding enums defined in `gpu/formats.h`.

/// Specifies where an allocation resides and how it may be used.
enum StorageMode {
  /// Allocations can be mapped onto the hosts address space and also be used by
  /// the device.
  hostVisible,

  /// Allocations can only be used by the device. This location is optimal for
  /// use by the device. If the host needs to access these allocations, the
  /// data must first be copied into a host visible allocation.
  devicePrivate,

  /// Used by the device for temporary render targets. These allocations cannot
  /// be copied to or from other allocations. This storage mode is only valid
  /// for Textures.
  ///
  /// These allocations reside in tile memory which has higher bandwidth, lower
  /// latency and lower power consumption. The total device memory usage is
  /// also lower as a separate allocation does not need to be created in
  /// device memory. Prefer using these allocations for intermediates like depth
  /// and stencil buffers.
  deviceTransient,
}

/// The memory layout of the texels in a [Texture].
///
/// Each name spells out the texture's components in order, the bit width of
/// each component, and how those bits are interpreted. For example,
/// [r8g8b8a8UNormInt] is a 32 bit per pixel format with four 8 bit components
/// ordered red, green, blue, alpha, each stored as an unsigned normalized
/// integer.
///
/// Component key:
///
///  * `r`, `g`, `b`: the red, green, and blue color components.
///  * `a`: the alpha component.
///  * `d`: the depth component.
///  * `s`: the stencil component.
///  * `UNorm`: an unsigned integer that is mapped from the range
///    `[0, 2^bits - 1]` onto the floating point range `[0.0, 1.0]` when read.
///  * `UInt`: an unsigned integer that is read without normalization.
///  * `Float`: an IEEE 754 floating point value.
///  * `SRGB`: the color components are stored in the sRGB color space and are
///    converted to and from linear space when read and written.
///
/// The block-compressed formats are named after their compression scheme (BC,
/// ETC2, or ASTC) and block dimensions. See [PixelFormatProperties] for block
/// geometry and [TextureCompressionFamily] for how hardware support is
/// grouped.
enum PixelFormat {
  /// An invalid or unspecified format.
  ///
  /// Used as a placeholder and never as the format of a real texture.
  unknown,

  /// A single 8 bit alpha component, stored as an unsigned normalized integer.
  a8UNormInt,

  /// A single 8 bit red component, stored as an unsigned normalized integer.
  r8UNormInt,

  /// Two 8 bit components (red, green), stored as unsigned normalized integers.
  r8g8UNormInt,

  /// Four 8 bit components (red, green, blue, alpha), stored as unsigned
  /// normalized integers.
  ///
  /// This is the most common 32 bit per pixel color format and the default for
  /// [GpuContext.createTexture].
  r8g8b8a8UNormInt,

  /// Like [r8g8b8a8UNormInt], but the color components are stored in the sRGB
  /// color space.
  r8g8b8a8UNormIntSRGB,

  /// Four 8 bit components ordered blue, green, red, alpha, stored as unsigned
  /// normalized integers.
  b8g8r8a8UNormInt,

  /// Like [b8g8r8a8UNormInt], but the color components are stored in the sRGB
  /// color space.
  b8g8r8a8UNormIntSRGB,

  /// Four 32 bit floating point components (red, green, blue, alpha), for a
  /// total of 128 bits per pixel.
  r32g32b32a32Float,

  /// Four 16 bit (half precision) floating point components (red, green, blue,
  /// alpha), for a total of 64 bits per pixel.
  r16g16b16a16Float,

  /// A single-channel 32-bit floating-point pixel format.
  r32Float,
  // Depth and stencil formats.
  /// A single 8 bit stencil component, stored as an unsigned integer.
  s8UInt,

  /// A 24 bit depth component stored as an unsigned normalized integer, packed
  /// together with an 8 bit unsigned integer stencil component.
  d24UnormS8Uint,

  /// A 32 bit floating point depth component, packed together with an 8 bit
  /// unsigned integer stencil component.
  d32FloatS8UInt,
  // Block-compressed formats. These are sample-only: they cannot be used as
  // render targets, with storage modes other than `hostVisible`/`devicePrivate`,
  // for shader writes, or with multisampling. Hardware support varies by
  // family; check [GpuContext.supportsTextureCompression] before allocating.
  /// BC1 RGBA, 4x4 blocks, 8 bytes per block. Desktop BC family.
  bc1RGBAUNormInt,

  /// BC1 RGBA sRGB, 4x4 blocks, 8 bytes per block. Desktop BC family.
  bc1RGBAUNormIntSRGB,

  /// BC3 RGBA, 4x4 blocks, 16 bytes per block. Desktop BC family.
  bc3RGBAUNormInt,

  /// BC3 RGBA sRGB, 4x4 blocks, 16 bytes per block. Desktop BC family.
  bc3RGBAUNormIntSRGB,

  /// BC5 RG, 4x4 blocks, 16 bytes per block. Desktop BC family.
  bc5RGUNormInt,

  /// BC7 RGBA, 4x4 blocks, 16 bytes per block. Desktop BC family.
  bc7RGBAUNormInt,

  /// BC7 RGBA sRGB, 4x4 blocks, 16 bytes per block. Desktop BC family.
  bc7RGBAUNormIntSRGB,

  /// ETC2 RGB8, 4x4 blocks, 8 bytes per block. Mobile ETC2 family.
  etc2RGB8UNormInt,

  /// ETC2 RGB8 sRGB, 4x4 blocks, 8 bytes per block. Mobile ETC2 family.
  etc2RGB8UNormIntSRGB,

  /// ETC2 RGBA8, 4x4 blocks, 16 bytes per block. Mobile ETC2 family.
  etc2RGBA8UNormInt,

  /// ETC2 RGBA8 sRGB, 4x4 blocks, 16 bytes per block. Mobile ETC2 family.
  etc2RGBA8UNormIntSRGB,

  /// ASTC LDR, 4x4 blocks, 16 bytes per block. Modern mobile ASTC family.
  astc4x4LDR,

  /// ASTC LDR sRGB, 4x4 blocks, 16 bytes per block. Modern mobile ASTC family.
  astc4x4LDRSRGB,

  /// ASTC LDR, 8x8 blocks, 16 bytes per block. Modern mobile ASTC family.
  astc8x8LDR,

  /// ASTC LDR sRGB, 8x8 blocks, 16 bytes per block. Modern mobile ASTC family.
  astc8x8LDRSRGB,

  /// ASTC HDR, 4x4 blocks, 16 bytes per block. Modern mobile ASTC HDR family.
  /// HDR samples are linear floating point, so there is no sRGB variant.
  astc4x4HDR,

  /// ASTC HDR, 8x8 blocks, 16 bytes per block. Modern mobile ASTC HDR family.
  /// HDR samples are linear floating point, so there is no sRGB variant.
  astc8x8HDR,
}

/// The family of a block-compressed pixel format. Hardware support for
/// compressed formats is granted on a per-family basis.
enum TextureCompressionFamily {
  /// BC1 through BC7. Typical on desktop GPUs.
  bc,

  /// ETC2 and EAC. Typical on mobile, OpenGL ES 3.0, and WebGL2.
  etc2,

  /// ASTC LDR. Typical on modern mobile and some desktop GPUs.
  astc,

  /// ASTC HDR. A separate device feature from ASTC LDR. Typical on newer mobile
  /// GPUs.
  astcHdr,
}

/// Block-geometry and family queries for [PixelFormat].
extension PixelFormatProperties on PixelFormat {
  /// Whether this is a block-compressed pixel format.
  bool get isCompressed {
    return blockWidth > 1 || blockHeight > 1;
  }

  /// The width, in texels, of a single block. Uncompressed formats return 1.
  int get blockWidth {
    switch (this) {
      case PixelFormat.astc8x8LDR:
      case PixelFormat.astc8x8LDRSRGB:
      case PixelFormat.astc8x8HDR:
        return 8;
      case PixelFormat.bc1RGBAUNormInt:
      case PixelFormat.bc1RGBAUNormIntSRGB:
      case PixelFormat.bc3RGBAUNormInt:
      case PixelFormat.bc3RGBAUNormIntSRGB:
      case PixelFormat.bc5RGUNormInt:
      case PixelFormat.bc7RGBAUNormInt:
      case PixelFormat.bc7RGBAUNormIntSRGB:
      case PixelFormat.etc2RGB8UNormInt:
      case PixelFormat.etc2RGB8UNormIntSRGB:
      case PixelFormat.etc2RGBA8UNormInt:
      case PixelFormat.etc2RGBA8UNormIntSRGB:
      case PixelFormat.astc4x4LDR:
      case PixelFormat.astc4x4LDRSRGB:
      case PixelFormat.astc4x4HDR:
        return 4;
      // ignore: no_default_cases
      default:
        return 1;
    }
  }

  /// The height, in texels, of a single block. Uncompressed formats return 1.
  int get blockHeight {
    switch (this) {
      case PixelFormat.astc8x8LDR:
      case PixelFormat.astc8x8LDRSRGB:
      case PixelFormat.astc8x8HDR:
        return 8;
      case PixelFormat.bc1RGBAUNormInt:
      case PixelFormat.bc1RGBAUNormIntSRGB:
      case PixelFormat.bc3RGBAUNormInt:
      case PixelFormat.bc3RGBAUNormIntSRGB:
      case PixelFormat.bc5RGUNormInt:
      case PixelFormat.bc7RGBAUNormInt:
      case PixelFormat.bc7RGBAUNormIntSRGB:
      case PixelFormat.etc2RGB8UNormInt:
      case PixelFormat.etc2RGB8UNormIntSRGB:
      case PixelFormat.etc2RGBA8UNormInt:
      case PixelFormat.etc2RGBA8UNormIntSRGB:
      case PixelFormat.astc4x4LDR:
      case PixelFormat.astc4x4LDRSRGB:
      case PixelFormat.astc4x4HDR:
        return 4;
      // ignore: no_default_cases
      default:
        return 1;
    }
  }

  /// The number of bytes used to store one block. For uncompressed formats a
  /// block is a single texel, so this matches the bytes per texel.
  int get bytesPerBlock {
    switch (this) {
      case PixelFormat.unknown:
        return 0;
      case PixelFormat.a8UNormInt:
      case PixelFormat.r8UNormInt:
      case PixelFormat.s8UInt:
        return 1;
      case PixelFormat.r8g8UNormInt:
        return 2;
      case PixelFormat.r8g8b8a8UNormInt:
      case PixelFormat.r8g8b8a8UNormIntSRGB:
      case PixelFormat.b8g8r8a8UNormInt:
      case PixelFormat.b8g8r8a8UNormIntSRGB:
      case PixelFormat.r32Float:
      case PixelFormat.d24UnormS8Uint:
        return 4;
      case PixelFormat.d32FloatS8UInt:
        return 5;
      case PixelFormat.r16g16b16a16Float:
        return 8;
      case PixelFormat.r32g32b32a32Float:
        return 16;
      case PixelFormat.bc1RGBAUNormInt:
      case PixelFormat.bc1RGBAUNormIntSRGB:
      case PixelFormat.etc2RGB8UNormInt:
      case PixelFormat.etc2RGB8UNormIntSRGB:
        return 8;
      case PixelFormat.bc3RGBAUNormInt:
      case PixelFormat.bc3RGBAUNormIntSRGB:
      case PixelFormat.bc5RGUNormInt:
      case PixelFormat.bc7RGBAUNormInt:
      case PixelFormat.bc7RGBAUNormIntSRGB:
      case PixelFormat.etc2RGBA8UNormInt:
      case PixelFormat.etc2RGBA8UNormIntSRGB:
      case PixelFormat.astc4x4LDR:
      case PixelFormat.astc4x4LDRSRGB:
      case PixelFormat.astc8x8LDR:
      case PixelFormat.astc8x8LDRSRGB:
      case PixelFormat.astc4x4HDR:
      case PixelFormat.astc8x8HDR:
        return 16;
    }
  }

  /// The compression family this format belongs to. Returns null for
  /// uncompressed formats.
  TextureCompressionFamily? get compressionFamily {
    switch (this) {
      case PixelFormat.bc1RGBAUNormInt:
      case PixelFormat.bc1RGBAUNormIntSRGB:
      case PixelFormat.bc3RGBAUNormInt:
      case PixelFormat.bc3RGBAUNormIntSRGB:
      case PixelFormat.bc5RGUNormInt:
      case PixelFormat.bc7RGBAUNormInt:
      case PixelFormat.bc7RGBAUNormIntSRGB:
        return TextureCompressionFamily.bc;
      case PixelFormat.etc2RGB8UNormInt:
      case PixelFormat.etc2RGB8UNormIntSRGB:
      case PixelFormat.etc2RGBA8UNormInt:
      case PixelFormat.etc2RGBA8UNormIntSRGB:
        return TextureCompressionFamily.etc2;
      case PixelFormat.astc4x4LDR:
      case PixelFormat.astc4x4LDRSRGB:
      case PixelFormat.astc8x8LDR:
      case PixelFormat.astc8x8LDRSRGB:
        return TextureCompressionFamily.astc;
      case PixelFormat.astc4x4HDR:
      case PixelFormat.astc8x8HDR:
        return TextureCompressionFamily.astcHdr;
      // ignore: no_default_cases
      default:
        return null;
    }
  }
}

/// A coefficient that scales one input to the blend equation.
///
/// When blending is enabled for a color attachment, the new (source) color
/// produced by the fragment shader is combined with the existing (destination)
/// color already in the attachment. Each side is first multiplied by a
/// [BlendFactor] and then combined by a [BlendOperation]:
///
/// ```
/// result.rgb = (sourceColorFactor * source.rgb) <op> (destinationColorFactor * destination.rgb);
/// result.a   = (sourceAlphaFactor * source.a)   <op> (destinationAlphaFactor * destination.a);
/// ```
///
/// The "blend color" referenced by some factors is a separate constant color
/// supplied to the blend equation, distinct from the source and destination
/// colors.
enum BlendFactor {
  /// Multiplies the input by zero, dropping it from the blend.
  zero,

  /// Multiplies the input by one, leaving it unchanged.
  one,

  /// Multiplies the input by the source color, component by component.
  sourceColor,

  /// Multiplies the input by one minus the source color, component by
  /// component.
  oneMinusSourceColor,

  /// Multiplies the input by the source alpha.
  sourceAlpha,

  /// Multiplies the input by one minus the source alpha.
  oneMinusSourceAlpha,

  /// Multiplies the input by the destination color, component by component.
  destinationColor,

  /// Multiplies the input by one minus the destination color, component by
  /// component.
  oneMinusDestinationColor,

  /// Multiplies the input by the destination alpha.
  destinationAlpha,

  /// Multiplies the input by one minus the destination alpha.
  oneMinusDestinationAlpha,

  /// Multiplies the input by `min(sourceAlpha, 1 - destinationAlpha)`.
  sourceAlphaSaturated,

  /// Multiplies the input by the constant blend color, component by component.
  blendColor,

  /// Multiplies the input by one minus the constant blend color, component by
  /// component.
  oneMinusBlendColor,

  /// Multiplies the input by the alpha of the constant blend color.
  blendAlpha,

  /// Multiplies the input by one minus the alpha of the constant blend color.
  oneMinusBlendAlpha,
}

/// The operator that combines the scaled source and destination values in the
/// blend equation.
///
/// Each operand is first scaled by a [BlendFactor] before this operation is
/// applied.
enum BlendOperation {
  /// Adds the source and destination values: `source + destination`.
  add,

  /// Subtracts the destination from the source: `source - destination`.
  subtract,

  /// Subtracts the source from the destination: `destination - source`.
  reverseSubtract,
}

/// What happens to the contents of an attachment's [Texture] when a render
/// pass begins.
enum LoadAction {
  /// The existing contents are not preserved and may be left undefined.
  ///
  /// Use this when the entire attachment will be drawn over during the pass.
  dontCare,

  /// The existing contents of the texture are loaded so that the render pass
  /// draws on top of them.
  load,

  /// The texture is cleared to the attachment's clear value before drawing.
  clear,
}

/// What happens to the contents of an attachment's [Texture] when a render
/// pass ends.
enum StoreAction {
  /// The results are not guaranteed to be stored and may be discarded.
  ///
  /// Use this for transient attachments that are not read after the pass, such
  /// as a depth or stencil buffer used only during rendering.
  dontCare,

  /// The results are written back to the texture so they can be read later.
  store,

  /// The multisampled results are resolved into the attachment's resolve
  /// texture. The multisampled texture itself is not stored.
  multisampleResolve,

  /// The multisampled results are both stored and resolved into the
  /// attachment's resolve texture.
  storeAndMultisampleResolve,
}

/// A programmable stage of the render pipeline that a [Shader] runs in.
enum ShaderStage {
  /// The vertex stage, which runs once per input vertex.
  vertex,

  /// The fragment stage, which runs once per rasterized fragment.
  fragment,
}

/// How a [Texture] is sampled when it is minified or magnified to fit the area
/// being drawn.
enum MinMagFilter {
  /// Uses the value of the single texel nearest to the sample point.
  ///
  /// This is the most widely supported filter.
  nearest,

  /// Linearly interpolates between the texels nearest to the sample point.
  linear,
}

/// How samples are selected and filtered between the mipmap levels of a
/// [Texture].
enum MipFilter {
  /// Samples from the single nearest mipmap level.
  nearest,

  /// Samples from the two nearest mipmap levels and linearly interpolates
  /// between them.
  linear,
}

/// How texture coordinates outside the range `[0, 1]` are mapped back onto a
/// [Texture] when sampling.
enum SamplerAddressMode {
  /// Coordinates are clamped to the edge of the texture, so sampling outside
  /// the texture repeats its border texels.
  clampToEdge,

  /// The texture is tiled by wrapping coordinates around, keeping only their
  /// fractional part.
  repeat,

  /// The texture is tiled by mirroring it at every integer coordinate
  /// boundary.
  mirror,
}

/// The width of each element in an index buffer.
///
/// See [RenderPass.bindIndexBuffer].
enum IndexType {
  /// Each index is a 16 bit unsigned integer.
  int16,

  /// Each index is a 32 bit unsigned integer.
  int32,
}

/// How a sequence of vertices is assembled into primitives to be rasterized.
enum PrimitiveType {
  /// Draws a separate triangle for each group of three vertices.
  ///
  /// Vertices `[A, B, C, D, E, F]` produce triangles `[ABC, DEF]`.
  triangle,

  /// Draws a connected strip of triangles, adding one triangle for each vertex
  /// after the first two.
  ///
  /// Vertices `[A, B, C, D, E, F]` produce triangles
  /// `[ABC, BCD, CDE, DEF]`.
  triangleStrip,

  /// Draws a separate line segment for each pair of vertices.
  ///
  /// Vertices `[A, B, C, D]` produce line segments `[AB, CD]`.
  line,

  /// Draws a single connected line that passes through every vertex in order.
  ///
  /// Vertices `[A, B, C]` produce one connected line `[ABC]`.
  lineStrip,

  /// Draws a point at each vertex.
  point,
}

/// Which triangle faces, if any, are discarded before rasterization.
///
/// A triangle's facing is determined by its [WindingOrder].
enum CullMode {
  /// No triangles are culled. Both front and back faces are drawn.
  none,

  /// Front facing triangles are culled.
  frontFace,

  /// Back facing triangles are culled.
  backFace,
}

/// The vertex winding direction that defines the front face of a triangle.
///
/// Used together with [CullMode] to decide which triangles are discarded.
enum WindingOrder {
  /// Triangles whose vertices appear in clockwise order are front facing.
  clockwise,

  /// Triangles whose vertices appear in counter clockwise order are front
  /// facing.
  counterClockwise,
}

/// How triangles are rasterized: as filled areas or as outlines.
enum PolygonMode {
  /// Triangles are filled.
  fill,

  /// Only the edges of triangles are drawn, producing a wireframe.
  line,
}

/// The comparison applied between a new value and the value already stored in
/// the depth or stencil buffer.
///
/// The test passes when the comparison evaluates to true.
enum CompareFunction {
  /// Comparison test never passes.
  never,

  /// Comparison test always passes.
  always,

  /// Comparison test passes if new_value < current_value.
  less,

  /// Comparison test passes if new_value == current_value.
  equal,

  /// Comparison test passes if new_value <= current_value.
  lessEqual,

  /// Comparison test passes if new_value > current_value.
  greater,

  /// Comparison test passes if new_value != current_value.
  notEqual,

  /// Comparison test passes if new_value >= current_value.
  greaterEqual,
}

/// The operation performed on the value in the stencil buffer based on the
/// outcome of the stencil and depth tests.
///
/// See [StencilConfig].
enum StencilOperation {
  /// Don't modify the current stencil value.
  keep,

  /// Reset the stencil value to zero.
  zero,

  /// Reset the stencil value to the reference value.
  setToReferenceValue,

  /// Increment the current stencil value by 1. Clamp it to the maximum.
  incrementClamp,

  /// Decrement the current stencil value by 1. Clamp it to zero.
  decrementClamp,

  /// Perform a logical bitwise invert on the current stencil value.
  invert,

  /// Increment the current stencil value by 1. If at maximum, set to zero.
  incrementWrap,

  /// Decrement the current stencil value by 1. If at zero, set to maximum.
  decrementWrap,
}

/// The kind of a [Texture], which determines its dimensionality and how it is
/// sampled.
enum TextureType {
  /// A 2-dimensional texture.
  texture2D,

  /// A 2-dimensional texture with multisampling enabled.
  texture2DMultisample,

  /// A cubemap texture.
  textureCube,

  /// A texture sourced from an external source.
  textureExternalOES,
}
