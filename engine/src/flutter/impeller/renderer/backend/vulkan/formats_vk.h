// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/descriptor_set_layout.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/shader_types.h"
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
    case MipFilter::kNone:
      return vk::SamplerMipmapMode::eNearest;
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

constexpr vk::DescriptorSetLayoutBinding ToVKDescriptorSetLayoutBinding(
    const DescriptorSetLayout& layout) {
  vk::DescriptorSetLayoutBinding binding;
  binding.binding = layout.binding;
  binding.descriptorCount = layout.descriptor_count;
  vk::DescriptorType desc_type = vk::DescriptorType();
  switch (layout.descriptor_type) {
    case DescriptorType::kSampledImage:
      desc_type = vk::DescriptorType::eCombinedImageSampler;
      break;
    case DescriptorType::kUniformBuffer:
      desc_type = vk::DescriptorType::eUniformBuffer;
      break;
  }
  binding.descriptorType = desc_type;
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
      // TODO (kaushikiska): vulkan doesn't support multisample resolve.
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

}  // namespace impeller
