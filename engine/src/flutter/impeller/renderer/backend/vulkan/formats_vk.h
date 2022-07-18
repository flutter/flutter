// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/shader_types.h"

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

}  // namespace impeller
