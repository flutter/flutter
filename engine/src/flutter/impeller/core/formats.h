// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_FORMATS_H_
#define FLUTTER_IMPELLER_CORE_FORMATS_H_

#include <cstdint>
#include <functional>
#include <memory>
#include <string>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/logging.h"
#include "impeller/base/mask.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/scalar.h"

namespace impeller {

enum class WindingOrder {
  kClockwise,
  kCounterClockwise,
};

class Texture;

//------------------------------------------------------------------------------
/// @brief      Specified where the allocation resides and how it is used.
///
enum class StorageMode {
  //----------------------------------------------------------------------------
  /// Allocations can be mapped onto the hosts address space and also be used by
  /// the device.
  ///
  kHostVisible,
  //----------------------------------------------------------------------------
  /// Allocations can only be used by the device. This location is optimal for
  /// use by the device. If the host needs to access these allocations, the
  /// transfer queue must be used to transfer this allocation onto the a host
  /// visible buffer.
  ///
  kDevicePrivate,
  //----------------------------------------------------------------------------
  /// Used by the device for temporary render targets. These allocations cannot
  /// be transferred from and to other allocations using the transfer queue.
  /// Render pass cannot initialize the contents of these buffers using load and
  /// store actions.
  ///
  /// These allocations reside in tile memory which has higher bandwidth, lower
  /// latency and lower power consumption. The total device memory usage is
  /// also lower as a separate allocation does not need to be created in
  /// device memory. Prefer using these allocations for intermediates like depth
  /// and stencil buffers.
  ///
  kDeviceTransient,
};

constexpr const char* StorageModeToString(StorageMode mode) {
  switch (mode) {
    case StorageMode::kHostVisible:
      return "HostVisible";
    case StorageMode::kDevicePrivate:
      return "DevicePrivate";
    case StorageMode::kDeviceTransient:
      return "DeviceTransient";
  }
  FML_UNREACHABLE();
}

//------------------------------------------------------------------------------
/// @brief      The Pixel formats supported by Impeller. The naming convention
///             denotes the usage of the component, the bit width of that
///             component, and then one or more qualifiers to its
///             interpretation.
///
///             For instance, `kR8G8B8A8UNormIntSRGB` is a 32 bits-per-pixel
///             format ordered in RGBA with 8 bits per component with each
///             component expressed as an unsigned normalized integer and a
///             conversion from sRGB to linear color space.
///
///             Key:
///               R -> Red Component
///               G -> Green Component
///               B -> Blue Component
///               D -> Depth Component
///               S -> Stencil Component
///               U -> Unsigned (Lack of this denotes a signed component)
///               Norm -> Normalized
///               SRGB -> sRGB to linear interpretation
///
///             While the effective bit width of the pixel can be determined by
///             adding up the widths of each component, only the non-esoteric
///             formats are tightly packed. Do not assume tight packing for the
///             esoteric formats and use blit passes to convert to a
///             non-esoteric pass.
///
enum class PixelFormat : uint8_t {
  kUnknown,
  kA8UNormInt,
  kR8UNormInt,
  kR8G8UNormInt,
  kR8G8B8A8UNormInt,
  kR8G8B8A8UNormIntSRGB,
  kB8G8R8A8UNormInt,
  kB8G8R8A8UNormIntSRGB,
  kR32G32B32A32Float,
  kR16G16B16A16Float,
  kB10G10R10XR,
  kB10G10R10XRSRGB,
  kB10G10R10A10XR,
  kR32Float,
  // Depth and stencil formats.
  kS8UInt,
  kD24UnormS8Uint,
  kD32FloatS8UInt,
  // Block-compressed formats. These are sample-only; they cannot be used as
  // render targets, storage textures, or transient attachments, and their
  // support varies by device (see `Capabilities::SupportsTextureCompression`).
  kBC1RGBAUNormInt,
  kBC1RGBAUNormIntSRGB,
  kBC3RGBAUNormInt,
  kBC3RGBAUNormIntSRGB,
  kBC5RGUNormInt,
  kBC7RGBAUNormInt,
  kBC7RGBAUNormIntSRGB,
  kETC2RGB8UNormInt,
  kETC2RGB8UNormIntSRGB,
  kETC2RGBA8UNormInt,
  kETC2RGBA8UNormIntSRGB,
  kASTC4x4LDR,
  kASTC4x4LDRSRGB,
  kASTC8x8LDR,
  kASTC8x8LDRSRGB,
  // ASTC HDR has no sRGB variant; the data is already linear floating point.
  kASTC4x4HDR,
  kASTC8x8HDR,
};

//------------------------------------------------------------------------------
/// @brief      The family of a block-compressed pixel format. GPUs support
///             compressed formats on a per-family basis, so each family is
///             gated behind a single device feature.
///
enum class CompressedTextureFamily {
  /// S3TC, RGTC, and BPTC (BC1 through BC7). Desktop GPUs.
  kBC,
  /// ETC2 and EAC. Mobile, OpenGL ES 3.0, and WebGL2.
  kETC2,
  /// ASTC LDR. Modern mobile and some desktop.
  kASTC,
  /// ASTC HDR. A separate device feature from ASTC LDR.
  kASTCHDR,
};

/// @brief Whether `format` is a block-compressed format.
constexpr bool IsCompressed(PixelFormat format) {
  switch (format) {
    case PixelFormat::kBC1RGBAUNormInt:
    case PixelFormat::kBC1RGBAUNormIntSRGB:
    case PixelFormat::kBC3RGBAUNormInt:
    case PixelFormat::kBC3RGBAUNormIntSRGB:
    case PixelFormat::kBC5RGUNormInt:
    case PixelFormat::kBC7RGBAUNormInt:
    case PixelFormat::kBC7RGBAUNormIntSRGB:
    case PixelFormat::kETC2RGB8UNormInt:
    case PixelFormat::kETC2RGB8UNormIntSRGB:
    case PixelFormat::kETC2RGBA8UNormInt:
    case PixelFormat::kETC2RGBA8UNormIntSRGB:
    case PixelFormat::kASTC4x4LDR:
    case PixelFormat::kASTC4x4LDRSRGB:
    case PixelFormat::kASTC8x8LDR:
    case PixelFormat::kASTC8x8LDRSRGB:
    case PixelFormat::kASTC4x4HDR:
    case PixelFormat::kASTC8x8HDR:
      return true;
    default:
      return false;
  }
}

/// @brief The compression family that `format` belongs to. Only valid for
///        formats where `IsCompressed` is true.
constexpr CompressedTextureFamily CompressedTextureFamilyForFormat(
    PixelFormat format) {
  switch (format) {
    case PixelFormat::kBC1RGBAUNormInt:
    case PixelFormat::kBC1RGBAUNormIntSRGB:
    case PixelFormat::kBC3RGBAUNormInt:
    case PixelFormat::kBC3RGBAUNormIntSRGB:
    case PixelFormat::kBC5RGUNormInt:
    case PixelFormat::kBC7RGBAUNormInt:
    case PixelFormat::kBC7RGBAUNormIntSRGB:
      return CompressedTextureFamily::kBC;
    case PixelFormat::kETC2RGB8UNormInt:
    case PixelFormat::kETC2RGB8UNormIntSRGB:
    case PixelFormat::kETC2RGBA8UNormInt:
    case PixelFormat::kETC2RGBA8UNormIntSRGB:
      return CompressedTextureFamily::kETC2;
    case PixelFormat::kASTC4x4LDR:
    case PixelFormat::kASTC4x4LDRSRGB:
    case PixelFormat::kASTC8x8LDR:
    case PixelFormat::kASTC8x8LDRSRGB:
      return CompressedTextureFamily::kASTC;
    case PixelFormat::kASTC4x4HDR:
    case PixelFormat::kASTC8x8HDR:
      return CompressedTextureFamily::kASTCHDR;
    default:
      break;
  }
  FML_UNREACHABLE();
}

/// @brief The width, in texels, of one compression block. Uncompressed formats
///        report 1.
constexpr size_t CompressedBlockWidthForPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::kASTC8x8LDR:
    case PixelFormat::kASTC8x8LDRSRGB:
    case PixelFormat::kASTC8x8HDR:
      return 8u;
    case PixelFormat::kBC1RGBAUNormInt:
    case PixelFormat::kBC1RGBAUNormIntSRGB:
    case PixelFormat::kBC3RGBAUNormInt:
    case PixelFormat::kBC3RGBAUNormIntSRGB:
    case PixelFormat::kBC5RGUNormInt:
    case PixelFormat::kBC7RGBAUNormInt:
    case PixelFormat::kBC7RGBAUNormIntSRGB:
    case PixelFormat::kETC2RGB8UNormInt:
    case PixelFormat::kETC2RGB8UNormIntSRGB:
    case PixelFormat::kETC2RGBA8UNormInt:
    case PixelFormat::kETC2RGBA8UNormIntSRGB:
    case PixelFormat::kASTC4x4LDR:
    case PixelFormat::kASTC4x4LDRSRGB:
    case PixelFormat::kASTC4x4HDR:
      return 4u;
    default:
      return 1u;
  }
}

