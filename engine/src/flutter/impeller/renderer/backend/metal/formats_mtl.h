// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/texture_descriptor.h"

namespace impeller {

class RenderTarget;

constexpr PixelFormat FromMTLPixelFormat(MTLPixelFormat format) {
  switch (format) {
    case MTLPixelFormatInvalid:
      return PixelFormat::kUnknown;
    case MTLPixelFormatBGRA8Unorm:
      return PixelFormat::kB8G8R8A8UNormInt;
    case MTLPixelFormatBGRA8Unorm_sRGB:
      return PixelFormat::kB8G8R8A8UNormIntSRGB;
    case MTLPixelFormatRGBA8Unorm:
      return PixelFormat::kR8G8B8A8UNormInt;
    case MTLPixelFormatRGBA8Unorm_sRGB:
      return PixelFormat::kR8G8B8A8UNormIntSRGB;
    case MTLPixelFormatRGBA32Float:
      return PixelFormat::kR32G32B32A32Float;
    case MTLPixelFormatRGBA16Float:
      return PixelFormat::kR16G16B16A16Float;
    case MTLPixelFormatStencil8:
      return PixelFormat::kS8UInt;
    case MTLPixelFormatDepth32Float_Stencil8:
      return PixelFormat::kD32FloatS8UInt;
    case MTLPixelFormatBGR10_XR_sRGB:
      return PixelFormat::kB10G10R10XRSRGB;
    case MTLPixelFormatBGR10_XR:
      return PixelFormat::kB10G10R10XR;
    default:
      return PixelFormat::kUnknown;
  }
  return PixelFormat::kUnknown;
}

/// Safe accessor for MTLPixelFormatBGR10_XR_sRGB.
/// Returns PixelFormat::kUnknown if MTLPixelFormatBGR10_XR_sRGB isn't
/// supported.
MTLPixelFormat SafeMTLPixelFormatBGR10_XR_sRGB();

/// Safe accessor for MTLPixelFormatBGR10_XR.
/// Returns PixelFormat::kUnknown if MTLPixelFormatBGR10_XR isn't supported.
MTLPixelFormat SafeMTLPixelFormatBGR10_XR();

constexpr MTLPixelFormat ToMTLPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::kUnknown:
      return MTLPixelFormatInvalid;
    case PixelFormat::kA8UNormInt:
      return MTLPixelFormatA8Unorm;
    case PixelFormat::kR8UNormInt:
      return MTLPixelFormatR8Unorm;
    case PixelFormat::kR8G8UNormInt:
      return MTLPixelFormatRG8Unorm;
    case PixelFormat::kB8G8R8A8UNormInt:
      return MTLPixelFormatBGRA8Unorm;
    case PixelFormat::kB8G8R8A8UNormIntSRGB:
      return MTLPixelFormatBGRA8Unorm_sRGB;
    case PixelFormat::kR8G8B8A8UNormInt:
      return MTLPixelFormatRGBA8Unorm;
    case PixelFormat::kR8G8B8A8UNormIntSRGB:
      return MTLPixelFormatRGBA8Unorm_sRGB;
    case PixelFormat::kR32G32B32A32Float:
      return MTLPixelFormatRGBA32Float;
    case PixelFormat::kR16G16B16A16Float:
      return MTLPixelFormatRGBA16Float;
    case PixelFormat::kS8UInt:
      return MTLPixelFormatStencil8;
    case PixelFormat::kD32FloatS8UInt:
      return MTLPixelFormatDepth32Float_Stencil8;
    case PixelFormat::kB10G10R10XRSRGB:
      return SafeMTLPixelFormatBGR10_XR_sRGB();
    case PixelFormat::kB10G10R10XR:
      return SafeMTLPixelFormatBGR10_XR();
  }
  return MTLPixelFormatInvalid;
};

