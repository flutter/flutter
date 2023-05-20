// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_vk.h"

namespace impeller {

PipelineVK::PipelineVK(std::weak_ptr<DeviceHolder> device_holder,
                       std::weak_ptr<PipelineLibrary> library,
                       const PipelineDescriptor& desc,
                       vk::UniquePipeline pipeline,
                       vk::UniqueRenderPass render_pass,
                       vk::UniquePipelineLayout layout,
                       vk::UniqueDescriptorSetLayout descriptor_set_layout)
    : Pipeline(std::move(library), desc),
      device_holder_(device_holder),
      pipeline_(std::move(pipeline)),
      render_pass_(std::move(render_pass)),
      layout_(std::move(layout)),
      descriptor_set_layout_(std::move(descriptor_set_layout)) {
  is_valid_ = pipeline_ && render_pass_ && layout_ && descriptor_set_layout_;
}

PipelineVK::~PipelineVK() {
  std::shared_ptr<DeviceHolder> device_holder = device_holder_.lock();
  if (device_holder) {
    descriptor_set_layout_.reset();
    layout_.reset();
    render_pass_.reset();
    pipeline_.reset();
  } else {
    descriptor_set_layout_.release();
    layout_.release();
    render_pass_.release();
    pipeline_.release();
  }
}

bool PipelineVK::IsValid() const {
  return is_valid_;
}

const vk::Pipeline& PipelineVK::GetPipeline() const {
  return *pipeline_;
}

const vk::RenderPass& PipelineVK::GetRenderPass() const {
  return *render_pass_;
}

const vk::PipelineLayout& PipelineVK::GetPipelineLayout() const {
  return *layout_;
}

const vk::DescriptorSetLayout& PipelineVK::GetDescriptorSetLayout() const {
  return *descriptor_set_layout_;
}

}  // namespace impeller
