// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/pipeline_descriptor.h"

#include "impeller/compositor/formats_metal.h"
#include "impeller/compositor/shader_library.h"
#include "impeller/compositor/vertex_descriptor.h"

namespace impeller {

PipelineDescriptor::PipelineDescriptor() = default;

PipelineDescriptor::~PipelineDescriptor() = default;

// Comparable<PipelineDescriptor>
std::size_t PipelineDescriptor::GetHash() const {
  auto seed = fml::HashCombine();
  fml::HashCombineSeed(seed, label_);
  fml::HashCombineSeed(seed, sample_count_);
  for (const auto& entry : entrypoints_) {
    fml::HashCombineSeed(seed, entry.first);
    if (auto second = entry.second) {
      fml::HashCombineSeed(seed, second->GetHash());
    }
  }
  for (const auto& des : color_attachment_descriptors_) {
    fml::HashCombineSeed(seed, des.first);
    fml::HashCombineSeed(seed, des.second.Hash());
  }
  if (vertex_descriptor_) {
    fml::HashCombineSeed(seed, vertex_descriptor_->GetHash());
  }
  fml::HashCombineSeed(seed, depth_stencil_pixel_format_);
  fml::HashCombineSeed(seed, depth_attachment_descriptor_);
  fml::HashCombineSeed(seed, front_stencil_attachment_descriptor_);
  fml::HashCombineSeed(seed, back_stencil_attachment_descriptor_);
  return seed;
}

// Comparable<PipelineDescriptor>
bool PipelineDescriptor::IsEqual(const PipelineDescriptor& other) const {
  return label_ == other.label_ && sample_count_ == other.sample_count_ &&
         DeepCompareMap(entrypoints_, other.entrypoints_) &&
         color_attachment_descriptors_ == other.color_attachment_descriptors_ &&
         DeepComparePointer(vertex_descriptor_, other.vertex_descriptor_) &&
         depth_stencil_pixel_format_ == other.depth_stencil_pixel_format_ &&
         depth_attachment_descriptor_ == other.depth_attachment_descriptor_ &&
         front_stencil_attachment_descriptor_ ==
             other.front_stencil_attachment_descriptor_ &&
         back_stencil_attachment_descriptor_ ==
             other.back_stencil_attachment_descriptor_;
}

PipelineDescriptor& PipelineDescriptor::SetLabel(
    const std::string_view& label) {
  label_ = {label.data(), label.size()};
  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetSampleCount(size_t samples) {
  sample_count_ = samples;
  return *this;
}

PipelineDescriptor& PipelineDescriptor::AddStageEntrypoint(
    std::shared_ptr<const ShaderFunction> function) {
  if (!function) {
    return *this;
  }

  if (function->GetStage() == ShaderStage::kUnknown) {
    return *this;
  }

  entrypoints_[function->GetStage()] = std::move(function);

  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetVertexDescriptor(
    std::shared_ptr<VertexDescriptor> vertex_descriptor) {
  vertex_descriptor_ = std::move(vertex_descriptor);
  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetColorAttachmentDescriptor(
    size_t index,
    ColorAttachmentDescriptor desc) {
  color_attachment_descriptors_[index] = std::move(desc);
  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetDepthStencilPixelFormat(
    PixelFormat format) {
  depth_stencil_pixel_format_ = format;
  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetDepthStencilAttachmentDescriptor(
    DepthAttachmentDescriptor desc) {
  depth_attachment_descriptor_ = desc;
  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetStencilAttachmentDescriptors(
    StencilAttachmentDescriptor front_and_back) {
  return SetStencilAttachmentDescriptors(front_and_back, front_and_back);
}

PipelineDescriptor& PipelineDescriptor::SetStencilAttachmentDescriptors(
    StencilAttachmentDescriptor front,
    StencilAttachmentDescriptor back) {
  front_stencil_attachment_descriptor_ = front;
  back_stencil_attachment_descriptor_ = back;
  return *this;
}

MTLRenderPipelineDescriptor*
PipelineDescriptor::GetMTLRenderPipelineDescriptor() const {
  auto descriptor = [[MTLRenderPipelineDescriptor alloc] init];
  descriptor.label = @(label_.c_str());
  descriptor.sampleCount = sample_count_;

  for (const auto& entry : entrypoints_) {
    if (entry.first == ShaderStage::kVertex) {
      descriptor.vertexFunction = entry.second->GetMTLFunction();
    }
    if (entry.first == ShaderStage::kFragment) {
      descriptor.fragmentFunction = entry.second->GetMTLFunction();
    }
  }

  if (vertex_descriptor_) {
    descriptor.vertexDescriptor = vertex_descriptor_->GetMTLVertexDescriptor();
  }

  for (const auto& item : color_attachment_descriptors_) {
    descriptor.colorAttachments[item.first] =
        ToMTLRenderPipelineColorAttachmentDescriptor(item.second);
  }

  descriptor.depthAttachmentPixelFormat =
      ToMTLPixelFormat(depth_stencil_pixel_format_);
  descriptor.stencilAttachmentPixelFormat =
      ToMTLPixelFormat(depth_stencil_pixel_format_);

  return descriptor;
}

id<MTLDepthStencilState> PipelineDescriptor::CreateDepthStencilDescriptor(
    id<MTLDevice> device) const {
  auto descriptor =
      ToMTLDepthStencilDescriptor(depth_attachment_descriptor_,          //
                                  front_stencil_attachment_descriptor_,  //
                                  back_stencil_attachment_descriptor_    //
      );
  return [device newDepthStencilStateWithDescriptor:descriptor];
}

}  // namespace impeller