constexpr MTLBlendFactor ToMTLBlendFactor(BlendFactor type) {
  switch (type) {
    case BlendFactor::kZero:
      return MTLBlendFactorZero;
    case BlendFactor::kOne:
      return MTLBlendFactorOne;
    case BlendFactor::kSourceColor:
      return MTLBlendFactorSourceColor;
    case BlendFactor::kOneMinusSourceColor:
      return MTLBlendFactorOneMinusSourceColor;
    case BlendFactor::kSourceAlpha:
      return MTLBlendFactorSourceAlpha;
    case BlendFactor::kOneMinusSourceAlpha:
      return MTLBlendFactorOneMinusSourceAlpha;
    case BlendFactor::kDestinationColor:
      return MTLBlendFactorDestinationColor;
    case BlendFactor::kOneMinusDestinationColor:
      return MTLBlendFactorOneMinusDestinationColor;
    case BlendFactor::kDestinationAlpha:
      return MTLBlendFactorDestinationAlpha;
    case BlendFactor::kOneMinusDestinationAlpha:
      return MTLBlendFactorOneMinusDestinationAlpha;
    case BlendFactor::kSourceAlphaSaturated:
      return MTLBlendFactorSourceAlphaSaturated;
    case BlendFactor::kBlendColor:
      return MTLBlendFactorBlendColor;
    case BlendFactor::kOneMinusBlendColor:
      return MTLBlendFactorOneMinusBlendColor;
    case BlendFactor::kBlendAlpha:
      return MTLBlendFactorBlendAlpha;
    case BlendFactor::kOneMinusBlendAlpha:
      return MTLBlendFactorOneMinusBlendAlpha;
  }
  return MTLBlendFactorZero;
};

constexpr MTLPrimitiveType ToMTLPrimitiveType(PrimitiveType type) {
  switch (type) {
    case PrimitiveType::kTriangle:
      return MTLPrimitiveTypeTriangle;
    case PrimitiveType::kTriangleStrip:
      return MTLPrimitiveTypeTriangleStrip;
    case PrimitiveType::kLine:
      return MTLPrimitiveTypeLine;
    case PrimitiveType::kLineStrip:
      return MTLPrimitiveTypeLineStrip;
    case PrimitiveType::kPoint:
      return MTLPrimitiveTypePoint;
  }
  return MTLPrimitiveTypePoint;
}

constexpr MTLIndexType ToMTLIndexType(IndexType type) {
  switch (type) {
    case IndexType::k16bit:
      return MTLIndexTypeUInt16;
    default:
      return MTLIndexTypeUInt32;
  }
}

constexpr MTLCullMode ToMTLCullMode(CullMode mode) {
  switch (mode) {
    case CullMode::kNone:
      return MTLCullModeNone;
    case CullMode::kBackFace:
      return MTLCullModeBack;
    case CullMode::kFrontFace:
      return MTLCullModeFront;
  }
  return MTLCullModeNone;
}

constexpr MTLBlendOperation ToMTLBlendOperation(BlendOperation type) {
  switch (type) {
    case BlendOperation::kAdd:
      return MTLBlendOperationAdd;
    case BlendOperation::kSubtract:
      return MTLBlendOperationSubtract;
    case BlendOperation::kReverseSubtract:
      return MTLBlendOperationReverseSubtract;
  }
  return MTLBlendOperationAdd;
};

constexpr MTLColorWriteMask ToMTLColorWriteMask(
    std::underlying_type_t<ColorWriteMask> type) {
  using UnderlyingType = decltype(type);

  MTLColorWriteMask mask = MTLColorWriteMaskNone;

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kRed)) {
    mask |= MTLColorWriteMaskRed;
  }

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kGreen)) {
    mask |= MTLColorWriteMaskGreen;
  }

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kBlue)) {
    mask |= MTLColorWriteMaskBlue;
  }

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kAlpha)) {
    mask |= MTLColorWriteMaskAlpha;
  }

  return mask;
};

constexpr MTLCompareFunction ToMTLCompareFunction(CompareFunction func) {
  switch (func) {
    case CompareFunction::kNever:
      return MTLCompareFunctionNever;
    case CompareFunction::kLess:
      return MTLCompareFunctionLess;
    case CompareFunction::kEqual:
      return MTLCompareFunctionEqual;
    case CompareFunction::kLessEqual:
      return MTLCompareFunctionLessEqual;
    case CompareFunction::kGreater:
      return MTLCompareFunctionGreater;
    case CompareFunction::kNotEqual:
      return MTLCompareFunctionNotEqual;
    case CompareFunction::kGreaterEqual:
      return MTLCompareFunctionGreaterEqual;
    case CompareFunction::kAlways:
      return MTLCompareFunctionAlways;
  }
  return MTLCompareFunctionAlways;
};

constexpr MTLStencilOperation ToMTLStencilOperation(StencilOperation op) {
  switch (op) {
    case StencilOperation::kKeep:
      return MTLStencilOperationKeep;
    case StencilOperation::kZero:
      return MTLStencilOperationZero;
    case StencilOperation::kSetToReferenceValue:
      return MTLStencilOperationReplace;
    case StencilOperation::kIncrementClamp:
      return MTLStencilOperationIncrementClamp;
    case StencilOperation::kDecrementClamp:
      return MTLStencilOperationDecrementClamp;
    case StencilOperation::kInvert:
      return MTLStencilOperationInvert;
    case StencilOperation::kIncrementWrap:
      return MTLStencilOperationIncrementWrap;
    case StencilOperation::kDecrementWrap:
      return MTLStencilOperationDecrementWrap;
  }
  return MTLStencilOperationKeep;
};

