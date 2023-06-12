// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/core/formats.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "vulkan/vulkan_enums.hpp"

namespace impeller {

constexpr vk::SampleCountFlagBits ToVKSampleCountFlagBits(SampleCount count) {
  switch (count) {
    case SampleCount::kCount1:
      return vk::SampleCountFlagBits::e1;
    case SampleCount::kCount4:
      return vk::SampleCountFlagBits::e4;
  }
  FML_UNREACHABLE();
}

constexpr vk::BlendFactor ToVKBlendFactor(BlendFactor factor) {
  switch (factor) {
    case BlendFactor::kZero:
      return vk::BlendFactor::eZero;
    case BlendFactor::kOne:
      return vk::BlendFactor::eOne;
    case BlendFactor::kSourceColor:
      return vk::BlendFactor::eSrcColor;
    case BlendFactor::kOneMinusSourceColor:
      return vk::BlendFactor::eOneMinusSrcColor;
    case BlendFactor::kSourceAlpha:
      return vk::BlendFactor::eSrcAlpha;
    case BlendFactor::kOneMinusSourceAlpha:
      return vk::BlendFactor::eOneMinusSrcAlpha;
    case BlendFactor::kDestinationColor:
      return vk::BlendFactor::eDstColor;
    case BlendFactor::kOneMinusDestinationColor:
      return vk::BlendFactor::eOneMinusDstColor;
    case BlendFactor::kDestinationAlpha:
      return vk::BlendFactor::eDstAlpha;
    case BlendFactor::kOneMinusDestinationAlpha:
      return vk::BlendFactor::eOneMinusDstAlpha;
    case BlendFactor::kSourceAlphaSaturated:
      return vk::BlendFactor::eSrcAlphaSaturate;
    case BlendFactor::kBlendColor:
      return vk::BlendFactor::eConstantColor;
    case BlendFactor::kOneMinusBlendColor:
      return vk::BlendFactor::eOneMinusConstantColor;
    case BlendFactor::kBlendAlpha:
      return vk::BlendFactor::eConstantAlpha;
    case BlendFactor::kOneMinusBlendAlpha:
      return vk::BlendFactor::eOneMinusConstantAlpha;
  }
  FML_UNREACHABLE();
}

constexpr vk::BlendOp ToVKBlendOp(BlendOperation op) {
  switch (op) {
    case BlendOperation::kAdd:
      return vk::BlendOp::eAdd;
    case BlendOperation::kSubtract:
      return vk::BlendOp::eSubtract;
    case BlendOperation::kReverseSubtract:
      return vk::BlendOp::eReverseSubtract;
  }
  FML_UNREACHABLE();
}

constexpr vk::ColorComponentFlags ToVKColorComponentFlags(
    std::underlying_type_t<ColorWriteMask> type) {
  using UnderlyingType = decltype(type);

  vk::ColorComponentFlags mask;

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kRed)) {
    mask |= vk::ColorComponentFlagBits::eR;
  }

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kGreen)) {
    mask |= vk::ColorComponentFlagBits::eG;
  }

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kBlue)) {
    mask |= vk::ColorComponentFlagBits::eB;
  }

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kAlpha)) {
    mask |= vk::ColorComponentFlagBits::eA;
  }

  return mask;
}

constexpr vk::PipelineColorBlendAttachmentState
ToVKPipelineColorBlendAttachmentState(const ColorAttachmentDescriptor& desc) {
  vk::PipelineColorBlendAttachmentState res;

  res.setBlendEnable(desc.blending_enabled);

  res.setSrcColorBlendFactor(ToVKBlendFactor(desc.src_color_blend_factor));
  res.setColorBlendOp(ToVKBlendOp(desc.color_blend_op));
  res.setDstColorBlendFactor(ToVKBlendFactor(desc.dst_color_blend_factor));

  res.setSrcAlphaBlendFactor(ToVKBlendFactor(desc.src_alpha_blend_factor));
  res.setAlphaBlendOp(ToVKBlendOp(desc.alpha_blend_op));
  res.setDstAlphaBlendFactor(ToVKBlendFactor(desc.dst_alpha_blend_factor));

  res.setColorWriteMask(ToVKColorComponentFlags(desc.write_mask));

  return res;
}

