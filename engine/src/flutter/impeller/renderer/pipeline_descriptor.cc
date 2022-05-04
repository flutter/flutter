// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_descriptor.h"

#include "impeller/renderer/formats.h"
#include "impeller/renderer/shader_function.h"
#include "impeller/renderer/shader_library.h"
#include "impeller/renderer/vertex_descriptor.h"

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
  fml::HashCombineSeed(seed, depth_pixel_format_);
  fml::HashCombineSeed(seed, stencil_pixel_format_);
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
         stencil_pixel_format_ == other.stencil_pixel_format_ &&
         depth_pixel_format_ == other.depth_pixel_format_ &&
         depth_attachment_descriptor_ == other.depth_attachment_descriptor_ &&
         front_stencil_attachment_descriptor_ ==
             other.front_stencil_attachment_descriptor_ &&
         back_stencil_attachment_descriptor_ ==
             other.back_stencil_attachment_descriptor_;
}

PipelineDescriptor& PipelineDescriptor::SetLabel(std::string label) {
  label_ = std::move(label);
  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetSampleCount(SampleCount samples) {
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

PipelineDescriptor& PipelineDescriptor::SetColorAttachmentDescriptors(
    std::map<size_t /* index */, ColorAttachmentDescriptor> descriptors) {
  color_attachment_descriptors_ = std::move(descriptors);
  return *this;
}

const ColorAttachmentDescriptor*
PipelineDescriptor::GetColorAttachmentDescriptor(size_t index) const {
  auto found = color_attachment_descriptors_.find(index);
  return found == color_attachment_descriptors_.end() ? nullptr
                                                      : &found->second;
}

const ColorAttachmentDescriptor*
PipelineDescriptor::GetLegacyCompatibleColorAttachment() const {
  // Legacy renderers may only render to a single color attachment at index 0u.
  if (color_attachment_descriptors_.size() != 1u) {
    return nullptr;
  }
  return GetColorAttachmentDescriptor(0u);
}

PipelineDescriptor& PipelineDescriptor::SetDepthPixelFormat(
    PixelFormat format) {
  depth_pixel_format_ = format;
  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetStencilPixelFormat(
    PixelFormat format) {
  stencil_pixel_format_ = format;
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

void PipelineDescriptor::ResetAttachments() {
  color_attachment_descriptors_.clear();
  depth_attachment_descriptor_.reset();
  front_stencil_attachment_descriptor_.reset();
  back_stencil_attachment_descriptor_.reset();
}

PixelFormat PipelineDescriptor::GetStencilPixelFormat() const {
  return stencil_pixel_format_;
}

std::optional<StencilAttachmentDescriptor>
PipelineDescriptor::GetFrontStencilAttachmentDescriptor() const {
  return front_stencil_attachment_descriptor_;
}

std::optional<DepthAttachmentDescriptor>
PipelineDescriptor::GetDepthStencilAttachmentDescriptor() const {
  return depth_attachment_descriptor_;
}

const std::map<size_t /* index */, ColorAttachmentDescriptor>&
PipelineDescriptor::GetColorAttachmentDescriptors() const {
  return color_attachment_descriptors_;
}

const std::shared_ptr<VertexDescriptor>&
PipelineDescriptor::GetVertexDescriptor() const {
  return vertex_descriptor_;
}

const std::map<ShaderStage, std::shared_ptr<const ShaderFunction>>&
PipelineDescriptor::GetStageEntrypoints() const {
  return entrypoints_;
}

std::shared_ptr<const ShaderFunction> PipelineDescriptor::GetEntrypointForStage(
    ShaderStage stage) const {
  if (auto found = entrypoints_.find(stage); found != entrypoints_.end()) {
    return found->second;
  }
  return nullptr;
}

const std::string& PipelineDescriptor::GetLabel() const {
  return label_;
}

PixelFormat PipelineDescriptor::GetDepthPixelFormat() const {
  return depth_pixel_format_;
}

std::optional<StencilAttachmentDescriptor>
PipelineDescriptor::GetBackStencilAttachmentDescriptor() const {
  return back_stencil_attachment_descriptor_;
}

bool PipelineDescriptor::HasStencilAttachmentDescriptors() const {
  return front_stencil_attachment_descriptor_.has_value() ||
         back_stencil_attachment_descriptor_.has_value();
}

}  // namespace impeller