/// @brief The height, in texels, of one compression block. Uncompressed formats
///        report 1.
constexpr size_t CompressedBlockHeightForPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::kASTC8x8LDR:
    case PixelFormat::kASTC8x8LDRSRGB:
    case PixelFormat::kASTC8x8HDR:
      return 8u;
    case PixelFormat::kBC1RGBAUNormInt:
    case PixelFormat::kBC1RGBAUNormIntSRGB:
    case PixelFormat::kBC3RGBAUNormInt:
    case PixelFormat::kBC3RGBAUNormIntSRGB:
    case PixelFormat::kBC5RGUNormInt:
    case PixelFormat::kBC7RGBAUNormInt:
    case PixelFormat::kBC7RGBAUNormIntSRGB:
    case PixelFormat::kETC2RGB8UNormInt:
    case PixelFormat::kETC2RGB8UNormIntSRGB:
    case PixelFormat::kETC2RGBA8UNormInt:
    case PixelFormat::kETC2RGBA8UNormIntSRGB:
    case PixelFormat::kASTC4x4LDR:
    case PixelFormat::kASTC4x4LDRSRGB:
    case PixelFormat::kASTC4x4HDR:
      return 4u;
    default:
      return 1u;
  }
}

constexpr bool IsDepthWritable(PixelFormat format) {
  switch (format) {
    case PixelFormat::kD24UnormS8Uint:
    case PixelFormat::kD32FloatS8UInt:
      return true;
    default:
      return false;
  }
}