constexpr std::optional<vk::ShaderStageFlagBits> ToVKShaderStageFlagBits(
    ShaderStage stage) {
  switch (stage) {
    case ShaderStage::kUnknown:
      return std::nullopt;
    case ShaderStage::kVertex:
      return vk::ShaderStageFlagBits::eVertex;
    case ShaderStage::kFragment:
      return vk::ShaderStageFlagBits::eFragment;
    case ShaderStage::kTessellationControl:
      return vk::ShaderStageFlagBits::eTessellationControl;
    case ShaderStage::kTessellationEvaluation:
      return vk::ShaderStageFlagBits::eTessellationEvaluation;
    case ShaderStage::kCompute:
      return vk::ShaderStageFlagBits::eCompute;
  }
  FML_UNREACHABLE();
}

constexpr vk::Format ToVKImageFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::kUnknown:
    case PixelFormat::kB10G10R10XR:
    case PixelFormat::kB10G10R10A10XR:
    case PixelFormat::kB10G10R10XRSRGB:
      return vk::Format::eUndefined;
    case PixelFormat::kA8UNormInt:
      // TODO(csg): This is incorrect. Don't depend on swizzle support for GLES.
      return vk::Format::eR8Unorm;
    case PixelFormat::kR8G8B8A8UNormInt:
      return vk::Format::eR8G8B8A8Unorm;
    case PixelFormat::kR8G8B8A8UNormIntSRGB:
      return vk::Format::eR8G8B8A8Srgb;
    case PixelFormat::kB8G8R8A8UNormInt:
      return vk::Format::eB8G8R8A8Unorm;
    case PixelFormat::kB8G8R8A8UNormIntSRGB:
      return vk::Format::eB8G8R8A8Srgb;
    case PixelFormat::kR32G32B32A32Float:
      return vk::Format::eR32G32B32A32Sfloat;
    case PixelFormat::kR16G16B16A16Float:
      return vk::Format::eR16G16B16A16Sfloat;
    case PixelFormat::kS8UInt:
      return vk::Format::eS8Uint;
    case PixelFormat::kD32FloatS8UInt:
      return vk::Format::eD32SfloatS8Uint;
    case PixelFormat::kR8UNormInt:
      return vk::Format::eR8Unorm;
    case PixelFormat::kR8G8UNormInt:
      return vk::Format::eR8G8Unorm;
  }

  FML_UNREACHABLE();
}

constexpr PixelFormat ToPixelFormat(vk::Format format) {
  switch (format) {
    case vk::Format::eUndefined:
      return PixelFormat::kUnknown;
    case vk::Format::eR8G8B8A8Unorm:
      return PixelFormat::kR8G8B8A8UNormInt;
    case vk::Format::eR8G8B8A8Srgb:
      return PixelFormat::kR8G8B8A8UNormIntSRGB;
    case vk::Format::eB8G8R8A8Unorm:
      return PixelFormat::kB8G8R8A8UNormInt;
    case vk::Format::eB8G8R8A8Srgb:
      return PixelFormat::kB8G8R8A8UNormIntSRGB;
    case vk::Format::eR32G32B32A32Sfloat:
      return PixelFormat::kR32G32B32A32Float;
    case vk::Format::eR16G16B16A16Sfloat:
      return PixelFormat::kR16G16B16A16Float;
    case vk::Format::eS8Uint:
      return PixelFormat::kS8UInt;
    case vk::Format::eD32SfloatS8Uint:
      return PixelFormat::kD32FloatS8UInt;
    case vk::Format::eR8Unorm:
      return PixelFormat::kR8UNormInt;
    case vk::Format::eR8G8Unorm:
      return PixelFormat::kR8G8UNormInt;
    default:
      return PixelFormat::kUnknown;
  }
}

constexpr vk::SampleCountFlagBits ToVKSampleCount(SampleCount sample_count) {
  switch (sample_count) {
    case SampleCount::kCount1:
      return vk::SampleCountFlagBits::e1;
    case SampleCount::kCount4:
      return vk::SampleCountFlagBits::e4;
  }

  FML_UNREACHABLE();
}

constexpr vk::Filter ToVKSamplerMinMagFilter(MinMagFilter filter) {
  switch (filter) {
    case MinMagFilter::kNearest:
      return vk::Filter::eNearest;
    case MinMagFilter::kLinear:
      return vk::Filter::eLinear;
  }

  FML_UNREACHABLE();
}

