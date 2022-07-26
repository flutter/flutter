// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_vk.h"

namespace impeller {

PipelineCreateInfoVK::PipelineCreateInfoVK(vk::UniquePipeline pipeline,
                                           vk::UniqueRenderPass render_pass)
    : pipeline_(std::move(pipeline)), render_pass_(std::move(render_pass)) {
  is_valid_ = pipeline_ && render_pass_;
}

bool PipelineCreateInfoVK::IsValid() const {
  return is_valid_;
}

vk::UniquePipeline PipelineCreateInfoVK::GetPipeline() {
  return std::move(pipeline_);
}

vk::UniqueRenderPass PipelineCreateInfoVK::GetRenderPass() {
  return std::move(render_pass_);
}

PipelineVK::PipelineVK(std::weak_ptr<PipelineLibrary> library,
                       PipelineDescriptor desc,
                       std::unique_ptr<PipelineCreateInfoVK> create_info)
    : Pipeline(std::move(library), std::move(desc)),
      pipeline_info_(std::move(create_info)) {}

PipelineVK::~PipelineVK() = default;

bool PipelineVK::IsValid() const {
  return pipeline_info_->IsValid();
}

}  // namespace impeller