constexpr bool IsStencilWritable(PixelFormat format) {
  switch (format) {
    case PixelFormat::kS8UInt:
    case PixelFormat::kD24UnormS8Uint:
    case PixelFormat::kD32FloatS8UInt:
      return true;
    default:
      return false;
  }
}

constexpr const char* PixelFormatToString(PixelFormat format) {
  switch (format) {
    case PixelFormat::kUnknown:
      return "Unknown";
    case PixelFormat::kA8UNormInt:
      return "A8UNormInt";
    case PixelFormat::kR8UNormInt:
      return "R8UNormInt";
    case PixelFormat::kR8G8UNormInt:
      return "R8G8UNormInt";
    case PixelFormat::kR8G8B8A8UNormInt:
      return "R8G8B8A8UNormInt";
    case PixelFormat::kR8G8B8A8UNormIntSRGB:
      return "R8G8B8A8UNormIntSRGB";
    case PixelFormat::kB8G8R8A8UNormInt:
      return "B8G8R8A8UNormInt";
    case PixelFormat::kB8G8R8A8UNormIntSRGB:
      return "B8G8R8A8UNormIntSRGB";
    case PixelFormat::kR32G32B32A32Float:
      return "R32G32B32A32Float";
    case PixelFormat::kR16G16B16A16Float:
      return "R16G16B16A16Float";
    case PixelFormat::kB10G10R10XR:
      return "B10G10R10XR";
    case PixelFormat::kB10G10R10XRSRGB:
      return "B10G10R10XRSRGB";
    case PixelFormat::kB10G10R10A10XR:
      return "B10G10R10A10XR";
    case PixelFormat::kS8UInt:
      return "S8UInt";
    case PixelFormat::kD24UnormS8Uint:
      return "D24UnormS8Uint";
    case PixelFormat::kD32FloatS8UInt:
      return "D32FloatS8UInt";
    case PixelFormat::kR32Float:
      return "R32Float";
    case PixelFormat::kBC1RGBAUNormInt:
      return "BC1RGBAUNormInt";
    case PixelFormat::kBC1RGBAUNormIntSRGB:
      return "BC1RGBAUNormIntSRGB";
    case PixelFormat::kBC3RGBAUNormInt:
      return "BC3RGBAUNormInt";
    case PixelFormat::kBC3RGBAUNormIntSRGB:
      return "BC3RGBAUNormIntSRGB";
    case PixelFormat::kBC5RGUNormInt:
      return "BC5RGUNormInt";
    case PixelFormat::kBC7RGBAUNormInt:
      return "BC7RGBAUNormInt";
    case PixelFormat::kBC7RGBAUNormIntSRGB:
      return "BC7RGBAUNormIntSRGB";
    case PixelFormat::kETC2RGB8UNormInt:
      return "ETC2RGB8UNormInt";
    case PixelFormat::kETC2RGB8UNormIntSRGB:
      return "ETC2RGB8UNormIntSRGB";
    case PixelFormat::kETC2RGBA8UNormInt:
      return "ETC2RGBA8UNormInt";
    case PixelFormat::kETC2RGBA8UNormIntSRGB:
      return "ETC2RGBA8UNormIntSRGB";
    case PixelFormat::kASTC4x4LDR:
      return "ASTC4x4LDR";
    case PixelFormat::kASTC4x4LDRSRGB:
      return "ASTC4x4LDRSRGB";
    case PixelFormat::kASTC8x8LDR:
      return "ASTC8x8LDR";
    case PixelFormat::kASTC8x8LDRSRGB:
      return "ASTC8x8LDRSRGB";
    case PixelFormat::kASTC4x4HDR:
      return "ASTC4x4HDR";
    case PixelFormat::kASTC8x8HDR:
      return "ASTC8x8HDR";
  }
  FML_UNREACHABLE();
}