constexpr vk::SamplerMipmapMode ToVKSamplerMipmapMode(MipFilter filter) {
  vk::SamplerCreateInfo sampler_info;
  switch (filter) {
    case MipFilter::kNearest:
      return vk::SamplerMipmapMode::eNearest;
    case MipFilter::kLinear:
      return vk::SamplerMipmapMode::eLinear;
  }

  FML_UNREACHABLE();
}

constexpr vk::SamplerAddressMode ToVKSamplerAddressMode(
    SamplerAddressMode mode) {
  switch (mode) {
    case SamplerAddressMode::kRepeat:
      return vk::SamplerAddressMode::eRepeat;
    case SamplerAddressMode::kMirror:
      return vk::SamplerAddressMode::eMirroredRepeat;
    case SamplerAddressMode::kClampToEdge:
      return vk::SamplerAddressMode::eClampToEdge;
    case SamplerAddressMode::kDecal:
      return vk::SamplerAddressMode::eClampToBorder;
  }

  FML_UNREACHABLE();
}

constexpr vk::ShaderStageFlags ToVkShaderStage(ShaderStage stage) {
  switch (stage) {
    case ShaderStage::kUnknown:
      return vk::ShaderStageFlagBits::eAll;
    case ShaderStage::kFragment:
      return vk::ShaderStageFlagBits::eFragment;
    case ShaderStage::kTessellationControl:
      return vk::ShaderStageFlagBits::eTessellationControl;
    case ShaderStage::kTessellationEvaluation:
      return vk::ShaderStageFlagBits::eTessellationEvaluation;
    case ShaderStage::kCompute:
      return vk::ShaderStageFlagBits::eCompute;
    case ShaderStage::kVertex:
      return vk::ShaderStageFlagBits::eVertex;
  }

  FML_UNREACHABLE();
}

constexpr vk::DescriptorType ToVKDescriptorType(DescriptorType type) {
  switch (type) {
    case DescriptorType::kSampledImage:
      return vk::DescriptorType::eCombinedImageSampler;
      break;
    case DescriptorType::kUniformBuffer:
      return vk::DescriptorType::eUniformBuffer;
      break;
    case DescriptorType::kStorageBuffer:
      return vk::DescriptorType::eStorageBuffer;
      break;
    case DescriptorType::kImage:
      return vk::DescriptorType::eSampledImage;
      break;
    case DescriptorType::kSampler:
      return vk::DescriptorType::eSampler;
      break;
  }

  FML_UNREACHABLE();
}

constexpr vk::DescriptorSetLayoutBinding ToVKDescriptorSetLayoutBinding(
    const DescriptorSetLayout& layout) {
  vk::DescriptorSetLayoutBinding binding;
  binding.binding = layout.binding;
  binding.descriptorCount = 1u;
  binding.descriptorType = ToVKDescriptorType(layout.descriptor_type);
  binding.stageFlags = ToVkShaderStage(layout.shader_stage);
  return binding;
}

constexpr vk::AttachmentLoadOp ToVKAttachmentLoadOp(LoadAction load_action) {
  switch (load_action) {
    case LoadAction::kLoad:
      return vk::AttachmentLoadOp::eLoad;
    case LoadAction::kClear:
      return vk::AttachmentLoadOp::eClear;
    case LoadAction::kDontCare:
      return vk::AttachmentLoadOp::eDontCare;
  }

  FML_UNREACHABLE();
}

constexpr vk::AttachmentStoreOp ToVKAttachmentStoreOp(
    StoreAction store_action) {
  switch (store_action) {
    case StoreAction::kStore:
      return vk::AttachmentStoreOp::eStore;
    case StoreAction::kDontCare:
      return vk::AttachmentStoreOp::eDontCare;
    case StoreAction::kMultisampleResolve:
    case StoreAction::kStoreAndMultisampleResolve:
      return vk::AttachmentStoreOp::eDontCare;
  }

  FML_UNREACHABLE();
}

constexpr vk::IndexType ToVKIndexType(IndexType index_type) {
  switch (index_type) {
    case IndexType::k16bit:
      return vk::IndexType::eUint16;
    case IndexType::k32bit:
      return vk::IndexType::eUint32;
    case IndexType::kUnknown:
      return vk::IndexType::eUint32;
    case IndexType::kNone:
      FML_UNREACHABLE();
  }

  FML_UNREACHABLE();
}