constexpr MTLLoadAction ToMTLLoadAction(LoadAction action) {
  switch (action) {
    case LoadAction::kDontCare:
      return MTLLoadActionDontCare;
    case LoadAction::kLoad:
      return MTLLoadActionLoad;
    case LoadAction::kClear:
      return MTLLoadActionClear;
  }

  return MTLLoadActionDontCare;
}

constexpr LoadAction FromMTLLoadAction(MTLLoadAction action) {
  switch (action) {
    case MTLLoadActionDontCare:
      return LoadAction::kDontCare;
    case MTLLoadActionLoad:
      return LoadAction::kLoad;
    case MTLLoadActionClear:
      return LoadAction::kClear;
    default:
      break;
  }

  return LoadAction::kDontCare;
}

constexpr MTLStoreAction ToMTLStoreAction(StoreAction action) {
  switch (action) {
    case StoreAction::kDontCare:
      return MTLStoreActionDontCare;
    case StoreAction::kStore:
      return MTLStoreActionStore;
    case StoreAction::kMultisampleResolve:
      return MTLStoreActionMultisampleResolve;
    case StoreAction::kStoreAndMultisampleResolve:
      return MTLStoreActionStoreAndMultisampleResolve;
  }
  return MTLStoreActionDontCare;
}

constexpr StoreAction FromMTLStoreAction(MTLStoreAction action) {
  switch (action) {
    case MTLStoreActionDontCare:
      return StoreAction::kDontCare;
    case MTLStoreActionStore:
      return StoreAction::kStore;
    case MTLStoreActionMultisampleResolve:
      return StoreAction::kMultisampleResolve;
    case MTLStoreActionStoreAndMultisampleResolve:
      return StoreAction::kStoreAndMultisampleResolve;
    default:
      break;
  }
  return StoreAction::kDontCare;
}

constexpr MTLSamplerMinMagFilter ToMTLSamplerMinMagFilter(MinMagFilter filter) {
  switch (filter) {
    case MinMagFilter::kNearest:
      return MTLSamplerMinMagFilterNearest;
    case MinMagFilter::kLinear:
      return MTLSamplerMinMagFilterLinear;
  }
  return MTLSamplerMinMagFilterNearest;
}

constexpr MTLSamplerMipFilter ToMTLSamplerMipFilter(MipFilter filter) {
  switch (filter) {
    case MipFilter::kNone:
      return MTLSamplerMipFilterNotMipmapped;
    case MipFilter::kNearest:
      return MTLSamplerMipFilterNearest;
    case MipFilter::kLinear:
      return MTLSamplerMipFilterLinear;
  }
  return MTLSamplerMipFilterNotMipmapped;
}

constexpr MTLSamplerAddressMode ToMTLSamplerAddressMode(
    SamplerAddressMode mode) {
  switch (mode) {
    case SamplerAddressMode::kClampToEdge:
      return MTLSamplerAddressModeClampToEdge;
    case SamplerAddressMode::kRepeat:
      return MTLSamplerAddressModeRepeat;
    case SamplerAddressMode::kMirror:
      return MTLSamplerAddressModeMirrorRepeat;
  }
  return MTLSamplerAddressModeClampToEdge;
}

inline MTLClearColor ToMTLClearColor(const Color& color) {
  return MTLClearColorMake(color.red, color.green, color.blue, color.alpha);
}

constexpr MTLTextureType ToMTLTextureType(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
      return MTLTextureType2D;
    case TextureType::kTexture2DMultisample:
      return MTLTextureType2DMultisample;
    case TextureType::kTextureCube:
      return MTLTextureTypeCube;
  }
  return MTLTextureType2D;
}

MTLRenderPipelineColorAttachmentDescriptor*
ToMTLRenderPipelineColorAttachmentDescriptor(
    ColorAttachmentDescriptor descriptor);

MTLDepthStencilDescriptor* ToMTLDepthStencilDescriptor(
    std::optional<DepthAttachmentDescriptor> depth,
    std::optional<StencilAttachmentDescriptor> front,
    std::optional<StencilAttachmentDescriptor> back);

MTLTextureDescriptor* ToMTLTextureDescriptor(const TextureDescriptor& desc);

}  // namespace impeller
