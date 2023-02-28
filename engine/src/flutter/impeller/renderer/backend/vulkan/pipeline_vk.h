// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/pipeline.h"

namespace impeller {

class PipelineCreateInfoVK {
 public:
  PipelineCreateInfoVK(vk::UniquePipeline pipeline,
                       vk::UniqueRenderPass render_pass,
                       vk::UniquePipelineLayout pipeline_layout,
                       vk::UniqueDescriptorSetLayout descriptor_set_layout);

  bool IsValid() const;

  const vk::Pipeline& GetVKPipeline() const;

  vk::RenderPass GetRenderPass() const;

  vk::PipelineLayout GetPipelineLayout() const;

  vk::DescriptorSetLayout GetDescriptorSetLayout() const;

 private:
  bool is_valid_ = false;
  vk::UniquePipeline pipeline_;
  vk::UniqueRenderPass render_pass_;
  vk::UniquePipelineLayout pipeline_layout_;
  vk::UniqueDescriptorSetLayout descriptor_set_layout_;
};

class PipelineVK final
    : public Pipeline<PipelineDescriptor>,
      public BackendCast<PipelineVK, Pipeline<PipelineDescriptor>> {
 public:
  PipelineVK(std::weak_ptr<PipelineLibrary> library,
             const PipelineDescriptor& desc,
             std::unique_ptr<PipelineCreateInfoVK> create_info);

  // |Pipeline|
  ~PipelineVK() override;

  PipelineCreateInfoVK* GetCreateInfo() const;

 private:
  friend class PipelineLibraryVK;

  // |Pipeline|
  bool IsValid() const override;

  std::unique_ptr<PipelineCreateInfoVK> pipeline_info_;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineVK);
};

}  // namespace impeller