enum class BlendFactor {
  kZero,
  kOne,
  kSourceColor,
  kOneMinusSourceColor,
  kSourceAlpha,
  kOneMinusSourceAlpha,
  kDestinationColor,
  kOneMinusDestinationColor,
  kDestinationAlpha,
  kOneMinusDestinationAlpha,
  kSourceAlphaSaturated,
  kBlendColor,
  kOneMinusBlendColor,
  kBlendAlpha,
  kOneMinusBlendAlpha,
};

enum class BlendOperation {
  kAdd,
  kSubtract,
  kReverseSubtract,
};

enum class LoadAction {
  kDontCare,
  kLoad,
  kClear,
};

enum class StoreAction {
  kDontCare,
  kStore,
  kMultisampleResolve,
  kStoreAndMultisampleResolve,
};

constexpr const char* LoadActionToString(LoadAction action) {
  switch (action) {
    case LoadAction::kDontCare:
      return "DontCare";
    case LoadAction::kLoad:
      return "Load";
    case LoadAction::kClear:
      return "Clear";
  }
}

constexpr const char* StoreActionToString(StoreAction action) {
  switch (action) {
    case StoreAction::kDontCare:
      return "DontCare";
    case StoreAction::kStore:
      return "Store";
    case StoreAction::kMultisampleResolve:
      return "MultisampleResolve";
    case StoreAction::kStoreAndMultisampleResolve:
      return "StoreAndMultisampleResolve";
  }
}

constexpr bool CanClearAttachment(LoadAction action) {
  switch (action) {
    case LoadAction::kLoad:
      return false;
    case LoadAction::kDontCare:
    case LoadAction::kClear:
      return true;
  }
  FML_UNREACHABLE();
}

constexpr bool CanDiscardAttachmentWhenDone(StoreAction action) {
  switch (action) {
    case StoreAction::kStore:
    case StoreAction::kStoreAndMultisampleResolve:
      return false;
    case StoreAction::kDontCare:
    case StoreAction::kMultisampleResolve:
      return true;
  }
  FML_UNREACHABLE();
}

enum class TextureType {
  kTexture2D,
  kTexture2DMultisample,
  kTextureCube,
  kTextureExternalOES,
};

constexpr const char* TextureTypeToString(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
      return "Texture2D";
    case TextureType::kTexture2DMultisample:
      return "Texture2DMultisample";
    case TextureType::kTextureCube:
      return "TextureCube";
    case TextureType::kTextureExternalOES:
      return "TextureExternalOES";
  }
  FML_UNREACHABLE();
}

constexpr bool IsMultisampleCapable(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
    case TextureType::kTextureCube:
    case TextureType::kTextureExternalOES:
      return false;
    case TextureType::kTexture2DMultisample:
      return true;
  }
  return false;
}

enum class SampleCount : uint8_t {
  kCount1 = 1,
  kCount4 = 4,
};