constexpr vk::PolygonMode ToVKPolygonMode(PolygonMode mode) {
  switch (mode) {
    case PolygonMode::kFill:
      return vk::PolygonMode::eFill;
    case PolygonMode::kLine:
      return vk::PolygonMode::eLine;
  }
  FML_UNREACHABLE();
}

constexpr vk::PrimitiveTopology ToVKPrimitiveTopology(PrimitiveType primitive) {
  switch (primitive) {
    case PrimitiveType::kTriangle:
      return vk::PrimitiveTopology::eTriangleList;
    case PrimitiveType::kTriangleStrip:
      return vk::PrimitiveTopology::eTriangleStrip;
    case PrimitiveType::kLine:
      return vk::PrimitiveTopology::eLineList;
    case PrimitiveType::kLineStrip:
      return vk::PrimitiveTopology::eLineStrip;
    case PrimitiveType::kPoint:
      return vk::PrimitiveTopology::ePointList;
  }

  FML_UNREACHABLE();
}

constexpr bool PixelFormatIsDepthStencil(PixelFormat format) {
  switch (format) {
    case PixelFormat::kUnknown:
    case PixelFormat::kA8UNormInt:
    case PixelFormat::kR8UNormInt:
    case PixelFormat::kR8G8UNormInt:
    case PixelFormat::kR8G8B8A8UNormInt:
    case PixelFormat::kR8G8B8A8UNormIntSRGB:
    case PixelFormat::kB8G8R8A8UNormInt:
    case PixelFormat::kB8G8R8A8UNormIntSRGB:
    case PixelFormat::kR32G32B32A32Float:
    case PixelFormat::kR16G16B16A16Float:
    case PixelFormat::kB10G10R10XR:
    case PixelFormat::kB10G10R10XRSRGB:
    case PixelFormat::kB10G10R10A10XR:
      return false;
    case PixelFormat::kS8UInt:
    case PixelFormat::kD32FloatS8UInt:
      return true;
  }
  return false;
}

enum class AttachmentKind {
  kColor,
  kDepth,
  kStencil,
  kDepthStencil,
};

constexpr AttachmentKind AttachmentKindFromFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::kUnknown:
    case PixelFormat::kA8UNormInt:
    case PixelFormat::kR8UNormInt:
    case PixelFormat::kR8G8UNormInt:
    case PixelFormat::kR8G8B8A8UNormInt:
    case PixelFormat::kR8G8B8A8UNormIntSRGB:
    case PixelFormat::kB8G8R8A8UNormInt:
    case PixelFormat::kB8G8R8A8UNormIntSRGB:
    case PixelFormat::kR32G32B32A32Float:
    case PixelFormat::kR16G16B16A16Float:
    case PixelFormat::kB10G10R10XR:
    case PixelFormat::kB10G10R10XRSRGB:
    case PixelFormat::kB10G10R10A10XR:
      return AttachmentKind::kColor;
    case PixelFormat::kS8UInt:
      return AttachmentKind::kStencil;
    case PixelFormat::kD32FloatS8UInt:
      return AttachmentKind::kDepthStencil;
  }
  FML_UNREACHABLE();
}

