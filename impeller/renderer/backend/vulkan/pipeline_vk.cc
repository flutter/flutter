// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_vk.h"

namespace impeller {

PipelineCreateInfoVK::PipelineCreateInfoVK(
    vk::UniquePipeline pipeline,
    vk::UniqueRenderPass render_pass,
    vk::UniquePipelineLayout layout,
    vk::UniqueDescriptorSetLayout descriptor_set_layout)
    : pipeline_(std::move(pipeline)),
      render_pass_(std::move(render_pass)),
      pipeline_layout_(std::move(layout)),
      descriptor_set_layout_(std::move(descriptor_set_layout)) {
  is_valid_ =
      pipeline_ && render_pass_ && pipeline_layout_ && descriptor_set_layout_;
}

bool PipelineCreateInfoVK::IsValid() const {
  return is_valid_;
}

const vk::Pipeline& PipelineCreateInfoVK::GetVKPipeline() const {
  return *pipeline_;
}

vk::RenderPass PipelineCreateInfoVK::GetRenderPass() const {
  return *render_pass_;
}

vk::PipelineLayout PipelineCreateInfoVK::GetPipelineLayout() const {
  return *pipeline_layout_;
}

vk::DescriptorSetLayout PipelineCreateInfoVK::GetDescriptorSetLayout() const {
  return *descriptor_set_layout_;
}

PipelineVK::PipelineVK(std::weak_ptr<PipelineLibrary> library,
                       const PipelineDescriptor& desc,
                       std::unique_ptr<PipelineCreateInfoVK> create_info)
    : Pipeline(std::move(library), desc),
      pipeline_info_(std::move(create_info)) {}

PipelineVK::~PipelineVK() = default;

bool PipelineVK::IsValid() const {
  return pipeline_info_->IsValid();
}

PipelineCreateInfoVK* PipelineVK::GetCreateInfo() const {
  return pipeline_info_.get();
}

}  // namespace impeller