enum class TextureUsage {
  kUnknown = 0,
  kShaderRead = 1 << 0,
  kShaderWrite = 1 << 1,
  kRenderTarget = 1 << 2,
};
IMPELLER_ENUM_IS_MASK(TextureUsage);

using TextureUsageMask = Mask<TextureUsage>;

constexpr const char* TextureUsageToString(TextureUsage usage) {
  switch (usage) {
    case TextureUsage::kUnknown:
      return "Unknown";
    case TextureUsage::kShaderRead:
      return "ShaderRead";
    case TextureUsage::kShaderWrite:
      return "ShaderWrite";
    case TextureUsage::kRenderTarget:
      return "RenderTarget";
  }
  FML_UNREACHABLE();
}

std::string TextureUsageMaskToString(TextureUsageMask mask);

enum class CullMode {
  kNone,
  kFrontFace,
  kBackFace,
};

enum class IndexType : uint8_t {
  kUnknown,
  k16bit,
  k32bit,
  /// Does not use the index buffer.
  kNone,
};

/// Decides how backend draws pixels based on input vertices.
enum class PrimitiveType : uint8_t {
  /// Draws a triangle for each separate set of three vertices.
  ///
  /// Vertices [A, B, C, D, E, F] will produce triangles
  /// [ABC, DEF].
  kTriangle,

  /// Draws a triangle for every adjacent three vertices.
  ///
  /// Vertices [A, B, C, D, E, F] will produce triangles
  /// [ABC, BCD, CDE, DEF].
  kTriangleStrip,

  /// Draws a line for each separate set of two vertices.
  ///
  /// Vertices [A, B, C] will produce discontinued line
  /// [AB, BC].
  kLine,

  /// Draws a continuous line that connect every input vertices
  ///
  /// Vertices [A, B, C] will produce one continuous line
  /// [ABC].
  kLineStrip,

  /// Draws a point at each input vertex.
  kPoint,

  /// Draws a triangle for every two vertices, after the first.
  ///
  /// The first vertex acts as the hub, all following vertices connect with
  /// this hub to "fan" out from the first vertex.
  ///
  /// Triangle fans are not supported in Metal and need a capability check.
  kTriangleFan,
};

enum class PolygonMode {
  kFill,
  kLine,
};

struct DepthRange {
  Scalar z_near = 0.0;
  Scalar z_far = 1.0;

  constexpr bool operator==(const DepthRange& other) const {
    return z_near == other.z_near && z_far == other.z_far;
  }
};

struct Viewport {
  Rect rect;
  DepthRange depth_range;

  constexpr bool operator==(const Viewport& other) const {
    return rect == other.rect && depth_range == other.depth_range;
  }
};

/// @brief      Describes how the texture should be sampled when the texture
///             is being shrunk (minified) or expanded (magnified) to fit to
///             the sample point.
enum class MinMagFilter : uint8_t {
  /// Select nearest to the sample point. Most widely supported.
  kNearest,

  /// Select two points and linearly interpolate between them. Some formats
  /// may not support this.
  kLinear,
};

/// @brief      Options for selecting and filtering between mipmap levels.
enum class MipFilter : uint8_t {
  /// @brief    The texture is sampled as if it only had a single mipmap level.
  ///
  ///           All samples are read from level 0.
  kBase,

  /// @brief    The nearst mipmap level is selected.
  kNearest,

  /// @brief    Sample from the two nearest mip levels and linearly interpolate.
  ///
  ///           If the filter falls between levels, both levels are sampled, and
  ///           their results linearly interpolated between levels.
  kLinear,
};

enum class SamplerAddressMode : uint8_t {
  kClampToEdge,
  kRepeat,
  kMirror,
  // More modes are almost always supported but they are usually behind
  // extensions checks. The ones current in these structs are safe (always
  // supported) defaults.

  /// @brief decal sampling mode is only supported on devices that pass
  ///        the `Capabilities.SupportsDecalSamplerAddressMode` check.
  kDecal,
};

enum class ColorWriteMaskBits : uint64_t {
  kNone = 0,
  kRed = 1 << 0,
  kGreen = 1 << 1,
  kBlue = 1 << 2,
  kAlpha = 1 << 3,
  kAll = kRed | kGreen | kBlue | kAlpha,
};
IMPELLER_ENUM_IS_MASK(ColorWriteMaskBits);