constexpr vk::AttachmentDescription CreateAttachmentDescription(
    PixelFormat format,
    SampleCount sample_count,
    LoadAction load_action,
    StoreAction store_action,
    vk::ImageLayout current_layout) {
  vk::AttachmentDescription vk_attachment;

  vk_attachment.format = ToVKImageFormat(format);
  vk_attachment.samples = ToVKSampleCount(sample_count);

  // The Vulkan spec has somewhat complicated rules for when these ops are used
  // and ignored. Just set safe defaults.
  vk_attachment.loadOp = vk::AttachmentLoadOp::eDontCare;
  vk_attachment.storeOp = vk::AttachmentStoreOp::eDontCare;
  vk_attachment.stencilLoadOp = vk::AttachmentLoadOp::eDontCare;
  vk_attachment.stencilStoreOp = vk::AttachmentStoreOp::eDontCare;

  const auto kind = AttachmentKindFromFormat(format);

  switch (kind) {
    case AttachmentKind::kColor:
      // If the attachment uses a color format, then loadOp and storeOp are
      // used, and stencilLoadOp and stencilStoreOp are ignored.
      vk_attachment.loadOp = ToVKAttachmentLoadOp(load_action);
      vk_attachment.storeOp = ToVKAttachmentStoreOp(store_action);
      break;
    case AttachmentKind::kDepth:
    case AttachmentKind::kDepthStencil:
      // If the format has depth and/or stencil components, loadOp and storeOp
      // apply only to the depth data, while stencilLoadOp and stencilStoreOp
      // define how the stencil data is handled.
      vk_attachment.loadOp = ToVKAttachmentLoadOp(load_action);
      vk_attachment.storeOp = ToVKAttachmentStoreOp(store_action);
      [[fallthrough]];
    case AttachmentKind::kStencil:
      vk_attachment.stencilLoadOp = ToVKAttachmentLoadOp(load_action);
      vk_attachment.stencilStoreOp = ToVKAttachmentStoreOp(store_action);
      break;
  }

  switch (kind) {
    case AttachmentKind::kColor:
      vk_attachment.initialLayout = current_layout;
      vk_attachment.finalLayout = vk::ImageLayout::eGeneral;
      break;
    case AttachmentKind::kDepth:
    case AttachmentKind::kStencil:
    case AttachmentKind::kDepthStencil:
      // Separate depth stencil layouts feature is only available in Vulkan 1.2.
      vk_attachment.initialLayout = current_layout;
      vk_attachment.finalLayout =
          vk::ImageLayout::eDepthStencilAttachmentOptimal;
      break;
  }

  return vk_attachment;
}

static constexpr vk::AttachmentReference kUnusedAttachmentReference = {
    VK_ATTACHMENT_UNUSED, vk::ImageLayout::eUndefined};

constexpr vk::CullModeFlags ToVKCullModeFlags(CullMode mode) {
  switch (mode) {
    case CullMode::kNone:
      return vk::CullModeFlagBits::eNone;
    case CullMode::kFrontFace:
      return vk::CullModeFlagBits::eFront;
    case CullMode::kBackFace:
      return vk::CullModeFlagBits::eBack;
  }
  FML_UNREACHABLE();
}

constexpr vk::CompareOp ToVKCompareOp(CompareFunction op) {
  switch (op) {
    case CompareFunction::kNever:
      return vk::CompareOp::eNever;
    case CompareFunction::kAlways:
      return vk::CompareOp::eAlways;
    case CompareFunction::kLess:
      return vk::CompareOp::eLess;
    case CompareFunction::kEqual:
      return vk::CompareOp::eEqual;
    case CompareFunction::kLessEqual:
      return vk::CompareOp::eLessOrEqual;
    case CompareFunction::kGreater:
      return vk::CompareOp::eGreater;
    case CompareFunction::kNotEqual:
      return vk::CompareOp::eNotEqual;
    case CompareFunction::kGreaterEqual:
      return vk::CompareOp::eGreaterOrEqual;
  }
  FML_UNREACHABLE();
}

constexpr vk::StencilOp ToVKStencilOp(StencilOperation op) {
  switch (op) {
    case StencilOperation::kKeep:
      return vk::StencilOp::eKeep;
    case StencilOperation::kZero:
      return vk::StencilOp::eZero;
    case StencilOperation::kSetToReferenceValue:
      return vk::StencilOp::eReplace;
    case StencilOperation::kIncrementClamp:
      return vk::StencilOp::eIncrementAndClamp;
    case StencilOperation::kDecrementClamp:
      return vk::StencilOp::eDecrementAndClamp;
    case StencilOperation::kInvert:
      return vk::StencilOp::eInvert;
    case StencilOperation::kIncrementWrap:
      return vk::StencilOp::eIncrementAndWrap;
    case StencilOperation::kDecrementWrap:
      return vk::StencilOp::eDecrementAndWrap;
      break;
  }
  FML_UNREACHABLE();
}

constexpr vk::StencilOpState ToVKStencilOpState(
    const StencilAttachmentDescriptor& desc) {
  vk::StencilOpState state;
  state.failOp = ToVKStencilOp(desc.stencil_failure);
  state.passOp = ToVKStencilOp(desc.depth_stencil_pass);
  state.depthFailOp = ToVKStencilOp(desc.depth_failure);
  state.compareOp = ToVKCompareOp(desc.stencil_compare);
  state.compareMask = desc.read_mask;
  state.writeMask = desc.write_mask;
  // This is irrelevant as the stencil references are always dynamic state and
  // will be set in the render pass.
  state.reference = 1988;
  return state;
}

