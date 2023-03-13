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

class PipelineVK final
    : public Pipeline<PipelineDescriptor>,
      public BackendCast<PipelineVK, Pipeline<PipelineDescriptor>> {
 public:
  PipelineVK(std::weak_ptr<PipelineLibrary> library,
             const PipelineDescriptor& desc,
             vk::UniquePipeline pipeline,
             vk::UniqueRenderPass render_pass,
             vk::UniquePipelineLayout layout,
             vk::UniqueDescriptorSetLayout descriptor_set_layout);

  // |Pipeline|
  ~PipelineVK() override;

  const vk::Pipeline& GetPipeline() const;

  const vk::RenderPass& GetRenderPass() const;

  const vk::PipelineLayout& GetPipelineLayout() const;

  const vk::DescriptorSetLayout& GetDescriptorSetLayout() const;

 private:
  friend class PipelineLibraryVK;

  const vk::UniquePipeline pipeline_;
  const vk::UniqueRenderPass render_pass_;
  const vk::UniquePipelineLayout layout_;
  const vk::UniqueDescriptorSetLayout descriptor_set_layout_;
  bool is_valid_ = false;

  // |Pipeline|
  bool IsValid() const override;

  std::unique_ptr<PipelineVK> CreatePipeline(const PipelineDescriptor& desc);

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineVK);
};

}  // namespace impeller
