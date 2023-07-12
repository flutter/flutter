// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <type_traits>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/scalar.h"

namespace impeller {

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
enum class PixelFormat {
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
  // Depth and stencil formats.
  kS8UInt,
  kD32FloatS8UInt,
};

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
    case PixelFormat::kD32FloatS8UInt:
      return "D32FloatS8UInt";
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
};

constexpr const char* TextureTypeToString(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
      return "Texture2D";
    case TextureType::kTexture2DMultisample:
      return "Texture2DMultisample";
    case TextureType::kTextureCube:
      return "TextureCube";
  }
  FML_UNREACHABLE();
}

constexpr bool IsMultisampleCapable(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
    case TextureType::kTextureCube:
      return false;
    case TextureType::kTexture2DMultisample:
      return true;
  }
  return false;
}

enum class SampleCount {
  kCount1 = 1,
  kCount4 = 4,
};

using TextureUsageMask = uint64_t;

enum class TextureUsage : TextureUsageMask {
  kUnknown = 0,
  kShaderRead = 1 << 0,
  kShaderWrite = 1 << 1,
  kRenderTarget = 1 << 2,
};

constexpr bool TextureUsageIsRenderTarget(TextureUsageMask mask) {
  return static_cast<TextureUsageMask>(TextureUsage::kRenderTarget) & mask;
}

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

enum class TextureIntent {
  kUploadFromHost,
  kRenderToTexture,
};

enum class CullMode {
  kNone,
  kFrontFace,
  kBackFace,
};

enum class IndexType {
  kUnknown,
  k16bit,
  k32bit,
  /// Does not use the index buffer.
  kNone,
};

enum class PrimitiveType {
  kTriangle,
  kTriangleStrip,
  kLine,
  kLineStrip,
  kPoint,
  // Triangle fans are implementation dependent and need extra extensions
  // checks. Hence, they are not supported here.
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

enum class MinMagFilter {
  /// Select nearest to the sample point. Most widely supported.
  kNearest,
  /// Select two points and linearly interpolate between them. Some formats
  /// may not support this.
  kLinear,
};

enum class MipFilter {
  /// Sample from the nearest mip level.
  kNearest,
  /// Sample from the two nearest mip levels and linearly interpolate between
  /// them.
  kLinear,
};

enum class SamplerAddressMode {
  kClampToEdge,
  kRepeat,
  kMirror,
  // More modes are almost always supported but they are usually behind
  // extensions checks. The ones current in these structs are safe (always
  // supported) defaults.

  /// @brief decal sampling mode is only supported on devices that pass
  ///        the Capabilities.SupportsDecalTileMode check.
  kDecal,
};

enum class ColorWriteMask : uint64_t {
  kNone = 0,
  kRed = 1 << 0,
  kGreen = 1 << 1,
  kBlue = 1 << 2,
  kAlpha = 1 << 3,
  kAll = kRed | kGreen | kBlue | kAlpha,
};

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
      return 4u;
    case PixelFormat::kD32FloatS8UInt:
      return 5u;
    case PixelFormat::kR16G16B16A16Float:
    case PixelFormat::kB10G10R10A10XR:
      return 8u;
    case PixelFormat::kR32G32B32A32Float:
      return 16u;
  }
  return 0u;
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

  std::underlying_type_t<ColorWriteMask> write_mask =
      static_cast<uint64_t>(ColorWriteMask::kAll);

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
    return fml::HashCombine(format, blending_enabled, src_color_blend_factor,
                            color_blend_op, dst_color_blend_factor,
                            src_alpha_blend_factor, alpha_blend_op,
                            dst_alpha_blend_factor, write_mask);
  }
};

enum class CompareFunction {
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

enum class StencilOperation {
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