using ColorWriteMask = Mask<ColorWriteMaskBits>;

constexpr size_t BytesPerPixelForPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::kUnknown:
      return 0u;
    case PixelFormat::kA8UNormInt:
    case PixelFormat::kR8UNormInt:
    case PixelFormat::kS8UInt:
      return 1u;
    case PixelFormat::kR8G8UNormInt:
      return 2u;
    case PixelFormat::kR8G8B8A8UNormInt:
    case PixelFormat::kR8G8B8A8UNormIntSRGB:
    case PixelFormat::kB8G8R8A8UNormInt:
    case PixelFormat::kB8G8R8A8UNormIntSRGB:
    case PixelFormat::kB10G10R10XRSRGB:
    case PixelFormat::kB10G10R10XR:
    case PixelFormat::kR32Float:
      return 4u;
    case PixelFormat::kD24UnormS8Uint:
      return 4u;
    case PixelFormat::kD32FloatS8UInt:
      return 5u;
    case PixelFormat::kR16G16B16A16Float:
    case PixelFormat::kB10G10R10A10XR:
      return 8u;
    case PixelFormat::kR32G32B32A32Float:
      return 16u;
    // Block-compressed formats have no meaningful bytes-per-pixel. Use
    // `BytesPerBlockForPixelFormat` together with the block dimensions instead.
    case PixelFormat::kBC1RGBAUNormInt:
    case PixelFormat::kBC1RGBAUNormIntSRGB:
    case PixelFormat::kBC3RGBAUNormInt:
    case PixelFormat::kBC3RGBAUNormIntSRGB:
    case PixelFormat::kBC5RGUNormInt:
    case PixelFormat::kBC7RGBAUNormInt:
    case PixelFormat::kBC7RGBAUNormIntSRGB:
    case PixelFormat::kETC2RGB8UNormInt:
    case PixelFormat::kETC2RGB8UNormIntSRGB:
    case PixelFormat::kETC2RGBA8UNormInt:
    case PixelFormat::kETC2RGBA8UNormIntSRGB:
    case PixelFormat::kASTC4x4LDR:
    case PixelFormat::kASTC4x4LDRSRGB:
    case PixelFormat::kASTC8x8LDR:
    case PixelFormat::kASTC8x8LDRSRGB:
    case PixelFormat::kASTC4x4HDR:
    case PixelFormat::kASTC8x8HDR:
      return 0u;
  }
  return 0u;
}

/// @brief The number of bytes used to store one block of `format`. For
///        uncompressed formats a block is a single pixel, so this matches
///        `BytesPerPixelForPixelFormat`.
constexpr size_t BytesPerBlockForPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::kBC1RGBAUNormInt:
    case PixelFormat::kBC1RGBAUNormIntSRGB:
    case PixelFormat::kETC2RGB8UNormInt:
    case PixelFormat::kETC2RGB8UNormIntSRGB:
      return 8u;
    case PixelFormat::kBC3RGBAUNormInt:
    case PixelFormat::kBC3RGBAUNormIntSRGB:
    case PixelFormat::kBC5RGUNormInt:
    case PixelFormat::kBC7RGBAUNormInt:
    case PixelFormat::kBC7RGBAUNormIntSRGB:
    case PixelFormat::kETC2RGBA8UNormInt:
    case PixelFormat::kETC2RGBA8UNormIntSRGB:
    case PixelFormat::kASTC4x4LDR:
    case PixelFormat::kASTC4x4LDRSRGB:
    case PixelFormat::kASTC8x8LDR:
    case PixelFormat::kASTC8x8LDRSRGB:
    case PixelFormat::kASTC4x4HDR:
    case PixelFormat::kASTC8x8HDR:
      return 16u;
    default:
      return BytesPerPixelForPixelFormat(format);
  }
}

/// @brief The number of bytes required to store a `width` x `height` texel
///        region in `format`. Block-compressed formats round the dimensions up
///        to whole blocks. Uncompressed formats reduce to `width * height *
///        bytes-per-pixel`.
constexpr size_t BytesForTextureRegion(PixelFormat format,
                                       int64_t width,
                                       int64_t height) {
  const size_t block_width = CompressedBlockWidthForPixelFormat(format);
  const size_t block_height = CompressedBlockHeightForPixelFormat(format);
  const size_t w = width <= 0 ? 0u : static_cast<size_t>(width);
  const size_t h = height <= 0 ? 0u : static_cast<size_t>(height);
  const size_t blocks_wide = (w + block_width - 1u) / block_width;
  const size_t blocks_high = (h + block_height - 1u) / block_height;
  return blocks_wide * blocks_high * BytesPerBlockForPixelFormat(format);
}