constexpr vk::ImageAspectFlags ToVKImageAspectFlags(PixelFormat format) {
  switch (format) {
    case PixelFormat::kUnknown:
    case PixelFormat::kA8UNormInt:
    case PixelFormat::kR8UNormInt:
    case PixelFormat::kR8G8UNormInt:
    case PixelFormat::kR8G8B8A8UNormInt:
    case PixelFormat::kR8G8B8A8UNormIntSRGB:
    case PixelFormat::kB8G8R8A8UNormInt:
    case PixelFormat::kB8G8R8A8UNormIntSRGB:
    case PixelFormat::kR32G32B32A32Float:
    case PixelFormat::kR16G16B16A16Float:
    case PixelFormat::kB10G10R10XR:
    case PixelFormat::kB10G10R10XRSRGB:
    case PixelFormat::kB10G10R10A10XR:
      return vk::ImageAspectFlagBits::eColor;
    case PixelFormat::kS8UInt:
      return vk::ImageAspectFlagBits::eStencil;
    case PixelFormat::kD32FloatS8UInt:
      return vk::ImageAspectFlagBits::eDepth |
             vk::ImageAspectFlagBits::eStencil;
  }
  FML_UNREACHABLE();
}

constexpr uint32_t ToArrayLayerCount(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
    case TextureType::kTexture2DMultisample:
      return 1u;
    case TextureType::kTextureCube:
      return 6u;
  }
  FML_UNREACHABLE();
}

constexpr vk::ImageViewType ToVKImageViewType(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
    case TextureType::kTexture2DMultisample:
      return vk::ImageViewType::e2D;
    case TextureType::kTextureCube:
      return vk::ImageViewType::eCube;
  }
  FML_UNREACHABLE();
}

constexpr vk::ImageCreateFlags ToVKImageCreateFlags(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
    case TextureType::kTexture2DMultisample:
      return {};
    case TextureType::kTextureCube:
      return vk::ImageCreateFlagBits::eCubeCompatible;
  }
  FML_UNREACHABLE();
}

vk::PipelineDepthStencilStateCreateInfo ToVKPipelineDepthStencilStateCreateInfo(
    std::optional<DepthAttachmentDescriptor> depth,
    std::optional<StencilAttachmentDescriptor> front,
    std::optional<StencilAttachmentDescriptor> back);

constexpr vk::ImageAspectFlags ToImageAspectFlags(PixelFormat format) {
  switch (format) {
    case PixelFormat::kUnknown:
      return {};
    case PixelFormat::kA8UNormInt:
    case PixelFormat::kR8UNormInt:
    case PixelFormat::kR8G8UNormInt:
    case PixelFormat::kR8G8B8A8UNormInt:
    case PixelFormat::kR8G8B8A8UNormIntSRGB:
    case PixelFormat::kB8G8R8A8UNormInt:
    case PixelFormat::kB8G8R8A8UNormIntSRGB:
    case PixelFormat::kR32G32B32A32Float:
    case PixelFormat::kR16G16B16A16Float:
    case PixelFormat::kB10G10R10XR:
    case PixelFormat::kB10G10R10XRSRGB:
    case PixelFormat::kB10G10R10A10XR:
      return vk::ImageAspectFlagBits::eColor;
    case PixelFormat::kS8UInt:
      return vk::ImageAspectFlagBits::eStencil;
    case PixelFormat::kD32FloatS8UInt:
      return vk::ImageAspectFlagBits::eDepth |
             vk::ImageAspectFlagBits::eStencil;
  }
  FML_UNREACHABLE();
}

struct LayoutTransition {
  vk::CommandBuffer cmd_buffer = {};
  vk::ImageLayout new_layout = vk::ImageLayout::eUndefined;
  vk::PipelineStageFlags src_stage = vk::PipelineStageFlagBits::eNone;
  vk::AccessFlags src_access = vk::AccessFlagBits::eNone;
  vk::PipelineStageFlags dst_stage = vk::PipelineStageFlagBits::eNone;
  vk::AccessFlags dst_access = vk::AccessFlagBits::eNone;
};

}  // namespace impeller
