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
                       vk::UniqueRenderPass render_pass);

  bool IsValid() const;

  vk::UniquePipeline GetPipeline();

  vk::UniqueRenderPass GetRenderPass();

 private:
  bool is_valid_ = false;
  vk::UniquePipeline pipeline_;
  vk::UniqueRenderPass render_pass_;
};

class PipelineVK final : public Pipeline,
                         public BackendCast<PipelineVK, Pipeline> {
 public:
  PipelineVK(std::weak_ptr<PipelineLibrary> library,
             PipelineDescriptor desc,
             std::unique_ptr<PipelineCreateInfoVK> create_info);

  // |Pipeline|
  ~PipelineVK() override;

 private:
  friend class PipelineLibraryVK;

  // |Pipeline|
  bool IsValid() const override;

  std::unique_ptr<PipelineCreateInfoVK> pipeline_info_;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineVK);
};

}  // namespace impeller