/// @brief The number of bytes in a single row of texel blocks for a texture of
///        the given `width` in `format`.
constexpr size_t BytesPerRowForTextureWidth(PixelFormat format, int64_t width) {
  const size_t block_width = CompressedBlockWidthForPixelFormat(format);
  const size_t w = width <= 0 ? 0u : static_cast<size_t>(width);
  const size_t blocks_wide = (w + block_width - 1u) / block_width;
  return blocks_wide * BytesPerBlockForPixelFormat(format);
}

//------------------------------------------------------------------------------
/// @brief      Describe the color attachment that will be used with this
///             pipeline.
///
/// Blending at specific color attachments follows the pseudo-code:
/// ```
/// if (blending_enabled) {
///   final_color.rgb = (src_color_blend_factor * new_color.rgb)
///                             <color_blend_op>
///                     (dst_color_blend_factor * old_color.rgb);
///   final_color.a = (src_alpha_blend_factor * new_color.a)
///                             <alpha_blend_op>
///                     (dst_alpha_blend_factor * old_color.a);
/// } else {
///   final_color = new_color;
/// }
/// // IMPORTANT: The write mask is applied irrespective of whether
/// //            blending_enabled is set.
/// final_color = final_color & write_mask;
/// ```
///
/// The default blend mode is 1 - source alpha.
struct ColorAttachmentDescriptor {
  PixelFormat format = PixelFormat::kUnknown;
  bool blending_enabled = false;

  BlendFactor src_color_blend_factor = BlendFactor::kSourceAlpha;
  BlendOperation color_blend_op = BlendOperation::kAdd;
  BlendFactor dst_color_blend_factor = BlendFactor::kOneMinusSourceAlpha;

  BlendFactor src_alpha_blend_factor = BlendFactor::kSourceAlpha;
  BlendOperation alpha_blend_op = BlendOperation::kAdd;
  BlendFactor dst_alpha_blend_factor = BlendFactor::kOneMinusSourceAlpha;

  ColorWriteMask write_mask = ColorWriteMaskBits::kAll;

  constexpr bool operator==(const ColorAttachmentDescriptor& o) const {
    return format == o.format &&                                  //
           blending_enabled == o.blending_enabled &&              //
           src_color_blend_factor == o.src_color_blend_factor &&  //
           color_blend_op == o.color_blend_op &&                  //
           dst_color_blend_factor == o.dst_color_blend_factor &&  //
           src_alpha_blend_factor == o.src_alpha_blend_factor &&  //
           alpha_blend_op == o.alpha_blend_op &&                  //
           dst_alpha_blend_factor == o.dst_alpha_blend_factor &&  //
           write_mask == o.write_mask;
  }

  constexpr size_t Hash() const {
    return fml::HashCombine(
        format, blending_enabled, src_color_blend_factor, color_blend_op,
        dst_color_blend_factor, src_alpha_blend_factor, alpha_blend_op,
        dst_alpha_blend_factor, static_cast<uint64_t>(write_mask));
  }
};

enum class CompareFunction : uint8_t {
  /// Comparison test never passes.
  kNever,
  /// Comparison test passes always passes.
  kAlways,
  /// Comparison test passes if new_value < current_value.
  kLess,
  /// Comparison test passes if new_value == current_value.
  kEqual,
  /// Comparison test passes if new_value <= current_value.
  kLessEqual,
  /// Comparison test passes if new_value > current_value.
  kGreater,
  /// Comparison test passes if new_value != current_value.
  kNotEqual,
  /// Comparison test passes if new_value >= current_value.
  kGreaterEqual,
};

enum class StencilOperation : uint8_t {
  /// Don't modify the current stencil value.
  kKeep,
  /// Reset the stencil value to zero.
  kZero,
  /// Reset the stencil value to the reference value.
  kSetToReferenceValue,
  /// Increment the current stencil value by 1. Clamp it to the maximum.
  kIncrementClamp,
  /// Decrement the current stencil value by 1. Clamp it to zero.
  kDecrementClamp,
  /// Perform a logical bitwise invert on the current stencil value.
  kInvert,
  /// Increment the current stencil value by 1. If at maximum, set to zero.
  kIncrementWrap,
  /// Decrement the current stencil value by 1. If at zero, set to maximum.
  kDecrementWrap,
};

