// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

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

enum PixelFormat {
  unknown,
  a8UNormInt,
  r8UNormInt,
  r8g8UNormInt,
  r8g8b8a8UNormInt,
  r8g8b8a8UNormIntSRGB,
  b8g8r8a8UNormInt,
  b8g8r8a8UNormIntSRGB,
  r32g32b32a32Float,
  r16g16b16a16Float,

  /// A single-channel 32-bit floating-point pixel format.
  r32Float,
  // Depth and stencil formats.
  s8UInt,
  d24UnormS8Uint,
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

enum TextureCoordinateSystem {
  /// Alternative coordinate system used when uploading texture data from the
  /// host.
  /// (0, 0) is the bottom-left of the image with +Y going up.
  uploadFromHost,

  /// Default coordinate system.
  /// (0, 0) is the top-left of the image with +Y going down.
  renderToTexture,
}

enum BlendFactor {
  zero,
  one,
  sourceColor,
  oneMinusSourceColor,
  sourceAlpha,
  oneMinusSourceAlpha,
  destinationColor,
  oneMinusDestinationColor,
  destinationAlpha,
  oneMinusDestinationAlpha,
  sourceAlphaSaturated,
  blendColor,
  oneMinusBlendColor,
  blendAlpha,
  oneMinusBlendAlpha,
}

enum BlendOperation { add, subtract, reverseSubtract }

enum LoadAction { dontCare, load, clear }

enum StoreAction {
  dontCare,
  store,
  multisampleResolve,
  storeAndMultisampleResolve,
}

enum ShaderStage { vertex, fragment }

enum MinMagFilter { nearest, linear }

enum MipFilter { nearest, linear }

enum SamplerAddressMode { clampToEdge, repeat, mirror }

enum IndexType { int16, int32 }

enum PrimitiveType { triangle, triangleStrip, line, lineStrip, point }

enum CullMode { none, frontFace, backFace }

enum WindingOrder { clockwise, counterClockwise }

enum PolygonMode { fill, line }

enum CompareFunction {
  /// Comparison test never passes.
  never,

  /// Comparison test passes always passes.
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