struct DepthAttachmentDescriptor {
  //----------------------------------------------------------------------------
  /// Indicates how to compare the value with that in the depth buffer.
  ///
  CompareFunction depth_compare = CompareFunction::kAlways;
  //----------------------------------------------------------------------------
  /// Indicates when writes must be performed to the depth buffer.
  ///
  bool depth_write_enabled = false;

  constexpr bool operator==(const DepthAttachmentDescriptor& o) const {
    return depth_compare == o.depth_compare &&
           depth_write_enabled == o.depth_write_enabled;
  }

  constexpr size_t GetHash() const {
    return fml::HashCombine(depth_compare, depth_write_enabled);
  }
};

struct StencilAttachmentDescriptor {
  //----------------------------------------------------------------------------
  /// Indicates the operation to perform between the reference value and the
  /// value in the stencil buffer. Both values have the read_mask applied to
  /// them before performing this operation.
  ///
  CompareFunction stencil_compare = CompareFunction::kAlways;
  //----------------------------------------------------------------------------
  /// Indicates what to do when the stencil test has failed.
  ///
  StencilOperation stencil_failure = StencilOperation::kKeep;
  //----------------------------------------------------------------------------
  /// Indicates what to do when the stencil test passes but the depth test
  /// fails.
  ///
  StencilOperation depth_failure = StencilOperation::kKeep;
  //----------------------------------------------------------------------------
  /// Indicates what to do when both the stencil and depth tests pass.
  ///
  StencilOperation depth_stencil_pass = StencilOperation::kKeep;

  //----------------------------------------------------------------------------
  /// The mask applied to the reference and stencil buffer values before
  /// performing the stencil_compare operation.
  ///
  uint32_t read_mask = ~0;
  //----------------------------------------------------------------------------
  /// The mask applied to the new stencil value before it is written into the
  /// stencil buffer.
  ///
  uint32_t write_mask = ~0;

  constexpr bool operator==(const StencilAttachmentDescriptor& o) const {
    return stencil_compare == o.stencil_compare &&
           stencil_failure == o.stencil_failure &&
           depth_failure == o.depth_failure &&
           depth_stencil_pass == o.depth_stencil_pass &&
           read_mask == o.read_mask && write_mask == o.write_mask;
  }

  constexpr size_t GetHash() const {
    return fml::HashCombine(stencil_compare, stencil_failure, depth_failure,
                            depth_stencil_pass, read_mask, write_mask);
  }
};

struct Attachment {
  std::shared_ptr<Texture> texture;
  std::shared_ptr<Texture> resolve_texture;
  LoadAction load_action = LoadAction::kDontCare;
  StoreAction store_action = StoreAction::kStore;
  // The mip level of `texture` to render into. Must be < the texture's
  // mip_count.
  uint32_t mip_level = 0;
  // The slice (cube map face or array layer) of `texture` to render into.
  // Must be < the slice count implied by the texture's type.
  uint32_t slice = 0;

  bool IsValid() const;
};

struct ColorAttachment : public Attachment {
  Color clear_color = Color::BlackTransparent();
};

struct DepthAttachment : public Attachment {
  double clear_depth = 0.0;
};

struct StencilAttachment : public Attachment {
  uint32_t clear_stencil = 0;
};

std::string AttachmentToString(const Attachment& attachment);

std::string ColorAttachmentToString(const ColorAttachment& color);

std::string DepthAttachmentToString(const DepthAttachment& depth);

std::string StencilAttachmentToString(const StencilAttachment& stencil);

}  // namespace impeller

namespace std {

template <>
struct hash<impeller::DepthAttachmentDescriptor> {
  constexpr std::size_t operator()(
      const impeller::DepthAttachmentDescriptor& des) const {
    return des.GetHash();
  }
};

template <>
struct hash<impeller::StencilAttachmentDescriptor> {
  constexpr std::size_t operator()(
      const impeller::StencilAttachmentDescriptor& des) const {
    return des.GetHash();
  }
};

}  // namespace std

#endif  // FLUTTER_IMPELLER_CORE_FORMATS_H_
